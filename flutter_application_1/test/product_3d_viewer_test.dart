import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/jewelry_product.dart';
import 'package:flutter_application_1/screens/product_details_screen.dart';
import 'package:flutter_application_1/widgets/product_3d_viewer.dart';

void main() {
  test('converts a Sketchfab model page into its embed URL', () {
    final uri = threeDModelViewerUri(
      'https://sketchfab.com/3d-models/ring-1234567890abcdef1234567890abcdef',
    );

    expect(
      uri.toString(),
      'https://sketchfab.com/models/1234567890abcdef1234567890abcdef/embed',
    );
  });

  test('keeps existing embed and other HTTPS viewer URLs', () {
    const sketchfabEmbed =
        'https://sketchfab.com/models/1234567890abcdef1234567890abcdef/embed';
    const customViewer = 'https://models.example.com/product/ring';

    expect(threeDModelViewerUri(sketchfabEmbed).toString(), sketchfabEmbed);
    expect(threeDModelViewerUri(customViewer).toString(), customViewer);
  });

  test('rejects missing and insecure model URLs', () {
    expect(threeDModelViewerUri(null), isNull);
    expect(threeDModelViewerUri('http://models.example.com/ring'), isNull);
    expect(threeDModelViewerUri('not a url'), isNull);
  });

  testWidgets('hides the 3D action when a product has no model URL', (
    tester,
  ) async {
    final product = JewelryProduct(
      id: 'ring-1',
      name: 'Golden Ring',
      category: 'Rings',
      priceEgp: 12500,
      artworkIcon: Icons.diamond_outlined,
      artworkColor: const Color(0xFF605444),
    );

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailsScreen(product: product)),
    );
    await tester.pumpAndSettle();

    expect(find.text('View in 3D'), findsNothing);
    expect(find.text('Hide 3D Model'), findsNothing);
  });
}
