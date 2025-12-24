from fastapi import APIRouter, HTTPException, Depends
import stripe
from pydantic import BaseModel
from .config import STRIPE_SECRET_KEY
from .auth import get_current_user
from .models import User

router = APIRouter(prefix="/payments", tags=["payments"])

stripe.api_key = STRIPE_SECRET_KEY

class PaymentIntentRequest(BaseModel):
    amount: int  # Amount in cents
    currency: str = "usd"

class PaymentIntentResponse(BaseModel):
    clientSecret: str
    ephemeralKey: str
    customer: str
    publishableKey: str = "" # Optional, client might need it

@router.post("/create-payment-intent", response_model=PaymentIntentResponse)
def create_payment_intent(
    payload: PaymentIntentRequest,
    current_user: User = Depends(get_current_user)
):
    try:
        # 1. Search for existing customer by email
        customers = stripe.Customer.list(email=current_user.email, limit=1).data
        if customers:
            customer = customers[0]
        else:
            # 2. Create new customer if not exists
            customer = stripe.Customer.create(
                email=current_user.email,
                name=current_user.display_name,
                metadata={"uid": current_user.uid}
            )

        # 3. Create Ephemeral Key (required for Stripe Payment Sheet)
        ephemeral_key = stripe.EphemeralKey.create(
            customer=customer.id,
            stripe_version="2023-10-16" # Use a pinned version or latest
        )

        # 4. Create Payment Intent
        payment_intent = stripe.PaymentIntent.create(
            amount=payload.amount,
            currency=payload.currency,
            customer=customer.id,
            automatic_payment_methods={"enabled": True},
        )

        return PaymentIntentResponse(
            clientSecret=payment_intent.client_secret,
            ephemeralKey=ephemeral_key.secret,
            customer=customer.id
        )

    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
