import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/profile/edit_profile_screen.dart';
import 'presentation/screens/shop/shop_screen.dart';
import 'presentation/screens/payment/payment_screen.dart';
import 'data/repositories/auth_repository_fastapi.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'data/providers/product_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/cart/cart_screen.dart';
import 'presentation/screens/reels/reels_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/profile/add_post_screen.dart';
import 'presentation/screens/products/product_detail_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/reels/search_reels_screen.dart';
import 'presentation/screens/search/search_screen.dart';
import 'presentation/screens/orders/orders_track_screen.dart';
import 'presentation/screens/orders/orders_history_screen.dart';
import 'presentation/screens/products/recently_viewed_screen.dart';
import 'presentation/screens/payment/payment_methods_screen.dart';
import 'presentation/screens/settings/location_settings_screen.dart';
import 'presentation/screens/settings/language_settings_screen.dart';
import 'presentation/screens/settings/change_password_screen.dart';
import 'presentation/screens/help/help_screen.dart';
import 'services/secure_storage_service.dart';
import 'services/security_audit_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Environment Variables
  await dotenv.load(fileName: ".env");

  // تهيئة Hive للتخزين المحلي
  await Hive.initFlutter();

  // تهيئة الخدمات الأمنية
  try {
    await SecureStorageService.initialize();

    // تشغيل مراجعة أمنية أولية
    final auditReport = await SecurityAuditService.performSecurityAudit();
    if (auditReport.overallScore < 70) {
      debugPrint(
        '⚠️ Security audit warning: Score ${auditReport.overallScore}/100',
      );
      debugPrint('Risk level: ${auditReport.riskLevel}');
    } else {
      debugPrint(
        '✅ Security audit passed: Score ${auditReport.overallScore}/100',
      );
    }
  } catch (e) {
    debugPrint('❌ Security services initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            final authRepo = AuthRepositoryFastApi();
            return AuthProvider(authRepo);
          },
        ),
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
      ],
      child: MaterialApp(
        title: 'BuyV E-commerce',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/register': (context) => const RegisterScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/cart': (context) => const CartScreen(),
          '/shop': (context) => const ShopScreen(),
          '/reels': (context) => const ReelsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit_profile': (context) => const EditProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/add_new_content': (context) => const AddPostScreen(),
          '/product_detail': (context) => const ProductDetailScreen(
            productId: '',
            productName: 'Product',
            productImage: '',
            price: 0.0,
            category: 'General',
          ),
          '/notifications': (context) => const NotificationsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/payment': (context) => const PaymentScreen(),
          '/search_reels': (context) => const SearchReelsScreen(),
          '/search': (context) => const SearchScreen(),
          '/orders-track': (context) => const OrdersTrackScreen(),
          '/orders-history': (context) => const OrdersHistoryScreen(),
          '/recently-viewed': (context) => const RecentlyViewedScreen(),
          '/payment-methods': (context) => const PaymentMethodsScreen(),
          '/location-settings': (context) => const LocationSettingsScreen(),
          '/language-settings': (context) => const LanguageSettingsScreen(),
          '/change-password': (context) => const ChangePasswordScreen(),
          '/help': (context) => const HelpScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
