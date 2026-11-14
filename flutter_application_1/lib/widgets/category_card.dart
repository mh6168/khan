import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jewelry_category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.onTap});

  final JewelryCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: khanGold.withValues(alpha: 0.22)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: khanLightGold.withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                ),
                child: Icon(_categoryIcon, color: khanDark, size: 27),
              ),
              const SizedBox(height: 11),
              Text(
                category.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: khanDark, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _categoryIcon => switch (category) {
    JewelryCategory.rings => Icons.circle_outlined,
    JewelryCategory.necklaces => Icons.cable_outlined,
    JewelryCategory.bracelets => Icons.watch_outlined,
    JewelryCategory.earrings => Icons.hearing_outlined,
    JewelryCategory.pendants => Icons.diamond_outlined,
    JewelryCategory.watches => Icons.watch,
  };
}
