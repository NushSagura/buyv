# 🧪 Guide de Test Rapide - Corrections Session & Navigation

## 📋 Corrections Appliquées

✅ **Problème 1:** Page noire au retour arrière → **RÉSOLU**  
✅ **Problème 2:** Reconnexion obligatoire à chaque ouverture → **RÉSOLU**

---

## 🚀 Commandes de Rebuild

```bash
cd buyv_flutter_app
flutter clean
flutter pub get
flutter run
```

---

## 📱 Tests à Effectuer

### Test 1: Navigation avec Bouton Back ⬅️

**Scénario:**
1. ✅ Ouvrir l'app
2. ✅ Se connecter avec email/mot de passe
3. ✅ Aller sur "Products" (bottom nav)
4. ✅ Appuyer sur le bouton "Back" du téléphone
5. ✅ Aller sur "Cart"
6. ✅ Appuyer sur le bouton "Back" du téléphone
7. ✅ Aller sur "Profile"
8. ✅ Appuyer sur le bouton "Back" du téléphone

**Résultat Attendu:**
- ❌ PAS de page noire
- ✅ Navigation fluide
- ✅ L'app affiche un message "Appuyez à nouveau pour quitter"
- ✅ Double-tap sur Back pour quitter l'app

---

### Test 2: Persistance de Session 🔐

**Scénario:**
1. ✅ Ouvrir l'app
2. ✅ Se connecter avec email/mot de passe
3. ✅ Naviguer dans l'app (Feed, Products, etc.)
4. ✅ **Fermer COMPLÈTEMENT l'app** (swipe depuis les apps récentes)
5. ⏳ Attendre 5 secondes
6. ✅ **Rouvrir l'app**

**Résultat Attendu:**
- ✅ Splash screen s'affiche 3 secondes
- ✅ L'utilisateur est toujours connecté
- ✅ Redirection automatique vers le Home Screen
- ❌ PAS de redirection vers login/onboarding

**Dans les logs (adb logcat ou Xcode):**
```
✅ Utilisateur authentifié automatiquement: [Nom Utilisateur]
✅ Utilisateur déjà connecté - redirection vers home
```

---

### Test 3: Navigation Profonde 🔍

**Scénario:**
1. ✅ Ouvrir l'app
2. ✅ Se connecter
3. ✅ Aller sur Feed → Sélectionner un post → Voir les commentaires
4. ✅ Appuyer sur Back
5. ✅ Aller sur Products → Voir un produit
6. ✅ Appuyer sur Back
7. ✅ Aller sur Profile → Modifier le profil
8. ✅ Appuyer sur Back

**Résultat Attendu:**
- ✅ Retour à l'écran précédent à chaque fois
- ❌ PAS de page noire
- ✅ Navigation cohérente

---

### Test 4: Créer un Post ➕

**Scénario:**
1. ✅ Se connecter
2. ✅ Appuyer sur le bouton "+" (FloatingActionButton orange)
3. ✅ L'écran "Add Post" s'ouvre
4. ✅ Appuyer sur Back
5. ✅ Retour au Home Screen

**Résultat Attendu:**
- ✅ Navigation fluide
- ❌ PAS de page noire

---

### Test 5: Session Expirée ⏰

**Scénario:**
1. ✅ Se connecter
2. ⏳ Attendre **1 heure** (ou plus selon config backend)
3. ✅ Réouvrir l'app

**Résultat Attendu:**
- ✅ Token expiré détecté
- ✅ Redirection vers le login
- ❌ PAS de crash

---

### Test 6: Première Installation 🆕

**Scénario:**
1. ✅ Désinstaller l'app complètement
2. ✅ Réinstaller l'app
3. ✅ Ouvrir l'app

**Résultat Attendu:**
- ✅ Splash screen → Onboarding → Login
- ✅ Pas de token stocké détecté
- ✅ Navigation fluide

**Dans les logs:**
```
⚠️ Pas de token valide - redirection vers onboarding
```

---

## 🐛 Si Problèmes Persistent

### Vérification des Logs

**Android (via Terminal):**
```bash
adb logcat | grep -E "✅|❌|⚠️"
```

**iOS (via Xcode):**
- Ouvrir Xcode
- Window → Devices and Simulators
- Sélectionner l'appareil
- Voir les logs en temps réel

### Rechercher dans les Logs:
- `✅ Utilisateur authentifié automatiquement` → Session restaurée
- `⚠️ Pas de token valide` → Pas de session
- `❌ Erreur` → Problème technique

---

## 📊 Checklist Validation

| Test | Status | Notes |
|------|--------|-------|
| Navigation Back | ⬜ | Pas de page noire |
| Session persistante | ⬜ | Reste connecté après fermeture |
| Double-tap pour quitter | ⬜ | Message affiché |
| Navigation profonde | ⬜ | Tous les retours OK |
| Bouton + (Add Post) | ⬜ | Navigation fluide |
| Première installation | ⬜ | Onboarding affiché |

---

## 🔧 Dépannage

### Problème: Page noire persiste
```bash
# Rebuild complet
cd buyv_flutter_app
flutter clean
rm -rf build/
flutter pub get
flutter run --release
```

### Problème: Session pas restaurée
1. Vérifier que l'utilisateur s'est bien connecté (pas en mode démo)
2. Vérifier les permissions de stockage (Android)
3. Vérifier keychain access (iOS)

### Problème: Crash au démarrage
```bash
# Vérifier les dépendances
flutter doctor -v
flutter pub get
```

---

## ✅ Validation Finale

Une fois tous les tests passés:
1. ✅ Navigation fluide partout
2. ✅ Session persistante fonctionne
3. ✅ Pas de page noire
4. ✅ Double-tap pour quitter l'app

**L'app est prête pour utilisation! 🎉**

---

## 📞 Support

Si un problème persiste:
1. Exécuter: `flutter doctor -v`
2. Capturer les logs
3. Fournir les étapes de reproduction
4. Indiquer le modèle de téléphone et version OS
