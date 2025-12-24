# Railway Deployment Guide 🚀

This guide explains how to deploy your **FastAPI Backend** to Railway.app and connect it to your Flutter app.

## Why Railway?
*   **Zero Config**: It detects our `Dockerfile` automatically.
*   **Public URL**: You get a real `https://...up.railway.app` URL for your app.
*   **24/7 Uptime**: Your server runs continuously in the cloud.
*   **Built-in Database**: Easily add a MySQL or PostgreSQL database.

---

## Part 1: Prepare Your Code

1.  **Code Check**: Ensure your `buyv_backend` folder has:
    *   `Dockerfile` (Created by me)
    *   `requirements.txt` (Updated with latest packages)
    *   `app/` folder (Your code)

2.  **GitHub**: Push your project to GitHub. Railway pulls code directly from there.

---

## Part 2: Deploy to Railway

1.  **Sign Up**: Go to [Railway.app](https://railway.app/) and login with GitHub.
2.  **New Project**: Click **"New Project"** -> **"Deploy from GitHub repo"**.
3.  **Select Repo**: Choose your `E-commerce-master` repository.
4.  **Configure Service**:
    *   Railway will likely detect the root folder. If you have a monorepo (backend and frontend in one repo), you might need to specify the **Root Directory** as `buyv_backend` in the service settings.
    *   Go to **Settings** -> **Root Directory** -> Set to `/buyv_backend` (if your repo structure requires it).
5.  **Environment Variables**:
    *   Go to the **Variables** tab.
    *   Add all keys from your local `.env` file:
        *   `SECRET_KEY`
        *   `ALGORITHM`
        *   `ACCESS_TOKEN_EXPIRE_MINUTES`
        *   `STRIPE_SECRET_KEY`
        *   `CJ_API_KEY`, etc.
        *   **DATABASE_URL**: *See Part 3 below.*

---

## Part 3: Add a Database

1.  In your Railway project view, right-click the empty space (or click "New") -> **Database** -> **MySQL**.
2.  Railway will create a MySQL service.
3.  Go to the MySQL service -> **Variables**.
4.  Copy the `MYSQL_URL` value.
5.  Go back to your **Backend Service** -> **Variables**.
6.  Add a new variable: `DATABASE_URL` and paste the `MYSQL_URL`.
    *   *Note: Ensure your `config.py` uses `DATABASE_URL` if present, or configure `MYSQL_HOST`, `MYSQL_USER`, etc. individually using the values from the MySQL service.*

---

## Part 4: Connect Flutter App

1.  Once deployed, Railway gives you a public domain (e.g., `buyv-production.up.railway.app`).
2.  Open your Flutter code: `lib/constants/app_constants.dart` (or `.env`).
3.  Update the **Base URL**:
    ```dart
    static const String fastApiBaseUrl = 'https://buyv-production.up.railway.app';
    ```
4.  **Rebuild App**: Run `flutter run` or build your APK.

## 🎉 Done!
Your app is now live. Anyone with the APK can use the app, and it will talk to your real cloud server.
