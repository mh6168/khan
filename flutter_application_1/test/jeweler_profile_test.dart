import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/jeweler_service.dart';
import 'package:flutter_application_1/data/product_service.dart';
import 'package:flutter_application_1/models/jeweler_profile.dart';
import 'package:flutter_application_1/models/jewelry_product.dart';
import 'package:flutter_application_1/screens/jeweler_profile_screen.dart';
import 'package:flutter_application_1/screens/product_details_screen.dart';

class _FakeJewelerService extends JewelerService {
  _FakeJewelerService(this.profiles);

  final Map<String, JewelerProfile?> profiles;

  @override
  Future<JewelerProfile?> fetchApprovedJeweler(String jewelerId) async {
    return profiles[jewelerId];
  }
}

class _FakeProductService extends ProductService {
  _FakeProductService(this.products);

  final Map<String, List<JewelryProduct>> products;
  final requestedJewelerIds = <String>[];

  @override
  Future<List<JewelryProduct>> fetchAvailableProductsForJeweler(
    String jewelerId,
  ) async {
    requestedJewelerIds.add(jewelerId);
    return products[jewelerId] ?? const [];
  }
}

class _FailingJewelerService extends JewelerService {
  @override
  Future<JewelerProfile?> fetchApprovedJeweler(String jewelerId) {
    return Future.error(StateError('Firestore unavailable'));
  }
}

JewelryProduct _product({
  required String id,
  required String name,
  required String jewelerId,
}) {
  return JewelryProduct(
    id: id,
    name: name,
    category: 'Rings',
    priceEgp: 12500,
    artworkIcon: Icons.diamond_outlined,
    artworkColor: const Color(0xFF605444),
    jewelerId: jewelerId,
  );
}

void main() {
  const profile = JewelerProfile(
    id: 'jeweler-1',
    status: 'approved',
    storeName: 'Cairo Gold House',
    fullName: 'Store Owner',
    phone: '01000000000',
    location: 'Cairo',
  );

  test('maps approved application fields without document paths', () {
    final mapped = JewelerProfile.fromFirestore('jeweler-1', {
      'status': 'approved',
      'storeName': 'Cairo Gold House',
      'fullName': 'Store Owner',
      'phone': '01000000000',
      'storeAddress': 'Cairo',
      'nationalIdPath': 'private/national-id.pdf',
    });

    expect(mapped.isVerified, isTrue);
    expect(mapped.displayName, 'Cairo Gold House');
    expect(mapped.location, 'Cairo');
    expect(mapped.phone, '01000000000');
    expect(mapped.description, isNull);
    expect(mapped.logoUrl, isNull);
  });

  testWidgets('listed-by section opens store and store products open details', (
    tester,
  ) async {
    final ring = _product(
      id: 'ring-1',
      name: 'Golden Ring',
      jewelerId: 'jeweler-1',
    );
    final otherRing = _product(
      id: 'ring-2',
      name: 'Pearl Ring',
      jewelerId: 'jeweler-1',
    );
    final jewelerService = _FakeJewelerService({'jeweler-1': profile});
    final productService = _FakeProductService({
      'jeweler-1': [otherRing],
      'jeweler-2': [
        _product(
          id: 'ring-3',
          name: 'Other Store Ring',
          jewelerId: 'jeweler-2',
        ),
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsScreen(
          product: ring,
          jewelerService: jewelerService,
          productService: productService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Listed By'), findsOneWidget);
    expect(find.text('Cairo Gold House'), findsOneWidget);
    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text('Verified jeweler'), findsOneWidget);

    await tester.ensureVisible(find.text('Cairo Gold House'));
    await tester.tap(find.text('Cairo Gold House'));
    await tester.pumpAndSettle();

    expect(find.byType(JewelerProfileScreen), findsOneWidget);
    expect(find.text('Products by this Jeweler'), findsOneWidget);
    expect(find.text('Pearl Ring'), findsOneWidget);
    expect(find.text('Other Store Ring'), findsNothing);
    expect(productService.requestedJewelerIds, ['jeweler-1']);
    expect(find.text('12500 EGP'), findsOneWidget);

    await tester.ensureVisible(find.text('Pearl Ring'));
    await tester.tap(find.text('Pearl Ring'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(find.text('Pearl Ring'), findsOneWidget);
    expect(find.text('Cairo Gold House'), findsOneWidget);
    expect(find.text('12500 EGP'), findsOneWidget);
  });

  testWidgets('shows missing jeweler fallback when product has no owner', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsScreen(
          product: _product(id: 'ring-1', name: 'Golden Ring', jewelerId: ''),
          jewelerService: _FakeJewelerService(const {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Listed By'), findsOneWidget);
    expect(
      find.text('Seller information is not available for this item.'),
      findsOneWidget,
    );
  });

  testWidgets('shows empty product state and loading indicator', (
    tester,
  ) async {
    final profileCompleter = Completer<JewelerProfile?>();
    final productsCompleter = Completer<List<JewelryProduct>>();
    final jewelerService = _CompleterJewelerService(profileCompleter);
    final productService = _CompleterProductService(productsCompleter);

    await tester.pumpWidget(
      MaterialApp(
        home: JewelerProfileScreen(
          jewelerId: 'jeweler-1',
          jewelerService: jewelerService,
          productService: productService,
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    profileCompleter.complete(profile);
    productsCompleter.complete(const []);
    await tester.pumpAndSettle();

    expect(find.text('Cairo Gold House'), findsOneWidget);
    expect(
      find.text('This jeweler has no available products right now.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a friendly message when jeweler retrieval fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: JewelerProfileScreen(
          jewelerId: 'jeweler-1',
          jewelerService: _FailingJewelerService(),
          productService: _FakeProductService(const {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Store information could not be loaded. Please try again.'),
      findsOneWidget,
    );
  });
}

class _CompleterJewelerService extends JewelerService {
  _CompleterJewelerService(this.completer);

  final Completer<JewelerProfile?> completer;

  @override
  Future<JewelerProfile?> fetchApprovedJeweler(String jewelerId) {
    return completer.future;
  }
}

class _CompleterProductService extends ProductService {
  _CompleterProductService(this.completer);

  final Completer<List<JewelryProduct>> completer;

  @override
  Future<List<JewelryProduct>> fetchAvailableProductsForJeweler(
    String jewelerId,
  ) {
    return completer.future;
  }
}
