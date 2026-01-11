import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/cart_provider.dart';

/// TopBar avec Logo centré et icône Notifications (style Kotlin)
class ShopTopBar extends StatelessWidget {
  final VoidCallback? onNotificationTap;

  const ShopTopBar({
    super.key,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Spacer à gauche pour centrer le logo
          const Expanded(child: SizedBox()),
          
          // Logo centré
          Expanded(
            child: Center(
              child: SizedBox(
                height: 52,
                child: Image.asset(
                  'assets/images/logo_v3.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 52,
                      child: Center(
                        child: Text(
                          'buyv',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066CC),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Notifications avec badge à droite
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onNotificationTap,
                    icon: Image.asset(
                      'assets/icons/notification_icon.png',
                      width: 28,
                      height: 28,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.notifications_outlined,
                          size: 28,
                          color: Color(0xFFFFC107),
                        );
                      },
                    ),
                  ),
                  // Badge notification - TODO: rendre dynamique avec un provider
                  // Pour l'instant on le cache car pas de vraies notifications
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
