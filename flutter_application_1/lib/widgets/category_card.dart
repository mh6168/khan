import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jewelry_category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.onTap});

  final JewelryCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: khanDark.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                category.imageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x79000000),
                      Color(0xE6111618),
                    ],
                    stops: [0.32, 0.68, 1],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 10,
                child: Text(
                  category.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: khanDark.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                    border: Border.all(color: khanGold.withValues(alpha: 0.75)),
                  ),
                  child: Icon(_categoryIcon, color: khanGold, size: 16),
                ),
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
