# ☁️ GUIDE CONFIGURATION CLOUDINARY POUR CLIENT

**Date**: 27 Décembre 2024  
**Service**: Cloudinary Media Upload  
**App**: BuyV Flutter

---

## 🎯 OBJECTIF

Configurer votre propre compte **Cloudinary** pour:
- Upload photos utilisateurs
- Upload vidéos pour reels
- Stockage média sécurisé
- CDN rapide mondial

---

## 📋 QU'EST-CE QUE CLOUDINARY?

**Cloudinary** = Service cloud pour gérer images et vidéos:
- ✅ Upload depuis mobile
- ✅ Redimensionnement automatique
- ✅ Optimisation formats (WebP, AVIF)
- ✅ CDN global (livraison rapide)
- ✅ Transformations (crop, resize, filter)
- ✅ Stockage sécurisé

**Prix**:
- **FREE**: 25 GB stockage, 25 crédits/mois
- **PLUS**: $99/mois, 100 GB stockage
- **ADVANCED**: $249/mois, 200 GB stockage

Pour tests/début: **Plan FREE suffit**

---

## 🚀 ÉTAPE 1: CRÉER COMPTE CLOUDINARY

### 1.1 Inscription

1. Aller sur: https://cloudinary.com/users/register/free
2. Choisir méthode inscription:
   - Email + mot de passe
   - Google account
   - GitHub account

3. Remplir formulaire:
   ```
   Email: votre-email@example.com
   Mot de passe: [choisir mot de passe fort]
   Prénom: [votre prénom]
   Nom: [votre nom]
   Entreprise: BuyV (optionnel)
   ```

4. Cocher "I agree to the Terms of Service"
5. Cliquer **"Sign Up"**

### 1.2 Vérification Email

1. Ouvrir email de Cloudinary
2. Cliquer lien "Verify your email"
3. Redirection vers dashboard Cloudinary

### 1.3 Configuration Initiale

Cloudinary demande quelques infos:
- **Cloud name**: Choisir nom unique (ex: `buyv-prod`, `buyv-client`)
- **Primary use**: Choisir "E-commerce"
- **Role**: Choisir "Developer" ou "Product Owner"

⚠️ **IMPORTANT**: **Cloud Name** ne peut pas être changé après!

---

## 🔑 ÉTAPE 2: OBTENIR API CREDENTIALS

### 2.1 Accéder au Dashboard

URL: https://console.cloudinary.com/

Vous verrez:
```
Account Details
---------------
Cloud name: votre-cloud-name
API Key: 123456789012345
API Secret: [cliquer "Reveal" pour voir]
API Environment variable: cloudinary://123...
```

### 2.2 Copier Credentials

**Noter ces 3 valeurs** (vous en aurez besoin plus tard):

1. **Cloud Name**: `votre-cloud-name`
2. **API Key**: `123456789012345`
3. **API Secret**: `abcdefghijklmnopqrstuvwxyz` (cliquer "Reveal")

⚠️ **SÉCURITÉ**:
- **Ne jamais** partager API Secret
- **Ne jamais** commit dans Git
- Stocker dans .env (pas dans code)

---

## ⚙️ ÉTAPE 3: CONFIGURER UPLOAD PRESET

### 3.1 Qu'est-ce qu'un Upload Preset?

**Upload Preset** = Configuration pour uploads:
- Dossier destination
- Transformations automatiques
- Permissions (unsigned vs signed)
- Formats acceptés

### 3.2 Créer Unsigned Upload Preset

**Pourquoi unsigned?**
- ✅ Upload direct depuis mobile (pas besoin backend)
- ✅ Plus simple à implémenter
- ✅ Suffisant pour app mobile

**Étapes**:

1. Dashboard → **Settings** (icône engrenage en bas gauche)
2. Onglet **Upload**
3. Scroll vers **"Upload presets"**
4. Cliquer **"Add upload preset"**

### 3.3 Configuration du Preset

**Page de configuration**:

**Section: Preset name & signing mode**
```
Preset name: buyv_upload
Signing mode: Unsigned (☑ cocher)
```

**Section: Folder**
```
Folder: buyv/
(tous les uploads iront dans dossier buyv/)
```

**Section: Upload manipulations**
```
☑ Unique filename: true
  (évite doublons)
  
☑ Use filename or externally defined Public ID: false
  (génère IDs automatiques)
```

**Section: Allowed formats**
```
☑ Image formats: jpg, png, gif, webp, heic
☑ Video formats: mp4, mov, avi, webm
```

**Section: Transformations**
```
☑ Eager transformations: (optionnel)
  - Image: c_limit,w_1080,h_1920,q_auto
  - Video: c_limit,w_1080,h_1920,q_auto,vc_h264
```

**Section: Access control**
```
Resource access mode: public
(les médias seront accessibles via URL publique)
```

5. Cliquer **"Save"** en haut à droite

### 3.4 Vérifier le Preset

1. Retour à **Settings** → **Upload**
2. Section **Upload presets**
3. Vous devez voir:
   ```
   Preset name: buyv_upload
   Mode: Unsigned
   Folder: buyv/
   Status: Active (☑)
   ```

---

## 📱 ÉTAPE 4: CONFIGURER APP FLUTTER

### 4.1 Mettre à jour .env

**Fichier**: `buyv_flutter_app/.env`

Ajouter/modifier:
```env
# Cloudinary - VOTRE COMPTE
CLOUDINARY_CLOUD_NAME=votre-cloud-name
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_UPLOAD_PRESET=buyv_upload
```

Remplacer:
- `votre-cloud-name` → Cloud name de votre dashboard
- `123456789012345` → API Key de votre dashboard

### 4.2 Vérifier app_constants.dart (optionnel)

**Fichier**: `buyv_flutter_app/lib/constants/app_constants.dart`

Normalement déjà configuré pour lire .env:
```dart
class AppConstants {
  static const String cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String cloudinaryApiKey = String.fromEnvironment('CLOUDINARY_API_KEY');
  static const String cloudinaryUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: 'buyv_upload');
  
  static const String cloudinaryBaseUrl = 'https://res.cloudinary.com/$cloudinaryCloudName';
  static const String cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/upload';
}
```

Si pas configuré, ajoutez ces constantes.

### 4.3 Vérifier cloudinary_service.dart

**Fichier**: `buyv_flutter_app/lib/services/cloudinary_service.dart`

Code doit ressembler à:
```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';

class CloudinaryService {
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse(AppConstants.cloudinaryUploadUrl);
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
      request.fields['cloud_name'] = AppConstants.cloudinaryCloudName;
      
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseData);
        return jsonData['secure_url'] as String;
      } else {
        print('❌ Cloudinary upload error: $responseData');
        return null;
      }
    } catch (e) {
      print('❌ Cloudinary exception: $e');
      return null;
    }
  }
  
  static Future<String?> uploadVideo(File videoFile) async {
    try {
      final uri = Uri.parse(
        AppConstants.cloudinaryUploadUrl.replaceAll('/upload', '/video/upload')
      );
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
      request.fields['cloud_name'] = AppConstants.cloudinaryCloudName;
      request.fields['resource_type'] = 'video';
      
      request.files.add(
        await http.MultipartFile.fromPath('file', videoFile.path),
      );
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseData);
        return jsonData['secure_url'] as String;
      } else {
        print('❌ Cloudinary video upload error: $responseData');
        return null;
      }
    } catch (e) {
      print('❌ Cloudinary video exception: $e');
      return null;
    }
  }
}
```

---

## 🧪 ÉTAPE 5: TESTER UPLOAD

### 5.1 Test depuis App

1. Lancer l'app BuyV:
   ```powershell
   cd buyv_flutter_app
   flutter run
   ```

2. Aller à **Créer Post** (icône + en bas)
3. Cliquer **"Choisir photo"** ou **"Choisir vidéo"**
4. Sélectionner média depuis galerie
5. Attendre upload (spinner)
6. Vérifier message **"Photo uploadée avec succès"**

### 5.2 Vérifier dans Dashboard Cloudinary

1. Aller sur: https://console.cloudinary.com/console/media_library
2. Cliquer dossier **"buyv/"**
3. Vous devriez voir le fichier uploadé

**Informations affichées**:
- **Public ID**: buyv/abc123xyz
- **URL**: https://res.cloudinary.com/votre-cloud/image/upload/v1234567890/buyv/abc123xyz.jpg
- **Format**: jpg, png, mp4, etc.
- **Taille**: Dimensions + poids
- **Date**: Date upload

### 5.3 Test Manuel (Postman / Curl)

**Curl Windows PowerShell**:
```powershell
$cloudName = "votre-cloud-name"
$uploadPreset = "buyv_upload"
$imagePath = "C:\chemin\vers\test.jpg"

$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$bodyLines = (
    "--$boundary",
    "Content-Disposition: form-data; name=`"upload_preset`"$LF",
    $uploadPreset,
    "--$boundary",
    "Content-Disposition: form-data; name=`"file`"; filename=`"test.jpg`"",
    "Content-Type: image/jpeg$LF",
    [System.Text.Encoding]::GetEncoding('iso-8859-1').GetString([System.IO.File]::ReadAllBytes($imagePath)),
    "--$boundary--$LF"
) -join $LF

Invoke-RestMethod `
  -Uri "https://api.cloudinary.com/v1_1/$cloudName/upload" `
  -Method Post `
  -ContentType "multipart/form-data; boundary=$boundary" `
  -Body $bodyLines
```

**Résultat attendu**:
```json
{
  "public_id": "buyv/abc123xyz",
  "version": 1234567890,
  "signature": "...",
  "width": 1080,
  "height": 1920,
  "format": "jpg",
  "resource_type": "image",
  "created_at": "2024-12-27T10:30:00Z",
  "bytes": 524288,
  "type": "upload",
  "url": "http://res.cloudinary.com/votre-cloud/image/upload/v1234567890/buyv/abc123xyz.jpg",
  "secure_url": "https://res.cloudinary.com/votre-cloud/image/upload/v1234567890/buyv/abc123xyz.jpg"
}
```

---

## 🔐 ÉTAPE 6: SÉCURISER LA CONFIGURATION

### 6.1 Variables Environnement Backend (optionnel)

Si backend FastAPI doit accéder Cloudinary (signed uploads):

**Fichier**: `buyv_backend/.env`

```env
# Cloudinary
CLOUDINARY_CLOUD_NAME=votre-cloud-name
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_API_SECRET=votre-api-secret
```

**Fichier**: `buyv_backend/app/config.py`

```python
import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    CLOUDINARY_CLOUD_NAME = os.getenv("CLOUDINARY_CLOUD_NAME")
    CLOUDINARY_API_KEY = os.getenv("CLOUDINARY_API_KEY")
    CLOUDINARY_API_SECRET = os.getenv("CLOUDINARY_API_SECRET")

settings = Settings()
```

### 6.2 Ajouter au .gitignore

**Fichier**: `.gitignore`

Vérifier que ces lignes existent:
```gitignore
# Environment variables
.env
.env.local
.env.production

# Cloudinary
cloudinary_credentials.json
```

### 6.3 Documentation Équipe

Créer fichier partagé (Google Docs, Notion) avec:
```
Cloudinary Credentials - BuyV Production
========================================

Cloud Name: votre-cloud-name
API Key: 123456789012345
API Secret: ************************ (demander à admin)
Upload Preset: buyv_upload

Dashboard: https://console.cloudinary.com/
Email: votre-email@example.com
Password: ********** (demander à admin)

Upload URLs:
- Image: https://api.cloudinary.com/v1_1/votre-cloud/upload
- Video: https://api.cloudinary.com/v1_1/votre-cloud/video/upload

CDN URLs:
- Base: https://res.cloudinary.com/votre-cloud/
- Dossier: https://res.cloudinary.com/votre-cloud/image/upload/buyv/
```

---

## 📊 ÉTAPE 7: SURVEILLER USAGE

### 7.1 Dashboard Analytics

1. Aller sur: https://console.cloudinary.com/console/usage
2. Voir statistiques:
   - **Storage**: GB utilisés / limite
   - **Bandwidth**: GB transférés ce mois
   - **Transformations**: Nombre opérations
   - **Credits**: Crédits restants

### 7.2 Alertes (optionnel)

1. Settings → **Notifications**
2. Configurer alertes:
   - ☑ 80% storage utilisé
   - ☑ 90% bandwidth utilisé
   - ☑ Quota dépassé
3. Email notifications

### 7.3 Optimisation Coûts

**Tips pour rester dans plan FREE**:

1. **Comprimer images avant upload**:
   ```dart
   // Dans app Flutter
   import 'package:flutter_image_compress/flutter_image_compress.dart';
   
   final compressedFile = await FlutterImageCompress.compressAndGetFile(
     imageFile.path,
     '/tmp/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
     quality: 85,
   );
   ```

2. **Limiter taille vidéos**:
   - Max 30 secondes pour reels
   - Max 1080p résolution
   - Compression avant upload

3. **Nettoyer médias inutilisés**:
   - Dashboard → Media Library
   - Supprimer vieux fichiers
   - Automatiser avec scripts

4. **Utiliser transformations Cloudinary**:
   ```
   # URL originale
   https://res.cloudinary.com/votre-cloud/image/upload/buyv/photo.jpg
   
   # URL transformée (thumbnail 300x300)
   https://res.cloudinary.com/votre-cloud/image/upload/c_fill,w_300,h_300/buyv/photo.jpg
   ```
   
   Avantage: Pas besoin stocker plusieurs versions

---

## 🔧 ÉTAPE 8: TROUBLESHOOTING

### Erreur: "Invalid upload preset"

**Cause**: Upload preset n'existe pas ou mal nommé

**Solution**:
1. Vérifier preset dans Dashboard → Settings → Upload
2. Vérifier nom exact (sensible à la casse)
3. Vérifier preset est **Unsigned**

### Erreur: "Unauthorized"

**Cause**: API Key incorrecte ou manquante

**Solution**:
1. Vérifier .env contient CLOUDINARY_API_KEY
2. Vérifier valeur correspond au Dashboard
3. Rebuild app: `flutter clean && flutter run`

### Erreur: "Invalid cloud name"

**Cause**: Cloud name incorrect

**Solution**:
1. Dashboard → Account Details
2. Copier exact cloud name (pas d'espaces)
3. Mettre à jour .env

### Upload très lent

**Cause**: Fichier trop gros

**Solutions**:
1. Compresser image avant upload (voir section optimisation)
2. Limiter résolution à 1080p
3. Utiliser format JPEG au lieu de PNG pour photos

### Quota dépassé

**Cause**: Trop d'uploads ce mois

**Solutions**:
1. Upgrade vers plan PLUS ($99/mois)
2. Attendre début mois prochain (reset quota)
3. Nettoyer anciens médias
4. Optimiser taille fichiers

---

## ✅ CHECKLIST CONFIGURATION CLOUDINARY

- [ ] Compte Cloudinary créé
- [ ] Email vérifié
- [ ] Cloud name choisi et noté
- [ ] API Key copiée et notée
- [ ] API Secret copiée et notée
- [ ] Upload preset `buyv_upload` créé (unsigned)
- [ ] Dossier `buyv/` configuré
- [ ] Formats autorisés: jpg, png, mp4, mov
- [ ] .env Flutter mis à jour avec credentials
- [ ] .env Backend mis à jour (si signed uploads)
- [ ] .gitignore inclut .env
- [ ] Test upload photo réussi depuis app
- [ ] Test upload vidéo réussi depuis app
- [ ] Fichier visible dans Media Library
- [ ] Dashboard analytics configuré
- [ ] Alertes quota configurées

---

## 📞 SUPPORT CLOUDINARY

**Documentation**:
- API Reference: https://cloudinary.com/documentation/image_upload_api_reference
- Flutter SDK: https://cloudinary.com/documentation/flutter_integration
- Upload Presets: https://cloudinary.com/documentation/upload_presets

**Contact Support**:
- Email: support@cloudinary.com
- Chat: Dashboard → icône chat en bas droite
- Forum: https://community.cloudinary.com/

**Statut Service**:
- https://status.cloudinary.com/

---

**Créé**: 27 Décembre 2024  
**Status**: ✅ Guide complet configuration Cloudinary  
**Pour**: Client BuyV E-commerce
