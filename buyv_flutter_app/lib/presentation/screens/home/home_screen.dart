import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../reels/reels_screen.dart';
import '../shop/shop_screen_new.dart';
import '../cart/cart_screen_new.dart';
import '../profile/profile_screen_kotlin.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/user_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/buy_bottom_sheet.dart';
import '../../widgets/require_login_prompt.dart';
import '../../../domain/models/reel_model.dart';

/// HomeScreen - Shell principal de l'application
/// 
/// Structure basée sur AppBottomBar.kt de Kotlin :
/// - Scaffold comme container principal
/// - IndexedStack pour maintenir l'état des 4 onglets
/// - Bottom Navigation Bar personnalisée avec coins arrondis
/// - FloatingActionButton "Buy" centré avec effet halo
class HomeScreen extends StatefulWidget {
  final int initialTab;
  
  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  int _previousIndex = 0;
  DateTime? _lastPressedAt;

  /// GlobalKey pour accéder au ReelsScreen et contrôler les vidéos
  final GlobalKey<ReelsScreenState> _reelsKey = GlobalKey<ReelsScreenState>();

  /// Les 4 onglets de l'application (comme Kotlin)
  /// IndexedStack maintient l'état de chaque page
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _screens = [
      ReelsScreen(key: _reelsKey),    // Tab 0: Reels (icône maison)
      const ShopScreen(),              // Tab 1: Products (icône grille) - Nouveau style Kotlin
      const CartScreenNew(),           // Tab 2: Cart (icône panier) - Nouveau style Kotlin
      const ProfileScreenKotlin(),     // Tab 3: Profile (icône personne) - Nouveau style Kotlin
    ];
  }

  /// Change d'onglet et gère la pause/reprise des vidéos
  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    
    _previousIndex = _currentIndex;
    
    // ✅ IMPORTANT: Pause les vidéos AVANT de changer d'onglet
    if (_previousIndex == 0 && index != 0) {
      debugPrint('🏠 HomeScreen: Leaving Reels tab → Pausing videos');
      _reelsKey.currentState?.pauseAllVideos();
    }
    
    setState(() => _currentIndex = index);
    
    // ✅ Resume les vidéos APRÈS avoir changé vers l'onglet Reels
    if (index == 0 && _previousIndex != 0) {
      debugPrint('🏠 HomeScreen: Entering Reels tab → Resuming videos');
      // Petit délai pour laisser le setState se propager
      Future.delayed(const Duration(milliseconds: 100), () {
        _reelsKey.currentState?.resumeCurrentVideo();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex != 0,
      onPopInvokedWithResult: _handleBackPress,
      child: Scaffold(
        // Fond transparent pour laisser le contenu gérer son propre fond
        backgroundColor: AppTheme.backgroundColor,
        // Corps avec IndexedStack pour préserver l'état
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        // FloatingActionButton "Buy" au centre avec halo blanc - TOUJOURS ORANGE
        floatingActionButton: _currentIndex == 0 ? _buildBuyFab() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        // Bottom Navigation Bar personnalisée style Kotlin
        bottomNavigationBar: AppBottomBar(
          selectedIndex: _currentIndex,
          onTabSelected: _onTabChanged,
        ),
      ),
    );
  }

  /// Buy FAB - TOUJOURS ORANGE avec effet halo blanc
  /// Le bouton est toujours visible et cliquable, même sans produit 
  /// Design:
  /// - Container circulaire 72x72
  /// - Bordure blanche épaisse (4-6dp) pour effet halo
  /// - BoxShadow avec blurRadius élevé pour l'effet lumineux
  /// - Dégradé orange/rouge TOUJOURS (jamais gris)
  Widget _buildBuyFab() {
    return GestureDetector(
      onTap: _onBuyFabPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // ✅ TOUJOURS le dégradé orange - jamais gris
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF9800), // Orange
              Color(0xFFFF5722), // Deep Orange
            ],
          ),
          // Bordure blanche épaisse pour effet halo
          border: Border.all(
            color: Colors.white,
            width: 5,
          ),
          // BoxShadow pour effet de halo lumineux sur fond sombre
          boxShadow: [
            // Shadow principale pour élévation
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            // Glow blanc pour effet halo
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Buy',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gère le tap sur le Buy FAB
  void _onBuyFabPressed() {
    final currentReel = _reelsKey.currentState?.getCurrentReel();
    
    // Si pas de reel ou pas de produit, afficher un message
    if (currentReel == null || !currentReel.hasProduct || currentReel.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product available for this reel')),
      );
      return;
    }
    
    _onBuyPressed(currentReel);
  }

  /// Ouvre le BuyBottomSheet quand on appuie sur Buy
  void _onBuyPressed(ReelModel reel) {
    if (!reel.hasProduct || reel.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No product linked to this reel')),
      );
      return;
    }

    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    if (!isAuthenticated) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: RequireLoginPrompt(
              onLogin: () {
                Navigator.pop(ctx);
                context.go('/login');
              },
              onSignUp: () {
                Navigator.pop(ctx);
                context.go('/signup');
              },
              onDismiss: () {
                Navigator.pop(ctx);
              },
              showCloseButton: true,
            ),
          );
        },
      );
      return;
    }

    final product = reel.product!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return BuyBottomSheet(
          product: product,
          promoterId: reel.userId,
          onAddToCart: (qty, promoterId) {
            Navigator.pop(ctx);
            context.read<CartProvider>().addToCart(
              product,
              quantity: qty,
              promoterId: promoterId,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product added to cart')),
            );
          },
          onBuyNow: (qty, promoterId) {
            Navigator.pop(ctx);
            context.read<CartProvider>().addToCart(
              product,
              quantity: qty,
              promoterId: promoterId,
            );
            context.go('/cart');
          },
        );
      },
    );
  }

  /// Gestion du bouton retour (double tap pour quitter sur Reels)
  void _handleBackPress(bool didPop, dynamic result) {
    if (didPop || _currentIndex != 0) return;

    final now = DateTime.now();
    final shouldExit = _lastPressedAt != null &&
        now.difference(_lastPressedAt!) <= const Duration(seconds: 2);

    if (shouldExit) {
      SystemNavigator.pop();
    } else {
      _lastPressedAt = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appuyez à nouveau pour quitter'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// AppBottomBar - Barre de navigation inférieure
/// 
/// Design Kotlin transposé :
/// - Container avec coins arrondis (topLeft: 28, topRight: 28)
/// - BoxShadow subtile
/// - 4 items : Reels, Products, Cart, Profile
/// - Badge rouge sur Profile pour notifications
/// - Couleur active: #176DBA (bleu), inactive: noir 85%
class AppBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  // Couleurs du thème Kotlin
  static const Color _activeColor = Color(0xFF176DBA);    // Bleu
  static const Color _inactiveColor = Color(0xD8000000);  // Noir 85%
  static const Color _badgeColor = Color(0xFFE53935);     // Rouge badge

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        // Coins arrondis uniquement en haut (28dp comme Kotlin)
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        // Ombre subtile vers le haut
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tab 0: Reels
            _NavBarItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Reels',
              isSelected: selectedIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            // Tab 1: Products
            _NavBarItem(
              index: 1,
              icon: Icons.grid_view_rounded,
              label: 'Products',
              isSelected: selectedIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            // Tab 2: Cart (avec badge si items)
            Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                return _NavBarItem(
                  index: 2,
                  icon: Icons.shopping_cart_rounded,
                  label: 'Cart',
                  isSelected: selectedIndex == 2,
                  onTap: () => onTabSelected(2),
                  showBadge: cartProvider.items.isNotEmpty,
                );
              },
            ),
            // Tab 3: Profile (avec badge notifications)
            Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                // Badge affiché si l'utilisateur est connecté (pour notifications)
                final showBadge = userProvider.isLoggedIn;
                return _NavBarItem(
                  index: 3,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: selectedIndex == 3,
                  onTap: () => onTabSelected(3),
                  showBadge: showBadge,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Item individuel de la navigation bar
class _NavBarItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showBadge;

  const _NavBarItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected 
        ? AppBottomBar._activeColor 
        : AppBottomBar._inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône avec badge optionnel
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: color,
                  ),
                  // Badge point rouge (position top-right de l'icône)
                  if (showBadge)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppBottomBar._badgeColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: color,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
