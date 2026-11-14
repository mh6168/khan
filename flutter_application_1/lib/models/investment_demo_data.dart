import 'package:flutter/material.dart';

class InvestmentUnitDemo {
  const InvestmentUnitDemo({
    required this.name,
    required this.description,
    required this.priceEgp,
    required this.priceLabel,
    required this.icon,
    required this.accent,
    this.definition,
  });

  final String name;
  final String description;
  final int priceEgp;
  final String priceLabel;
  final IconData icon;
  final Color accent;
  final String? definition;
}

class InvestmentActivityDemo {
  const InvestmentActivityDemo({
    required this.unit,
    required this.type,
    required this.date,
    required this.amount,
    required this.status,
    required this.icon,
  });

  final String unit;
  final String type;
  final String date;
  final String amount;
  final String status;
  final IconData icon;
}

const liraDemo = InvestmentUnitDemo(
  name: 'LIRA',
  description: 'Digital gold investment unit',
  definition: '1 LIRA represents 0.01 grams of 24-karat gold.',
  priceEgp: 145,
  priceLabel: 'EGP 145.00',
  icon: Icons.monetization_on_outlined,
  accent: Color(0xFFB88C31),
);

const paraDemo = InvestmentUnitDemo(
  name: 'PARA',
  description: 'Digital precious-metals investment unit',
  priceEgp: 42,
  priceLabel: 'EGP 42.00',
  icon: Icons.auto_awesome_outlined,
  accent: Color(0xFF658087),
);

const investmentPerformanceDemo = [
  0.22,
  0.29,
  0.25,
  0.36,
  0.33,
  0.43,
  0.39,
  0.53,
  0.48,
  0.61,
  0.58,
  0.76,
];

const recentInvestmentActivityDemo = [
  InvestmentActivityDemo(
    unit: 'LIRA',
    type: 'Sample purchase',
    date: '12 Nov 2026',
    amount: '+ 10.00 LIRA',
    status: 'Demo',
    icon: Icons.south_west_rounded,
  ),
  InvestmentActivityDemo(
    unit: 'PARA',
    type: 'Sample allocation',
    date: '08 Nov 2026',
    amount: '+ 25.00 PARA',
    status: 'Demo',
    icon: Icons.south_west_rounded,
  ),
  InvestmentActivityDemo(
    unit: 'LIRA',
    type: 'Sample portfolio entry',
    date: '01 Nov 2026',
    amount: '+ 5.00 LIRA',
    status: 'Demo',
    icon: Icons.auto_graph_rounded,
  ),
];
