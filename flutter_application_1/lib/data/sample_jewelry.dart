import 'package:flutter/material.dart';

import '../models/jewelry_product.dart';

const trendingJewelry = [
  JewelryProduct(
    id: 'nile-light-ring',
    name: 'Nile Light Ring',
    category: 'Rings',
    priceEgp: 12800,
    artworkIcon: Icons.circle_outlined,
    artworkColor: Color(0xFF69503A),
  ),
  JewelryProduct(
    id: 'desert-bloom',
    name: 'Desert Bloom',
    category: 'Earrings',
    priceEgp: 9400,
    artworkIcon: Icons.hearing_outlined,
    artworkColor: Color(0xFF735A42),
  ),
  JewelryProduct(
    id: 'cairo-links',
    name: 'Cairo Links',
    category: 'Bracelets',
    priceEgp: 15600,
    artworkIcon: Icons.watch_outlined,
    artworkColor: Color(0xFF4A5551),
  ),
];

const newArrivals = [
  JewelryProduct(
    id: 'lotus-pendant',
    name: 'Lotus Pendant',
    category: 'Pendants',
    priceEgp: 11200,
    artworkIcon: Icons.diamond_outlined,
    artworkColor: Color(0xFF605444),
  ),
  JewelryProduct(
    id: 'moonlit-chain',
    name: 'Moonlit Chain',
    category: 'Necklaces',
    priceEgp: 18400,
    artworkIcon: Icons.cable_outlined,
    artworkColor: Color(0xFF46504F),
  ),
  JewelryProduct(
    id: 'heritage-watch',
    name: 'Heritage Watch',
    category: 'Watches',
    priceEgp: 22900,
    artworkIcon: Icons.watch,
    artworkColor: Color(0xFF59483C),
  ),
];

const sampleJewelry = [...trendingJewelry, ...newArrivals];
