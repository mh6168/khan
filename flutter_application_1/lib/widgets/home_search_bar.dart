import 'package:flutter/material.dart';

import '../khan_colors.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search jewelry...',
        hintStyle: const TextStyle(color: khanSecondaryDark),
        prefixIcon: const Icon(Icons.search_rounded, color: khanGold),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: khanGold.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: khanGold, width: 1.5),
        ),
      ),
    );
  }
}
