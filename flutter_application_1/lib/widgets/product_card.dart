import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jewelry_product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onFavoriteTap,
  });

  final JewelryProduct product;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 218,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: khanGold.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              _ProductArtwork(product: product),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filled(
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: onFavoriteTap,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    foregroundColor: isFavorite ? khanGold : khanDark,
                    minimumSize: const Size(38, 38),
                  ),
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: khanSecondaryDark.withValues(alpha: 0.7),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                Text(
                  '${product.priceEgp} EGP',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductArtwork extends StatelessWidget {
  const _ProductArtwork({required this.product});

  final JewelryProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [product.artworkColor, khanDark],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -34,
            right: -25,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: khanLightGold.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Icon(product.artworkIcon, color: khanLightGold, size: 62),
          Positioned(
            bottom: 12,
            left: 13,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: khanDark.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'KHAN EDIT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: khanLightGold,
                  letterSpacing: 1,
                  fontSize: 9,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
