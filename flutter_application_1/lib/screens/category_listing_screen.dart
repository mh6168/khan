import 'package:flutter/material.dart';

import '../data/product_service.dart';
import '../khan_colors.dart';
import '../models/jewelry_category.dart';
import '../models/jewelry_product.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/product_sort_control.dart';
import 'product_details_screen.dart';

class CategoryListingScreen extends StatefulWidget {
  const CategoryListingScreen({
    super.key,
    required this.category,
    this.productsFuture,
  });

  final JewelryCategory category;
  final Future<List<JewelryProduct>>? productsFuture;

  @override
  State<CategoryListingScreen> createState() => _CategoryListingScreenState();
}

class _CategoryListingScreenState extends State<CategoryListingScreen> {
  late Future<List<JewelryProduct>> _productsFuture;
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.recommended;

  @override
  void initState() {
    super.initState();
    _productsFuture =
        widget.productsFuture ?? ProductService().fetchAvailableProducts();
  }

  @override
  void didUpdateWidget(covariant CategoryListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productsFuture != widget.productsFuture) {
      _productsFuture =
          widget.productsFuture ?? ProductService().fetchAvailableProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: Text(widget.category.label),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
        iconTheme: const IconThemeData(color: khanGold),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: FutureBuilder<List<JewelryProduct>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _CategoryMessage(
                    icon: Icons.cloud_off_outlined,
                    message: 'Products could not be loaded. Please try again.',
                    actionLabel: 'Retry',
                    onAction: _retryLoading,
                  );
                }

                final products = _visibleProducts(
                  _productsInCategory(snapshot.data ?? const []),
                );
                return _buildCategoryContent(products);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContent(List<JewelryProduct> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeSearchBar(
                hintText: 'Search ${widget.category.label.toLowerCase()}...',
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${products.length} ${products.length == 1 ? 'piece' : 'pieces'}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: khanSecondaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ProductSortControl(
                    value: _sortOption,
                    onChanged: (value) => setState(() => _sortOption = value),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? _CategoryMessage(
                  icon: _searchQuery.trim().isEmpty
                      ? Icons.diamond_outlined
                      : Icons.search_off_rounded,
                  message: _searchQuery.trim().isEmpty
                      ? 'No jewelry available in this category yet.'
                      : 'No products match your search.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 270,
                    mainAxisExtent: 270,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      expand: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ProductDetailsScreen(product: product),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<JewelryProduct> _productsInCategory(List<JewelryProduct> products) {
    if (widget.category == JewelryCategory.watches) {
      return products
          .where((product) => product.productType == 'watch')
          .toList();
    }
    final categoryLabel = widget.category.label.toLowerCase();
    return products
        .where(
          (product) =>
              product.productType != 'watch' &&
              product.category.trim().toLowerCase() == categoryLabel,
        )
        .toList();
  }

  List<JewelryProduct> _visibleProducts(List<JewelryProduct> products) {
    final query = _searchQuery.trim().toLowerCase();
    final matching = query.isEmpty
        ? products
        : products
              .where((product) => product.name.toLowerCase().contains(query))
              .toList();

    return sortProducts(matching, _sortOption);
  }

  void _retryLoading() {
    setState(() {
      _productsFuture = ProductService().fetchAvailableProducts();
    });
  }
}

class _CategoryMessage extends StatelessWidget {
  const _CategoryMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: khanGold.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: khanDark.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: khanLightGold,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: khanSecondaryDark, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: khanSecondaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: onAction,
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: khanDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
