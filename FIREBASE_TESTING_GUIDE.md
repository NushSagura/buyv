# 🔥 Guide de Test Firebase Cloud Messaging - BuyV

## ✅ Configuration Complétée

### 📱 Configuration Android
- ✅ Firebase initialisé dans la console Firebase
- ✅ `google-services.json` placé dans `android/app/`
- ✅ `build.gradle.kts` modifié avec plugin Google Services
- ✅ `AndroidManifest.xml` configuré avec permissions et service FCM
- ✅ Icône de notification créée (`ic_notification.xml`)
- ✅ `firebase_options.dart` généré avec vos credentials
- ✅ Dépendances Firebase ajoutées à `pubspec.yaml`
- ✅ Service Firebase initialisé dans `main.dart`

### 🔑 Vos Credentials Firebase
```
Project ID: buyv-beb01
Project Number: 168600920904
App ID: 1:168600920904:android:92ad34d994e8526b86497d
API Key: AIzaSyCYntEy3vEtyu7eUqJsrqfWXkDe13iDLvQ
```

---

## 🧪 Test 1: Vérifier l'Initialisation Firebase

### Commande
```bash
cd "c:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv\buyv_flutter_app"
flutter run
```

### Ce que vous devez voir dans les logs
```
✅ Firebase initialized
✅ Environment variables loaded
✅ Stripe initialized
✅ Firebase Notifications initialized
FCM Token: [votre-token-fcm]
```

### Si l'application démarre sans erreur:
- ✅ Firebase est bien configuré
- ✅ Le service de notifications fonctionne
- ✅ Le token FCM est généré automatiquement

---

## 🧪 Test 2: Vérifier le Token FCM dans les Logs

### Après le lancement de l'app, recherchez dans les logs:
```
Firebase Notification Service initialized
FCM Token: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Copiez ce token FCM** - vous en aurez besoin pour tester les notifications depuis le backend.

---

## 🧪 Test 3: Tester une Notification depuis Firebase Console

### Étapes:
1. **Allez dans Firebase Console** → [https://console.firebase.google.com](https://console.firebase.google.com)
2. **Sélectionnez votre projet**: `buyv-beb01`
3. **Menu** → **Engage** → **Cloud Messaging**
4. **Cliquez sur** "Send your first message"
5. **Remplissez**:
   - **Notification title**: "Test BuyV"
   - **Notification text**: "Notification de test depuis Firebase"
6. **Next** → **Select app**: Android (`com.buyv.flutter_app`)
7. **Test on device** → Collez votre FCM Token
8. **Test** → Cliquez sur "Send"

### Résultats attendus:

#### Si l'app est en foreground (ouverte):
- ✅ Notification affichée dans l'app (snackbar ou dialog)
- ✅ Log dans la console: `Received notification: ...`

#### Si l'app est en background (minimisée):
- ✅ Notification apparaît dans la barre de notification Android
- ✅ Cliquer sur la notification ouvre l'app

#### Si l'app est fermée (terminated):
- ✅ Notification apparaît dans la barre de notification Android
- ✅ Cliquer sur la notification lance l'app

---

## 🧪 Test 4: Tester les Notifications Backend

### Configuration Backend Requise

#### 1. Télécharger le Service Account Key
1. **Firebase Console** → **Project Settings** (⚙️)
2. **Service accounts** → **Generate new private key**
3. **Télécharger** le fichier JSON
4. **Renommer** en `firebase-credentials.json`
5. **Placer** dans `buyv_backend/` (au même niveau que `app/`)

#### 2. Installer la dépendance Firebase Admin
```bash
cd "c:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv\buyv_backend"
pip install firebase-admin
```

#### 3. Tester l'envoi depuis Python
```python
# Test direct depuis Python (terminal)
cd "c:\Users\user\Desktop\Ecommercemasternewfull 2\Buyv\buyv_backend"
python

# Dans l'interpréteur Python:
from app.firebase_service import FirebaseService

# Initialiser
firebase = FirebaseService()
firebase.initialize()

# Remplacer avec votre FCM token de Test 2
token = "VOTRE_TOKEN_FCM_ICI"

# Envoyer une notification
result = firebase.send_notification(
    token=token,
    title="Test Backend BuyV",
    body="Notification envoyée depuis le backend Python",
    data={"type": "test"}
)

print(result)  # Devrait retourner True
```

---

## 🧪 Test 5: Tester les Notifications dans l'Application

### Scénarios à Tester

#### A. Notification lors d'un nouveau like
1. **Utilisateur A**: Se connecte sur un appareil/émulateur
2. **Utilisateur B**: Se connecte sur un autre appareil/émulateur
3. **Utilisateur B**: Like un post de l'Utilisateur A
4. **Résultat**: Utilisateur A reçoit une notification

#### B. Notification lors d'un nouveau commentaire
1. **Utilisateur A**: Crée un post
2. **Utilisateur B**: Commente le post
3. **Résultat**: Utilisateur A reçoit une notification

#### C. Notification lors d'un nouveau follow
1. **Utilisateur A**: Se connecte
2. **Utilisateur B**: Follow l'Utilisateur A
3. **Résultat**: Utilisateur A reçoit une notification

#### D. Notification lors d'une nouvelle commande (pour les vendeurs)
1. **Vendeur**: Crée un produit avec commission
2. **Acheteur**: Achète le produit
3. **Résultat**: Vendeur reçoit une notification

---

## 🧪 Test 6: Enregistrement du Token FCM

### Test manuel via API

#### Avec cURL:
```bash
# Remplacer JWT_TOKEN par votre vrai token JWT
# Remplacer FCM_TOKEN par votre token FCM de Test 2

curl -X POST http://localhost:8000/api/v1/users/me/fcm-token \
  -H "Authorization: Bearer JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"fcm_token": "FCM_TOKEN"}'
```

#### Résultat attendu:
```json
{
  "message": "FCM token updated successfully"
}
```

### Vérifier dans la base de données:
```sql
-- Connectez-vous à votre PostgreSQL
SELECT id, username, fcm_token 
FROM users 
WHERE fcm_token IS NOT NULL;
```

---

## 📋 Checklist de Dépannage

### Si Firebase n'initialise pas:
- [ ] Vérifiez que `google-services.json` est dans `android/app/`
- [ ] Vérifiez que le package name est `com.buyv.flutter_app` dans:
  - `android/app/build.gradle.kts` (ligne: `namespace = "com.buyv.flutter_app"`)
  - `google-services.json` (ligne: `"package_name": "com.buyv.flutter_app"`)
- [ ] Nettoyez et reconstruisez: `flutter clean && flutter pub get`

### Si les notifications n'arrivent pas:
- [ ] Vérifiez que le token FCM est bien généré (logs)
- [ ] Vérifiez que le token est enregistré dans la base de données
- [ ] Vérifiez les permissions Android 13+ (POST_NOTIFICATIONS)
- [ ] Testez d'abord avec Firebase Console (Test 3)
- [ ] Vérifiez les logs backend pour les erreurs Firebase

### Si les notifications ne s'affichent pas en foreground:
- [ ] Vérifiez que `FirebaseNotificationService` est initialisé
- [ ] Vérifiez les logs: `Received notification in foreground`
- [ ] Vérifiez que le channel existe: `high_importance_channel`

### Si les notifications background/terminated ne marchent pas:
- [ ] Vérifiez `AndroidManifest.xml` → service `FlutterFirebaseMessagingBackgroundService`
- [ ] Vérifiez les metadata dans `AndroidManifest.xml`
- [ ] Redémarrez complètement l'application
- [ ] Vérifiez les logs système Android: `adb logcat | grep Firebase`

---

## 🎯 Prochaines Étapes

### 1. Configuration iOS (Optionnel mais recommandé)
- Ajouter l'app iOS dans Firebase Console
- Télécharger `GoogleService-Info.plist`
- Configurer les capabilities dans Xcode
- Tester sur iOS

### 2. Intégration Admin Panel
- Créer endpoint pour envoyer notifications broadcast
- Interface pour envoyer notifications à des groupes d'utilisateurs
- Historique des notifications envoyées

### 3. Personnalisation des Notifications
- Ajouter des images dans les notifications
- Ajouter des actions (boutons) dans les notifications
- Sons personnalisés pour différents types de notifications

### 4. Analytics et Monitoring
- Suivre le taux de delivery des notifications
- Suivre le taux de clics
- A/B testing de messages

---

## 📚 Ressources

- [Firebase Console](https://console.firebase.google.com)
- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Android Notification Best Practices](https://developer.android.com/develop/ui/views/notifications)

---

## ✅ Configuration Complétée par l'Assistant

```
✅ android/build.gradle.kts - Plugin Google Services ajouté
✅ android/app/build.gradle.kts - Dépendances Firebase ajoutées
✅ android/app/src/main/AndroidManifest.xml - Permissions et service FCM
✅ android/app/src/main/res/drawable/ic_notification.xml - Icône créée
✅ pubspec.yaml - firebase_core et firebase_messaging ajoutés
✅ lib/firebase_options.dart - Credentials configurés
✅ lib/main.dart - Firebase initialisé
✅ lib/services/firebase_notification_service.dart - Service créé
✅ buyv_backend/app/firebase_service.py - Service backend créé
✅ buyv_backend/app/users.py - Endpoint FCM token créé
✅ buyv_backend/app/notifications.py - Intégration Firebase ajoutée
```

**🎉 Votre application est maintenant prête pour les notifications push Firebase !**
