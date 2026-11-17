import 'package:flutter/material.dart';

import '../../khan_colors.dart';

class PerformanceChart extends StatelessWidget {
  const PerformanceChart({super.key, required this.values});

  final List<double> values;

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
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Actual saved investment price history',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: khanSecondaryDark.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 18),
          if (values.length < 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'Your investment performance will appear here as price history becomes available.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            Text(
              '${((values.last - values.first) / values.first * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 13),
            SizedBox(
              height: 150,
              width: double.infinity,
              child: CustomPaint(
                painter: _PerformanceChartPainter(values),
              ),
            ),
          ],
        ],
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
