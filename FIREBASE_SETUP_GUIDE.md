# 🔥 Guide de Configuration Firebase pour Push Notifications

Ce guide vous explique comment configurer Firebase Cloud Messaging (FCM) pour recevoir des notifications push dans votre application Buyv, même quand l'application est fermée.

## 📋 Table des Matières

1. [Prérequis](#prérequis)
2. [Configuration Firebase Console](#configuration-firebase-console)
3. [Configuration Android](#configuration-android)
4. [Configuration iOS](#configuration-ios)
5. [Configuration Backend (Python)](#configuration-backend)
6. [Test des Notifications](#test-des-notifications)
7. [Troubleshooting](#troubleshooting)

---

## 1️⃣ Prérequis

- Un compte Google (pour Firebase Console)
- Accès au code source de l'application
- Pour iOS: un compte Apple Developer (99$/an)
- Pour Android: rien de spécial requis

---

## 2️⃣ Configuration Firebase Console

### Étape 1: Créer un Projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur "Add project" (Ajouter un projet)
3. Entrez le nom du projet: `Buyv` (ou votre choix)
4. Désactivez Google Analytics (optionnel pour ce projet)
5. Cliquez sur "Create project"

### Étape 2: Activer Cloud Messaging

1. Dans votre projet Firebase, allez dans **Build** → **Cloud Messaging**
2. Cliquez sur **Get Started** si nécessaire
3. L'API Firebase Cloud Messaging sera activée automatiquement

### Étape 3: Obtenir les Credentials

#### Pour Android:
1. Dans Firebase Console, allez dans **Project Settings** (⚙️ en haut à gauche)
2. Téléchargez le fichier `google-services.json`
3. Notez votre **Server Key** (dans Cloud Messaging > Project credentials)

#### Pour iOS:
1. Dans Firebase Console, allez dans **Project Settings**
2. Onglet **Cloud Messaging**
3. Uploadez votre certificat APNs (Apple Push Notification service)
4. Téléchargez le fichier `GoogleService-Info.plist`

### Étape 4: Obtenir la Server Key et Private Key

1. Dans Firebase Console → **Project Settings** → **Service accounts**
2. Cliquez sur **Generate new private key**
3. Téléchargez le fichier JSON (ex: `buyv-firebase-adminsdk.json`)
4. **IMPORTANT**: Gardez ce fichier secret, ne le commitez jamais dans Git!

---

## 3️⃣ Configuration Android

### Étape 1: Ajouter google-services.json

```bash
# Placez le fichier dans:
buyv_flutter_app/android/app/google-services.json
```

### Étape 2: Modifier build.gradle (Project level)

Fichier: `buyv_flutter_app/android/build.gradle`

```gradle
buildscript {
    dependencies {
        // Ajoutez cette ligne
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### Étape 3: Modifier build.gradle (App level)

Fichier: `buyv_flutter_app/android/app/build.gradle`

```gradle
// En haut du fichier, après les autres plugins
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        // ... votre config existante ...
        multiDexEnabled true
    }
}

dependencies {
    // ... vos dépendances existantes ...
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

### Étape 4: Modifier AndroidManifest.xml

Fichier: `buyv_flutter_app/android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <application>
        <!-- Ajoutez ces lignes DANS la balise <application> -->
        
        <!-- Service pour les notifications en arrière-plan -->
        <service
            android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundService"
            android:permission="android.permission.BIND_JOB_SERVICE"
            android:exported="false" />
        
        <!-- Metadata Firebase -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
            
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
    </application>
    
    <!-- Permissions requises -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
</manifest>
```

### Étape 5: Ajouter une icône de notification

Créez un fichier `ic_notification.xml` dans:
`buyv_flutter_app/android/app/src/main/res/drawable/ic_notification.xml`

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="#FFFFFF">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.89,2 2,2zM18,16v-5c0,-3.07 -1.64,-5.64 -4.5,-6.32V4c0,-0.83 -0.67,-1.5 -1.5,-1.5s-1.5,0.67 -1.5,1.5v0.68C7.63,5.36 6,7.92 6,11v5l-2,2v1h16v-1l-2,-2z"/>
</vector>
```

---

## 4️⃣ Configuration iOS

### Étape 1: Ajouter GoogleService-Info.plist

```bash
# Placez le fichier dans:
buyv_flutter_app/ios/Runner/GoogleService-Info.plist
```

### Étape 2: Activer Push Notifications dans Xcode

1. Ouvrez `buyv_flutter_app/ios/Runner.xcworkspace` dans Xcode
2. Sélectionnez le projet **Runner** dans le navigateur
3. Allez dans **Signing & Capabilities**
4. Cliquez sur **+ Capability**
5. Ajoutez **Push Notifications**
6. Ajoutez **Background Modes** et cochez:
   - ✅ Remote notifications
   - ✅ Background fetch

### Étape 3: Générer un certificat APNs

1. Allez sur [Apple Developer Portal](https://developer.apple.com/)
2. **Certificates, Identifiers & Profiles** → **Keys**
3. Créez une nouvelle Key:
   - Name: `Buyv Push Notifications`
   - Cochez **Apple Push Notifications service (APNs)**
4. Téléchargez la clé `.p8`
5. Notez le **Key ID** et **Team ID**

### Étape 4: Configurer APNs dans Firebase

1. Retournez dans Firebase Console
2. **Project Settings** → **Cloud Messaging** → **iOS app configuration**
3. Uploadez votre clé `.p8`
4. Entrez votre **Key ID** et **Team ID**

### Étape 5: Modifier Info.plist

Fichier: `buyv_flutter_app/ios/Runner/Info.plist`

```xml
<dict>
    <!-- Ajoutez cette ligne -->
    <key>FirebaseAppDelegateProxyEnabled</key>
    <false/>
</dict>
```

---

## 5️⃣ Configuration Backend (Python/FastAPI)

### Étape 1: Installer Firebase Admin SDK

```bash
cd buyv_backend
pip install firebase-admin
pip freeze > requirements.txt
```

### Étape 2: Ajouter le fichier de credentials

```bash
# Placez votre fichier JSON Firebase dans:
buyv_backend/firebase-credentials.json

# IMPORTANT: Ajoutez au .gitignore
echo "firebase-credentials.json" >> .gitignore
```

### Étape 3: Créer le service Firebase

Créez `buyv_backend/app/firebase_service.py`:

```python
import firebase_admin
from firebase_admin import credentials, messaging
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)

class FirebaseService:
    _initialized = False
    
    @classmethod
    def initialize(cls):
        """Initialize Firebase Admin SDK"""
        if not cls._initialized:
            try:
                cred = credentials.Certificate("firebase-credentials.json")
                firebase_admin.initialize_app(cred)
                cls._initialized = True
                logger.info("Firebase Admin SDK initialized successfully")
            except Exception as e:
                logger.error(f"Failed to initialize Firebase: {e}")
                raise
    
    @classmethod
    def send_notification(
        cls,
        token: str,
        title: str,
        body: str,
        data: Optional[dict] = None
    ) -> bool:
        """
        Send a push notification to a single device
        
        Args:
            token: FCM device token
            title: Notification title
            body: Notification body
            data: Optional custom data payload
            
        Returns:
            bool: True if sent successfully
        """
        if not cls._initialized:
            cls.initialize()
        
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                token=token,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='high_importance_channel',
                        sound='default',
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                        ),
                    ),
                ),
            )
            
            response = messaging.send(message)
            logger.info(f"Successfully sent notification: {response}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send notification: {e}")
            return False
    
    @classmethod
    def send_multicast(
        cls,
        tokens: List[str],
        title: str,
        body: str,
        data: Optional[dict] = None
    ) -> dict:
        """
        Send notification to multiple devices
        
        Returns:
            dict: {'success_count': int, 'failure_count': int, 'responses': list}
        """
        if not cls._initialized:
            cls.initialize()
        
        try:
            message = messaging.MulticastMessage(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=data or {},
                tokens=tokens,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        channel_id='high_importance_channel',
                        sound='default',
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1,
                        ),
                    ),
                ),
            )
            
            response = messaging.send_multicast(message)
            logger.info(
                f"Sent to {response.success_count}/{len(tokens)} devices"
            )
            
            return {
                'success_count': response.success_count,
                'failure_count': response.failure_count,
                'responses': response.responses,
            }
            
        except Exception as e:
            logger.error(f"Failed to send multicast notification: {e}")
            return {
                'success_count': 0,
                'failure_count': len(tokens),
                'responses': [],
            }
```

### Étape 4: Ajouter le token FCM au modèle User

Modifiez `buyv_backend/app/models.py`:

```python
class User(Base):
    __tablename__ = "users"
    # ... champs existants ...
    
    # Nouveau champ pour le token FCM
    fcm_token: Mapped[str | None] = mapped_column(String(512), nullable=True)
```

### Étape 5: Ajouter l'endpoint pour enregistrer le token

Modifiez `buyv_backend/app/users.py`:

```python
from pydantic import BaseModel

class FCMTokenUpdate(BaseModel):
    fcm_token: str

@router.post("/me/fcm-token")
def update_fcm_token(
    payload: FCMTokenUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Update user's FCM token for push notifications"""
    current_user.fcm_token = payload.fcm_token
    db.commit()
    return {"message": "FCM token updated successfully"}
```

### Étape 6: Utiliser le service dans vos notifications

Exemple dans `buyv_backend/app/notifications.py`:

```python
from .firebase_service import FirebaseService

@router.post("/")
def create_notification(
    payload: NotificationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # ... code existant pour créer la notification dans la DB ...
    
    # Envoyer la push notification
    target_user = db.query(models.User).filter(
        models.User.uid == target_uid
    ).first()
    
    if target_user and target_user.fcm_token:
        FirebaseService.send_notification(
            token=target_user.fcm_token,
            title=payload.title,
            body=payload.body,
            data={
                'notification_id': str(notification.id),
                'type': payload.type,
            }
        )
    
    return notification
```

---

## 6️⃣ Configuration Flutter

### Étape 1: Ajouter les dépendances

Modifiez `buyv_flutter_app/pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

Puis exécutez:

```bash
cd buyv_flutter_app
flutter pub get
```

### Étape 2: Créer le service de notifications

Les fichiers sont déjà créés dans le projet:
- `lib/services/firebase_notification_service.dart`
- Modifications dans `lib/main.dart`

### Étape 3: Demander la permission (iOS)

Le code demande automatiquement la permission au démarrage de l'app.

---

## 7️⃣ Test des Notifications

### Test 1: Via Firebase Console (Simple)

1. Allez dans Firebase Console
2. **Engage** → **Cloud Messaging** → **Send your first message**
3. Entrez un titre et un message
4. Cliquez sur **Send test message**
5. Entrez le token FCM de votre appareil
6. Envoyez!

### Test 2: Via votre Backend (Complet)

```bash
# Démarrez votre backend
cd buyv_backend
uvicorn app.main:app --reload

# Testez l'endpoint
curl -X POST http://localhost:8000/notifications/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Notification",
    "body": "Ceci est un test!",
    "type": "test",
    "targetUserId": "USER_UID"
  }'
```

### Test 3: Scénarios Réels

1. **Nouveau follower**: Suivez un utilisateur → il doit recevoir une notification
2. **Nouveau commentaire**: Commentez un post → le créateur doit être notifié
3. **Like sur post**: Likez un post → le créateur doit être notifié
4. **Commande confirmée**: Passez une commande → notification de confirmation

---

## 8️⃣ Troubleshooting

### ❌ Problème: Notifications ne s'affichent pas sur Android

**Solutions:**

1. Vérifiez que `google-services.json` est bien placé
2. Vérifiez les permissions dans AndroidManifest.xml
3. Vérifiez que l'app a la permission POST_NOTIFICATIONS (Android 13+)
4. Redémarrez l'app complètement (pas juste hot reload)

```bash
flutter clean
flutter pub get
flutter run
```

### ❌ Problème: Notifications ne s'affichent pas sur iOS

**Solutions:**

1. Vérifiez que les capabilities sont activées dans Xcode
2. Vérifiez que le certificat APNs est uploadé dans Firebase
3. Testez sur un appareil réel (pas le simulateur)
4. Vérifiez Info.plist

### ❌ Problème: Token FCM est null

**Solutions:**

```dart
// Forcer la récupération du token
final token = await FirebaseMessaging.instance.getToken(
  vapidKey: 'VOTRE_VAPID_KEY' // Pour web seulement
);
print('FCM Token: $token');
```

### ❌ Problème: Notifications ne fonctionnent qu'en foreground

**Solution:**

Vérifiez que le service background est bien configuré dans `main.dart`:

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}
```

### ❌ Problème: Erreur "Firebase already initialized"

**Solution:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
```

---

## 9️⃣ Bonnes Pratiques

### ✅ Sécurité

1. **Ne commitez JAMAIS** les fichiers credentials:
   ```bash
   # .gitignore
   **/google-services.json
   **/GoogleService-Info.plist
   **/firebase-credentials.json
   ```

2. Utilisez des **variables d'environnement** en production:
   ```python
   import os
   cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH', 'firebase-credentials.json')
   ```

### ✅ Performance

1. **Batch notifications**: Utilisez `send_multicast()` pour plusieurs utilisateurs
2. **Rate limiting**: Limitez le nombre de notifications par utilisateur/jour
3. **Nettoyage des tokens**: Supprimez les tokens expirés

### ✅ UX

1. **Groupez les notifications** similaires
2. **Utilisez des actions**: Permettez de répondre directement
3. **Sons personnalisés**: Pour différencier les types
4. **Badge count**: Affichez le nombre de notifications non lues

---

## 🔟 Variables d'Environnement (Production)

Pour Railway ou autre hébergement:

```env
# Railway Environment Variables
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
FIREBASE_PROJECT_ID=your-project-id
```

Uploadez votre `firebase-credentials.json` directement dans Railway:

1. Railway Dashboard → Project → Settings
2. Variables → Add File Variable
3. Nom: `firebase-credentials.json`
4. Contenu: Collez le contenu du fichier JSON

---

## 📚 Ressources Utiles

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview/)
- [Firebase Admin Python SDK](https://firebase.google.com/docs/admin/setup)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)

---

## ✅ Checklist de Configuration

### Backend:
- [ ] Firebase Admin SDK installé
- [ ] firebase-credentials.json ajouté
- [ ] firebase-credentials.json dans .gitignore
- [ ] FirebaseService créé
- [ ] Champ fcm_token ajouté au modèle User
- [ ] Endpoint /users/me/fcm-token créé
- [ ] Notifications envoyées lors des événements

### Android:
- [ ] google-services.json ajouté
- [ ] build.gradle (project) modifié
- [ ] build.gradle (app) modifié
- [ ] AndroidManifest.xml modifié
- [ ] Icône de notification créée
- [ ] Permissions ajoutées

### iOS:
- [ ] GoogleService-Info.plist ajouté
- [ ] Push Notifications capability activée
- [ ] Background Modes activé
- [ ] Certificat APNs généré
- [ ] Certificat uploadé dans Firebase
- [ ] Info.plist modifié

### Flutter:
- [ ] Dependencies ajoutées
- [ ] firebase_notification_service.dart créé
- [ ] main.dart modifié
- [ ] Token FCM envoyé au backend
- [ ] Handlers de notifications configurés

---

**🎉 Félicitations!** Votre application est maintenant prête à envoyer et recevoir des push notifications, même quand elle est fermée!

Pour toute question, référez-vous à la documentation officielle ou aux logs de debug.
