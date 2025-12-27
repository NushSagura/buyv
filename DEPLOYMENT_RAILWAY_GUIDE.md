# 🚂 GUIDE DÉPLOIEMENT RAILWAY - BACKEND BUYV

**Date**: 27 Décembre 2024  
**Version Backend**: FastAPI + PostgreSQL  
**Database**: Supabase PostgreSQL

---

## 📋 PRÉREQUIS

- ✅ Compte Railway (https://railway.app)
- ✅ Compte GitHub (repo BuyV)
- ✅ Database Supabase existante
- ✅ Credentials Cloudinary
- ✅ Credentials Stripe

---

## 🎯 ÉTAPE 1: PRÉPARER LE BACKEND

### 1.1 Créer `railway.json`

```bash
cd "C:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv"
```

Créez: `buyv_backend/railway.json`
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### 1.2 Créer `Procfile`

Créez: `buyv_backend/Procfile`
```
web: uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### 1.3 Créer `runtime.txt`

Créez: `buyv_backend/runtime.txt`
```
python-3.11
```

### 1.4 Vérifier `requirements.txt`

Fichier: `buyv_backend/requirements.txt`
```txt
fastapi==0.115.6
uvicorn[standard]==0.34.0
sqlalchemy==2.0.36
psycopg2-binary==2.9.10
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.20
cloudinary==1.41.0
stripe==11.3.0
pydantic==2.10.4
pydantic-settings==2.7.0
python-dotenv==1.0.1
```

### 1.5 Vérifier structure backend

```
buyv_backend/
├── app/
│   ├── __init__.py
│   ├── main.py          # Point d'entrée FastAPI
│   ├── config.py        # Configuration environnement
│   ├── database.py      # Connexion PostgreSQL
│   ├── models.py        # Modèles SQLAlchemy
│   ├── schemas.py       # Schémas Pydantic
│   ├── auth.py          # Endpoints authentification
│   ├── users.py         # Endpoints utilisateurs
│   ├── posts.py         # Endpoints posts/reels
│   ├── orders.py        # Endpoints commandes
│   ├── payments.py      # Endpoints paiements Stripe
│   ├── comments.py      # Endpoints commentaires
│   ├── follows.py       # Endpoints follows
│   ├── notifications.py # Endpoints notifications
│   └── commissions.py   # Endpoints commissions
├── requirements.txt
├── railway.json
├── Procfile
├── runtime.txt
└── .env.example
```

---

## 🚀 ÉTAPE 2: DÉPLOIEMENT SUR RAILWAY

### 2.1 Accéder à Railway Dashboard

1. Allez sur https://railway.app
2. Connectez-vous avec GitHub
3. Cliquez **"New Project"**

### 2.2 Déployer depuis GitHub

**Option A: Nouveau déploiement**
1. Cliquez **"Deploy from GitHub repo"**
2. Sélectionnez votre repo BuyV
3. Cliquez **"Deploy Now"**

**Option B: Modifier déploiement existant**
1. Cliquez sur votre projet existant
2. Allez dans **Settings** → **Service**
3. Vérifiez que **Root Directory** = `buyv_backend`
4. Cliquez **"Redeploy"**

### 2.3 Configurer Root Directory

**IMPORTANT**: Railway doit pointer vers le dossier backend

1. Dans le service → **Settings**
2. Trouvez **"Root Directory"**
3. Entrez: `buyv_backend`
4. **Save Changes**

---

## 🔐 ÉTAPE 3: VARIABLES D'ENVIRONNEMENT

### 3.1 Accéder aux Variables

1. Dans votre service Railway
2. Cliquez l'onglet **"Variables"**
3. Ajoutez TOUTES ces variables:

### 3.2 Variables Requises

```env
# Database (Supabase)
DATABASE_URL=postgresql://postgres.[PROJECT]:[PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres

# JWT Secret
SECRET_KEY=votre-secret-key-super-securisee-minimum-32-caracteres

# CORS
CORS_ORIGINS=*

# Cloudinary
CLOUDINARY_CLOUD_NAME=votre-cloud-name
CLOUDINARY_API_KEY=votre-api-key
CLOUDINARY_API_SECRET=votre-api-secret

# Stripe
STRIPE_SECRET_KEY=sk_test_votre_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=pk_test_votre_stripe_publishable_key
STRIPE_WEBHOOK_SECRET=whsec_votre_webhook_secret

# App Config
ENVIRONMENT=production
DEBUG=False
PORT=8000
```

### 3.3 Obtenir DATABASE_URL Supabase

1. Allez sur https://supabase.com
2. Sélectionnez votre projet
3. **Settings** → **Database**
4. Trouvez **"Connection string"** → **"URI"**
5. Mode: **Transaction** (port 6543)
6. Copiez l'URL complète

**Format**:
```
postgresql://postgres.[projet]:[mot-de-passe]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres
```

### 3.4 Générer SECRET_KEY

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## 📡 ÉTAPE 4: VÉRIFIER LE DÉPLOIEMENT

### 4.1 Attendre le Build

1. Railway va détecter `requirements.txt`
2. Build Python + install packages (2-3 min)
3. Status: **"Deploying"** → **"Active"**

### 4.2 Obtenir l'URL

1. Dans Railway dashboard
2. Cliquez **"Settings"** → **"Networking"**
3. Cliquez **"Generate Domain"**
4. Votre URL: `https://buyv-backend-production.up.railway.app`

### 4.3 Tester l'API

**Test 1: Root endpoint**
```bash
curl https://votre-app.up.railway.app/
```

Réponse attendue:
```json
{
  "message": "BuyV API",
  "version": "1.0.0",
  "status": "running"
}
```

**Test 2: Health check**
```bash
curl https://votre-app.up.railway.app/health
```

**Test 3: Docs**
Ouvrez: `https://votre-app.up.railway.app/docs`

---

## 🔧 ÉTAPE 5: CONFIGURATION FLUTTER APP

### 5.1 Mettre à jour les URLs

Fichier: `buyv_flutter_app/lib/constants/app_constants.dart`

```dart
class AppConstants {
  // API URLs - PRODUCTION
  static const String fastApiBaseUrl = 'https://votre-app.up.railway.app';
  
  // Autres configs...
}
```

### 5.2 Créer fichier de configuration environnement

Fichier: `buyv_flutter_app/.env`

```env
# Backend API
API_BASE_URL=https://votre-app.up.railway.app

# Cloudinary
CLOUDINARY_CLOUD_NAME=votre-cloud-name
CLOUDINARY_API_KEY=votre-api-key
CLOUDINARY_UPLOAD_PRESET=buyv_upload

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_test_votre_stripe_publishable_key
```

---

## 🐛 ÉTAPE 6: DEBUGGING

### 6.1 Voir les Logs

1. Railway Dashboard → Votre service
2. Onglet **"Deployments"**
3. Cliquez sur le déploiement actif
4. Onglet **"Logs"**

### 6.2 Erreurs Communes

**Erreur: "Application failed to respond"**
```
Solution: Vérifier DATABASE_URL est correct
```

**Erreur: "Module not found"**
```
Solution: Vérifier requirements.txt contient toutes les dépendances
```

**Erreur: CORS**
```
Solution: Ajouter CORS_ORIGINS=* dans variables Railway
```

**Erreur: Port binding**
```
Solution: S'assurer que uvicorn utilise --port $PORT (Railway injecte PORT)
```

### 6.3 Commandes Debug Locales

Tester localement avec variables Railway:

```bash
cd buyv_backend
$env:DATABASE_URL="postgresql://..."
$env:SECRET_KEY="votre-secret"
uvicorn app.main:app --reload
```

---

## 📊 ÉTAPE 7: MONITORING

### 7.1 Métriques Railway

Railway Dashboard → **Metrics**:
- CPU usage
- Memory usage
- Network traffic
- Deployment history

### 7.2 Health Checks

Configurez un monitoring externe:
- UptimeRobot (gratuit): https://uptimerobot.com
- Pingdom
- Checkly

URL à surveiller: `https://votre-app.up.railway.app/health`

---

## 🔄 ÉTAPE 8: REDÉPLOIEMENT

### 8.1 Push Git

```bash
cd "C:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv"
git add .
git commit -m "Update backend for production"
git push origin main
```

Railway redéploie **automatiquement** à chaque push sur `main`.

### 8.2 Redéploiement Manuel

1. Railway Dashboard
2. Cliquez **"Deployments"**
3. Menu ⋮ → **"Redeploy"**

### 8.3 Rollback

Si problème:
1. **Deployments** → Ancien déploiement
2. Menu ⋮ → **"Rollback to this version"**

---

## ✅ CHECKLIST DÉPLOIEMENT

- [ ] `railway.json` créé
- [ ] `Procfile` créé  
- [ ] `runtime.txt` créé
- [ ] `requirements.txt` à jour
- [ ] Projet Railway créé/configuré
- [ ] Root Directory = `buyv_backend`
- [ ] Toutes les variables d'environnement ajoutées
- [ ] DATABASE_URL Supabase configurée
- [ ] Build réussi (logs verts)
- [ ] Domain généré
- [ ] Test API: `/` retourne JSON
- [ ] Test API: `/docs` accessible
- [ ] Test API: `/health` retourne OK
- [ ] URLs mises à jour dans Flutter
- [ ] `.env` Flutter configuré

---

## 🎯 URLS FINALES

**Backend API**: `https://[votre-app].up.railway.app`  
**API Docs**: `https://[votre-app].up.railway.app/docs`  
**Health**: `https://[votre-app].up.railway.app/health`

---

## 📝 NOTES IMPORTANTES

1. **Base de données**: Railway ne fournit PAS de PostgreSQL gratuit illimité. Utilisez Supabase (gratuit 500MB).

2. **Plan Railway**: 
   - Free tier: $5 crédit/mois
   - Hobby: $5/mois
   - Suffisant pour début

3. **Scaling**: Railway scale automatiquement selon trafic.

4. **Backups**: Supabase fait backups automatiques (24h).

5. **SSL**: Railway fournit HTTPS automatiquement.

---

**Créé**: 27 Décembre 2024  
**Status**: ✅ Prêt pour déploiement  
**Support**: Railway Docs - https://docs.railway.app
