import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'onboarding_name_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              // Floating emojis area
              SizedBox(
                height: 300,
                child: Stack(
                  children: [
                    // Curved path
                    CustomPaint(
                      size: const Size(double.infinity, 300),
                      painter: WelcomeCurvePainter(isDark: isDark),
                    ),
                    // Floating emojis
                    ..._buildFloatingEmojis(),
                  ],
                ),
              ),
              const Spacer(),
              // Welcome text
              Text(
                'Welcome To The\nHabit Tracker',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              // Get Start button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OnboardingNameScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F53C),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8F53C).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Get Start',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF111111),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF111111),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFFC8F53C),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingEmojis() {
    final emojis = [
      {'emoji': '💪', 'top': 80.0, 'left': 50.0, 'delay': 0.3, 'size': 32.0},
      {'emoji': '📚', 'top': 60.0, 'left': 170.0, 'delay': 0.9, 'size': 28.0},
      {'emoji': '🏃', 'top': 100.0, 'right': 45.0, 'delay': 0.5, 'size': 30.0},
      {'emoji': '🌙', 'top': 200.0, 'left': 30.0, 'delay': 1.2, 'size': 26.0},
      {'emoji': '💧', 'top': 180.0, 'right': 35.0, 'delay': 0.7, 'size': 28.0},
      {'emoji': '🎯', 'top': 260.0, 'left': 130.0, 'delay': 1.5, 'size': 24.0},
      {'emoji': '🔥', 'top': 140.0, 'left': 85.0, 'delay': 0.4, 'size': 22.0},
      {'emoji': '🚀', 'top': 300.0, 'right': 60.0, 'delay': 1.0, 'size': 26.0},
    ];

    return emojis.map((data) {
      return AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          final yOffset = math.sin((_floatController.value * 2 * math.pi) + (data['delay'] as double)) * 8;
          return Positioned(
            top: (data['top'] as double) + yOffset,
            left: data['left'] as double?,
            right: data['right'] as double?,
            child: Text(
              data['emoji'] as String,
              style: TextStyle(fontSize: data['size'] as double),
            ),
          );
        },
      );
    }).toList();
  }
}

class WelcomeCurvePainter extends CustomPainter {
  final bool isDark;

  WelcomeCurvePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFFE0E0E0))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(60, 120)
      ..quadraticBezierTo(size.width * 0.5, 60, size.width - 60, 140)
      ..quadraticBezierTo(size.width - 20, 200, size.width * 0.7, 280)
      ..quadraticBezierTo(size.width * 0.5, 340, size.width * 0.2, 300)
      ..quadraticBezierTo(30, 260, 60, 120);

    final dashPath = _dashPath(path, 6, 4);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, double dashLength, double gapLength) {
    final Path dashed = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        final end = math.min(distance + length, metric.length);
        final segment = metric.extractPath(distance, end);
        if (draw) dashed.addPath(segment, Offset.zero);
        distance += length;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
