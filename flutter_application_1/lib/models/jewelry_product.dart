import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/supabase_storage.dart';

class JewelryProduct {
  const JewelryProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.priceEgp,
    required this.artworkIcon,
    required this.artworkColor,
    this.productType = 'jewelry',
    this.imageUrls = const [],
    this.jewelerId,
    this.description,
    this.goldKarat,
    this.goldColor,
    this.totalWeight,
    this.goldWeight,
    this.brand,
    this.origin,
    this.threeDModelUrl,
    this.createdAt,
  });

  factory JewelryProduct.fromFirestore(String id, Map<String, dynamic> data) {
    final productType = data['productType'] == 'watch' ? 'watch' : 'jewelry';
    final brand = _stringValue(data['brand']);
    final model = _stringValue(data['model']);
    final title = _stringValue(data['title']);
    final name = productType == 'watch'
        ? [brand, model].whereType<String>().join(' ').trim()
        : title;
    final displayName = name ?? '';
    final category = productType == 'watch'
        ? 'Watches'
        : (_stringValue(data['category']) ?? 'Jewelry');

    return JewelryProduct(
      id: id,
      name: displayName.isEmpty ? 'Jewelry piece' : displayName,
      category: category,
      priceEgp: productType == 'watch' ? _doubleValue(data['price']) : null,
      artworkIcon: productType == 'watch'
          ? Icons.watch_outlined
          : Icons.diamond_outlined,
      artworkColor: productType == 'watch'
          ? const Color(0xFF59483C)
          : const Color(0xFF605444),
      productType: productType,
      imageUrls: publicSupabaseImageUrls(data['photoPaths']),
      jewelerId: _stringValue(data['jewelerId']),
      goldKarat: _intValue(data['goldKarat']),
      goldColor: _stringValue(data['goldColor']),
      totalWeight: _doubleValue(data['totalWeight']),
      goldWeight: _doubleValue(data['goldWeight']),
      brand: brand,
      origin: _stringValue(data['countryOfOrigin']),
      threeDModelUrl: _stringValue(data['threeDModelUrl']),
      createdAt: _dateValue(data['createdAt']),
    );
  }

  final String id;
  final String name;
  final String category;
  final double? priceEgp;
  final IconData artworkIcon;
  final Color artworkColor;
  final String productType;
  final List<String> imageUrls;
  final String? jewelerId;
  final String? description;
  final int? goldKarat;
  final String? goldColor;
  final double? totalWeight;
  final double? goldWeight;
  final String? brand;
  final String? origin;
  final String? threeDModelUrl;
  final DateTime? createdAt;

  static String? _stringValue(dynamic value) {
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  static double? _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
