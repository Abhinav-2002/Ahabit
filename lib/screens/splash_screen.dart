import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_name_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _badgesController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoTranslateAnimation;
  late Animation<double> _badgesFadeAnimation;
  late Animation<double> _badgesTranslateAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller - 800ms
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Badges animation controller - 600ms with 400ms delay
    _badgesController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    _logoTranslateAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Badges animations
    _badgesFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgesController, curve: Curves.easeOut),
    );

    _badgesTranslateAnimation = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(parent: _badgesController, curve: Curves.easeOut),
    );

    // Start logo animation
    _logoController.forward();

    // Start badges animation after 400ms delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _badgesController.forward();
      }
    });

    // Navigate after 3.5 seconds - check isFirstTime from SharedPreferences
    Future.delayed(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
      
      if (isFirstTime) {
        // First time user → Onboarding Name screen (Welcome removed)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingNameScreen()),
        );
      } else {
        // Returning user → Home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _badgesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF6B8A), // Primary Pink
              Color(0xFFFF4757), // Deep Pink
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Center content
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _logoTranslateAnimation.value),
                    child: FadeTransition(
                      opacity: _logoFadeAnimation,
                      child: ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo box with A and checkmark
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: CustomPaint(
                                  size: const Size(48, 48),
                                  painter: ALogoPainter(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            
                            // App name
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'A',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Habit',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Tagline
                            Text(
                              'Build better. One day at a time.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom badges
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _badgesController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _badgesTranslateAnimation.value),
                    child: FadeTransition(
                      opacity: _badgesFadeAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badges row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBadge('✓ No Ads'),
                              const SizedBox(width: 8),
                              _buildBadge('✓ No Login'),
                              const SizedBox(width: 8),
                              _buildBadge('✓ No Subscription'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Free forever text
                          Text(
                            'Free Forever 🌱',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Custom painter for A logo with checkmark
class ALogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B8A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Draw letter A shape
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Left stroke of A
    path.moveTo(centerX - 16, centerY + 16);
    path.lineTo(centerX, centerY - 16);
    
    // Right stroke of A
    path.moveTo(centerX, centerY - 16);
    path.lineTo(centerX + 16, centerY + 16);
    
    canvas.drawPath(path, paint);
    
    // Draw checkmark across the A (instead of crossbar)
    final checkPaint = Paint()
      ..color = const Color(0xFFFF6B8A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final checkPath = Path();
    checkPath.moveTo(centerX - 10, centerY + 2);
    checkPath.lineTo(centerX - 2, centerY + 8);
    checkPath.lineTo(centerX + 12, centerY - 6);
    
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
