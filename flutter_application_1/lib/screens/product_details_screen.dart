import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/jeweler_service.dart';
import '../data/product_service.dart';
import '../data/supabase_storage.dart';
import '../khan_colors.dart';
import '../models/jeweler_profile.dart';
import '../models/jewelry_product.dart';
import '../widgets/jeweler_avatar.dart';
import 'jeweler_profile_screen.dart';
import 'reservation/reservation_payment_method_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.jewelerService,
    this.productService,
  });

  final JewelryProduct product;
  final JewelerService? jewelerService;
  final ProductService? productService;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImage = 0;
  late Future<JewelerProfile?> _jewelerProfile;

  @override
  void initState() {
    super.initState();
    _jewelerProfile = _loadJewelerProfile();
  }

  @override
  void didUpdateWidget(covariant ProductDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.jewelerId != widget.product.jewelerId) {
      _jewelerProfile = _loadJewelerProfile();
    }
  }

  Future<JewelerProfile?> _loadJewelerProfile() {
    final jewelerId = widget.product.jewelerId?.trim();
    if (jewelerId == null || jewelerId.isEmpty) {
      return Future.value(null);
    }
    return (widget.jewelerService ?? const JewelerService())
        .fetchApprovedJeweler(jewelerId);
  }

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
                const SizedBox(height: 24),
                if (widget.product.productType == 'jewelry') ...[
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReservationPaymentMethodScreen(
                          product: widget.product,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Reserve Now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: khanDark,
                      foregroundColor: khanGold,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _ListedBySection(
                  jewelerProfile: _jewelerProfile,
                  onVisitStore: (profile) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => JewelerProfileScreen(
                          jewelerId: profile.id,
                          jewelerService: widget.jewelerService,
                          productService: widget.productService,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListedBySection extends StatelessWidget {
  const _ListedBySection({
    required this.jewelerProfile,
    required this.onVisitStore,
  });

  final Future<JewelerProfile?> jewelerProfile;
  final ValueChanged<JewelerProfile> onVisitStore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listed By',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        FutureBuilder<JewelerProfile?>(
          future: jewelerProfile,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ListedByCard(
                message: 'Loading jeweler information...',
                loading: true,
              );
            }
            if (snapshot.hasError) {
              return const _ListedByCard(
                message: 'Jeweler information is currently unavailable.',
              );
            }

            final profile = snapshot.data;
            if (profile == null) {
              return const _ListedByCard(
                message: 'Seller information is not available for this item.',
              );
            }

            return _ListedByCard(
              profile: profile,
              onTap: () => onVisitStore(profile),
            );
          },
        ),
      ],
    );
  }
}

class _ListedByCard extends StatelessWidget {
  const _ListedByCard({
    this.profile,
    this.message = 'Store description not provided yet.',
    this.loading = false,
    this.onTap,
  });

  final JewelerProfile? profile;
  final String message;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final jeweler = profile;
    final storeName = jeweler?.displayName;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: khanGold.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: khanDark.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (jeweler != null)
                JewelerAvatar(profile: jeweler, size: 60)
              else
                _ListedByPlaceholder(loading: loading),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (storeName != null)
                      Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: khanDark,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    if (jeweler?.isVerified ?? false) ...[
                      const SizedBox(height: 5),
                      const _VerifiedBadge(),
                    ],
                    const SizedBox(height: 6),
                    if (jeweler != null)
                      Text(
                        jeweler.location ?? 'Location not provided',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: khanSecondaryDark),
                      ),
                    Text(
                      jeweler?.description ?? message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: khanSecondaryDark.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: khanGold),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ListedByPlaceholder extends StatelessWidget {
  const _ListedByPlaceholder({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(color: khanDark, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: khanGold),
            )
          : const Icon(Icons.storefront_outlined, color: khanGold, size: 30),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.verified_rounded, color: khanGold, size: 16),
        const SizedBox(width: 4),
        Text(
          'Verified jeweler',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: khanSecondaryDark, fontWeight: FontWeight.w700),
        ),
      ],
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
