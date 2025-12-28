import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'data/repositories/auth_repository_fastapi.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'data/providers/product_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'services/secure_storage_service.dart';
import 'services/security_audit_service.dart';
import 'core/router/app_router.dart';
import 'services/deep_link_handler.dart';
import 'services/firebase_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
    
    // Load Environment Variables
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Environment variables loaded');

    // Initialize Stripe
    final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (stripeKey != null && stripeKey.isNotEmpty) {
      Stripe.publishableKey = stripeKey;
      Stripe.merchantIdentifier = 'BuyV';
      await Stripe.instance.applySettings();
      debugPrint('✅ Stripe initialized');
    } else {
      debugPrint('⚠️ Stripe key not found, skipping Stripe initialization');
    }
  } catch (e) {
    debugPrint('❌ Error during initialization: $e');
  }

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initFirebaseNotifications();
  }

  Future<void> _initFirebaseNotifications() async {
    try {
      await FirebaseNotificationService.instance.initialize();
      debugPrint('✅ Firebase Notifications initialized');
    } catch (e) {
      debugPrint('❌ Firebase Notifications initialization failed: $e');
    }
  }

  Future<void> _initDeepLinks() async {
    debugPrint('🔗 Initializing deep link listener...');
    
    // Handle initial link when app starts (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Initial deep link detected: $initialUri');
        // Delay to ensure router is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _handleDeepLink(initialUri);
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error getting initial link: $e');
    }

    // Handle links while app is running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 Deep link received while app running: $uri');
        if (mounted) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        debugPrint('❌ Deep link error: $err');
      },
    );
    
    debugPrint('✅ Deep link listener initialized');
  }

  void _handleDeepLink(Uri uri) {
    // Get the router context
    final navigatorKey = GlobalKey<NavigatorState>();
    final context = navigatorKey.currentContext;
    
    if (context != null) {
      DeepLinkHandler.handleDeepLink(context, uri);
    } else {
      debugPrint('⚠️ Context not available yet, retrying...');
      Future.delayed(const Duration(milliseconds: 300), () {
        final retryContext = navigatorKey.currentContext;
        if (retryContext != null) {
          DeepLinkHandler.handleDeepLink(retryContext, uri);
        }
      });
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

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
        ChangeNotifierProvider(
          create: (context) {
            final provider = CartProvider();
            provider.loadCart();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => ProductProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.getRouter(context);
          
          return MaterialApp.router(
            title: 'BuyV E-commerce',
            theme: AppTheme.lightTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
