import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _hasSeenOnboardingKey = 'hasSeenOnboarding';
  static const _splashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    unawaited(_redirectAfterSplash());
  }

  Future<void> _redirectAfterSplash() async {
    final preferences = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        preferences.getBool(_hasSeenOnboardingKey) ?? false;

    await Future<void>.delayed(_splashDuration);

    if (!mounted) return;

    context.go(hasSeenOnboarding ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.42),
              colorScheme.surface,
              colorScheme.secondaryContainer.withValues(alpha: 0.32),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.22),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: const Image(
                        image: AssetImage('assets/logo/logored.png'),
                        width: 52,
                        height: 52,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
                    .scale(
                      begin: const Offset(0.84, 0.84),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 24),
                Text(
                      'ReviewApp',
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                    .animate(delay: 180.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(
                      begin: 0.18,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 8),
                Text(
                  'La voix de votre quartier',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ).animate(delay: 320.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
