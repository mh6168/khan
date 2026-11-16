import 'package:cloud_firestore/cloud_firestore.dart';

import 'gold_price_service.dart';
import '../models/jewelry_product.dart';

class ProductService {
  ProductService({this.firestore});

  final FirebaseFirestore? firestore;

  Future<List<JewelryProduct>> fetchAvailableProducts() async {
    final database = firestore ?? FirebaseFirestore.instance;
    final goldPrices = await const GoldPriceService().fetchPrices();
    final snapshot = await database
        .collection('products')
        .where('availability', isEqualTo: 'available')
        .get();

    return _mapAndSort(snapshot, goldPrices);
  }

  Future<List<JewelryProduct>> fetchAvailableProductsForJeweler(
    String jewelerId,
  ) async {
    final normalizedId = jewelerId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(jewelerId, 'jewelerId', 'Must not be empty.');
    }

    final database = firestore ?? FirebaseFirestore.instance;
    final goldPrices = await const GoldPriceService().fetchPrices();
    final snapshot = await database
        .collection('products')
        .where('jewelerId', isEqualTo: normalizedId)
        .where('availability', isEqualTo: 'available')
        .get();

    return _mapAndSort(snapshot, goldPrices);
  }

  List<JewelryProduct> _mapAndSort(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    Map<int, double> goldPrices,
  ) {
    final products = snapshot.docs
        .map(
          (document) => JewelryProduct.fromFirestore(
            document.id,
            document.data(),
            goldPrices: goldPrices,
          ),
        )
        .toList();
    products.sort(
      (left, right) =>
          (right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
    );
    return List<JewelryProduct>.unmodifiable(products);
  }
}
