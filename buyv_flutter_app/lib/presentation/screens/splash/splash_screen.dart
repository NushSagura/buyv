import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/router/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../../services/security/secure_token_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Afficher splash pendant 2 secondes puis naviguer
    Timer(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }
  
  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    
    try {
      // Check if first time
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;
      
      // Vérifier si l'utilisateur a un token valide
      final hasValidToken = await SecureTokenManager.isAccessTokenValid();
      
      if (hasValidToken) {
        // Token valide - essayer de récupérer les infos utilisateur
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Si l'utilisateur est déjà authentifié, aller à l'accueil
        if (authProvider.isAuthenticated) {
          debugPrint('✅ Utilisateur déjà connecté - redirection vers home');
          if (mounted) {
            context.go(RouteNames.home);
          }
        } else {
          // Token existe mais utilisateur pas chargé - recharger
          debugPrint('🔄 Token trouvé - rechargement utilisateur');
          await authProvider.reloadUserData();
          
          if (mounted) {
            if (authProvider.isAuthenticated) {
              context.go(RouteNames.home);
            } else {
              // Token invalid but first time
              context.go(isFirstTime ? RouteNames.onboarding : RouteNames.login);
            }
          }
        }
      } else {
        // Pas de token valide - check si première fois
        debugPrint('⚠️ Pas de token valide - redirection');
        if (mounted) {
          context.go(isFirstTime ? RouteNames.onboarding : RouteNames.login);
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification auth: $e');
      // En cas d'erreur, aller à l'onboarding
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        final isFirstTime = prefs.getBool('isFirstTime') ?? true;
        context.go(isFirstTime ? RouteNames.onboarding : RouteNames.login);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        // Pas de contenu par-dessus - juste l'image splash fullscreen comme dans Kotlin
      ),
    );
  }
}