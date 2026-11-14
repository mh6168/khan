import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jewelry_product.dart';
import '../widgets/home_sections.dart';
import '../widgets/product_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    required this.header,
    required this.products,
    required this.onFavoriteTap,
    required this.onBrowseHome,
  });

  final Widget header;
  final List<JewelryProduct> products;
  final ValueChanged<JewelryProduct> onFavoriteTap;
  final VoidCallback onBrowseHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: header,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Row(
            children: [
              const Expanded(
                child: HomeSectionHeading(
                  title: 'My Favorites',
                  subtitle: 'Your saved jewelry collection.',
                ),
              ),
              if (products.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: khanLightGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${products.length} ${products.length == 1 ? 'piece' : 'pieces'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: khanDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? _EmptyFavorites(onBrowseHome: onBrowseHome)
              : _FavoritesGrid(
                  products: products,
                  onFavoriteTap: onFavoriteTap,
                ),
        ),
      ],
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({required this.products, required this.onFavoriteTap});

  final List<JewelryProduct> products;
  final ValueChanged<JewelryProduct> onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 270,
          mainAxisExtent: 270,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: constraints.maxWidth < 360 ? 0.88 : 1,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            isFavorite: true,
            onFavoriteTap: () => onFavoriteTap(product),
          );
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.onBrowseHome});

  final VoidCallback onBrowseHome;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: khanGold.withValues(alpha: 0.24)),
              boxShadow: [
                BoxShadow(
                  color: khanDark.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: khanDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: khanGold.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: khanLightGold.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.favorite_border_rounded,
                        color: khanGold,
                        size: 42,
                      ),
                      const Positioned(
                        top: 20,
                        right: 21,
                        child: Icon(
                          Icons.auto_awesome,
                          color: khanLightGold,
                          size: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Your favorites collection is empty.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 9),
                Text(
                  'When a piece catches your eye, tap its heart to keep it '
                  'close. Your saved jewelry will be waiting here.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: khanSecondaryDark.withValues(alpha: 0.82),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onBrowseHome,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Explore jewelry'),
                    style: FilledButton.styleFrom(
                      backgroundColor: khanDark,
                      foregroundColor: khanGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
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
