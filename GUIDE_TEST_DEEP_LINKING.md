# 🔗 GUIDE TEST DEEP LINKING - RAPIDE

## ✅ INSTALLATION TERMINÉE

**Checkpoint**: 27 Dec 2024 - Deep Linking 100% opérationnel

---

## 📱 COMMENT TESTER

### **Option 1: Script Automatique** (RECOMMANDÉ)

1. **Connectez votre téléphone Android via USB**
2. **Lancez l'app BuyV** (elle doit être installée)
3. **Double-cliquez**: `test_deep_links.bat`
4. **Choisissez un test** du menu

```
1. Test Post/Reel (votre reel actuel)
2. Test User Profile (votre profil)
3. Test Product avec params
4. Test Home, Shop, Reels, etc.
```

### **Option 2: Commandes Manuelles**

Ouvrez **PowerShell** et tapez:

**Test Reel**:
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "buyv://post/762136ed-468b-4315-ba58-16b1d41a1bdb" com.buyv.flutter_app
```

**Test Profil**:
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "buyv://user/359b21e7-03d4-41de-984a-b693ef6c03f7" com.buyv.flutter_app
```

**Test Home**:
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "buyv://home" com.buyv.flutter_app
```

**Test Shop**:
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "buyv://shop" com.buyv.flutter_app
```

---

## 🎯 RÉSULTATS ATTENDUS

### Test #1: Post/Reel
- ✅ App s'ouvre (ou revient au premier plan)
- ✅ Navigation automatique vers ReelsScreen
- ✅ Vidéo spécifique se charge et joue

### Test #2: User Profile
- ✅ App s'ouvre
- ✅ Navigation vers UserProfileScreen
- ✅ Profil de l'utilisateur s'affiche

### Test #3: Product
- ✅ App s'ouvre
- ✅ Navigation vers ProductDetailScreen
- ✅ Détails produit avec params (nom, prix, etc.)

### Test #4: Routes simples (home, shop, reels)
- ✅ App s'ouvre
- ✅ Navigation vers l'écran correspondant

---

## 📊 LOGS À VÉRIFIER

Dans **Android Studio Logcat** ou **VS Code Terminal**, cherchez:

```
🔗 Initializing deep link listener...
✅ Deep link listener initialized
🔗 Initial deep link detected: buyv://post/abc123
🔗 Deep Link received: buyv://post/abc123
✅ Navigated to post: abc123
```

---

## ⚠️ TROUBLESHOOTING

### Problème: "Activity not started, unknown URL scheme"
**Solution**: Vérifiez le package name
```powershell
# Vérifier le package installé
adb shell pm list packages | findstr buyv
```
Devrait montrer: `com.buyv.flutter_app`

### Problème: App ne s'ouvre pas
**Solution**: 
1. Vérifier que l'app est installée
2. Redémarrer l'app manuellement une fois
3. Retester le deep link

### Problème: Navigation ne fonctionne pas
**Solution**: Hot restart (`r`) pour recharger le listener

---

## 🎬 WORKFLOW COMPLET

1. ✅ **Build & Install** l'app sur device
2. ✅ **Lancer** l'app une fois manuellement
3. ✅ **Fermer** l'app (retour home Android)
4. ✅ **Exécuter** `test_deep_links.bat`
5. ✅ **Choisir** un test
6. ✅ **Observer**: L'app s'ouvre et navigue automatiquement!

---

## 🔗 EXEMPLES DE DEEP LINKS

**Format général**: `buyv://route/param?query=value`

**Posts/Reels**:
```
buyv://post/762136ed-468b-4315-ba58-16b1d41a1bdb
```

**User Profiles**:
```
buyv://user/359b21e7-03d4-41de-984a-b693ef6c03f7
```

**Products**:
```
buyv://product/12345?name=T-Shirt&price=29.99&category=Fashion
```

**Routes simples**:
```
buyv://home
buyv://shop
buyv://reels
buyv://search
buyv://cart
buyv://profile
buyv://notifications
buyv://orders-history
buyv://settings
```

---

## 💡 UTILISATION RÉELLE

### Partage de Post:
```dart
// Dans votre code Flutter
final deepLink = DeepLinkHandler.createPostDeepLink('post-id-123');
Share.share(deepLink); // Partage: buyv://post/post-id-123
```

### Partage de Profil:
```dart
final deepLink = DeepLinkHandler.createUserDeepLink('user-id-456');
Share.share(deepLink); // Partage: buyv://user/user-id-456
```

### Partage de Produit:
```dart
final deepLink = DeepLinkHandler.createProductDeepLink(
  'prod-789',
  name: 'iPhone 15',
  price: 999.99,
  category: 'Electronics',
);
Share.share(deepLink);
```

---

## ✅ CHECKLIST VALIDATION

- [ ] Test #1 (Post/Reel) → App ouvre + navigue vers reel
- [ ] Test #2 (User Profile) → App ouvre + navigue vers profil
- [ ] Test #3 (Product) → App ouvre + affiche détails produit
- [ ] Test #4 (Home) → App ouvre sur l'accueil
- [ ] Test #5 (Shop) → App ouvre sur le shop
- [ ] Test cold start (app fermée)
- [ ] Test warm start (app en arrière-plan)
- [ ] Logs affichent "🔗 Deep link received"
- [ ] Logs affichent "✅ Navigated to..."

---

**Date**: 27 Décembre 2024
**Statut**: ✅ IMPLÉMENTÉ & PRÊT
**Prochaine étape**: Tester sur device réel
