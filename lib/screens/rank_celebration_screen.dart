import 'package:flutter/material.dart';
import 'dart:math' as math;

class RankCelebrationScreen extends StatefulWidget {
  final String rankName;
  final int totalCompletions;

  const RankCelebrationScreen({
    super.key,
    required this.rankName,
    required this.totalCompletions,
  });

  @override
  State<RankCelebrationScreen> createState() => _RankCelebrationScreenState();
}

class _RankCelebrationScreenState extends State<RankCelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti
            ...List.generate(30, (index) {
              final random = math.Random(index);
              final colors = [
                const Color(0xFFFF6584),
                const Color(0xFFFFD166),
                const Color(0xFF4CAF50),
                const Color(0xFF4DABF7),
                const Color(0xFF845EF7),
                const Color(0xFFC8F53C),
                const Color(0xFFFF9F43),
              ];
              return Positioned(
                left: random.nextDouble() * MediaQuery.of(context).size.width,
                top: -20,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final fallProgress = (_pulseController.value + random.nextDouble()) % 1.0;
                    return Transform.translate(
                      offset: Offset(
                        0,
                        fallProgress * MediaQuery.of(context).size.height * 1.2,
                      ),
                      child: Transform.rotate(
                        angle: fallProgress * 4 * math.pi + random.nextDouble() * math.pi,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    width: 8 + random.nextDouble() * 8,
                    height: 8 + random.nextDouble() * 8,
                    decoration: BoxDecoration(
                      color: colors[random.nextInt(colors.length)],
                      borderRadius: random.nextBool()
                        ? BorderRadius.circular(2)
                        : null,
                    ),
                  ),
                ),
              );
            }),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = 1 + math.sin(_pulseController.value * 2 * math.pi) * 0.04;
                      return Transform.scale(
                        scale: scale,
                        child: Transform.rotate(
                          angle: math.pi / 4,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF9E14B), Color(0xFFF0C520)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF0C520).withOpacity(0.4),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: -math.pi / 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.rankName == 'Pro'
                                  ? Icons.workspace_premium
                                  : Icons.emoji_events,
                                size: 48,
                                color: const Color(0xFF7A5A00),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.totalCompletions.toString(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF7A5A00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Title
                  Text(
                    'New Award! 🏆',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rank text
                  Text(
                    'You reached ${widget.rankName} level!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: widget.rankName == 'Pro'
                        ? const Color(0xFF2196F3)
                        : (widget.rankName == 'Advanced'
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF888888)),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Keep building those habits!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Continue button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continue',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                        ],
                      ),
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
}
