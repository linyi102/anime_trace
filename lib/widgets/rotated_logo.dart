import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class RotatedLogo extends StatefulWidget {
  const RotatedLogo({
    super.key,
    this.size = 64,
    this.color,
    this.rotate = true,
  });
  final double size;
  final Color? color;
  final bool rotate;

  @override
  State<RotatedLogo> createState() => _RotatedLogoState();
}

class _RotatedLogoState extends State<RotatedLogo>
    with SingleTickerProviderStateMixin {
  late final animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );

  @override
  void initState() {
    super.initState();
    if (widget.rotate) animationController.repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RotatedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rotate != widget.rotate) {
      if (oldWidget.rotate) {
        animationController.reset();
      } else {
        animationController.repeat();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(widget.size * 0.24),
      ),
      child: RotationTransition(
        turns: animationController,
        child: SizedBox.square(
          dimension: widget.size,
          child: Transform.rotate(
            angle: pi / 3,
            // RepaintBoundary可以解决shouldRepaint为false时仍然一直paint的问题
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _LogoPainter(
                  centerDot: true,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool centerDot;
  final bool isDark;
  const _LogoPainter({
    this.centerDot = true,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * 0.5;
    final centerOffset = Offset(size.width * 0.5, size.height * 0.5);
    final borderColor =
        isDark ? const Color(0xFFCBCADA) : const Color(0xFF474E55);

    canvas.drawCircle(
      centerOffset,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.03
        ..color = borderColor,
    );

    if (centerDot) {
      canvas.drawPoints(
        PointMode.points,
        [
          centerOffset,
        ],
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = size.width * 0.24
          ..color = borderColor,
      );
    }

    final point = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.2;
    List<Color> colors = [Colors.red, Colors.blue, Colors.green];
    List<Offset> offsets = calculatePointsOnCircle(
        size.width * 0.5, size.height * 0.5, radius, colors.length);
    for (int index = 0; index < colors.length; index++) {
      canvas.drawPoints(
        PointMode.points,
        [
          offsets[index],
        ],
        point..color = colors[index],
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      centerDot != oldDelegate.centerDot || isDark != oldDelegate.isDark;

  @override
  bool shouldRebuildSemantics(_LogoPainter oldDelegate) => false;

  List<Offset> calculatePointsOnCircle(double x, double y, double r, int n) {
    List<Offset> points = [];
    final theta = (2 * pi) / n;
    for (int i = 0; i < n; i++) {
      final cx = r * cos(i * theta);
      final cy = r * sin(i * theta);
      final pointX = x + cx;
      final pointY = y + cy;
      points.add(Offset(pointX, pointY));
    }
    points.sort((a, b) => a.dy < b.dy ? 1 : -1);
    return points;
  }
}
