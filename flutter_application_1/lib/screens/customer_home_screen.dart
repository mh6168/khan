import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/jewelry_category.dart';
import '../widgets/category_card.dart';
import 'category_listing_screen.dart';

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
  late Future<String?> _customerName;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _customerName = _loadCustomerName();
  }

  @override
  void didUpdateWidget(covariant CustomerHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId ||
        oldWidget.customerName != widget.customerName) {
      _customerName = _loadCustomerName();
    }
  }

  Future<String?> _loadCustomerName() async {
    final authName = widget.customerName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;

    final customerId = widget.customerId;
    if (customerId == null || customerId.isEmpty) return null;

    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(customerId)
        .get();
    final profileName = profile.data()?['name'];
    return profileName is String && profileName.trim().isNotEmpty
        ? profileName.trim()
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: _selectedTab == 0
                    ? _buildHomeContent(context, constraints.maxWidth)
                    : _buildOtherTab(context, constraints.maxWidth),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: khanLightGold,
        selectedItemColor: khanDark,
        unselectedItemColor: khanSecondaryDark,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, double width) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 28),
          FutureBuilder<String?>(
            future: _customerName,
            builder: (context, snapshot) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.data == null
                        ? 'Discover Khan'
                        : 'Welcome, ${snapshot.data}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: khanDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Your profile name could not be loaded.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: Colors.red.shade700),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSearchField(),
          const SizedBox(height: 30),
          _buildSectionTitle(context, 'Explore categories'),
          const SizedBox(height: 14),
          _buildCategoryGrid(context, width),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: khanLightGold.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Discover thoughtfully crafted jewelry from trusted jewelers.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: khanSecondaryDark, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherTab(BuildContext context, double width) {
    if (_selectedTab == 1) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildSectionTitle(context, 'Explore categories'),
            const SizedBox(height: 14),
            _buildCategoryGrid(context, width),
          ],
        ),
      );
    }

    if (_selectedTab == 2) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildHeader(),
          ),
          Expanded(
            child: _buildEmptyDestination(
              context,
              icon: Icons.favorite_border,
              title: 'Favorites',
              message: 'Your saved jewelry will appear here.',
            ),
          ),
        ],
      );
    }

    return FutureBuilder<String?>(
      future: _customerName,
      builder: (context, snapshot) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildHeader(),
            ),
            Expanded(
              child: _buildEmptyDestination(
                context,
                icon: Icons.person_outline,
                title: snapshot.data ?? 'Profile',
                message: widget.customerEmail ?? 'Signed in to Khan',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: khanDark,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.auto_awesome, color: khanGold, size: 22),
        ),
        const SizedBox(width: 11),
        const Text(
          'KHAN',
          style: TextStyle(
            color: khanDark,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Log out',
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout, color: khanSecondaryDark),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search jewelry or jewelers...',
        hintStyle: const TextStyle(color: khanSecondaryDark),
        prefixIcon: const Icon(Icons.search, color: khanSecondaryDark),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: khanGold.withValues(alpha: 0.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: khanGold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, double width) {
    final crossAxisCount = width < 600
        ? 2
        : width < 900
        ? 3
        : 6;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: JewelryCategory.values.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: width < 600 ? 1.15 : 0.95,
      ),
      itemBuilder: (context, index) {
        final category = JewelryCategory.values[index];
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

  Widget _buildEmptyDestination(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: khanGold, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: khanSecondaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
