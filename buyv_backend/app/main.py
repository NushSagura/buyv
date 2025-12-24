from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import engine, Base
from .auth import router as auth_router
from .users import router as users_router
from .follows import router as follows_router
from .notifications import router as notifications_router
from .orders import router as orders_router
from .commissions import router as commissions_router
from .posts import router as posts_router
from .comments import router as comments_router
from .payments import router as payments_router

# Create tables if not exist
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Buyv API", version="0.1.0")

# CORS for Flutter dev (web/desktop/emulator)
origins = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:5173",
    "http://localhost:8080",
    "http://localhost:5500",
    "http://127.0.0.1",
    "http://127.0.0.1:5173",
    "http://127.0.0.1:5500",
    "http://10.0.2.2",      # Android Emulator default
    "http://10.0.2.2:8000",
    "http://10.0.3.2",      # Genymotion
    "http://10.0.3.2:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For dev phase, allow all. Can be restricted to `origins` later.
    # allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(follows_router)
app.include_router(notifications_router)
app.include_router(orders_router)
app.include_router(commissions_router)
app.include_router(posts_router)
app.include_router(comments_router)
app.include_router(payments_router)