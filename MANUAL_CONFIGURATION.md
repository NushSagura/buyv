# Manual Configuration Guide

This document lists technical configuration steps that require direct access to external 3rd-party accounts or local environment setup. These steps cannot be automated and must be performed manually.

## 1. Cloudinary Configuration (Critical for Uploads)

To enable image and video uploads (Profile pictures, Reels), you must configure your Cloudinary dashboard.

**Required Action:** Create an Unsigned Upload Preset.

1.  Log in to your [Cloudinary Console](https://console.cloudinary.com/).
2.  Navigate to **Settings** (gear icon) -> **Upload**.
3.  Scroll down to the **Upload presets** section.
4.  Click **Add upload preset**.
5.  **Critically Important Settings:**
    *   **Upload preset name**: `Ecommerce_BuyV`
        *   *Note: If you use a different name, you must update `lib/constants/app_constants.dart` or your `.env` file.*
    *   **Signing Mode**: Select `Unsigned`.
6.  Click **Save**.

> **Why?** The app uses "unsigned" uploads to allow users to upload media directly from the app without exposing your secure API secret.

---

## 2. CJ Dropshipping API

To fetch real products from CJ Dropshipping, you need to generate API credentials.

**Required Action:** Get API Key.

1.  Log in to your [CJ Dropshipping Account](https://cjdropshipping.com/).
2.  Go to **Authorization** -> **API**.
3.  Generate a new **API Key**.
4.  Update the app configuration:
    *   Open `lib/constants/app_constants.dart`.
    *   Update `cjApiKey` with your key (or set `CJ_API_KEY` in `.env`).

---

## 3. Development Environment Setup

### Windows Desktop Build
*   **Requirement**: Visual Studio 2022 (Community or higher).
*   **Workload**: "Desktop development with C++".
*   **Components**: Ensure `MSVC config` and `Windows 10/11 SDK` are selected.
*   *Fixes error: `Impossible d'ouvrir le fichier include : 'atlstr.h'`*

### Android Build
*   **Requirement**: Android Studio & Android SDK.
*   **Action**: Accept all SDK licenses:
    ```bash
    flutter doctor --android-licenses
    ```

### iOS Build (Mac Only)
*   **Requirement**: Xcode & CocoaPods.
*   **Action**:
    ```bash
    pod install
    ```

---

## 4. Stripe Payment Setup

To enable "Pay Now" with credit cards:

**Required Action:** Add Keys to `.env` (Backend & Frontend)

1.  **Backend (`buyv_backend/.env`)**:
    ```ini
    STRIPE_SECRET_KEY=sk_test_...  <-- Your Secret Key
    ```

2.  **Frontend (`buyv_flutter_app/.env`) or `main.dart`**:
    *   Currently, you must ensure the `STRIPE_PUBLISHABLE_KEY` is available.
    *   *Note: Typically handled via `dependencies` or hardcoded for dev.*

3.  **Android Theme Update**:
    *   We updated `android/app/src/main/res/values/styles.xml` to use `Theme.MaterialComponents`.
    *   If you see build errors, ensure your `compileSdkVersion` is 33+.
