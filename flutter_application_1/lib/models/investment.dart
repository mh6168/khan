import 'package:flutter/material.dart';

class InvestmentPrices {
  const InvestmentPrices({
    required this.spotMinor,
    required this.purchaseMinor,
    required this.buybackMinor,
  });

  factory InvestmentPrices.fromSpot(int spotMinor) {
    return InvestmentPrices(
      spotMinor: spotMinor,
      purchaseMinor: spotMinor + 500,
      buybackMinor: spotMinor + 100,
    );
  }

  final int spotMinor;
  final int purchaseMinor;
  final int buybackMinor;
}

class InvestmentPriceSnapshot {
  const InvestmentPriceSnapshot({
    required this.lira,
    required this.para,
    required this.updatedAt,
  });

  final InvestmentPrices lira;
  final InvestmentPrices para;
  final DateTime updatedAt;
}

class InvestmentUnit {
  const InvestmentUnit({
    required this.name,
    required this.description,
    required this.spotMinor,
    required this.purchaseMinor,
    required this.buybackMinor,
    required this.availableQuantity,
    required this.icon,
    required this.accent,
    this.definition,
  });

  final String name;
  final String description;
  final int spotMinor;
  final int purchaseMinor;
  final int buybackMinor;
  final int availableQuantity;
  final IconData icon;
  final Color accent;
  final String? definition;

  double get spot => spotMinor / 100;
  double get purchasePrice => purchaseMinor / 100;
  double get buybackPrice => buybackMinor / 100;

  String get spotLabel => formatEgpMinor(spotMinor);
  String get purchaseLabel => formatEgpMinor(purchaseMinor);
  String get buybackLabel => formatEgpMinor(buybackMinor);
}

String formatEgpMinor(int value) {
  final whole = value ~/ 100;
  final fraction = (value.abs() % 100).toString().padLeft(2, '0');
  final sign = value < 0 ? '-' : '';
  return 'EGP $sign$whole.$fraction';
}

class InvestmentPortfolio {
  const InvestmentPortfolio({this.liraQuantity = 0, this.paraQuantity = 0});

  final int liraQuantity;
  final int paraQuantity;
}

class InvestmentActivity {
  const InvestmentActivity({
    required this.unit,
    required this.type,
    required this.date,
    required this.quantity,
    required this.status,
  });

  final String unit;
  final String type;
  final DateTime? date;
  final int quantity;
  final String status;
}
