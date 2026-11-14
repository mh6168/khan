import 'package:flutter/material.dart';

import '../../models/investment_demo_data.dart';
import 'investment_unit_card.dart';

class ParaCard extends StatelessWidget {
  const ParaCard({super.key, required this.onBuyTap});

  final VoidCallback onBuyTap;

  @override
  Widget build(BuildContext context) {
    return InvestmentUnitCard(unit: paraDemo, onBuyTap: onBuyTap);
  }
}
