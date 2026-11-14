import 'package:flutter/material.dart';

import '../../khan_colors.dart';

class PortfolioOverview extends StatelessWidget {
  const PortfolioOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: khanDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: khanDark.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your portfolio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: khanLightGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.more_horiz_rounded, color: khanLightGold),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            'TOTAL PORTFOLIO VALUE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'EGP 86,420.00',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: khanLightGold,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 74,
            width: double.infinity,
            child: CustomPaint(painter: _PortfolioSparklinePainter()),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _PortfolioMetric(
                  label: 'Available balance',
                  value: 'EGP 12,400',
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              Expanded(
                child: _PortfolioMetric(
                  label: 'Total invested',
                  value: 'EGP 74,020',
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Illustrative portfolio values only · not a live balance',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioMetric extends StatelessWidget {
  const _PortfolioMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: khanGold),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PortfolioSparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(0, size.height * 0.76),
      Offset(size.width * 0.13, size.height * 0.62),
      Offset(size.width * 0.26, size.height * 0.68),
      Offset(size.width * 0.38, size.height * 0.37),
      Offset(size.width * 0.52, size.height * 0.48),
      Offset(size.width * 0.64, size.height * 0.26),
      Offset(size.width * 0.76, size.height * 0.39),
      Offset(size.width * 0.88, size.height * 0.16),
      Offset(size.width, size.height * 0.2),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          khanGold.withValues(alpha: 0.24),
          khanGold.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fill, gradient);

    final linePaint = Paint()
      ..color = khanGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, linePaint);
    canvas.drawCircle(
      points.last,
      4,
      Paint()
        ..color = khanGold
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
