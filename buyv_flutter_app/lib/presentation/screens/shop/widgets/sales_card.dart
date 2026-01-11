import 'package:flutter/material.dart';

/// Bannière promotionnelle "Sales" style Kotlin
/// - Fond bleu (#2196F3)
/// - Texte "Sales" + "get 25% discount"
/// - Bouton "Shop Now" avec dégradé orange
/// - Image à droite
class SalesCard extends StatelessWidget {
  final VoidCallback? onShopNowTap;

  const SalesCard({
    super.key,
    this.onShopNowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Texte et bouton à gauche
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 22, top: 14, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Titre "Sales"
                  const Text(
                    'Sales',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                  // Sous-titre
                  const Text(
                    'get 25% discount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Bouton "Shop Now" avec dégradé orange
                  _buildShopNowButton(),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Image à droite
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/keyboard_hand.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback avec icône
                    return Container(
                      color: Colors.white,
                      child: const Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 60,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopNowButton() {
    return GestureDetector(
      onTap: onShopNowTap,
      child: Container(
        height: 40,
        constraints: const BoxConstraints(minWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFf8a714), Color(0xFFed380a)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Shop Now',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
