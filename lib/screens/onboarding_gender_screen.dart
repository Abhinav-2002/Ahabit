import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'onboarding_feeling_screen.dart';

class OnboardingGenderScreen extends StatefulWidget {
  const OnboardingGenderScreen({super.key});

  @override
  State<OnboardingGenderScreen> createState() => _OnboardingGenderScreenState();
}

class _OnboardingGenderScreenState extends State<OnboardingGenderScreen> {
  String selectedGender = 'female';

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedGender.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0F3), // BG Light
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
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
                  child: const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Center content - wrapped in Expanded with SingleChildScrollView to prevent overflow
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji
                      const Text(
                        '🌟',
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      const Text(
                        'How do you identify?',
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
                        'This helps us personalize your journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Gender option cards - only Male and Female
                      _buildGenderCard(
                        icon: Icons.male,
                        label: 'Male',
                        subtitle: 'He/Him',
                        value: 'male',
                      ),
                      const SizedBox(height: 16),
                      _buildGenderCard(
                        icon: Icons.female,
                        label: 'Female',
                        subtitle: 'She/Her',
                        value: 'female',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Continue button
              GestureDetector(
                onTap: hasSelection ? _continueToFeeling : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: hasSelection
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFFF6B8A), // Primary Pink
                              Color(0xFFFF4757), // Deep Pink
                            ],
                          )
                        : null,
                    color: hasSelection ? null : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: hasSelection
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
                    hasSelection ? "Let's Go 🎯" : 'Continue →',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: hasSelection ? Colors.white : Colors.white.withOpacity(0.5),
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

  Widget _buildGenderCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required String value,
  }) {
    final isSelected = selectedGender == value;

    return GestureDetector(
      onTap: () => setState(() => selectedGender = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF0F3), // Pink Tint
                    Color(0xFFFFE4EC), // Soft Pink variant
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6B8A) // Primary Pink
                : const Color(0xFFFFD6E0), // Soft Pink
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B8A).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon in circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3), // Pink Tint
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: const Color(0xFFFF6B8A),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Label and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),

            // Radio circle with checkmark
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF6B8A)
                      : const Color(0xFFFFD6E0),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFFF6B8A) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _continueToFeeling() {
    context.read<UserProvider>().setGender(selectedGender);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingFeelingScreen()),
    );
  }
}
