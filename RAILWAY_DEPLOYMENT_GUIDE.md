# 🚀 Guide de Déploiement Railway - Buyv Platform

## Guide Complet : Backend + Admin Panel avec PostgreSQL

Ce guide vous accompagne dans le déploiement de votre plateforme Buyv sur Railway avec une base de données PostgreSQL partagée.

---

## 📋 Table des Matières

1. [Prérequis](#prérequis)
2. [Étape 1 : Créer la Base PostgreSQL](#étape-1--créer-la-base-postgresql)
3. [Étape 2 : Migrer les Données](#étape-2--migrer-les-données)
4. [Étape 3 : Déployer le Backend](#étape-3--déployer-le-backend)
5. [Étape 4 : Déployer l'Admin Panel](#étape-4--déployer-ladmin-panel)
6. [Étape 5 : Configuration Finale](#étape-5--configuration-finale)
7. [Dépannage](#dépannage)

---

## Prérequis

- ✅ Compte Railway (gratuit : railway.app)
- ✅ Code backend et admin panel prêts
- ✅ Base SQLite locale avec données existantes
- ✅ Git installé sur votre machine

---

## Étape 1 : Créer la Base PostgreSQL

### 1.1 Connexion à Railway

1. Allez sur [railway.app](https://railway.app)
2. Connectez-vous avec GitHub
3. Cliquez sur **"New Project"**

### 1.2 Création de la Base de Données

1. Dans votre nouveau projet, cliquez **"+ New"**
2. Sélectionnez **"Database"**
3. Choisissez **"PostgreSQL"**
4. ✅ Railway crée automatiquement votre base PostgreSQL

### 1.3 Récupérer l'URL de Connexion

1. Cliquez sur votre base PostgreSQL
2. Allez dans l'onglet **"Connect"**
3. Copiez la valeur de **"DATABASE_URL"**
   ```
   postgres://user:password@hostname.railway.app:port/railway
   ```
4. ⚠️ **IMPORTANT** : Gardez cette URL en lieu sûr !

---

## Étape 2 : Migrer les Données

### 2.1 Configuration du Script

1. Ouvrez un terminal dans le dossier du projet
2. Définissez la variable d'environnement avec l'URL PostgreSQL :

**Windows (PowerShell) :**
```powershell
$env:DATABASE_URL="postgresql://user:password@hostname.railway.app:port/railway"
```

**Windows (CMD) :**
```cmd
set DATABASE_URL=postgresql://user:password@hostname.railway.app:port/railway
```

**Mac/Linux :**
```bash
export DATABASE_URL="postgresql://user:password@hostname.railway.app:port/railway"
```

### 2.2 Installation des Dépendances

```bash
pip install psycopg2-binary SQLAlchemy
```

### 2.3 Exécution de la Migration

```bash
python migrate_to_postgresql.py
```

Le script va :
- ✅ Se connecter à SQLite locale
- ✅ Se connecter à PostgreSQL Railway
- ✅ Créer toutes les tables
- ✅ Copier toutes les données
- ✅ Afficher un rapport détaillé

**Exemple de sortie :**
```
======================================================================
🚀 Starting Database Migration: SQLite → PostgreSQL
======================================================================

📊 Connecting to databases...

🔨 Creating tables in PostgreSQL...
✅ Tables created successfully

📦 Migrating data...
----------------------------------------------------------------------
✅ Users                 -   15 records migrated
✅ Posts                 -   42 records migrated
✅ Comments              -   89 records migrated
✅ PostLikes             -  156 records migrated
✅ Follows               -   34 records migrated
✅ Orders                -    8 records migrated
✅ OrderItems            -   12 records migrated
✅ Commissions           -    5 records migrated
✅ Notifications         -   67 records migrated
----------------------------------------------------------------------

🎉 Migration completed successfully!
📊 Total records migrated: 428
======================================================================
```

---

## Étape 3 : Déployer le Backend

### 3.1 Préparer le Backend pour Railway

Railway utilise le fichier `Procfile` existant.

**Vérifiez votre `Procfile` :**
```
web: uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### 3.2 Déployer sur Railway

#### Option A : Depuis GitHub (Recommandé)

1. Pushez votre code sur GitHub :
   ```bash
   cd buyv_backend
   git init
   git add .
   git commit -m "Backend ready for Railway"
   git branch -M main
   git remote add origin https://github.com/VOTRE_USERNAME/buyv-backend.git
   git push -u origin main
   ```

2. Dans Railway :
   - Cliquez **"+ New"** → **"GitHub Repo"**
   - Sélectionnez votre repository
   - Railway détecte automatiquement le backend Python

#### Option B : Railway CLI

```bash
npm i -g @railway/cli
railway login
cd buyv_backend
railway init
railway up
```

### 3.3 Configuration des Variables d'Environnement

Dans Railway, allez dans votre service backend → **"Variables"** :

```
DATABASE_URL = ${{Postgres.DATABASE_URL}}
SECRET_KEY = votre-super-secret-key-change-en-production
CJ_API_KEY = votre-cle-cj
CJ_ACCOUNT_ID = votre-id-cj
CJ_EMAIL = votre-email-cj
STRIPE_SECRET_KEY = votre-cle-stripe
ALGORITHM = HS256
ACCESS_TOKEN_EXPIRE_MINUTES = 30
```

**🔗 Lier PostgreSQL :**
- `${{Postgres.DATABASE_URL}}` référence automatiquement votre base PostgreSQL
- Railway remplace automatiquement cette valeur

### 3.4 Tester le Backend

1. Railway vous donne une URL publique (ex: `https://buyv-backend-production.up.railway.app`)
2. Testez :
   ```bash
   curl https://votre-backend.railway.app/docs
   ```
3. Vous devriez voir la documentation FastAPI

---

## Étape 4 : Déployer l'Admin Panel

### 4.1 Préparer l'Admin Panel

**Créez un `Procfile` dans `buyv_admin/` :**
```
web: gunicorn admin_app:app --bind 0.0.0.0:$PORT
```

**Ajoutez `gunicorn` dans `requirements.txt` :**
```txt
Flask==3.0.0
Flask-Admin==1.6.1
Flask-Login==0.6.3
Flask-Babel==4.0.0
SQLAlchemy==2.0.23
Werkzeug==3.0.1
psycopg2-binary==2.9.10
python-dotenv==1.0.1
gunicorn==21.2.0
```

### 4.2 Déployer sur Railway

#### Option A : Depuis GitHub

1. Pushez votre admin panel sur GitHub :
   ```bash
   cd buyv_admin
   git init
   git add .
   git commit -m "Admin panel ready for Railway"
   git branch -M main
   git remote add origin https://github.com/VOTRE_USERNAME/buyv-admin.git
   git push -u origin main
   ```

2. Dans Railway :
   - **"+ New"** → **"GitHub Repo"**
   - Sélectionnez votre repository admin
   - Railway détecte automatiquement Flask

#### Option B : Railway CLI

```bash
cd buyv_admin
railway init
railway up
```

### 4.3 Configuration des Variables

Dans Railway, service admin panel → **"Variables"** :

```
DATABASE_URL = ${{Postgres.DATABASE_URL}}
SECRET_KEY = changez-cette-cle-secrete-admin-panel
```

### 4.4 Tester l'Admin Panel

1. Railway vous donne une URL (ex: `https://buyv-admin-production.up.railway.app`)
2. Ouvrez dans le navigateur
3. Connectez-vous avec `admin` / `admin123`
4. ⚠️ **CHANGEZ LE MOT DE PASSE** dans [admin_app.py](buyv_admin/admin_app.py#L59)

---

## Étape 5 : Configuration Finale

### 5.1 Mettre à Jour l'Application Mobile

Dans votre app Flutter, modifiez l'URL du backend :

**`lib/core/constants/api_constants.dart` :**
```dart
class ApiConstants {
  static const String baseUrl = 'https://votre-backend.railway.app';
  // ...
}
```

### 5.2 Sécurité - Admin Panel

**Modifier les identifiants par défaut :**

Éditez `buyv_admin/admin_app.py` :
```python
ADMIN_USERS = {
    'admin': generate_password_hash('NOUVEAU_MOT_DE_PASSE_FORT'),
    'buyv_admin': generate_password_hash('AUTRE_MOT_DE_PASSE_FORT')
}
```

Redéployez :
```bash
git add .
git commit -m "Update admin passwords"
git push
```

### 5.3 Configuration Production

**Backend : Désactiver les CORS en développement**

Dans `buyv_backend/app/main.py`, modifiez les CORS :
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://votre-domaine.com",  # Votre domaine de production
        "https://buyv-admin-production.up.railway.app"  # Admin panel
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 🎯 Architecture Finale

```
┌─────────────────────────────────────────────────────────────┐
│                      Railway Project                         │
│                                                              │
│  ┌──────────────┐      ┌──────────────┐     ┌────────────┐ │
│  │   Backend    │◄────►│  PostgreSQL  │◄───►│   Admin    │ │
│  │   FastAPI    │      │   Database   │     │   Panel    │ │
│  └──────┬───────┘      └──────────────┘     └─────┬──────┘ │
│         │                                           │        │
└─────────┼───────────────────────────────────────────┼────────┘
          │                                           │
          ▼                                           ▼
    ┌─────────────┐                            ┌──────────────┐
    │   Mobile    │                            │   Browser    │
    │     App     │                            │   (Admin)    │
    └─────────────┘                            └──────────────┘
```

**URLs :**
- Backend API : `https://buyv-backend.railway.app`
- Admin Panel : `https://buyv-admin.railway.app`
- PostgreSQL : Hébergée sur Railway (accès via DATABASE_URL)

---

## Dépannage

### ❌ Erreur : "postgres://" non reconnu

**Solution :** Le code inclut déjà la conversion automatique :
```python
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
```

### ❌ Admin panel : KeyError 'babel'

**Solution :** `Flask-Babel` est maintenant inclus dans requirements.txt

### ❌ Backend : "Could not import models"

**Solution :** Vérifiez que tous les fichiers sont bien pushés sur GitHub/Railway :
```bash
git status
git add .
git commit -m "Add missing files"
git push
```

### ❌ Migration : "No such table"

**Solution :** Le script crée automatiquement les tables. Si erreur :
```bash
# Supprimez les tables et relancez
python -c "from migrate_to_postgresql import *; models.Base.metadata.drop_all(bind=postgres_engine)"
python migrate_to_postgresql.py
```

### ❌ Railway : "Port already in use"

**Solution :** Railway utilise automatiquement la variable `$PORT`. Vérifiez votre Procfile :
```
web: uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

### 🔍 Vérifier les Logs Railway

Dans Railway :
1. Cliquez sur votre service (Backend ou Admin)
2. Onglet **"Deployments"**
3. Cliquez sur le déploiement actif
4. Consultez les logs en temps réel

---

## 📊 Coûts Railway

**Plan Gratuit :**
- $5 de crédit gratuit/mois
- Suffisant pour backend + admin + PostgreSQL
- Sleep après 12h d'inactivité (se réveille automatiquement)

**Plan Hobby ($5/mois) :**
- $5 de crédit + $5 supplémentaires
- Pas de sleep
- Idéal pour production

---

## ✅ Checklist de Déploiement

- [ ] PostgreSQL créée sur Railway
- [ ] `DATABASE_URL` copiée
- [ ] Données migrées avec succès (script exécuté)
- [ ] Backend déployé et accessible
- [ ] Variables d'environnement configurées (backend)
- [ ] Admin panel déployé et accessible
- [ ] Variables d'environnement configurées (admin)
- [ ] Mots de passe admin changés
- [ ] URL backend mise à jour dans l'app mobile
- [ ] CORS configurés pour production
- [ ] Logs vérifiés (aucune erreur)
- [ ] Tests fonctionnels effectués

---

## 🎉 Félicitations !

Votre plateforme Buyv est maintenant en production avec :
- ✅ Backend FastAPI sur Railway
- ✅ Admin Panel Flask sur Railway
- ✅ Base PostgreSQL partagée
- ✅ App mobile connectée au backend
- ✅ Panel d'administration web fonctionnel

---

## 📚 Ressources

- [Documentation Railway](https://docs.railway.app/)
- [Railway Discord](https://discord.gg/railway)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)
- [Flask Deployment](https://flask.palletsprojects.com/en/3.0.x/deploying/)

---

## 🆘 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs Railway
2. Consultez la section Dépannage ci-dessus
3. Vérifiez que toutes les variables d'environnement sont définies
4. Testez localement avec `DATABASE_URL` PostgreSQL

---

**Dernière mise à jour :** 28 Décembre 2024
