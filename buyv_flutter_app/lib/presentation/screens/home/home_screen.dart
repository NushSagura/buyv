import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../feed_screen.dart'; // Assuming standard relative path or absolute if needed
import '../shop/shop_screen.dart';
import '../cart/cart_screen.dart';
import '../earnings/earnings_screen.dart';
import '../profile/profile_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/route_names.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;

  final List<Widget> _screens = [
    const FeedScreen(), // Replaced ReelsScreen
    const ShopScreen(),
    const CartScreen(),
    const EarningsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        
        // Double tap to exit behavior
        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrSnackBarHasBeenClosed =
            _lastPressedAt == null ||
                now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrSnackBarHasBeenClosed) {
          _lastPressedAt = now;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appuyez à nouveau pour quitter'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: IndexedStack(index: _currentIndex, children: _screens),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // Use go_router for navigation
            context.push(RouteNames.addPost).then((result) {
              if (result == true && context.mounted) {
                Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).triggerPostRefresh();
              }
            });
          },
          backgroundColor: const Color(0xFFFF6F00),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF176DBA),
          unselectedItemColor: const Color(0xD8000000),
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library),
              label: 'Feed', // Updated label
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monetization_on),
              label: 'Earnings',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
