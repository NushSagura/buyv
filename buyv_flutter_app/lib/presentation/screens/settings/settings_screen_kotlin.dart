import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../services/auth_api_service.dart';

/// Settings Screen - Design Kotlin
/// Items avec bordures orange arrondies, icônes et chevrons
class SettingsScreenKotlin extends StatelessWidget {
  const SettingsScreenKotlin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF0066CC),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0066CC)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home?tab=3'); // Retour au Profile
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSettingsItem(
              context,
              icon: Icons.local_shipping_outlined,
              title: 'Orders Track',
              onTap: () => context.push('/orders-track'),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              icon: Icons.history,
              title: 'Orders history',
              onTap: () => context.push('/orders-history'),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              icon: Icons.visibility_outlined,
              title: 'Recently viewed',
              onTap: () => context.push('/recently-viewed'),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              icon: Icons.credit_card_outlined,
              title: 'Payment Methods',
              onTap: () => context.push('/payment-methods'),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              icon: Icons.location_on_outlined,
              title: 'Location',
              onTap: () => context.push('/location-settings'),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              icon: Icons.language_outlined,
              title: 'Language',
              onTap: () => context.push('/language-settings'),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: () => context.push('/change-password'),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              icon: Icons.help_outline,
              title: 'Ask Help',
              onTap: () => context.push('/help'),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              context,
              icon: Icons.delete_forever,
              title: 'Delete Account',
              onTap: () => context.push('/delete-account'),
              isDestructive: true,
            ),
            const SizedBox(height: 24),
            
            // Logout button
            _buildSettingsItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => _showLogoutDialog(context),
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color borderColor = isDestructive 
        ? Colors.red.withOpacity(0.5) 
        : const Color(0xFFFF6F00);
    final Color textColor = isDestructive 
        ? Colors.red 
        : const Color(0xFF0066CC);
    final Color iconColor = isDestructive 
        ? Colors.red 
        : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icône
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            
            // Titre
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            
            // Chevron
            Icon(
              Icons.chevron_right,
              color: textColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFF0066CC),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6F00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
