import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/typing_indicator.dart';
import '../../../app/router.dart';

/// Splash screen with animated logo
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after 2 seconds if router doesn't handle it
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // The router will handle the actual navigation based on auth state
        context.go(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1025),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Animated logo
              _buildLogo()
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 800.ms,
                    curve: Curves.easeOutBack,
                  ),
              
              const SizedBox(height: 24),
              
              // App name
              Text(
                'Amorae',
                style: AppTextStyles.displayLarge.copyWith(
                  foreground: Paint()
                    ..shader = AppColors.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 200, 70),
                    ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Your AI Companion',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 600.ms),
              
              const Spacer(flex: 2),
              
              // Loading indicator
              const PulsingHeart(size: 28)
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 400.ms),
              
              const SizedBox(height: 16),
              
              Text(
                'Loading...',
                style: AppTextStyles.bodySmall,
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.favorite,
          size: 56,
          color: Colors.white,
        ),
      ),
    );
  }
}
