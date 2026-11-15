import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/supabase_storage.dart';
import '../khan_colors.dart';
import '../models/jewelry_product.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final JewelryProduct product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('Product details'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
        iconTheme: const IconThemeData(color: khanGold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductGallery(
                  product: widget.product,
                  currentImage: _currentImage,
                  onImageChanged: (index) {
                    setState(() => _currentImage = index);
                  },
                ),
                const SizedBox(height: 24),
                _ProductHeader(product: widget.product),
                if (_validThreeDUrl(widget.product.threeDModelUrl)) ...[
                  const SizedBox(height: 16),
                  _ThreeDAction(url: widget.product.threeDModelUrl!),
                ],
                const SizedBox(height: 24),
                _Specifications(product: widget.product),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _validThreeDUrl(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

class _ThreeDAction extends StatelessWidget {
  const _ThreeDAction({required this.url});

  final String url;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !_validThreeDUrl(url)) {
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('This 3D model link could not be opened.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.view_in_ar_outlined),
      label: const Text('View in 3D'),
      style: OutlinedButton.styleFrom(
        foregroundColor: khanSecondaryDark,
        side: const BorderSide(color: khanGold),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({
    required this.product,
    required this.currentImage,
    required this.onImageChanged,
  });

  final JewelryProduct product;
  final int currentImage;
  final ValueChanged<int> onImageChanged;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentImage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.product.imageUrls;
    return Column(
      children: [
        Container(
          height: 330,
          decoration: BoxDecoration(
            color: widget.product.artworkColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: khanDark.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: images.isEmpty
              ? _GalleryFallback(product: widget.product)
              : PageView.builder(
                  key: PageStorageKey<String>(
                    'product-gallery-${widget.product.id}',
                  ),
                  controller: _pageController,
                  scrollDirection: Axis.horizontal,
                  physics: const PageScrollPhysics(),
                  itemCount: images.length,
                  onPageChanged: widget.onImageChanged,
                  itemBuilder: (context, index) => Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      logSupabaseImageError(images[index], error);
                      return _GalleryFallback(product: widget.product);
                    },
                  ),
                ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: index == widget.currentImage ? 22 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: index == widget.currentImage ? khanGold : khanDark,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GalleryFallback extends StatelessWidget {
  const _GalleryFallback({required this.product});

  final JewelryProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [product.artworkColor, khanDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(product.artworkIcon, color: khanLightGold, size: 96),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final JewelryProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.category.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: khanSecondaryDark.withValues(alpha: 0.7),
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text(
            product.priceEgp == null
                ? 'Price unavailable'
                : '${product.priceEgp!.toStringAsFixed(0)} EGP',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: khanSecondaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Specifications extends StatelessWidget {
  const _Specifications({required this.product});

  final JewelryProduct product;

  @override
  Widget build(BuildContext context) {
    final rows = product.productType == 'watch'
        ? <MapEntry<String, String?>>[
            MapEntry('Brand', product.brand),
            MapEntry('Model', product.model),
            MapEntry('Watch type', product.watchType),
            MapEntry('Case material', product.caseMaterial),
            MapEntry('Dial color', product.dialColor),
            MapEntry('Movement type', product.movementType),
            MapEntry('Country of origin', product.origin),
          ]
        : <MapEntry<String, String?>>[
            MapEntry('Category', product.category),
            MapEntry('Total weight', _grams(product.totalWeight)),
            MapEntry('Gold weight', _grams(product.goldWeight)),
            MapEntry(
              'Gold karat',
              product.goldKarat == null ? null : '${product.goldKarat}K',
            ),
            MapEntry('Gold color', product.goldColor),
            MapEntry('Country of origin', product.origin),
            MapEntry('Current premium', _egp(product.currentPremium)),
            MapEntry('Original premium', _egp(product.originalPremium)),
          ];
    final availableRows = rows
        .where((row) => row.value != null && row.value!.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Specifications',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (availableRows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No additional specifications available.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: khanSecondaryDark.withValues(alpha: 0.75),
                ),
              ),
            )
          else
            ...availableRows.map(
              (row) => _SpecificationRow(label: row.key, value: row.value!),
            ),
        ],
      ),
    );
  }

  static String? _grams(double? value) {
    return value == null ? null : '${value.toStringAsFixed(2)} g';
  }

  static String? _egp(double? value) {
    return value == null ? null : '${value.toStringAsFixed(2)} EGP / g';
  }
}

class _SpecificationRow extends StatelessWidget {
  const _SpecificationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: khanGold.withValues(alpha: 0.16)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: khanSecondaryDark.withValues(alpha: 0.75)),
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: khanGold.withValues(alpha: 0.2)),
    boxShadow: [
      BoxShadow(
        color: khanDark.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
