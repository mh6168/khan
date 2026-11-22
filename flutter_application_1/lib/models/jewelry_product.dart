import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/gold_price_service.dart';
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
    this.model,
    this.watchType,
    this.caseMaterial,
    this.dialColor,
    this.movementType,
    this.origin,
    this.currentPremium,
    this.originalPremium,
    this.threeDModelUrl,
    this.createdAt,
    this.availability = 'available',
  });

  factory JewelryProduct.fromFirestore(
    String id,
    Map<String, dynamic> data, {
    Map<int, double> goldPrices = const {},
  }) {
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
      priceEgp: productType == 'watch'
          ? _doubleValue(data['price'])
          : GoldPriceService.calculateJewelryPrice(
              goldWeight: _doubleValue(data['goldWeight']),
              goldKarat: _intValue(data['goldKarat']),
              currentPremium: _doubleValue(data['currentPremium']),
              goldPrices: goldPrices,
            ),
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
      model: model,
      watchType: _stringValue(data['watchType']),
      caseMaterial: _stringValue(data['caseMaterial']),
      dialColor: _stringValue(data['dialColor']),
      movementType: _stringValue(data['movementType']),
      origin: _stringValue(data['countryOfOrigin']),
      currentPremium: _doubleValue(data['currentPremium']),
      originalPremium: _doubleValue(data['originalPremium']),
      threeDModelUrl: _stringValue(data['threeDModelUrl']),
      createdAt: _dateValue(data['createdAt']),
      availability: _stringValue(data['availability']) ?? 'available',
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
  final String? model;
  final String? watchType;
  final String? caseMaterial;
  final String? dialColor;
  final String? movementType;
  final String? origin;
  final double? currentPremium;
  final double? originalPremium;
  final String? threeDModelUrl;
  final DateTime? createdAt;
  final String availability;

  bool get canReserve =>
      (productType == 'jewelry' || productType == 'watch') &&
      availability == 'available';

  JewelryProduct copyWithImageUrls(List<String> urls) {
    return JewelryProduct(
      id: id,
      name: name,
      category: category,
      priceEgp: priceEgp,
      artworkIcon: artworkIcon,
      artworkColor: artworkColor,
      productType: productType,
      imageUrls: urls,
      jewelerId: jewelerId,
      description: description,
      goldKarat: goldKarat,
      goldColor: goldColor,
      totalWeight: totalWeight,
      goldWeight: goldWeight,
      brand: brand,
      model: model,
      watchType: watchType,
      caseMaterial: caseMaterial,
      dialColor: dialColor,
      movementType: movementType,
      origin: origin,
      currentPremium: currentPremium,
      originalPremium: originalPremium,
      threeDModelUrl: threeDModelUrl,
      createdAt: createdAt,
      availability: availability,
    );
  }

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
