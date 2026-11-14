import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jewelry_product.dart';
import 'product_card.dart';

class HomeSectionHeading extends StatelessWidget {
  const HomeSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: khanSecondaryDark.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: khanSecondaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class HomeProductSection extends StatelessWidget {
  const HomeProductSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.products,
    required this.favoriteIds,
    required this.onFavoriteTap,
    this.onProductTap,
  });

  final String title;
  final String subtitle;
  final List<JewelryProduct> products;
  final Set<String> favoriteIds;
  final ValueChanged<JewelryProduct> onFavoriteTap;
  final ValueChanged<JewelryProduct>? onProductTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeading(
          title: title,
          subtitle: subtitle,
          trailing: 'View all',
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 258,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                isFavorite: favoriteIds.contains(product.id),
                onFavoriteTap: () => onFavoriteTap(product),
                onTap: onProductTap == null
                    ? null
                    : () => onProductTap!(product),
              );
            },
          ),
        ),
      ],
    );
  }
}

class FeaturedCollectionBanner extends StatelessWidget {
  const FeaturedCollectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: khanSecondaryDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: khanGold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: khanDark,
              size: 25,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Cairo Collection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: khanLightGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Inspired by a city that shines.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.72)),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: khanGold),
        ],
      ),
    );
  }
}
