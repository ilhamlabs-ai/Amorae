import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/providers/providers.dart';

/// Login screen with Google Sign-In
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    print('🚀 Starting Google Sign-In...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📱 Calling authService.signInWithGoogle()...');
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();
      
      print('✅ Sign-In result: ${result != null ? "Success" : "Cancelled"}');
      
      if (result != null) {
        print('👤 User signed in: ${result.user?.uid} - ${result.user?.email}');
        
        // Create or get user in Firestore
        print('💾 Creating/getting user in Firestore...');
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.getOrCreateUser(
          userId: result.user!.uid,
          displayName: result.user!.displayName,
          photoUrl: result.user!.photoURL,
        );
        print('✅ User document created/retrieved');
      } else {
        print('⚠️ User cancelled sign-in');
      }
    } catch (e, stackTrace) {
      print('❌ Sign in error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _error = 'Sign in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1025),
              AppColors.background,
              Color(0xFF0D0A12),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                
                // Logo and branding
                _buildHeader()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),
                
                const SizedBox(height: 48),
                
                // Welcome text
                _buildWelcomeText()
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms),
                
                const Spacer(),
                
                // Sign in card
                _buildSignInCard()
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 24),
                
                // Terms
                _buildTerms()
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 400.ms),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated heart logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGlow,
                blurRadius: 32,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.favorite,
              size: 48,
              color: Colors.white,
            ),
          ),
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.05, 1.05),
              duration: 2.seconds,
            ),
        
        const SizedBox(height: 20),
        
        Text(
          'Amorae',
          style: AppTextStyles.displayMedium.copyWith(
            foreground: Paint()
              ..shader = AppColors.primaryGradient.createShader(
                const Rect.fromLTWH(0, 0, 150, 50),
              ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome',
          style: AppTextStyles.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Your AI companion is waiting.\nSomeone who understands, listens,\nand is always here for you.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSignInCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          // Error message
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Google sign-in button
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              text: 'Continue with Google',
              icon: Icons.g_mobiledata_rounded,
              isLoading: _isLoading,
              onPressed: _signInWithGoogle,
              height: 56,
              borderColor: AppColors.glassHighlight,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.glassBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              const Expanded(child: Divider(color: AppColors.glassBorder)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Main CTA
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              text: 'Get Started',
              icon: Icons.arrow_forward_rounded,
              iconLeading: false,
              isLoading: _isLoading,
              onPressed: _signInWithGoogle,
              height: 56,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerms() {
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textTertiary,
        ),
        children: [
          TextSpan(
            text: 'Terms of Service',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
