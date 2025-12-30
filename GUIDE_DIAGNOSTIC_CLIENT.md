# 📋 Guide Diagnostic Client - Page Profile

## 🐛 Problèmes Corrigés

### 1. ✅ Nombre de posts enregistrés invisible
**Symptôme:** Le compteur de posts sauvegardés ne s'affichait pas sous l'icône bookmark.

**Cause:** Le champ `savedPosts` n'était pas renvoyé par le backend dans `/users/{uid}/stats`.

**Solution:**
- ✅ Backend: Ajout de `saved_posts_count` dans `UserStats` schema (schemas.py)
- ✅ Backend: Query `PostBookmark` dans endpoint `get_user_stats` (users.py)
- ✅ Frontend: Lecture de `savedPosts` dans `getUserStatistics` (user_service.dart)
- ✅ Frontend: Affichage du compteur dans l'icône bookmark (profile_screen.dart)

**Résultat:** Le nombre de posts sauvegardés s'affiche maintenant correctement.

---

### 2. ✅ Vidéo depuis Profile cause crash/erreurs
**Symptôme:** Cliquer sur une vidéo depuis le profile causait:
- `setState() or markNeedsBuild() called during build`
- `Duplicate GlobalKeys detected in widget tree`
- Navigation vers page noire

**Cause:**
- Navigation immédiate pendant le build cause setState() pendant build
- Pas de GlobalKey unique pour chaque item de grid
- Conflits de keys entre différents tabs

**Solution:**
```dart
// ✅ FIX 1: Unique keys par item
final itemKey = ValueKey('profile_${_selectedTabIndex}_${item.id}');

// ✅ FIX 2: Navigation APRÈS le frame
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted && (item.type == 'reel' || item.type == 'video')) {
    context.push('/reels', extra: {'startPostId': item.id});
  }
});
```

**Résultat:** Navigation fluide sans erreur, vidéo démarre correctement.

---

### 3. ✅ RenderFlex Overflow dans Shop
**Symptôme:** 
```
A RenderFlex overflowed by 16-17 pixels on the bottom
Widget: cj_products_grid.dart:114
```

**Cause:** Column avec hauteur fixe trop petite pour le contenu (nom produit + prix).

**Solution:**
```dart
// ✅ FIX 1: mainAxisSize: MainAxisSize.min
Column(
  mainAxisSize: MainAxisSize.min, // Ne force pas max height
  children: [
    // ✅ FIX 2: Flexible au lieu de Text direct
    Flexible(
      child: Text(...),
    ),
    const SizedBox(height: 2), // Réduit de 4 à 2
  ],
)
```

**Résultat:** Plus d'overflow, layout propre.

---

## 📱 Système de Logging Corrélé

### Format du Log
```
[HH:MM:SS.mmm] Type: Message | ID:actionId
```

### Types de Logs
- 👤 CLIENT: Action utilisateur (tap, swipe, etc.)
- 📱 FLUTTER: Événement app (navigation, setState, etc.)
- 🔧 BACKEND: Appel API (GET, POST, etc.)
- ✅ BACKEND RESPONSE: Réponse API (statusCode, data)

### Exemple de Trace Complète
```
[14:23:45.123] ℹ️ 👤 CLIENT: Tap video from profile | ID:a7f3c2d1 type:reel
[14:23:45.125] 🐛 📱 FLUTTER: Navigate to /reels | ID:a7f3c2d1 startPostId:xyz
[14:23:45.234] 🐛 🔧 BACKEND: GET /posts/xyz | ID:a7f3c2d1
[14:23:45.456] ℹ️ ✅ BACKEND RESPONSE: /posts/xyz | ID:a7f3c2d1 statusCode:200
[14:23:45.500] 🐛 📱 FLUTTER: Video initialized | ID:a7f3c2d1 duration:30s
```

### Comment Accéder aux Logs
1. Ouvrir l'app
2. Aller dans **Profil** → **Paramètres** (⚙️)
3. Cliquer sur **Diagnostic Logs**
4. Actions disponibles:
   - 📋 **Copy**: Copier tous les logs
   - 📤 **Share**: Partager via WhatsApp/Email
   - 🗑️ **Clear**: Effacer les logs

---

## 🔍 Diagnostic Page Profile

### Architecture
```
ProfileScreen
├── CustomScrollView
│   ├── SliverAppBar (username + boutons)
│   ├── SliverToBoxAdapter (stats + tabs)
│   ├── SliverToBoxAdapter (loading indicator)
│   └── SliverGrid (_buildTabContentSliver)
│       ├── Tab 0: Reels (_userReels)
│       ├── Tab 1: Products (_userProducts)
│       ├── Tab 2: Saved (_userSavedPosts)
│       └── Tab 3: Liked (_userLikedPosts)
```

### Flow de Chargement
```
1. initState()
   ↓
2. _loadProfileData()
   ├─ getUserStatistics() → Backend: GET /users/{uid}/stats
   │  ├─ followersCount
   │  ├─ followingCount
   │  ├─ reelsCount
   │  ├─ productsCount
   │  └─ savedPostsCount ✅ NOUVEAU
   ↓
3. _loadTabContent()
   ├─ Tab 0: getUserReels() → GET /posts/user/{uid}/reels
   ├─ Tab 1: getUserProducts() → GET /posts/user/{uid}/products
   ├─ Tab 2: getUserBookmarkedPosts() → GET /bookmarks/user/{uid}
   └─ Tab 3: getUserLikedPosts() → GET /likes/user/{uid}
```

### Points de Log Importants
```dart
// 1. Chargement initial du profile
final actionId = RemoteLogger.logUserAction('Load profile data');

// 2. Requête backend stats
RemoteLogger.logBackendCall('/users/$userId/stats', actionId: actionId);

// 3. Réponse backend
RemoteLogger.logBackendResponse('/users/$userId/stats', 
  statusCode: 200, 
  data: {'savedPosts': 5}
);

// 4. Switch de tab
RemoteLogger.logUserAction('Switch to tab 2', context: {'tabName': 'Saved'});

// 5. Navigation vers vidéo
RemoteLogger.logUserAction('Tap video from profile', 
  context: {'postId': 'xyz', 'type': 'reel'}
);
```

---

## 🧪 Tests à Effectuer

### Test 1: Compteur Saved Posts
1. ✅ Enregistrer 3 posts (bookmark)
2. ✅ Aller dans Profile → Tab "Saved" (icône bookmark)
3. ✅ Vérifier que le chiffre "3" apparaît sous l'icône
4. ✅ Retirer 1 bookmark
5. ✅ Pull-to-refresh le profile
6. ✅ Vérifier que le chiffre passe à "2"

### Test 2: Navigation depuis Profile
1. ✅ Ouvrir Profile
2. ✅ Aller dans tab "Reels"
3. ✅ Taper sur une vidéo
4. ✅ Vérifier: Video démarre immédiatement
5. ✅ Vérifier: Pas d'erreur dans logs
6. ✅ Vérifier: Pas de page noire

### Test 3: Logs Corrélés
1. ✅ Settings → Diagnostic Logs → Clear
2. ✅ Retour Profile → Tap vidéo → Regarder 10s
3. ✅ Retour Profile → Settings → Diagnostic Logs
4. ✅ Vérifier présence de:
   - `👤 CLIENT: Tap video from profile`
   - `📱 FLUTTER: Navigate to /reels`
   - `🔧 BACKEND: GET /posts/...`
   - `✅ BACKEND RESPONSE: /posts/...`

### Test 4: Performance Scroll
1. ✅ Profile avec 50+ posts
2. ✅ Scroller de haut en bas rapidement
3. ✅ Vérifier: Pas de lag
4. ✅ Vérifier: Pas d'overflow errors
5. ✅ Vérifier: Images chargent progressivement

---

## 📞 Que Faire en Cas de Problème

### Si lag persiste:
1. Settings → Diagnostic Logs
2. Clear logs
3. Reproduire le problème
4. Share logs → Envoyer au développeur

### Si vidéo ne démarre pas:
1. Vérifier connexion internet
2. Vérifier logs pour erreur backend
3. Chercher: `❌` dans logs (erreurs)

### Si compteur incorrect:
1. Pull-to-refresh le profile
2. Vérifier logs: `BACKEND RESPONSE: /users/.../stats`
3. Chercher `savedPosts` dans data

---

## 🚀 Améliorations Apportées

### Performance
- ✅ Polling commissions: 30s → 300s (90% réduction appels API)
- ✅ ProGuard/R8: Code minifié et optimisé
- ✅ Images lazy loading avec errorBuilder
- ✅ SliverGrid au lieu de GridView (meilleure performance scroll)

### Stabilité
- ✅ Unique GlobalKeys pour éviter conflits
- ✅ Navigation addPostFrameCallback pour éviter setState pendant build
- ✅ Try-catch sur tous les appels backend
- ✅ Gestion nullable safety partout

### Debugging
- ✅ Logs corrélés Frontend ↔ Backend avec actionId
- ✅ In-app diagnostic viewer (Settings → Diagnostic Logs)
- ✅ Copy/Share logs pour remote debugging
- ✅ Timestamps milliseconde pour timing précis

---

## 📊 Métriques Attendues

### Temps de Chargement
- Profile stats: < 500ms
- Tab content (20 posts): < 1s
- Navigation vers vidéo: < 300ms

### Mémoire
- Profile avec 100 posts: < 150MB RAM
- Scroll continu: Pas de memory leak

### Logs
- Buffer: 200 derniers logs
- Taille max: ~50KB en texte

---

## ✅ Checklist Validation

- [x] Saved posts counter visible
- [x] Navigation profile → video fonctionne
- [x] Pas de Duplicate GlobalKeys
- [x] Pas de setState during build
- [x] Pas de RenderFlex overflow
- [x] Logs corrélés disponibles in-app
- [x] Logging 👤 CLIENT → 📱 FLUTTER → 🔧 BACKEND
- [x] Copy/Share logs fonctionnel
- [ ] Test client sur Pocco 8GB RAM
- [ ] Validation lag improvement
- [ ] APK release build testé

---

**Version:** 1.0.0  
**Date:** 30 Décembre 2024  
**Status:** ✅ Prêt pour tests client
