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

  String get spotLabel => 'EGP ${spot.toStringAsFixed(2)}';
  String get purchaseLabel => 'EGP ${purchasePrice.toStringAsFixed(2)}';
  String get buybackLabel => 'EGP ${buybackPrice.toStringAsFixed(2)}';
}

class InvestmentPortfolio {
  const InvestmentPortfolio({
    this.liraQuantity = 0,
    this.paraQuantity = 0,
  });

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
