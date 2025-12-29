import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/add_post_screen.dart';
import '../../presentation/screens/shop/shop_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/reels/reels_screen.dart';
import '../../presentation/screens/reels/search_reels_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/comments/comments_screen.dart';
import '../../presentation/screens/products/product_detail_screen.dart';
import '../../presentation/screens/products/recently_viewed_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/settings/location_settings_screen.dart';
import '../../presentation/screens/settings/language_settings_screen.dart';
import '../../presentation/screens/settings/change_password_screen.dart';
import '../../presentation/screens/payment/payment_screen.dart';
import '../../presentation/screens/payment/payment_methods_screen.dart';
import '../../presentation/screens/orders/orders_track_screen.dart';
import '../../presentation/screens/orders/orders_history_screen.dart';
import '../../presentation/screens/help/help_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/providers/auth_provider.dart';
import './route_names.dart';
import './screens/post_detail_screen.dart';
import './screens/user_profile_screen.dart';

/// Main App Router with Deep Linking Support
class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  
  /// Get the router configuration
  static GoRouter getRouter(BuildContext context) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      debugLogDiagnostics: true,
      initialLocation: RouteNames.splash,
      
      // Redirect logic for authentication
      redirect: (BuildContext context, GoRouterState state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading = authProvider.isLoading;
        final isLoggingIn = state.matchedLocation == RouteNames.login ||
            state.matchedLocation == RouteNames.signup ||
            state.matchedLocation == RouteNames.register ||
            state.matchedLocation == RouteNames.onboarding ||
            state.matchedLocation == RouteNames.splash;

        // Allow access to public routes
        if (isLoggingIn) return null;

        // Don't redirect while loading - prevents black screen
        if (isLoading) return null;

        // Redirect to login if not authenticated
        if (!isAuthenticated && !isLoggingIn) {
          return RouteNames.login;
        }

        return null;
      },

      // Error handling
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page not found: ${state.matchedLocation}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),

      routes: [
        // Splash & Onboarding
        GoRoute(
          path: RouteNames.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: RouteNames.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),

        // Authentication
        GoRoute(
          path: RouteNames.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RouteNames.signup,
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: RouteNames.register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Main Navigation
        GoRoute(
          path: RouteNames.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: RouteNames.reels,
          name: 'reels',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final startPostId = extra?['startPostId'] as String?;
            return ReelsScreen(targetReelId: startPostId);
          },
        ),
        GoRoute(
          path: RouteNames.shop,
          name: 'shop',
          builder: (context, state) => const ShopScreen(),
        ),
        GoRoute(
          path: RouteNames.cart,
          name: 'cart',
          builder: (context, state) => const CartScreen(),
        ),

        // Profile
        GoRoute(
          path: RouteNames.profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: RouteNames.editProfile,
          name: 'edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: RouteNames.addPost,
          name: 'add-post',
          builder: (context, state) => const AddPostScreen(),
        ),

        // 🔥 Deep Link: User Profile with UID
        GoRoute(
          path: '${RouteNames.user}/:uid',
          name: 'user-detail',
          builder: (context, state) {
            final uid = state.pathParameters['uid']!;
            return UserProfileScreen(userId: uid);
          },
        ),

        // 🔥 Deep Link: Post Detail with UID
        GoRoute(
          path: '${RouteNames.post}/:uid',
          name: 'post-detail',
          builder: (context, state) {
            final uid = state.pathParameters['uid']!;
            return PostDetailScreen(postId: uid);
          },
        ),

        // 💬 Comments for a Post
        GoRoute(
          path: '/post/:postId/comments',
          name: 'post-comments',
          builder: (context, state) {
            final postId = state.pathParameters['postId']!;
            final postUsername = state.uri.queryParameters['username'];
            return CommentsScreen(
              postId: postId,
              postUsername: postUsername,
            );
          },
        ),

        // 🔥 Deep Link: Product Detail with ID
        GoRoute(
          path: '${RouteNames.product}/:id',
          name: 'product-detail',
          builder: (context, state) {
            final productId = state.pathParameters['id']!;
            // Optional query parameters
            final productName = state.uri.queryParameters['name'] ?? 'Product';
            final productImage = state.uri.queryParameters['image'] ?? '';
            final priceStr = state.uri.queryParameters['price'] ?? '0.0';
            final category = state.uri.queryParameters['category'] ?? 'General';
            final price = double.tryParse(priceStr) ?? 0.0;

            return ProductDetailScreen(
              productId: productId,
              productName: productName,
              productImage: productImage,
              price: price,
              category: category,
            );
          },
        ),

        // Search
        GoRoute(
          path: RouteNames.search,
          name: 'search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: RouteNames.searchReels,
          name: 'search-reels',
          builder: (context, state) => const SearchReelsScreen(),
        ),

        // Orders
        GoRoute(
          path: RouteNames.ordersHistory,
          name: 'orders-history',
          builder: (context, state) => const OrdersHistoryScreen(),
        ),
        GoRoute(
          path: RouteNames.ordersTrack,
          name: 'orders-track',
          builder: (context, state) => const OrdersTrackScreen(),
        ),

        // Payment
        GoRoute(
          path: RouteNames.payment,
          name: 'payment',
          builder: (context, state) => const PaymentScreen(),
        ),
        GoRoute(
          path: RouteNames.paymentMethods,
          name: 'payment-methods',
          builder: (context, state) => const PaymentMethodsScreen(),
        ),

        // Settings
        GoRoute(
          path: RouteNames.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.locationSettings,
          name: 'location-settings',
          builder: (context, state) => const LocationSettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.languageSettings,
          name: 'language-settings',
          builder: (context, state) => const LanguageSettingsScreen(),
        ),
        GoRoute(
          path: RouteNames.changePassword,
          name: 'change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),

        // Notifications
        GoRoute(
          path: RouteNames.notifications,
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),

        // Help & Others
        GoRoute(
          path: RouteNames.help,
          name: 'help',
          builder: (context, state) => const HelpScreen(),
        ),
        GoRoute(
          path: RouteNames.recentlyViewed,
          name: 'recently-viewed',
          builder: (context, state) => const RecentlyViewedScreen(),
        ),
      ],
    );
  }
}
