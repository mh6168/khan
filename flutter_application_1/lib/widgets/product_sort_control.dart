import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jewelry_product.dart';

enum ProductSortOption { recommended, priceLowToHigh, priceHighToLow }

extension ProductSortOptionLabel on ProductSortOption {
  String get label => switch (this) {
    ProductSortOption.recommended => 'Recommended',
    ProductSortOption.priceLowToHigh => 'Price: Low to High',
    ProductSortOption.priceHighToLow => 'Price: High to Low',
  };
}

List<JewelryProduct> sortProducts(
  List<JewelryProduct> products,
  ProductSortOption option,
) {
  if (option == ProductSortOption.recommended) {
    return List<JewelryProduct>.of(products);
  }

  final indexedProducts = products.asMap().entries.toList();
  indexedProducts.sort((left, right) {
    final leftPrice = _validPrice(left.value.priceEgp);
    final rightPrice = _validPrice(right.value.priceEgp);
    if (leftPrice == null || rightPrice == null) {
      if (leftPrice == null && rightPrice == null) {
        return left.key.compareTo(right.key);
      }
      return leftPrice == null ? 1 : -1;
    }

    final comparison = leftPrice.compareTo(rightPrice);
    if (comparison == 0) return left.key.compareTo(right.key);
    return option == ProductSortOption.priceLowToHigh
        ? comparison
        : -comparison;
  });
  return indexedProducts.map((entry) => entry.value).toList();
}

double? _validPrice(double? price) {
  if (price == null || !price.isFinite || price < 0) return null;
  return price;
}

class ProductSortControl extends StatelessWidget {
  const ProductSortControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ProductSortOption value;
  final ValueChanged<ProductSortOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sort products',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: khanGold.withValues(alpha: 0.32)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ProductSortOption>(
            value: value,
            borderRadius: BorderRadius.circular(14),
            iconEnabledColor: khanSecondaryDark,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: khanDark, fontWeight: FontWeight.w600),
            items: ProductSortOption.values
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(option.label),
                  ),
                )
                .toList(),
            onChanged: (option) {
              if (option != null) onChanged(option);
            },
          ),
        ),
      ),
    );
  }
}
