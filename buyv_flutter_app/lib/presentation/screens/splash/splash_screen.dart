import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../../services/security/secure_token_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    
    // Vérifier le token et rediriger vers la page appropriée
    Timer(const Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }
  
  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    
    try {
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
              context.go(RouteNames.onboarding);
            }
          }
        }
      } else {
        // Pas de token valide - aller à l'onboarding
        debugPrint('⚠️ Pas de token valide - redirection vers onboarding');
        if (mounted) {
          context.go(RouteNames.onboarding);
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification auth: $e');
      // En cas d'erreur, aller à l'onboarding
      if (mounted) {
        context.go(RouteNames.onboarding);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/images/logo_v3.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // App Name
                        Text(
                          'BuyV',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Tagline
                        Text(
                          'Shop Smart, Buy with Confidence',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 5,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        // Loading Indicator
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}