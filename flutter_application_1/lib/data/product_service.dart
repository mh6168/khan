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

    final products = snapshot.docs
        .map(
          (document) => JewelryProduct.fromFirestore(
            document.id,
            document.data(),
            goldPrices: goldPrices,
          ),
        )
        .toList(growable: false);
    final sortedProducts = [...products]
      ..sort(
        (left, right) =>
            (right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                ),
      );
    return sortedProducts;
  }
}
