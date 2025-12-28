# 🎉 Buyv - Social E-Commerce Platform

**Version:** 1.1.0  
**Dernière mise à jour:** 28 Décembre 2024

Une plateforme e-commerce sociale moderne avec reels vidéo, commissions d'affiliation, et intégration complète avec CJ Dropshipping et Stripe.

---

## 🌟 Fonctionnalités Principales

### 🎥 Social & Contenu
- **Reels Vidéo** style TikTok (swipe vertical)
- **Posts Photos** avec galerie
- **Promotion de Produits** avec deep linking CJ Dropshipping
- **Système de Follow** (followers/following)
- **Likes & Commentaires** en temps réel
- **Feed Personnalisé** (Following/Explore)

### 🛒 E-Commerce
- **Intégration CJ Dropshipping** (40M+ produits)
- **Panier d'Achat** avec gestion quantités
- **Checkout Stripe** sécurisé
- **Suivi de Commandes** en temps réel
- **Historique d'Achats**

### 💰 Système d'Affiliation
- **Commissions sur Ventes** (1-15% configurable)
- **Deep Links Trackables** par promoteur
- **Dashboard Commissions** avec stats
- **Paiements Automatisés**

### 🔔 Notifications Push (NOUVEAU)
- **Firebase Cloud Messaging**
- Notifications même quand l'app est fermée
- Types: Follow, Like, Comment, Order, Commission
- Routing automatique vers le contenu

### 🗑️ Suppression de Compte (NOUVEAU)
- **Conformité App Store & Play Store**
- Suppression complète de toutes les données
- Confirmation avec liste des conséquences
- Process sécurisé avec authentification

---

## 🏗️ Architecture

### Backend (Python/FastAPI)
```
buyv_backend/
├── app/
│   ├── main.py              # Point d'entrée
│   ├── auth.py              # Authentification JWT
│   ├── users.py             # Gestion utilisateurs + suppression compte
│   ├── posts.py             # Posts/Reels
│   ├── follows.py           # Système de follow
│   ├── orders.py            # Gestion commandes
│   ├── commissions.py       # Calcul commissions
│   ├── notifications.py     # Notifications + Firebase
│   ├── firebase_service.py  # Service FCM (NOUVEAU)
│   ├── models.py            # ORM SQLAlchemy
│   └── database.py          # Configuration DB
├── requirements.txt
└── firebase-credentials.json (à ajouter)
```

### Frontend (Flutter)
```
buyv_flutter_app/
├── lib/
│   ├── main.dart
│   ├── services/
│   │   ├── auth_api_service.dart
│   │   ├── user_service.dart
│   │   ├── post_service.dart
│   │   ├── cj_dropshipping_service.dart
│   │   ├── stripe_service.dart
│   │   └── firebase_notification_service.dart (NOUVEAU)
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── home/
│   │   │   ├── profile/
│   │   │   ├── shop/
│   │   │   ├── cart/
│   │   │   └── settings/ (avec Delete Account)
│   │   └── widgets/
│   └── domain/
│       └── models/
├── pubspec.yaml
├── android/
│   └── app/
│       ├── google-services.json (à ajouter)
│       └── build.gradle
└── ios/
    └── Runner/
        ├── GoogleService-Info.plist (à ajouter)
        └── Info.plist
```

---

## 🚀 Installation & Démarrage

### Prérequis
- Python 3.9+
- Flutter 3.16+
- PostgreSQL (ou SQLite pour dev)
- Compte Firebase (pour notifications)
- Compte Stripe (pour paiements)
- Compte CJ Dropshipping (pour produits)

### Backend Setup

```bash
# 1. Cloner et installer
cd buyv_backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt

# 2. Configurer l'environnement
cp .env.example .env
# Éditer .env avec vos credentials

# 3. Initialiser la base de données
python -c "from app.database import engine, Base; from app import models; Base.metadata.create_all(bind=engine)"

# 4. Démarrer le serveur
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Setup

```bash
# 1. Installer les dépendances
cd buyv_flutter_app
flutter pub get

# 2. Configurer les constantes
# Éditer lib/constants/app_constants.dart avec votre URL backend

# 3. Lancer l'app
flutter run

# Ou pour build
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

---

## 🔥 Configuration Firebase (Notifications Push)

**📄 Guide complet:** Voir [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md)

### Quick Start:

1. **Créer projet Firebase** sur [console.firebase.google.com](https://console.firebase.google.com)
2. **Télécharger credentials:**
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
   - Firebase Admin SDK JSON → `buyv_backend/firebase-credentials.json`
3. **Installer dépendances:**
   ```bash
   # Backend
   pip install firebase-admin
   
   # Flutter (dans pubspec.yaml)
   firebase_core: ^2.24.2
   firebase_messaging: ^14.7.9
   flutter_local_notifications: ^16.3.0
   ```
4. **Configurer Android/iOS** (voir guide détaillé)

---

## 📚 Documentation

### Guides Principaux
- 📖 [FIREBASE_SETUP_GUIDE.md](FIREBASE_SETUP_GUIDE.md) - Configuration complète Firebase (10+ pages)
- 📖 [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) - Installation des nouvelles fonctionnalités
- 📖 [ADVANCED_FEATURES_SUMMARY.md](ADVANCED_FEATURES_SUMMARY.md) - Résumé des fonctionnalités avancées
- 📖 [ARCHITECTURE_DIAGRAM.md](ARCHITECTURE_DIAGRAM.md) - Diagrammes d'architecture
- 📖 [ADMIN_PANEL_DISCUSSION.md](ADMIN_PANEL_DISCUSSION.md) - Planification Admin Panel

### Guides Techniques
- 🔧 [CLOUDINARY_CLIENT_SETUP.md](CLOUDINARY_CLIENT_SETUP.md) - Configuration Cloudinary
- 🔧 [STRIPE_CLIENT_SETUP.md](STRIPE_CLIENT_SETUP.md) - Configuration Stripe
- 🔧 [CJ_PROXY_SETUP.md](CJ_PROXY_SETUP.md) - Proxy pour CJ Dropshipping
- 🔧 [DEEP_LINKING_GUIDE.md](DEEP_LINKING_GUIDE.md) - Deep links produits

### Guides de Déploiement
- 🚀 [DEPLOYMENT_RAILWAY_GUIDE.md](DEPLOYMENT_RAILWAY_GUIDE.md) - Déploiement Railway
- 🚀 [APK_BUILD_GUIDE.md](APK_BUILD_GUIDE.md) - Build APK Android

---

## 🎯 Nouvelles Fonctionnalités (v1.1.0)

### ✅ Suppression de Compte
- **Endpoint:** `DELETE /users/me`
- **UI:** Settings → Delete Account (avec confirmation)
- **Suppression cascade** de toutes les données:
  - Posts, Comments, Likes
  - Follows, Orders, Commissions
  - Notifications, FCM Token
- **Conformité:** Apple App Store ✓ | Google Play Store ✓

### ✅ Notifications Push
- **Service Firebase:** `firebase_service.py` (backend)
- **Service Flutter:** `firebase_notification_service.dart`
- **États supportés:**
  - Foreground (app ouverte) ✓
  - Background (app en arrière-plan) ✓
  - Terminated (app fermée) ✓
- **Types de notifications:**
  - Nouveau follower
  - Like sur post
  - Commentaire sur post
  - Nouvelle commande
  - Commission approuvée
- **Routing automatique** vers le contenu

---

## 🔐 Sécurité

### Backend
- **JWT Authentication** avec refresh tokens
- **Bcrypt** pour hash des passwords
- **CORS** configuré pour Flutter
- **Rate Limiting** (optionnel)
- **SQL Injection Protection** via ORM
- **Audit Logs** pour actions sensibles

### Frontend
- **Flutter Secure Storage** pour tokens
- **HTTPS Only** en production
- **Token Refresh** automatique
- **Encryption** des données sensibles

### Firebase
- **Credentials sécurisés** (jamais dans Git)
- **Token validation** côté backend
- **Expired token cleanup**

---

## 📊 API Endpoints

### Authentification
```
POST   /auth/register       - Créer un compte
POST   /auth/login          - Se connecter
GET    /auth/me             - Profil actuel
POST   /auth/refresh        - Refresh token
```

### Utilisateurs
```
GET    /users/search        - Rechercher users
GET    /users/{uid}         - Profil user
PUT    /users/{uid}         - Modifier profil
POST   /users/me/fcm-token  - Enregistrer token FCM (NOUVEAU)
DELETE /users/me            - Supprimer compte (NOUVEAU)
```

### Posts
```
GET    /posts               - Liste posts (feed)
POST   /posts               - Créer post
GET    /posts/{uid}         - Détails post
POST   /posts/{uid}/like    - Like post
DELETE /posts/{uid}/like    - Unlike post
```

### Commandes
```
POST   /orders              - Créer commande
GET    /orders/me           - Mes commandes
GET    /orders/{id}         - Détails commande
```

### Notifications
```
GET    /notifications/me    - Mes notifications
POST   /notifications       - Créer notification (+ push)
POST   /notifications/{id}/read - Marquer lu
```

---

## 🧪 Tests

### Backend Tests
```bash
cd buyv_backend
pytest tests/
```

### Frontend Tests
```bash
cd buyv_flutter_app
flutter test
```

### Test Notifications
```bash
# Via Firebase Console
# Engage → Cloud Messaging → Send test message

# Via API
curl -X POST http://localhost:8000/notifications/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test",
    "body": "Ceci est un test",
    "type": "test",
    "userId": "USER_UID"
  }'
```

---

## 🚀 Déploiement

### Backend (Railway)
```bash
# 1. Push sur GitHub
git add .
git commit -m "feat: add Firebase push notifications"
git push

# 2. Railway auto-deploy
# Configurer variables d'environnement:
# - DATABASE_URL
# - SECRET_KEY
# - FIREBASE_CREDENTIALS_PATH
# - Upload firebase-credentials.json as file variable
```

### Frontend (App Stores)
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
# Puis upload via Xcode
```

---

## 🛠️ Troubleshooting

### Problème: Notifications ne marchent pas

**Android:**
1. Vérifier `google-services.json` présent
2. Vérifier permissions dans AndroidManifest.xml
3. Redémarrer app (pas hot reload)

**iOS:**
1. Tester sur appareil réel (pas simulateur)
2. Vérifier certificat APNs uploadé dans Firebase
3. Vérifier capabilities dans Xcode

**Backend:**
1. Vérifier `firebase-credentials.json` présent
2. Vérifier logs: `INFO: Firebase initialized`
3. Vérifier token FCM enregistré dans DB

### Problème: Suppression de compte échoue

1. Vérifier authentification (JWT token valide)
2. Vérifier migration DB (colonne fcm_token existe)
3. Vérifier logs backend pour erreurs

---

## 📝 TODO / Roadmap

### Phase 1 (Complétée ✅)
- [x] Suppression de compte
- [x] Notifications push Firebase
- [x] Documentation complète

### Phase 2 (En cours)
- [ ] Admin Panel web
- [ ] Analytics avancés
- [ ] Système de rôles
- [ ] Modération automatique

### Phase 3 (Futur)
- [ ] Stories (24h)
- [ ] Messages directs
- [ ] Live streaming
- [ ] AR product preview
- [ ] Multi-langue

---

## 🤝 Contribution

Ce projet est privé. Pour contribuer:

1. Fork le repo
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit (`git commit -m 'Add some AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

---

## 📄 License

Proprietary - Tous droits réservés

---

## 👥 Équipe

- **Backend:** Python/FastAPI
- **Frontend:** Flutter/Dart
- **Infrastructure:** Railway, Firebase, Cloudinary
- **Paiements:** Stripe
- **Dropshipping:** CJ Dropshipping

---

## 📞 Support

Pour questions ou support:
- 📧 Email: support@buyv.com
- 📚 Documentation: `/docs`
- 🐛 Issues: GitHub Issues

---

## 🙏 Remerciements

- Flutter Team pour le framework
- Firebase pour l'infrastructure
- FastAPI pour le backend
- Stripe pour les paiements
- CJ Dropshipping pour les produits

---

**🎉 Bon développement avec Buyv!**

---

## 📊 Stats du Projet

- **Lignes de Code:** ~50,000+
- **Fichiers:** 200+
- **Commits:** 500+
- **Version:** 1.1.0
- **Statut:** Production Ready 🚀

---

**Dernière mise à jour:** 28 Décembre 2024
