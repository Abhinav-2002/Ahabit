import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

class OnboardingFeelingScreen extends StatefulWidget {
  const OnboardingFeelingScreen({super.key});

  @override
  State<OnboardingFeelingScreen> createState() => _OnboardingFeelingScreenState();
}

class _OnboardingFeelingScreenState extends State<OnboardingFeelingScreen> {
  String selectedFeeling = 'happy';

  final List<Map<String, dynamic>> feelings = [
    {'emoji': '😢', 'label': 'Sad', 'value': 'sad'},
    {'emoji': '😕', 'label': 'Worried', 'value': 'worried'},
    {'emoji': '😂', 'label': 'Happy', 'value': 'happy'},
    {'emoji': '😎', 'label': 'Cool', 'value': 'cool'},
    {'emoji': '🥳', 'label': 'Excited', 'value': 'excited'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = feelings.indexWhere((f) => f['value'] == selectedFeeling);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0F3), // Pinkish background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBackButton(),
                  Text(
                    '3 of 3',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: _goToHome,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF888888),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Title
              const Text(
                'How Are You\nFeeling Today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'This feeling tracker allows you to analyse\nyour state of mind.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF888888),
                ),
              ),
              const SizedBox(height: 48),

              // Feeling emojis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: feelings.map((feeling) {
                  final isSelected = selectedFeeling == feeling['value'];
                  return GestureDetector(
                    onTap: () => setState(() => selectedFeeling = feeling['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: isSelected
                        ? Matrix4.diagonal3Values(1.4, 1.4, 1)
                        : Matrix4.diagonal3Values(1, 1, 1),
                      child: Text(
                        feeling['emoji'],
                        style: TextStyle(
                          fontSize: 36,
                          color: isSelected ? null : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Selected feeling label
              Text(
                feelings[selectedIndex]['label'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF6B8A),
                ),
              ),
              const SizedBox(height: 32),

              // Arc indicator
              SizedBox(
                width: 280,
                height: 60,
                child: CustomPaint(
                  painter: ArcPainter(
                    position: selectedIndex / (feelings.length - 1),
                    color: const Color(0xFFFF6584),
                  ),
                ),
              ),

              const Spacer(),

              // Arrow button - pink theme
              GestureDetector(
                onTap: _goToHome,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF6B8A),
                        Color(0xFFFF4757),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF6B8A).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
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

  Widget _buildBackButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_back, size: 16),
      ),
    );
  }

  void _goToHome() async {
    // Mark onboarding as complete
    await context.read<UserProvider>().setOnboardingComplete();
    
    // Mark as returning user (no longer first time)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }
}

class ArcPainter extends CustomPainter {
  final double position;
  final Color color;

  ArcPainter({required this.position, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(10, size.height - 5)
      ..quadraticBezierTo(size.width / 2, -10, size.width - 10, size.height - 5);

    canvas.drawPath(path, paint);

    // Draw indicator circle
    final indicatorX = 10 + (size.width - 20) * position;
    final indicatorY = size.height - 5 - math.sin(position * math.pi) * (size.height + 5);

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(indicatorX, indicatorY), 6, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
