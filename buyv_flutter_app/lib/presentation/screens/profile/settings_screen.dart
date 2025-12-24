import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSettingItem(
              context,
              icon: Icons.track_changes,
              title: 'Orders Track',
              onTap: () {
                // Navigate to orders track
                Navigator.pushNamed(context, '/orders-track');
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              context,
              icon: Icons.history,
              title: 'Orders history',
              onTap: () {
                // Navigate to orders history
                Navigator.pushNamed(context, '/orders-history');
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              context,
              icon: Icons.visibility,
              title: 'Recently viewed',
              onTap: () {
                // Navigate to recently viewed
                Navigator.pushNamed(context, '/recently-viewed');
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              context,
              icon: Icons.payment,
              title: 'Payment Methods',
              onTap: () {
                // Navigate to payment methods
                Navigator.pushNamed(context, '/payment-methods');
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              context,
              icon: Icons.location_on,
              title: 'Location',
              onTap: () {
                // Navigate to location settings
                Navigator.pushNamed(context, '/location-settings');
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              context,
              icon: Icons.language,
              title: 'Language',
              onTap: () {
                // Navigate to language settings
                Navigator.pushNamed(context, '/language-settings');
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              context,
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                // Navigate to change password
                Navigator.pushNamed(context, '/change-password');
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              context,
              icon: Icons.help,
              title: 'Ask Help',
              onTap: () {
                // Navigate to help
                Navigator.pushNamed(context, '/help');
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF6F00).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFFFF6F00),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFFF6F00)),
              ),
            ),
          ],
        );
      },
    );
  }
}