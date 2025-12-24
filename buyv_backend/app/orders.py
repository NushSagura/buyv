from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
import json

from .database import get_db
from .models import User, Order, OrderItem, Commission
from .auth import get_current_user
from .schemas import (
    OrderCreate,
    OrderOut,
    OrderItemOut,
    StatusUpdate,
    TrackingUpdate,
    Address,
)

router = APIRouter(prefix="/orders", tags=["orders"])


def _generate_order_number() -> str:
    ts = int(datetime.utcnow().timestamp() * 1000)
    rand = ts % 10000
    return f"ORD{ts}{rand}"



def _map_order_item_out(item: OrderItem) -> dict:
    try:
        attrs = json.loads(item.attributes) if item.attributes else {}
    except Exception:
        attrs = {}
    return {
        "id": item.id,
        "product_id": item.product_id,
        "product_name": item.product_name,
        "product_image": item.product_image,
        "price": item.price,
        "quantity": item.quantity,
        "size": item.size,
        "color": item.color,
        "attributes": attrs,
        "is_promoted_product": item.is_promoted_product,
        "promoter_uid": item.promoter_uid,
    }


def _map_order_out(order: Order, db: Session) -> dict:
    try:
        shipping_addr_dict = json.loads(order.shipping_address) if order.shipping_address else None
        # Align keys if stored differently in DB vs Schema alias expectations
        # Schema expects: fullName, address, city... (CamelModel will handle snake_case inputs if we pass snake_case keys, OR we pass camelCase keys directly if that's what we have)
        # But wait, Address schema uses aliases: fullName = Field(alias="fullName").
        # If we return a dict, Pydantic with populate_by_name=True can take "full_name" or "fullName".
        # Let's assume DB JSON was stored nicely or we map it. 
        # Flutter sends: fullName, address. So DB JSON likely has fullName, address.
        # Address schema: full_name field.
        # If DB JSON has "fullName", passing it to full_name field might need mapping if we want to be strict, but CamelModel populate_by_name=True allows "fullName" to populate "full_name".
        # So passing the dict as-is should work.
    except Exception:
        shipping_addr_dict = None

    user = db.query(User).filter(User.id == order.user_id).first()
    # order.user_id is int. Schema OrderOut.user_id is int. OrderOut.promoter_uid is string.

    return {
        "id": order.id,
        "user_id": order.user_id,
        "order_number": order.order_number,
        "items": [_map_order_item_out(i) for i in order.items],
        "status": order.status,
        "subtotal": order.subtotal,
        "shipping": order.shipping,
        "tax": order.tax,
        "total_amount": order.total, # Mapped to total_amount in schema (aliased to totalAmount)
        "shipping_address": shipping_addr_dict,
        
        # Construct payment_info object
        "payment_info": {
            "method": order.payment_method,
            "status": order.status, # Assuming payment status matches order status for now, or "paid"
            "amount": order.total,
        },
        
        "created_at": order.created_at,
        "updated_at": order.updated_at,
        "estimated_delivery": order.estimated_delivery,
        "tracking_number": order.tracking_number,
        "notes": order.notes or "",
        "promoter_uid": order.promoter_uid,
    }


@router.post("", response_model=OrderOut)
def create_order(
    payload: OrderCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order_number = payload.order_number or _generate_order_number()
    # payload.shipping_address is Address model. .dict(by_alias=True) to store as Flutter sent it? Or as keys?
    # Let's store as keys compatible with our Schema later. 
    shipping_address_json = (
        json.dumps(payload.shipping_address.model_dump(by_alias=True)) if payload.shipping_address else None
    )

    order = Order(
        order_number=order_number,
        user_id=current_user.id,
        status=payload.status or "pending",
        subtotal=payload.subtotal,
        shipping=payload.shipping,
        tax=payload.tax,
        total=payload.total,
        shipping_address=shipping_address_json,
        payment_method=payload.payment_method,
        estimated_delivery=payload.estimated_delivery,
        tracking_number=payload.tracking_number,
        notes=payload.notes,
        promoter_uid=payload.promoter_id,
    )
    db.add(order)
    db.commit()
    db.refresh(order)

    # Add items
    for item in payload.items:
        attributes_json = json.dumps(item.attributes or {})
        oi = OrderItem(
            order_id=order.id,
            product_id=item.product_id,
            product_name=item.product_name,
            product_image=item.product_image,
            price=item.price,
            quantity=item.quantity,
            size=item.size,
            color=item.color,
            attributes=attributes_json,
            is_promoted_product=item.is_promoted_product,
            promoter_uid=item.promoter_id or payload.promoter_id,
        )
        db.add(oi)
    db.commit()
    db.refresh(order)

    # Generate commissions for promoted items
    for item in order.items:
        if item.is_promoted_product and item.promoter_uid:
            promoter = db.query(User).filter(User.uid == item.promoter_uid).first()
            rate = 0.01
            amount = round(item.price * item.quantity * rate, 2)
            commission = Commission(
                user_id=promoter.id if promoter else None,
                user_uid=item.promoter_uid,
                order_id=order.id,
                order_item_id=item.id,
                product_id=item.product_id,
                product_name=item.product_name,
                product_price=item.price,
                commission_rate=rate,
                commission_amount=amount,
                status="pending",
                metadata_json=json.dumps({
                    "orderId": str(order.id),
                    "orderNumber": order.order_number,
                    "orderItemId": str(item.id),
                }),
            )
            db.add(commission)
    db.commit()
    db.refresh(order)

    return _map_order_out(order, db)


@router.get("/me", response_model=list[OrderOut])
def list_my_orders(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rows = (
        db.query(Order)
        .filter(Order.user_id == current_user.id)
        .order_by(Order.created_at.desc())
        .all()
    )
    return [_map_order_out(row, db) for row in rows]


@router.get("/{order_id}", response_model=OrderOut)
def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = (
        db.query(Order)
        .filter(Order.id == order_id, Order.user_id == current_user.id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return _map_order_out(order, db)


@router.get("/me/by_status", response_model=list[OrderOut])
def list_my_orders_by_status(
    status: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rows = (
        db.query(Order)
        .filter(Order.user_id == current_user.id, Order.status == status)
        .order_by(Order.created_at.desc())
        .all()
    )
    return [_map_order_out(row, db) for row in rows]


@router.patch("/{order_id}/status")
def update_status(
    order_id: int,
    payload: StatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = (
        db.query(Order)
        .filter(Order.id == order_id, Order.user_id == current_user.id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    order.status = payload.status
    order.updated_at = datetime.utcnow()
    db.add(order)
    db.commit()

    # Update commission status based on order status
    if payload.status.lower() == "delivered":
        commissions = db.query(Commission).filter(Commission.order_id == order.id).all()
        for c in commissions:
            c.status = "paid"
            c.paid_at = datetime.utcnow()
            c.updated_at = datetime.utcnow()
            db.add(c)
        db.commit()
    elif payload.status.lower() == "canceled":
        commissions = db.query(Commission).filter(Commission.order_id == order.id).all()
        for c in commissions:
            c.status = "canceled"
            c.updated_at = datetime.utcnow()
            db.add(c)
        db.commit()

    db.refresh(order)
    return {"status": "ok"}


@router.post("/{order_id}/cancel")
def cancel_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = (
        db.query(Order)
        .filter(Order.id == order_id, Order.user_id == current_user.id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")

    order.status = "canceled"
    order.updated_at = datetime.utcnow()
    db.add(order)
    db.commit()

    commissions = db.query(Commission).filter(Commission.order_id == order.id).all()
    for c in commissions:
        c.status = "canceled"
        c.updated_at = datetime.utcnow()
        db.add(c)
    db.commit()

    return {"status": "ok"}


@router.patch("/{order_id}/tracking")
def update_tracking(
    order_id: int,
    payload: TrackingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order = (
        db.query(Order)
        .filter(Order.id == order_id, Order.user_id == current_user.id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    order.tracking_number = payload.tracking_number
    order.updated_at = datetime.utcnow()
    db.add(order)
    db.commit()
    return {"status": "ok"}