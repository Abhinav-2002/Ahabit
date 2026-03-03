import 'dart:math' as math;
import 'package:flutter/material.dart';

class ActivityRings extends StatelessWidget {
  final double progress;
  final double size;
  final Widget child;

  const ActivityRings({
    super.key,
    required this.progress,
    this.size = 160,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring - Pink
          CustomPaint(
            size: Size(size, size),
            painter: RingPainter(
              progress: math.min(progress * 1.2, 1.0),
              color: const Color(0xFFFF6584),
              strokeWidth: 10,
              radius: size / 2 - 10,
              backgroundColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0),
            ),
          ),
          // Middle ring - Orange
          CustomPaint(
            size: Size(size * 0.75, size * 0.75),
            painter: RingPainter(
              progress: math.min(progress * 1.1, 1.0),
              color: const Color(0xFFFF9F43),
              strokeWidth: 10,
              radius: size * 0.75 / 2 - 10,
              backgroundColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0),
            ),
          ),
          // Inner ring - Green
          CustomPaint(
            size: Size(size * 0.5, size * 0.5),
            painter: RingPainter(
              progress: progress,
              color: const Color(0xFF4CAF50),
              strokeWidth: 10,
              radius: size * 0.5 / 2 - 10,
              backgroundColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F0F0),
            ),
          ),
          // Center content
          child,
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double radius;
  final Color backgroundColor;

  RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
