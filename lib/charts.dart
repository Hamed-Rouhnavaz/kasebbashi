import 'dart:math' as math;

import 'package:flutter/material.dart';

/// مبلغ را کوتاه می‌کند: م = میلیون، ه = هزار
String shortMoney(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} م';
  if (v >= 1000) return '${(v / 1000).round()} ه';
  return '$v';
}

class BarItem {
  final String label;
  final String sub;
  final int value;
  const BarItem(this.label, this.sub, this.value);
}

class BarChartView extends StatelessWidget {
  final List<BarItem> items;
  final Color color;
  final double height;

  const BarChartView({
    super.key,
    required this.items,
    required this.color,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<int>(0, (m, i) => math.max(m, i.value));
    final barArea = height - 60;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final i in items)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    i.value == 0 ? '' : shortMoney(i.value),
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: maxValue == 0
                        ? 2
                        : math.max(2, barArea * i.value / maxValue),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(i.label, style: const TextStyle(fontSize: 11)),
                  Text(
                    i.sub,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class DonutChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final Widget? center;
  final double size;

  const DonutChart({
    super.key,
    required this.values,
    required this.colors,
    this.center,
    this.size = 130,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(values, colors),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter(this.values, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final total = values.fold<double>(0, (a, b) => a + b);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    if (total <= 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }

    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = 2 * math.pi * values[i] / total;
      paint.color = colors[i];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
