import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class OnboardingDialog extends StatefulWidget {
  final VoidCallback? onCompleted;

  const OnboardingDialog({super.key, this.onCompleted});

  static Future<void> show(BuildContext context, {VoidCallback? onCompleted}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: OnboardingDialog(onCompleted: onCompleted),
      ),
    );
  }

  static Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool('sayn_onboarding_completed') ?? false);
    } catch (_) {
      return false;
    }
  }

  static Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sayn_onboarding_completed', true);
    } catch (_) {}
  }

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Welcome to SAYN',
      'subtitle': 'Zero-friction voice intelligence that formats spoken thoughts directly into your Android apps.',
      'icon': Icons.graphic_eq_rounded,
      'color': SaynColors.darkAccent,
    },
    {
      'title': 'Floating Voice Pill',
      'subtitle': 'Dictate anywhere without switching apps. Tap or hold the floating capsule to speak into WhatsApp, Notes, or Chrome.',
      'icon': Icons.layers_rounded,
      'color': SaynColors.roseMaroon,
    },
    {
      'title': 'Samsung One UI Keyboard',
      'subtitle': 'Custom layout with spacebar cursor trackpad, clipboard history drawer, and one-tap voice flow.',
      'icon': Icons.keyboard_rounded,
      'color': Colors.amber,
    },
    {
      'title': 'Privacy & Real-Time Sync',
      'subtitle': 'Local-first architecture with zero audio retention. Custom dictionary and snippets sync seamlessly across devices.',
      'icon': Icons.shield_rounded,
      'color': Colors.greenAccent,
    },
  ];

  void _finish() async {
    await OnboardingDialog.markCompleted();
    if (mounted) {
      Navigator.of(context).pop();
      widget.onCompleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1C1A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Step indicators & Skip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(_totalSteps, (index) {
                    final isActive = index == _currentStep;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: isActive ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive ? SaynColors.darkAccent : Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                GestureDetector(
                  onTap: _finish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Animated Icon Spotlight
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (step['color'] as Color).withOpacity(0.15),
                border: Border.all(color: (step['color'] as Color).withOpacity(0.3), width: 1.5),
              ),
              child: Icon(
                step['icon'] as IconData,
                size: 40,
                color: step['color'] as Color,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              step['title'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              step['subtitle'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),

            // Navigation Buttons
            Row(
              children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.white.withOpacity(0.18)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Previous',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < _totalSteps - 1) {
                        setState(() {
                          _currentStep++;
                        });
                      } else {
                        _finish();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _currentStep < _totalSteps - 1 ? 'Next' : 'Get Started',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
