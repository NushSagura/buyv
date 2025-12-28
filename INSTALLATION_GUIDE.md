# 🚀 Installation des Nouvelles Fonctionnalités

Ce guide vous explique comment installer et activer les nouvelles fonctionnalités avancées.

---

## 📦 Backend (Python/FastAPI)

### 1. Installer Firebase Admin SDK

```bash
cd buyv_backend

# Installer firebase-admin
pip install firebase-admin

# Mettre à jour requirements.txt
pip freeze > requirements.txt
```

### 2. Configurer Firebase (Optionnel pour l'instant)

```bash
# Créer le fichier .gitignore si pas existant
echo "firebase-credentials.json" >> .gitignore
echo "*.pyc" >> .gitignore
echo "__pycache__/" >> .gitignore
echo ".env" >> .gitignore
```

**Note:** Firebase est optionnel. L'application fonctionnera sans Firebase, simplement les notifications push ne seront pas envoyées.

### 3. Appliquer les migrations de base de données

Si vous utilisez SQLite (dev):
```bash
cd buyv_backend

# Option 1: Ajouter manuellement la colonne
sqlite3 buyv.db
> ALTER TABLE users ADD COLUMN fcm_token VARCHAR(512);
> .quit
```

Ou recréer la base (ATTENTION: perte de données):
```bash
rm buyv.db
python -c "from app.database import engine, Base; from app import models; Base.metadata.create_all(bind=engine)"
```

Si vous utilisez PostgreSQL (production):
```sql
-- Connectez-vous à votre base
-- Exécutez:
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(512);
```

### 4. Tester le backend

```bash
cd buyv_backend
uvicorn app.main:app --reload
```

Vérifiez les logs:
```
INFO:     Started server process
INFO:     Waiting for application startup.
⚠️ Firebase credentials file not found at firebase-credentials.json
⚠️ Push notifications will be disabled
INFO:     Application startup complete.
```

C'est normal si vous n'avez pas encore configuré Firebase.

### 5. Tester l'endpoint de suppression

```bash
# Obtenez un token (login)
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Copiez le access_token

# Testez la suppression (NE PAS FAIRE avec un vrai compte!)
curl -X DELETE http://localhost:8000/users/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 📱 Frontend (Flutter)

### 1. Ajouter les dépendances Firebase

Modifiez `buyv_flutter_app/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # ... vos dépendances existantes ...
  
  # Nouvelles dépendances Firebase
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

### 2. Installer les dépendances

```bash
cd buyv_flutter_app
flutter pub get
```

### 3. Configuration Android (Temporaire - sans Firebase)

Vous pouvez tester la suppression de compte sans configurer Firebase.
Les notifications push ne fonctionneront pas mais le reste de l'app oui.

### 4. Tester l'application

```bash
cd buyv_flutter_app
flutter run
```

### 5. Tester la suppression de compte

1. Créez un compte test
2. Allez dans Profile → Settings (icône engrenage)
3. Scrollez jusqu'en bas
4. Cliquez sur "Delete Account" (rouge avec icône poubelle)
5. Lisez le dialog de confirmation
6. Cliquez sur "Delete Account" dans le dialog
7. Attendez le chargement
8. Vous devriez être redirigé vers la page de login

---

## 🔥 Configuration Firebase (Quand vous êtes prêt)

### Référez-vous au guide complet:
📄 **`FIREBASE_SETUP_GUIDE.md`**

Ce guide contient:
- Configuration Firebase Console
- Setup Android détaillé
- Setup iOS détaillé
- Configuration Backend
- Tests et troubleshooting

---

## 🧪 Tests Rapides

### Test 1: Backend fonctionne
```bash
curl http://localhost:8000/health
# Devrait retourner: {"status":"ok"}
```

### Test 2: Endpoint suppression existe
```bash
curl -X DELETE http://localhost:8000/users/me
# Devrait retourner 401 (car pas authentifié)
# C'est normal!
```

### Test 3: Flutter compile
```bash
cd buyv_flutter_app
flutter doctor
flutter build apk --debug
# Ou
flutter build ios --debug
```

---

## ⚙️ Variables d'Environnement (Production)

Pour Railway ou autre hébergement:

### Backend:
```env
# .env ou Railway Variables
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
DATABASE_URL=postgresql://...
SECRET_KEY=your-secret-key
```

### Uploader firebase-credentials.json dans Railway:
1. Railway Dashboard → Project
2. Settings → Variables
3. Add File Variable
4. Name: `firebase-credentials.json`
5. Paste content

---

## 📋 Checklist d'Installation

### Backend:
- [ ] `pip install firebase-admin` exécuté
- [ ] `requirements.txt` mis à jour
- [ ] Migration DB exécutée (colonne fcm_token ajoutée)
- [ ] Backend démarre sans erreur
- [ ] Endpoint `/health` répond
- [ ] `.gitignore` mis à jour

### Frontend:
- [ ] `pubspec.yaml` mis à jour
- [ ] `flutter pub get` exécuté
- [ ] App compile sans erreur
- [ ] Settings screen affiche "Delete Account"
- [ ] Dialog de confirmation fonctionne

### Optional (Firebase):
- [ ] Projet Firebase créé
- [ ] `firebase-credentials.json` téléchargé
- [ ] Fichier ajouté au backend
- [ ] `google-services.json` ajouté (Android)
- [ ] `GoogleService-Info.plist` ajouté (iOS)

---

## 🐛 Problèmes Courants

### Backend: ModuleNotFoundError: No module named 'firebase_admin'
```bash
# Solution:
pip install firebase-admin
```

### Backend: Column fcm_token does not exist
```bash
# Solution: Exécutez la migration
sqlite3 buyv.db
> ALTER TABLE users ADD COLUMN fcm_token VARCHAR(512);
> .quit
```

### Flutter: Package not found
```bash
# Solution:
cd buyv_flutter_app
flutter clean
flutter pub get
```

### Flutter: Build fails
```bash
# Solution:
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

---

## 🎯 Prochaines Étapes

1. ✅ Installer les dépendances (backend + frontend)
2. ✅ Tester la suppression de compte
3. 🔜 Configurer Firebase (quand prêt)
4. 🔜 Tester les notifications push
5. 🔜 Déployer en production

---

## 📞 Support

En cas de problème:
1. Vérifiez les logs du backend
2. Vérifiez les logs Flutter (console)
3. Consultez `FIREBASE_SETUP_GUIDE.md` pour Firebase
4. Consultez `ADVANCED_FEATURES_SUMMARY.md` pour la vue d'ensemble

---

**Temps estimé d'installation:** 15-30 minutes (sans Firebase)

**Temps estimé avec Firebase:** 2-3 heures (première fois)
