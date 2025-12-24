# BuyV Project - Handover & Setup Guide

This project has been refactored to support dynamic environments, secure configuration, and strict API alignment between Flutter and Backend.

## 🚀 Key Changes

1.  **Dynamic Environment:** The Flutter app automatically detects if it's running on Web (`localhost`), Android Emulator (`10.0.2.2`), or iOS Simulator.
2.  **Security:** All API keys and Database credentials are moved to `.env` files.
3.  **API Alignment:** Backend schemas now automatically convert `snake_case` (DB) to `camelCase` (Flutter) and provide proper nested objects for Orders and Posts.

---

## 🛠️ Step 1: Backend Setup

### 1. Configuration
Navigate to `buyv_backend/` and copy the example environment file:
```bash
cp .env.example .env
```
Edit `.env` and fill in your details:
- `DATABASE_URL`: Your SQLite or MySQL URL.
- `CJ_API_KEY`: Your CJ Dropshipping API Key.
- `CJ_ACCOUNT_ID`: Your CJ Account ID.

### 2. Install Dependencies
```bash
cd buyv_backend
pip install -r requirements.txt
```

### 3. Run the Server
Double-click **`run_backend.bat`** (Windows) or run:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
> **Note:** Running on `0.0.0.0` is crucial for Android Emulator access.

---

## 📱 Step 2: Flutter Setup

### 1. Configuration
Navigate to `buyv_flutter_app/` and copy the example environment file:
```bash
# Windows
copy .env.example .env
```
Edit `.env`:
- `CJ_API_KEY`: Same as backend (if used directly).
- `CLOUDINARY_CLOUD_NAME`: Your Cloudinary cloud name.

### 2. Install Dependencies
```bash
cd buyv_flutter_app
flutter pub get
```

### 3. Run the App
- **Web:** `flutter run -d chrome`
- **Android Emulator:** `flutter run -d android`
    - *Network Note:* The app internally maps `localhost` to `10.0.2.2` for emulators properly.

---

## 📂 Project Structure

### `buyv_backend/`
- `app/main.py`: Entry point. Configured with CORS for `localhost` and `10.0.2.2`.
- `app/schemas.py`: **Critical.** Defines `CamelModel` which handles JSON serialization alignment.
- `app/config.py`: Loads secrets from `.env`.
- `run_backend.bat`: Start script.

### `buyv_flutter_app/`
- `lib/core/config/environment_config.dart`: **Critical.** Central logic for picking the right Base URL based on Platform (Web vs Android).
- `lib/constants/app_constants.dart`: Uses `EnvironmentConfig` and `dotenv`.
- `assets/.env`: Secure storage for API keys.

---

## ⚠️ Troubleshooting

**Q: App cannot connect to Backend on Emulator?**
A: Ensure the backend is running on `0.0.0.0` (use the `.bat` file), not just `127.0.0.1`.

**Q: "Missing .env file" error in Flutter?**
A: Ensure you created `.env` in `buyv_flutter_app/` and ran `flutter pub get`.

**Q: JSON parsing errors (null fields)?**
A: This usually means a mismatch in field names. The backend uses `CamelModel` to alias `snake_case` DB fields to `camelCase`. Ensure you haven't renamed fields in `schemas.py` without testing.
