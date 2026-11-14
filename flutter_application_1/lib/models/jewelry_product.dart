import 'package:flutter/material.dart';

class JewelryProduct {
  const JewelryProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.priceEgp,
    required this.artworkIcon,
    required this.artworkColor,
  });

  final String id;
  final String name;
  final String category;
  final int priceEgp;
  final IconData artworkIcon;
  final Color artworkColor;
}
