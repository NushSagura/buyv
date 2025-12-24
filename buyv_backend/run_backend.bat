@echo off
echo Starting BuyV Backend on 0.0.0.0:8000...
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
