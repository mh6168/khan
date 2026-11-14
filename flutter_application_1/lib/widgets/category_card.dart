import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jewelry_category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.onTap});

  final JewelryCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_categoryIcon, color: khanGold, size: 32),
              const SizedBox(height: 10),
              Text(
                category.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
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
    JewelryCategory.necklaces => Icons.link,
    JewelryCategory.bracelets => Icons.watch_outlined,
    JewelryCategory.earrings => Icons.diamond_outlined,
    JewelryCategory.pendants => Icons.auto_awesome_outlined,
    JewelryCategory.watches => Icons.access_time,
  };
}
