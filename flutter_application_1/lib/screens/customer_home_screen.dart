import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/sample_jewelry.dart';
import '../khan_colors.dart';
import '../models/jewelry_category.dart';
import '../models/customer_profile_info.dart';
import '../models/jewelry_product.dart';
import '../widgets/category_card.dart';
import '../widgets/customer_bottom_navigation.dart';
import '../widgets/home_header.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_sections.dart';
import 'category_listing_screen.dart';
import 'account_settings_screen.dart';
import 'favorites_screen.dart';
import 'invest_screen.dart';
import 'profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({
    super.key,
    this.customerId,
    this.customerName,
    this.customerEmail,
  });

  final String? customerId;
  final String? customerName;
  final String? customerEmail;

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late Future<CustomerProfileInfo> _customerProfile;
  int _selectedTab = 0;
  String _searchQuery = '';
  final Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _customerProfile = _loadCustomerProfile();
  }

  @override
  void didUpdateWidget(covariant CustomerHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId ||
        oldWidget.customerName != widget.customerName) {
      _customerProfile = _loadCustomerProfile();
    }
  }

  Future<CustomerProfileInfo> _loadCustomerProfile() async {
    final authName = widget.customerName?.trim();
    final authProfile = CustomerProfileInfo(
      name: authName == null || authName.isEmpty ? null : authName,
      email: widget.customerEmail,
    );

    final customerId = widget.customerId;
    if (customerId == null || customerId.isEmpty) return authProfile;

    DocumentSnapshot<Map<String, dynamic>> profile;
    try {
      profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .get();
    } on FirebaseException {
      return CustomerProfileInfo(
        name: authProfile.name,
        email: authProfile.email,
        profileLoadFailed: true,
      );
    }
    final data = profile.data();
    final profileName = data?['name'];
    final profilePhone = data?['phone'];
    return CustomerProfileInfo(
      name: profileName is String && profileName.trim().isNotEmpty
          ? profileName.trim()
          : authProfile.name,
      email: widget.customerEmail,
      phone: profilePhone is String && profilePhone.trim().isNotEmpty
          ? profilePhone.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      body: SafeArea(
        child: FutureBuilder<CustomerProfileInfo>(
          future: _customerProfile,
          builder: (context, snapshot) {
            return _buildSelectedDestination(
              snapshot.data?.name ?? widget.customerName,
              profileLoadFailed:
                  snapshot.hasError ||
                  (snapshot.data?.profileLoadFailed ?? false),
              customerProfile: snapshot.data,
            );
          },
        ),
      ),
      bottomNavigationBar: CustomerBottomNavigation(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
            _searchQuery = '';
          });
        },
      ),
    );
  }

  Widget _buildSelectedDestination(
    String? customerName, {
    required bool profileLoadFailed,
    required CustomerProfileInfo? customerProfile,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: switch (_selectedTab) {
              0 => _buildHomeContent(
                constraints.maxWidth,
                customerName,
                profileLoadFailed,
              ),
              1 => InvestScreen(header: _buildHeader(customerName)),
              2 => FavoritesScreen(
                header: _buildHeader(customerName),
                products: sampleJewelry
                    .where((product) => _favoriteIds.contains(product.id))
                    .toList(),
                onFavoriteTap: _toggleFavorite,
                onBrowseHome: () => setState(() => _selectedTab = 0),
              ),
              _ => ProfileScreen(
                header: _buildHeader(customerName),
                customerName: customerName,
                customerEmail: customerProfile?.email ?? widget.customerEmail,
                customerPhone: customerProfile?.phone,
                profileLoadFailed: profileLoadFailed,
                onLogout: () => FirebaseAuth.instance.signOut(),
                onFavoritesTap: () => setState(() => _selectedTab = 2),
                onAccountSettingsTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountSettingsScreen(),
                  ),
                ),
              ),
            },
          ),
        );
      },
    );
  }

  Widget _buildHomeContent(
    double width,
    String? customerName,
    bool profileLoadFailed,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final categories = JewelryCategory.values
        .where((category) => category.label.toLowerCase().contains(query))
        .toList();
    final matchingTrending = _matchingProducts(trendingJewelry, query);
    final matchingArrivals = _matchingProducts(newArrivals, query);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(customerName),
          if (profileLoadFailed) ...[
            const SizedBox(height: 8),
            Text(
              'Some profile details could not be loaded. '
              'Your sign-in information is still available.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: 22),
          HomeSearchBar(
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 28),
          const HomeSectionHeading(
            title: 'Explore categories',
            subtitle: 'A little something for every story.',
          ),
          const SizedBox(height: 14),
          if (categories.isNotEmpty)
            _buildCategoryGrid(categories, width)
          else if (query.isNotEmpty &&
              (matchingTrending.isNotEmpty || matchingArrivals.isNotEmpty))
            _buildNoResults('No matching categories.')
          else if (query.isNotEmpty &&
              matchingTrending.isEmpty &&
              matchingArrivals.isEmpty)
            _buildNoResults('No matching categories or jewelry.'),
          const SizedBox(height: 30),
          if (matchingTrending.isNotEmpty)
            HomeProductSection(
              title: query.isEmpty ? 'Trending jewelry' : 'Matching jewelry',
              subtitle: 'Pieces everyone is talking about.',
              products: matchingTrending,
              favoriteIds: _favoriteIds,
              onFavoriteTap: _toggleFavorite,
            ),
          if (matchingTrending.isNotEmpty && matchingArrivals.isNotEmpty)
            const SizedBox(height: 28),
          if (matchingArrivals.isNotEmpty)
            HomeProductSection(
              title: 'New arrivals',
              subtitle: 'Fresh designs, just added.',
              products: matchingArrivals,
              favoriteIds: _favoriteIds,
              onFavoriteTap: _toggleFavorite,
            ),
          if (query.isEmpty) ...[
            const SizedBox(height: 28),
            const FeaturedCollectionBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(String? customerName) {
    return HomeHeader(
      customerName: customerName,
      onNotificationsTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('You are all caught up.')),
          );
      },
      onLogoutTap: () => FirebaseAuth.instance.signOut(),
    );
  }

  Widget _buildCategoryGrid(List<JewelryCategory> categories, double width) {
    final crossAxisCount = width < 600
        ? 2
        : width < 900
        ? 3
        : 6;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: width < 600 ? 0.9 : 0.95,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CategoryListingScreen(category: category),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoResults(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: khanSecondaryDark),
      ),
    );
  }

  List<JewelryProduct> _matchingProducts(
    List<JewelryProduct> products,
    String query,
  ) {
    if (query.isEmpty) return products;
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query),
        )
        .toList();
  }

  void _toggleFavorite(JewelryProduct product) {
    setState(() {
      if (!_favoriteIds.add(product.id)) {
        _favoriteIds.remove(product.id);
      }
    });
  }
}
