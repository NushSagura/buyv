import 'package:flutter/material.dart';

/// SearchBar style Kotlin - pilule avec bordure bleue
class ShopSearchBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onTap;
  final bool enabled;

  const ShopSearchBar({
    super.key,
    this.searchQuery = '',
    this.onQueryChanged,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF176DBA),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                searchQuery.isEmpty ? 'Search' : searchQuery,
                style: TextStyle(
                  color: searchQuery.isEmpty ? Colors.grey : Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(right: 12),
              child: const Icon(
                Icons.search,
                color: Color(0xFF176DBA),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SearchBar interactive avec TextField
class ShopSearchBarTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onQueryChanged;
  final VoidCallback? onClear;

  const ShopSearchBarTextField({
    super.key,
    required this.controller,
    this.onQueryChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 46,
      child: TextField(
        controller: controller,
        onChanged: onQueryChanged,
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: onClear,
                )
              : const Icon(
                  Icons.search,
                  color: Color(0xFF176DBA),
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF176DBA),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF176DBA),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF176DBA),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
