import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jewelry_category.dart';

class CategoryListingScreen extends StatelessWidget {
  const CategoryListingScreen({super.key, required this.category});

  final JewelryCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: Text(category.label),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
        iconTheme: const IconThemeData(color: khanGold),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: khanGold.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: const BoxDecoration(
                              color: khanLightGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.diamond_outlined,
                              color: khanSecondaryDark,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No jewelry available in this category yet.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: khanSecondaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
