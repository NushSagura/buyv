# 💳 GUIDE CONFIGURATION STRIPE POUR CLIENT

**Date**: 27 Décembre 2024  
**Service**: Stripe Payments  
**App**: BuyV Flutter

---

## 🎯 OBJECTIF

Configurer votre propre compte **Stripe** pour:
- Accepter paiements par carte bancaire
- Gérer commandes shop CJ Dropshipping
- Calculer commissions vendeurs
- Gérer remboursements
- Suivre revenus en temps réel

---

## 📋 QU'EST-CE QUE STRIPE?

**Stripe** = Plateforme de paiement en ligne:
- ✅ Cartes de crédit/débit (Visa, Mastercard, Amex)
- ✅ Apple Pay / Google Pay
- ✅ Virements bancaires (SEPA, ACH)
- ✅ Wallets (Alipay, WeChat Pay)
- ✅ Sécurité PCI-DSS Level 1
- ✅ Dashboard complet analytics

**Prix**:
- **Frais transaction**: 1.4% + 0.25€ (cartes EU)
- **Frais transaction**: 2.9% + 0.30$ (cartes non-EU)
- **Pas de frais fixes mensuels**

**Activation compte**:
- **Test Mode**: Immédiat, gratuit
- **Live Mode**: Vérification identité (1-3 jours)

---

## 🚀 ÉTAPE 1: CRÉER COMPTE STRIPE

### 1.1 Inscription

1. Aller sur: https://dashboard.stripe.com/register
2. Remplir formulaire:
   ```
   Email: votre-email@example.com
   Nom complet: [Votre nom]
   Pays: [France / Autre pays]
   Mot de passe: [choisir mot de passe fort]
   ```

3. Cocher "I agree to the Stripe Services Agreement"
4. Cliquer **"Create account"**

### 1.2 Vérification Email

1. Ouvrir email de Stripe
2. Cliquer lien "Verify your email address"
3. Redirection vers dashboard Stripe

### 1.3 Configuration Initiale

Stripe demande informations business:
- **Type de compte**: Individual ou Company
- **Activité**: E-commerce
- **URL website**: https://buyv.app (ou votre domaine)
- **Description**: "Social commerce platform with dropshipping"

⚠️ **IMPORTANT**: Pour commencer, restez en **Test Mode**

---

## 🔑 ÉTAPE 2: OBTENIR API KEYS (TEST MODE)

### 2.1 Accéder aux API Keys

1. Dashboard: https://dashboard.stripe.com/
2. En haut à droite, vérifier **"Test mode"** est activé (toggle)
3. Aller à: **Developers** → **API keys**

### 2.2 Copier Test Keys

Vous verrez 2 types de clés:

**1. Publishable key** (publique - Frontend Flutter)
```
pk_test_51Abc123...xyz
```
- ✅ Peut être dans le code client
- ✅ Pas de risque sécurité si exposée
- Usage: Initialiser Stripe SDK Flutter

**2. Secret key** (secrète - Backend)
```
sk_test_51Abc123...xyz
```
- ❌ NE JAMAIS mettre dans code client
- ❌ NE JAMAIS commit dans Git
- Usage: Créer Payment Intents depuis backend

### 2.3 Noter les Keys

**Créer fichier privé** (NOT dans Git):
```
Stripe Test Keys - BuyV
=======================

Publishable Key (Frontend):
pk_test_51Abc123...xyz

Secret Key (Backend):
sk_test_51Abc123...xyz

Dashboard: https://dashboard.stripe.com/
Email: votre-email@example.com
Password: ********** (sécurisé)
```

---

## 💳 ÉTAPE 3: TESTER AVEC CARTES TEST

### 3.1 Cartes Test Stripe

**Pour tester paiements en Test Mode**:

**Carte SUCCÈS** (paiement accepté):
```
Numéro: 4242 4242 4242 4242
Expiration: n'importe quelle date future (ex: 12/25)
CVC: n'importe quel 3 chiffres (ex: 123)
Code postal: n'importe quel (ex: 75001)
```

**Carte REFUS** (paiement rejeté):
```
Numéro: 4000 0000 0000 0002
Expiration: n'importe quelle date future
CVC: n'importe quel 3 chiffres
Résultat: Card declined
```

**Carte 3D SECURE** (authentification requise):
```
Numéro: 4000 0025 0000 3155
Expiration: n'importe quelle date future
CVC: n'importe quel 3 chiffres
Résultat: Popup authentification 3DS
```

**Plus de cartes test**: https://stripe.com/docs/testing#cards

### 3.2 Test depuis Dashboard

1. Dashboard → **Payments**
2. Cliquer **"New"** → **"Payment"**
3. Montant: 10.00 EUR
4. Carte: 4242 4242 4242 4242
5. Cliquer **"Pay"**
6. Voir paiement dans liste Payments

---

## 📱 ÉTAPE 4: CONFIGURER APP FLUTTER

### 4.1 Installer Stripe Flutter SDK

**Déjà installé dans BuyV**, mais si besoin:
```powershell
cd buyv_flutter_app
flutter pub add flutter_stripe
```

### 4.2 Mettre à jour .env

**Fichier**: `buyv_flutter_app/.env`

Ajouter/modifier:
```env
# Stripe - TEST MODE
STRIPE_PUBLISHABLE_KEY=pk_test_votre_publishable_key
```

⚠️ Remplacer par votre vraie Publishable Key

### 4.3 Vérifier app_constants.dart

**Fichier**: `buyv_flutter_app/lib/constants/app_constants.dart`

```dart
class AppConstants {
  // Stripe
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_...',
  );
}
```

### 4.4 Initialiser Stripe SDK

**Fichier**: `buyv_flutter_app/lib/main.dart`

Dans `main()`:
```dart
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Stripe
  Stripe.publishableKey = AppConstants.stripePublishableKey;
  Stripe.merchantIdentifier = 'merchant.com.buyv.flutter_app';
  
  runApp(MyApp());
}
```

### 4.5 Vérifier payment_service.dart

**Fichier**: `buyv_flutter_app/lib/services/payment_service.dart`

```dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_constants.dart';

class PaymentService {
  // Créer Payment Intent via backend
  static Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.fastApiBaseUrl}/payments/create-intent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': (amount * 100).toInt(), // cents
          'currency': currency,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('❌ Create payment intent error: $e');
      return null;
    }
  }
  
  // Confirmer paiement avec Stripe SDK
  static Future<bool> confirmPayment({
    required String clientSecret,
  }) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'BuyV',
          style: ThemeMode.system,
        ),
      );
      
      await Stripe.instance.presentPaymentSheet();
      
      print('✅ Payment confirmed successfully');
      return true;
    } catch (e) {
      print('❌ Payment confirmation error: $e');
      return false;
    }
  }
}
```

---

## 🖥️ ÉTAPE 5: CONFIGURER BACKEND FASTAPI

### 5.1 Installer Stripe Python SDK

**Fichier**: `buyv_backend/requirements.txt`

Ajouter (si pas déjà présent):
```txt
stripe==7.8.0
```

Installer:
```powershell
cd buyv_backend
pip install -r requirements.txt
```

### 5.2 Mettre à jour .env Backend

**Fichier**: `buyv_backend/.env`

Ajouter:
```env
# Stripe - TEST MODE
STRIPE_SECRET_KEY=sk_test_votre_secret_key
STRIPE_PUBLISHABLE_KEY=pk_test_votre_publishable_key
```

### 5.3 Configurer config.py

**Fichier**: `buyv_backend/app/config.py`

```python
import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # Stripe
    STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY")
    STRIPE_PUBLISHABLE_KEY = os.getenv("STRIPE_PUBLISHABLE_KEY")
    
    # Autres configs...

settings = Settings()
```

### 5.4 Créer Endpoint Payment Intent

**Fichier**: `buyv_backend/app/payments.py`

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import stripe
from .config import settings
from .database import get_db
from .auth import get_current_user
from pydantic import BaseModel

router = APIRouter(prefix="/payments", tags=["payments"])

# Configurer Stripe avec Secret Key
stripe.api_key = settings.STRIPE_SECRET_KEY


class PaymentIntentRequest(BaseModel):
    amount: int  # en cents (ex: 1000 = 10.00 EUR)
    currency: str = "eur"


@router.post("/create-intent")
async def create_payment_intent(
    request: PaymentIntentRequest,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Créer un Payment Intent Stripe"""
    try:
        # Créer Payment Intent
        intent = stripe.PaymentIntent.create(
            amount=request.amount,
            currency=request.currency,
            metadata={
                'user_id': current_user.id,
                'username': current_user.username,
            },
            automatic_payment_methods={
                'enabled': True,
            },
        )
        
        return {
            "clientSecret": intent.client_secret,
            "paymentIntentId": intent.id,
        }
        
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/webhook")
async def stripe_webhook(request: Request, db: Session = Depends(get_db)):
    """Webhook Stripe pour événements (paiement réussi, échoué, etc.)"""
    payload = await request.body()
    sig_header = request.headers.get('stripe-signature')
    
    # Webhook secret (voir étape 6)
    webhook_secret = settings.STRIPE_WEBHOOK_SECRET
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, webhook_secret
        )
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    # Traiter événement
    if event['type'] == 'payment_intent.succeeded':
        payment_intent = event['data']['object']
        
        # Créer commande dans DB
        order = Order(
            user_id=int(payment_intent['metadata']['user_id']),
            amount=payment_intent['amount'] / 100,
            currency=payment_intent['currency'],
            stripe_payment_intent_id=payment_intent['id'],
            status='paid',
        )
        db.add(order)
        db.commit()
        
        print(f'✅ Payment succeeded: {payment_intent["id"]}')
        
    elif event['type'] == 'payment_intent.payment_failed':
        payment_intent = event['data']['object']
        print(f'❌ Payment failed: {payment_intent["id"]}')
    
    return {"status": "success"}
```

### 5.5 Ajouter Route dans main.py

**Fichier**: `buyv_backend/app/main.py`

```python
from .payments import router as payments_router

app.include_router(payments_router)
```

---

## 🔔 ÉTAPE 6: CONFIGURER WEBHOOKS (IMPORTANT)

### 6.1 Qu'est-ce qu'un Webhook?

**Webhook** = Stripe envoie notification à votre backend quand:
- ✅ Paiement réussi
- ❌ Paiement échoué
- 💰 Remboursement effectué
- 🔄 Abonnement renouvelé

### 6.2 Créer Webhook (Test Mode)

1. Dashboard → **Developers** → **Webhooks**
2. Cliquer **"Add endpoint"**
3. **Endpoint URL**: 
   ```
   https://votre-backend.up.railway.app/payments/webhook
   ```
   
4. **Events to send**: Sélectionner
   - ☑ payment_intent.succeeded
   - ☑ payment_intent.payment_failed
   - ☑ charge.refunded
   
5. Cliquer **"Add endpoint"**

### 6.3 Copier Webhook Secret

Après création, vous verrez:
```
Signing secret: whsec_abc123xyz...
```

**Ajouter au .env backend**:
```env
STRIPE_WEBHOOK_SECRET=whsec_abc123xyz...
```

### 6.4 Tester Webhook Localement (Stripe CLI)

**Installer Stripe CLI**:
```powershell
# Windows (via Scoop)
scoop install stripe

# Vérifier installation
stripe --version
```

**Login**:
```powershell
stripe login
```

**Forward webhooks vers localhost**:
```powershell
stripe listen --forward-to localhost:8000/payments/webhook
```

Résultat:
```
Ready! Your webhook signing secret is whsec_test123... (^C to quit)
```

**Tester événement**:
```powershell
stripe trigger payment_intent.succeeded
```

Vérifier logs backend: `✅ Payment succeeded: pi_123...`

---

## 🧪 ÉTAPE 7: TESTER PAIEMENT END-TO-END

### 7.1 Flow Complet

1. **Client Flutter** créer commande:
   ```dart
   final intent = await PaymentService.createPaymentIntent(
     amount: 29.99,
     currency: 'eur',
   );
   ```

2. **Backend** créer Payment Intent Stripe:
   ```python
   intent = stripe.PaymentIntent.create(amount=2999, currency='eur')
   return intent.client_secret
   ```

3. **Client Flutter** afficher Payment Sheet:
   ```dart
   await PaymentService.confirmPayment(
     clientSecret: intent['clientSecret'],
   );
   ```

4. **Utilisateur** entre carte test: 4242 4242 4242 4242

5. **Stripe** traite paiement

6. **Webhook** notifie backend: payment_intent.succeeded

7. **Backend** crée commande dans DB

8. **Client Flutter** affiche confirmation

### 7.2 Test depuis App

1. Lancer backend:
   ```powershell
   cd buyv_backend
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

2. Lancer app Flutter:
   ```powershell
   cd buyv_flutter_app
   flutter run
   ```

3. Dans app:
   - Aller au **Shop**
   - Ajouter produit au **Panier**
   - Aller au **Panier**
   - Cliquer **"Commander"**
   - Remplir formulaire checkout
   - Cliquer **"Payer"**

4. Payment Sheet s'ouvre:
   - Entrer carte: 4242 4242 4242 4242
   - Expiration: 12/25
   - CVC: 123
   - Cliquer **"Pay"**

5. Voir confirmation: **"Paiement réussi ✅"**

### 7.3 Vérifier dans Dashboard Stripe

1. Dashboard → **Payments**
2. Voir nouveau paiement:
   ```
   Montant: €29.99
   Status: Succeeded ✅
   Card: •••• 4242
   Date: [maintenant]
   ```

3. Cliquer sur paiement pour détails complets

---

## 🚀 ÉTAPE 8: ACTIVER LIVE MODE (PRODUCTION)

### 8.1 Compléter Informations Business

**Avant activer Live Mode**, Stripe demande:

1. Dashboard → **Settings** → **Account details**
2. Remplir formulaire complet:
   - **Type entreprise**: Individual / Company
   - **Nom légal**: [Nom complet ou raison sociale]
   - **Adresse**: [Adresse complète]
   - **SIRET/SIREN**: [Si France, numéro SIRET]
   - **Téléphone**: [Numéro contact]
   - **Description activité**: "E-commerce social platform"
   - **Website**: https://buyv.app

3. **Documents requis**:
   - ☑ Pièce d'identité (passeport, carte identité)
   - ☑ Justificatif domicile (< 3 mois)
   - ☑ Kbis (si entreprise)

4. Upload documents
5. Attendre validation (1-3 jours)

### 8.2 Obtenir Live API Keys

1. En haut à droite, **toggle "Live mode"**
2. Aller à **Developers** → **API keys**
3. Copier nouvelles keys:
   - Publishable key: `pk_live_51Abc...`
   - Secret key: `sk_live_51Abc...`

### 8.3 Créer Webhook Live Mode

1. Live mode → **Developers** → **Webhooks**
2. Ajouter endpoint:
   ```
   https://votre-backend-prod.up.railway.app/payments/webhook
   ```
3. Mêmes événements que test mode
4. Copier nouveau webhook secret: `whsec_live_abc...`

### 8.4 Mettre à jour .env Production

**Backend .env (Railway)**:
```env
# Stripe - LIVE MODE
STRIPE_SECRET_KEY=sk_live_votre_secret_key
STRIPE_PUBLISHABLE_KEY=pk_live_votre_publishable_key
STRIPE_WEBHOOK_SECRET=whsec_live_votre_webhook_secret
```

**Flutter .env**:
```env
# Stripe - LIVE MODE
STRIPE_PUBLISHABLE_KEY=pk_live_votre_publishable_key
```

### 8.5 Rebuild & Deploy

```powershell
# Backend
cd buyv_backend
git add .
git commit -m "Update Stripe to Live mode"
git push railway main

# Flutter
cd buyv_flutter_app
flutter clean
flutter build apk --release
```

---

## 💰 ÉTAPE 9: GÉRER REMBOURSEMENTS

### 9.1 Remboursement depuis Dashboard

1. Dashboard → **Payments**
2. Cliquer sur paiement à rembourser
3. Cliquer **"Refund payment"**
4. Montant: Full ou Partial
5. Raison: (optionnel)
6. Cliquer **"Refund"**

### 9.2 Remboursement via API

**Backend endpoint**:
```python
@router.post("/refund/{payment_intent_id}")
async def refund_payment(
    payment_intent_id: str,
    amount: int = None,  # None = remboursement total
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        refund = stripe.Refund.create(
            payment_intent=payment_intent_id,
            amount=amount,  # None = full refund
        )
        
        return {
            "refundId": refund.id,
            "status": refund.status,
            "amount": refund.amount / 100,
        }
        
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))
```

### 9.3 Webhook Refund

**Ajoutez dans webhook handler**:
```python
elif event['type'] == 'charge.refunded':
    charge = event['data']['object']
    
    # Mettre à jour commande dans DB
    order = db.query(Order).filter(
        Order.stripe_payment_intent_id == charge['payment_intent']
    ).first()
    
    if order:
        order.status = 'refunded'
        db.commit()
        
    print(f'💰 Refund processed: {charge["id"]}')
```

---

## 📊 ÉTAPE 10: SURVEILLER REVENUS & ANALYTICS

### 10.1 Dashboard Home

URL: https://dashboard.stripe.com/

Voir en temps réel:
- **Revenus aujourd'hui**
- **Volume transactions**
- **Taux réussite paiements**
- **Graphiques tendances**

### 10.2 Reports

1. Dashboard → **Reports** → **Payments**
2. Filtrer par:
   - Date range
   - Status (succeeded, failed, refunded)
   - Montant
   - Devise

3. Export CSV/Excel pour comptabilité

### 10.3 Balance & Payouts

1. Dashboard → **Balance**
2. Voir:
   - **Available balance**: Disponible pour virement
   - **Pending balance**: En attente (7 jours délai)
   - **Next payout**: Date prochain virement

3. **Payouts** (virements vers compte bancaire):
   - Automatiques tous les 7 jours par défaut
   - Configurable: Daily, Weekly, Monthly
   - Settings → **Bank accounts and scheduling**

### 10.4 Alertes

1. Settings → **Notifications**
2. Configurer emails:
   - ☑ Failed payments
   - ☑ Disputes (chargebacks)
   - ☑ Successful payouts
   - ☑ Daily summary

---

## 🔐 ÉTAPE 11: SÉCURITÉ

### 11.1 Best Practices

**Ne jamais**:
- ❌ Mettre Secret Key dans code client
- ❌ Commit keys dans Git
- ❌ Partager keys par email non chiffré
- ❌ Utiliser Live keys en développement

**Toujours**:
- ✅ Stocker keys dans .env
- ✅ Ajouter .env au .gitignore
- ✅ Utiliser Test keys en dev
- ✅ Vérifier webhooks signatures
- ✅ HTTPS uniquement pour webhooks

### 11.2 Rollover API Keys

Si keys compromises:

1. Dashboard → **Developers** → **API keys**
2. Cliquer **"Roll key"** à côté de la key
3. Nouvelle key générée, ancienne invalidée
4. Mettre à jour .env rapidement (ancienne key arrête de fonctionner)

### 11.3 2FA (Two-Factor Authentication)

1. Settings → **Team and security**
2. **Two-step authentication**
3. Activer via:
   - SMS
   - Authenticator app (Google Authenticator, Authy)

---

## 🔧 ÉTAPE 12: TROUBLESHOOTING

### Erreur: "Invalid API Key provided"

**Cause**: Secret key incorrecte ou manquante

**Solutions**:
1. Vérifier .env contient `STRIPE_SECRET_KEY`
2. Vérifier copié key complète (commence par `sk_test_` ou `sk_live_`)
3. Vérifier bon mode (test vs live)
4. Redémarrer backend après changement .env

### Erreur: "Your card was declined"

**Causes** (Live Mode):
- Carte invalide
- Fonds insuffisants
- Carte expirée
- Banque bloque transaction

**Solutions**:
- Demander client essayer autre carte
- Vérifier montant disponible
- Activer paiements internationaux (si nécessaire)

### Webhook non reçu

**Causes**:
- URL webhook incorrecte
- Backend pas accessible publiquement
- Firewall bloque Stripe IPs

**Solutions**:
1. Vérifier URL webhook: `https://votre-backend.up.railway.app/payments/webhook`
2. Tester endpoint: `curl https://votre-backend.up.railway.app/payments/webhook`
3. Logs Railway: Voir requêtes Stripe
4. Dashboard Stripe → Webhooks → [votre endpoint] → **Attempts** (voir erreurs)

### Payment Sheet ne s'ouvre pas

**Causes**:
- Publishable key manquante/incorrecte
- Client secret invalide
- Stripe SDK mal initialisé

**Solutions**:
1. Vérifier `Stripe.publishableKey` dans main.dart
2. Vérifier backend retourne `clientSecret` valide
3. Logs Flutter: Chercher erreurs Stripe
4. Tester avec carte test: 4242 4242 4242 4242

---

## ✅ CHECKLIST CONFIGURATION STRIPE

### Test Mode
- [ ] Compte Stripe créé
- [ ] Email vérifié
- [ ] Test mode activé
- [ ] Test Publishable Key copiée (pk_test_...)
- [ ] Test Secret Key copiée (sk_test_...)
- [ ] .env Flutter mis à jour (publishable key)
- [ ] .env Backend mis à jour (secret key)
- [ ] Backend endpoint /payments/create-intent créé
- [ ] Stripe SDK Flutter initialisé (main.dart)
- [ ] Test paiement carte 4242 réussi
- [ ] Paiement visible dans Dashboard
- [ ] Webhook test mode créé
- [ ] Webhook secret copié
- [ ] Webhook testé avec Stripe CLI

### Live Mode (Production)
- [ ] Informations business complétées
- [ ] Documents identité uploadés
- [ ] Compte validé par Stripe (1-3 jours)
- [ ] Live mode activé
- [ ] Live Publishable Key copiée (pk_live_...)
- [ ] Live Secret Key copiée (sk_live_...)
- [ ] .env production mis à jour
- [ ] Webhook live mode créé
- [ ] Webhook secret live copié
- [ ] Test paiement réel effectué (petite somme)
- [ ] Compte bancaire lié pour payouts
- [ ] Notifications emails configurées
- [ ] 2FA activé

---

## 📞 SUPPORT STRIPE

**Documentation**:
- API Reference: https://stripe.com/docs/api
- Flutter SDK: https://pub.dev/packages/flutter_stripe
- Webhooks: https://stripe.com/docs/webhooks
- Testing: https://stripe.com/docs/testing

**Contact Support**:
- Email: support@stripe.com
- Chat: Dashboard → icône "?" en bas droite
- Téléphone: https://stripe.com/contact (numéros par pays)

**Communauté**:
- Stack Overflow: Tag `stripe-payments`
- GitHub Issues: https://github.com/stripe/stripe-flutter

**Statut Service**:
- https://status.stripe.com/

---

**Créé**: 27 Décembre 2024  
**Status**: ✅ Guide complet configuration Stripe  
**Pour**: Client BuyV E-commerce
