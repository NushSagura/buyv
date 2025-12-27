# 📱 GUIDE CONSTRUCTION APK POUR CLIENT

**Date**: 27 Décembre 2024  
**App**: BuyV Flutter  
**Version**: Release Production

---

## 🎯 OBJECTIF

Créer un fichier **APK** pour que le client puisse:
- Installer l'app sur son téléphone Android
- Tester toutes les fonctionnalités
- Partager avec beta testers

---

## 📋 PRÉREQUIS

### ✅ Configuration Backend
- [x] Backend déployé sur Railway
- [x] URL API production disponible
- [x] Base de données Supabase configurée

### ✅ Configuration Services
- [x] Cloudinary account configuré
- [x] Stripe account configuré  
- [x] Credentials à jour

### ✅ Outils Requis
- [x] Flutter SDK installé
- [x] Android SDK installé
- [x] Java JDK 17+ installé

---

## 🔧 ÉTAPE 1: CONFIGURATION PRÉ-BUILD

### 1.1 Mettre à jour l'URL Backend

**Fichier**: `buyv_flutter_app/lib/constants/app_constants.dart`

```dart
class AppConstants {
  // API URLs - PRODUCTION
  static const String fastApiBaseUrl = 'https://votre-app.up.railway.app';
  
  // Autres constantes...
  static const String appName = 'BuyV';
  static const String appVersion = '1.0.0';
}
```

### 1.2 Configurer fichier .env

**Fichier**: `buyv_flutter_app/.env`

```env
# Backend API - PRODUCTION
API_BASE_URL=https://votre-app.up.railway.app

# Cloudinary - CLIENT CREDENTIALS
CLOUDINARY_CLOUD_NAME=nom-cloud-client
CLOUDINARY_API_KEY=api-key-client
CLOUDINARY_UPLOAD_PRESET=buyv_upload

# Stripe - CLIENT TEST CREDENTIALS
STRIPE_PUBLISHABLE_KEY=pk_test_client_publishable_key

# App Info
APP_NAME=BuyV
APP_VERSION=1.0.0
ENVIRONMENT=production
```

### 1.3 Vérifier AndroidManifest.xml

**Fichier**: `buyv_flutter_app/android/app/src/main/AndroidManifest.xml`

Vérifier que:
```xml
<application
    android:label="BuyV"
    android:icon="@mipmap/ic_launcher">
    
    <!-- Permissions Internet -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <!-- Deep Links configurés -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="buyv"/>
    </intent-filter>
</application>
```

### 1.4 Configurer build.gradle

**Fichier**: `buyv_flutter_app/android/app/build.gradle.kts`

Vérifier:
```kotlin
android {
    namespace = "com.buyv.flutter_app"
    compileSdk = 36
    
    defaultConfig {
        applicationId = "com.buyv.flutter_app"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }
    }
}
```

---

## 🔑 ÉTAPE 2: SIGNING (OPTIONNEL pour TEST)

### Option A: Debug Signing (RAPIDE - Pour Tests)

**Utilisation**: Partage rapide avec client pour tests

**Avantages**:
- ✅ Pas besoin de keystore
- ✅ Build rapide
- ✅ Parfait pour beta testing

**Inconvénients**:
- ❌ Ne peut pas être publié sur Play Store
- ❌ Moins sécurisé

**Action**: Rien à faire, signing debug automatique

---

### Option B: Release Signing (Pour PRODUCTION)

**Utilisation**: Pour publication Play Store future

#### 2.1 Générer Keystore

```powershell
cd "C:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv\buyv_flutter_app\android\app"

keytool -genkey -v -keystore buyv-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias buyv-key
```

**Informations à fournir**:
```
Enter keystore password: [choisir mot de passe fort]
Re-enter new password: [confirmer]
What is your first and last name? [Nom entreprise]
What is the name of your organizational unit? [Département]
What is the name of your organization? [BuyV]
What is the name of your City or Locality? [Ville]
What is the name of your State or Province? [Province]
What is the two-letter country code for this unit? [Code pays]
Is CN=..., OU=..., O=..., L=..., ST=..., C=... correct? [yes]

Enter key password for <buyv-key>: [même mot de passe ou différent]
Re-enter new password: [confirmer]
```

#### 2.2 Créer key.properties

**Fichier**: `buyv_flutter_app/android/key.properties`

```properties
storePassword=votre-store-password
keyPassword=votre-key-password
keyAlias=buyv-key
storeFile=buyv-release-key.jks
```

**⚠️ IMPORTANT**: Ajoutez à `.gitignore`:
```
android/key.properties
android/app/buyv-release-key.jks
```

#### 2.3 Modifier build.gradle.kts

**Fichier**: `buyv_flutter_app/android/app/build.gradle.kts`

Ajoutez AVANT `android {`:
```kotlin
// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## 🏗️ ÉTAPE 3: CONSTRUIRE L'APK

### 3.1 Nettoyer le projet

```powershell
cd "C:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv\buyv_flutter_app"

flutter clean
flutter pub get
```

### 3.2 Build APK Debug (RECOMMANDÉ pour tests)

```powershell
flutter build apk --debug
```

**Durée**: 3-5 minutes  
**Taille**: ~50-60 MB  
**Localisation**: `build/app/outputs/flutter-apk/app-debug.apk`

### 3.3 Build APK Release (Pour production)

**Sans obfuscation** (plus simple):
```powershell
flutter build apk --release
```

**Avec obfuscation** (plus sécurisé):
```powershell
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

**Durée**: 5-8 minutes  
**Taille**: ~30-40 MB  
**Localisation**: `build/app/outputs/flutter-apk/app-release.apk`

### 3.4 Build App Bundle (Pour Play Store)

```powershell
flutter build appbundle --release
```

**Localisation**: `build/app/outputs/bundle/release/app-release.aab`

---

## 📦 ÉTAPE 4: RÉCUPÉRER L'APK

### 4.1 Localisation du fichier

**Debug APK**:
```
C:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv\buyv_flutter_app\build\app\outputs\flutter-apk\app-debug.apk
```

**Release APK**:
```
C:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv\buyv_flutter_app\build\app\outputs\flutter-apk\app-release.apk
```

### 4.2 Renommer (optionnel)

```powershell
cd "C:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv\buyv_flutter_app\build\app\outputs\flutter-apk"

# Copier avec nom explicite
Copy-Item app-release.apk "BuyV-v1.0.0-$(Get-Date -Format 'yyyyMMdd').apk"
```

Résultat: `BuyV-v1.0.0-20241227.apk`

---

## 📲 ÉTAPE 5: PARTAGER AVEC LE CLIENT

### Option A: Email / Drive

1. Uploadez l'APK sur:
   - Google Drive
   - Dropbox
   - WeTransfer
   - Email (si < 25MB)

2. Partagez le lien avec instructions:

**Email Template**:
```
Bonjour,

Voici l'APK de test de l'application BuyV v1.0.0.

📱 INSTALLATION:
1. Téléchargez le fichier APK sur votre téléphone Android
2. Ouvrez le fichier téléchargé
3. Si demandé, autorisez "Installer des apps inconnues"
4. Cliquez "Installer"

📋 POUR TESTER:
1. Lancez l'app BuyV
2. Créez un compte ou connectez-vous
3. Testez toutes les fonctionnalités (voir guide test)

⚠️ NOTES:
- APK de test uniquement (non disponible sur Play Store)
- Nécessite Android 7.0+ (API 24+)
- Connexion Internet requise

📊 FONCTIONNALITÉS:
✅ Authentification (Login/Signup)
✅ Feed vidéos avec autoplay
✅ Tap-to-pause, scroll pause/resume
✅ Navigation profil → reels
✅ Deep linking (partage de posts/profils)
✅ Shop CJ Dropshipping
✅ Paiements Stripe (mode test)
✅ Upload photos/vidéos Cloudinary

🔗 LIENS UTILES:
- Guide test: [lien vers GUIDE_TEST_CLIENT.md]
- Support: votre-email@example.com

Cordialement
```

### Option B: Firebase App Distribution (PROFESSIONNEL)

1. Créez projet Firebase
2. Installez Firebase CLI
3. Uploadez APK:
```bash
firebase appdistribution:distribute app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "testers" \
  --release-notes "Version 1.0.0 - Initial release"
```

---

## 🧪 ÉTAPE 6: VÉRIFICATION PRÉ-PARTAGE

### 6.1 Tester l'APK sur device réel

```powershell
# Installer sur device connecté
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 6.2 Checklist Fonctionnalités

- [ ] App s'ouvre sans crash
- [ ] Login/Signup fonctionnent
- [ ] Feed charge les posts
- [ ] Vidéos jouent avec tap-to-pause
- [ ] Navigation profil → reels fonctionne
- [ ] Deep links fonctionnent
- [ ] Upload photo/vidéo fonctionne
- [ ] Shop affiche produits CJ
- [ ] Paiement Stripe (test mode) fonctionne
- [ ] Notifications fonctionnent
- [ ] Logout fonctionne

### 6.3 Taille APK

**Vérifier la taille**:
```powershell
Get-Item build/app/outputs/flutter-apk/app-release.apk | Select-Object Name, @{N='Size(MB)';E={[math]::Round($_.Length/1MB, 2)}}
```

**Taille acceptable**: 30-50 MB

---

## 📊 ÉTAPE 7: INFORMATIONS À FOURNIR AU CLIENT

### 7.1 Fichier README pour le client

Créez: `APK_INFO_CLIENT.txt`

```txt
=================================================
APPLICATION: BuyV - E-commerce Social
VERSION: 1.0.0
DATE BUILD: 27 Décembre 2024
=================================================

📱 INFORMATIONS APK
-------------------
Nom fichier: BuyV-v1.0.0-20241227.apk
Taille: ~35 MB
Android minimum: 7.0 (API 24)
Package: com.buyv.flutter_app

🔐 CREDENTIALS TEST
-------------------
Backend API: https://votre-app.up.railway.app
Compte test:
- Email: test@buyv.com
- Mot de passe: Test123!

Stripe (Test Mode):
- Carte test: 4242 4242 4242 4242
- Expiration: n'importe quelle date future
- CVC: n'importe quel 3 chiffres

✅ FONCTIONNALITÉS INCLUSES
----------------------------
1. Authentification sécurisée (JWT)
2. Feed social avec posts/photos/vidéos
3. Lecteur vidéo avec contrôles:
   - Tap pour pause/play
   - Pause auto au scroll
   - Pause auto à la navigation
4. Navigation profil → reels
5. Deep linking (buyv://post/id, buyv://user/id)
6. Shop CJ Dropshipping intégré
7. Paiements Stripe (mode test)
8. Upload média Cloudinary
9. Système de commissions
10. Notifications temps réel
11. Recherche utilisateurs/produits
12. Panier et gestion commandes

🐛 PROBLÈMES CONNUS
-------------------
Aucun problème majeur connu.

Si problème:
1. Vérifiez connexion Internet
2. Redémarrez l'app
3. Désinstallez et réinstallez
4. Contactez support

📞 SUPPORT
----------
Email: support@buyv.com
Téléphone: +XXX XXX XXX XXX

=================================================
```

---

## 🔄 ÉTAPE 8: MISE À JOUR APK

### 8.1 Incrémenter version

**Fichier**: `buyv_flutter_app/pubspec.yaml`

```yaml
version: 1.0.1+2  # version+buildNumber
```

**Fichier**: `buyv_flutter_app/android/app/build.gradle.kts`

```kotlin
defaultConfig {
    versionCode = 2      // Incrémenter
    versionName = "1.0.1"  // Nouvelle version
}
```

### 8.2 Rebuild

```powershell
flutter clean
flutter build apk --release
```

### 8.3 Renvoyer au client

Nouveau fichier: `BuyV-v1.0.1-20241228.apk`

---

## ✅ CHECKLIST FINALE

- [ ] Backend déployé sur Railway
- [ ] URLs production dans app_constants.dart
- [ ] .env configuré avec credentials production
- [ ] AndroidManifest.xml vérifié
- [ ] Deep links configurés
- [ ] APK construit avec succès
- [ ] APK testé sur device réel
- [ ] Toutes fonctionnalités validées
- [ ] APK renommé avec version + date
- [ ] README client créé
- [ ] APK uploadé (Drive/Email)
- [ ] Email envoyé au client avec instructions
- [ ] Guide test client fourni

---

## 📝 COMMANDES RAPIDES

```powershell
# Naviguer vers projet
cd "C:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv\buyv_flutter_app"

# Nettoyer
flutter clean && flutter pub get

# Build Debug (Tests)
flutter build apk --debug

# Build Release (Production)
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Installer sur device
adb install build/app/outputs/flutter-apk/app-release.apk

# Vérifier taille
Get-Item build/app/outputs/flutter-apk/app-release.apk | Select-Object Name, Length
```

---

**Créé**: 27 Décembre 2024  
**Status**: ✅ Prêt pour build & distribution  
**Type**: APK Release Production
