import 'package:flutter/material.dart';

import '../../khan_colors.dart';
import '../../models/investment_demo_data.dart';
import 'demo_data_badge.dart';

class PerformanceChart extends StatelessWidget {
  const PerformanceChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: khanGold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
              ),
              const DemoDataBadge(compact: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Illustrative portfolio trend · sample data',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: khanSecondaryDark.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+6.8%',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'sample period',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: khanSecondaryDark.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: _PerformanceChartPainter(investmentPerformanceDemo),
            ),
          ),
          const SizedBox(height: 9),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChartDateLabel('JUN'),
              _ChartDateLabel('JUL'),
              _ChartDateLabel('AUG'),
              _ChartDateLabel('SEP'),
              _ChartDateLabel('OCT'),
              _ChartDateLabel('NOV'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartDateLabel extends StatelessWidget {
  const _ChartDateLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: khanSecondaryDark.withValues(alpha: 0.58),
        letterSpacing: 0.7,
      ),
    );
  }
}

class _PerformanceChartPainter extends CustomPainter {
  const _PerformanceChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Offset.zero & size;
    final gridPaint = Paint()
      ..color = khanDark.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var line = 0; line < 4; line++) {
      final y = size.height * line / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - (values[i] * size.height * 0.88) - 5;
      points.add(Offset(x, y));
    }

    final curve = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      curve.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(curve)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          khanGold.withValues(alpha: 0.28),
          khanGold.withValues(alpha: 0),
        ],
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(
      curve,
      Paint()
        ..color = khanGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      points.last,
      4,
      Paint()
        ..color = khanDark
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      points.last,
      2,
      Paint()
        ..color = khanGold
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _PerformanceChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
