import 'package:flutter/material.dart';

/// ReelsTopBar - Barre supérieure avec onglets (Explore / Following / For you)
/// Référence Kotlin: ReelsTopHeader composable avec HeaderTab
class ReelTopBar extends StatelessWidget {
  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final VoidCallback onSearchTap;

  const ReelTopBar({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tabs Row
                Row(
                  children: tabs.map((tab) {
                    final isSelected = tab == selectedTab;
                    return GestureDetector(
                      onTap: () => onTabChanged(tab),
                      child: _HeaderTab(text: tab, isSelected: isSelected),
                    );
                  }).toList(),
                ),

                // Search Icon
                IconButton(
                  onPressed: onSearchTap,
                  icon: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 26,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// HeaderTab - Onglet avec underline indicator
class _HeaderTab extends StatelessWidget {
  final String text;
  final bool isSelected;

  const _HeaderTab({required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (isSelected)
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }
}
