import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../services/auth_api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
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
                    onTap: () => context.push('/payment'),
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
                    onTap: () => _showDeleteAccountDialog(context),
                    isDestructive: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsItem(
                    context,
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () async {
                      await context.read<AuthProvider>().signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    isLogout: true,
                  ),
                ],
              ),
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
    bool isLogout = false,
    bool isDestructive = false,
  }) {
    final Color itemColor = isDestructive 
        ? Colors.red 
        : (isLogout ? Colors.red : const Color(0xFFFF6F00));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: itemColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: itemColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: itemColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: (isLogout || isDestructive) ? Colors.red : Colors.blue,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: (isLogout || isDestructive) ? Colors.red : Colors.blue,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete your account?',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'This action will:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text('• Delete all your posts and reels'),
              Text('• Remove all your comments and likes'),
              Text('• Cancel all pending orders'),
              Text('• Remove all your follows'),
              Text('• Delete all your data permanently'),
              SizedBox(height: 16),
              Text(
                '⚠️ This action cannot be undone!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteAccount(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Account'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Import auth_api_service at top of file
      await AuthApiService.deleteAccount();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Sign out and redirect to login
      if (context.mounted) {
        await context.read<AuthProvider>().signOut();
        context.go('/login');
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}