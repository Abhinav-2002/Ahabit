import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'onboarding_gender_screen.dart';

class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final _nameController = TextEditingController();
  bool _isFocused = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasName = _nameController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0F3), // BG Light
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small logo at top left
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: CustomPaint(
                        size: const Size(20, 20),
                        painter: SmallALogoPainter(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF6B8A),
                        ),
                      ),
                      Text(
                        'Habit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFF6B8A).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Center content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emoji
                    const Text(
                      '🌸',
                      style: TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'What should we call you?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E), // BG Dark
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      "We'll personalize your experience",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Name input field
                    Focus(
                      onFocusChange: (hasFocus) {
                        setState(() {
                          _isFocused = hasFocus;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isFocused 
                                ? const Color(0xFFFF6B8A) // Primary Pink when focused
                                : const Color(0xFFFFD6E0), // Soft Pink when unfocused
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Your name...',
                            hintStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFFB3C6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, 
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Continue button
              GestureDetector(
                onTap: hasName ? _continueToGender : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: hasName
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFFF6B8A), // Primary Pink
                              Color(0xFFFF4757), // Deep Pink
                            ],
                          )
                        : null,
                    color: hasName ? null : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: hasName
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF4757).withOpacity(0.35),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Continue →',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: hasName ? Colors.white : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _continueToGender() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      context.read<UserProvider>().setUserName(name);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingGenderScreen()),
    );
  }
}

// Small logo painter for top left
class SmallALogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B8A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    path.moveTo(centerX - 7, centerY + 7);
    path.lineTo(centerX, centerY - 7);
    path.moveTo(centerX, centerY - 7);
    path.lineTo(centerX + 7, centerY + 7);
    
    canvas.drawPath(path, paint);
    
    final checkPaint = Paint()
      ..color = const Color(0xFFFF6B8A)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final checkPath = Path();
    checkPath.moveTo(centerX - 4, centerY + 1);
    checkPath.lineTo(centerX - 1, centerY + 4);
    checkPath.lineTo(centerX + 5, centerY - 3);
    
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
