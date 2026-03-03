import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String selectedGender = 'female';
  String selectedFeeling = 'happy';
  int currentStep = 1;

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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: currentStep == 1 ? _buildGenderStep() : _buildFeelingStep(),
      ),
    );
  }

  Widget _buildGenderStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBackButton(),
              Text(
                '1 of 2',
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
          Text(
            'Choose Your\nGender',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              height: 1.2,
            ),
          ),
          const SizedBox(height: 48),
          // Gender cards
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGenderCard(
                emoji: '🧔',
                label: 'Male',
                value: 'male',
                bgColor: const Color(0xFFE8F4FF),
              ),
              const SizedBox(width: 16),
              _buildGenderCard(
                emoji: '👩',
                label: 'Female',
                value: 'female',
                bgColor: const Color(0xFFFFE8F0),
              ),
            ],
          ),
          const Spacer(),
          // Arrow button
          _buildArrowButton(() {
            setState(() => currentStep = 2);
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeelingStep() {
    final selectedIndex = feelings.indexWhere((f) => f['value'] == selectedFeeling);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBackButton(onPressed: () => setState(() => currentStep = 1)),
              Text(
                '2 of 2',
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
          Text(
            'How Are You\nFeeling Today',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          // Subtitle
          Text(
            'This feeling tracker allows you to analyse\nyour state of mind.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
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
          // Arrow button
          _buildArrowButton(_goToHome),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBackButton({VoidCallback? onPressed}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).pop(),
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

  Widget _buildGenderCard({
    required String emoji,
    required String label,
    required String value,
    required Color bgColor,
  }) {
    final isSelected = selectedGender == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => selectedGender = value),
      child: Container(
        width: 130,
        height: 160,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? Colors.black.withOpacity(0.12)
                : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 28 : 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected 
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
        ),
        child: Stack(
          children: [
            // Background arc
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: bgColor.withOpacity(isDark ? 0.3 : 1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                    bottom: Radius.elliptical(150, 80),
                  ),
                ),
              ),
            ),
            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Text(emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
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
    );
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
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
