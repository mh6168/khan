import 'package:flutter/material.dart';

import '../../models/investment.dart';
import 'investment_unit_card.dart';

class ParaCard extends StatelessWidget {
  const ParaCard({super.key, required this.unit, required this.onBuyTap});

  final InvestmentUnit unit;
  final VoidCallback onBuyTap;

  @override
  Widget build(BuildContext context) {
    return InvestmentUnitCard(unit: unit, onBuyTap: onBuyTap);
  }
}
