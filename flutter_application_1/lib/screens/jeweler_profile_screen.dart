import 'package:flutter/material.dart';

import '../data/jeweler_service.dart';
import '../data/product_service.dart';
import '../khan_colors.dart';
import '../models/jeweler_profile.dart';
import '../models/jewelry_product.dart';
import '../widgets/home_sections.dart';
import '../widgets/jeweler_avatar.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';

class JewelerProfileScreen extends StatefulWidget {
  const JewelerProfileScreen({
    super.key,
    required this.jewelerId,
    this.jewelerService,
    this.productService,
  });

  final String jewelerId;
  final JewelerService? jewelerService;
  final ProductService? productService;

  @override
  State<JewelerProfileScreen> createState() => _JewelerProfileScreenState();
}

class _JewelerProfileScreenState extends State<JewelerProfileScreen> {
  late Future<JewelerProfile?> _jewelerProfile;
  late Future<List<JewelryProduct>> _products;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  @override
  void didUpdateWidget(covariant JewelerProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jewelerId != widget.jewelerId) {
      _loadStore();
    }
  }

  void _loadStore() {
    _jewelerProfile = (widget.jewelerService ?? const JewelerService())
        .fetchApprovedJeweler(widget.jewelerId);
    _products = (widget.productService ?? ProductService())
        .fetchAvailableProductsForJeweler(widget.jewelerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('Jeweler Store'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
        iconTheme: const IconThemeData(color: khanGold),
      ),
      body: FutureBuilder<JewelerProfile?>(
        future: _jewelerProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _StoreMessage(
              message: 'Loading store information...',
              loading: true,
            );
          }
          if (snapshot.hasError) {
            return const _StoreMessage(
              message: 'Store information could not be loaded. Please try again.',
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return const _StoreMessage(
              message: 'This jeweler store is not available.',
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StoreHeader(profile: profile),
                    const SizedBox(height: 28),
                    const HomeSectionHeading(
                      title: 'Products by this Jeweler',
                      subtitle: 'Available pieces from this store.',
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<JewelryProduct>>(
                      future: _products,
                      builder: (context, productSnapshot) {
                        if (productSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (productSnapshot.hasError) {
                          return const _ProductMessage(
                            message:
                                'Products could not be loaded. Please try again.',
                          );
                        }

                        final products =
                            productSnapshot.data ?? const <JewelryProduct>[];
                        if (products.isEmpty) {
                          return const _ProductMessage(
                            message:
                                'This jeweler has no available products right now.',
                          );
                        }

                        return _StoreProductGrid(
                          products: products,
                          jewelerService: widget.jewelerService,
                          productService: widget.productService,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.profile});

  final JewelerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: khanDark,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: khanGold.withValues(alpha: 0.48)),
        boxShadow: [
          BoxShadow(
            color: khanDark.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              JewelerAvatar(profile: profile, size: 82),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: khanLightGold,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(height: 9),
                      const _StoreVerifiedBadge(),
                    ],
                    const SizedBox(height: 12),
                    _StoreDetail(
                      icon: Icons.location_on_outlined,
                      value: profile.location ?? 'Location not provided',
                    ),
                    if (profile.phone != null) ...[
                      const SizedBox(height: 7),
                      _StoreDetail(
                        icon: Icons.phone_outlined,
                        value: profile.phone!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            profile.description ?? 'Store description not provided yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreVerifiedBadge extends StatelessWidget {
  const _StoreVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: khanGold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: khanGold.withValues(alpha: 0.45)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: khanGold, size: 16),
          SizedBox(width: 5),
          Text(
            'Verified jeweler',
            style: TextStyle(
              color: khanLightGold,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreDetail extends StatelessWidget {
  const _StoreDetail({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: khanGold, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: khanLightGold,
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreProductGrid extends StatelessWidget {
  const _StoreProductGrid({
    required this.products,
    this.jewelerService,
    this.productService,
  });

  final List<JewelryProduct> products;
  final JewelerService? jewelerService;
  final ProductService? productService;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 270,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailsScreen(
                product: product,
                jewelerService: jewelerService,
                productService: productService,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoreMessage extends StatelessWidget {
  const _StoreMessage({required this.message, this.loading = false});

  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator()
            else
              const Icon(Icons.storefront_outlined, color: khanGold, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ProductMessage extends StatelessWidget {
  const _ProductMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: khanSecondaryDark,
        ),
      ),
    );
  }
}
