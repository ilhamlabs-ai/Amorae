import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/router.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/user_model.dart';

/// Multi-step onboarding screen
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  
  // Onboarding data
  bool _ageConfirmed = false;
  bool _aiDisclosureAccepted = false;
  String? _gender; // male, female, other, prefer-not-to-say
  String _preferredName = '';
  String _ageText = '';
  String _bio = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill name from user data
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.displayName != null) {
      _preferredName = user!.displayName!.split(' ').first;
    }
    if (user?.gender != null) {
      _gender = user!.gender;
    }
    if (user?.age != null) {
      _ageText = user!.age!.toString();
    }
    if (user?.bio != null) {
      _bio = user!.bio!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canContinue() {
    switch (_currentPage) {
      case 0:
        return _ageConfirmed && _aiDisclosureAccepted;
      case 1:
        return _gender != null && _preferredName.trim().isNotEmpty && _isValidAge();
      case 2:
        return true;
      default:
        return true;
    }
  }

  bool _isValidAge() {
    final age = int.tryParse(_ageText.trim());
    if (age == null) return false;
    return age >= 18 && age <= 120;
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;

      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Update user with onboarding data
      await firestoreService.updateUser(userId, {
        'displayName': _preferredName.isNotEmpty ? _preferredName : null,
        'gender': _gender,
        'age': int.tryParse(_ageText.trim()),
        'bio': _bio.trim().isNotEmpty ? _bio.trim() : null,
        'onboarding': OnboardingState(
          completed: true,
          version: 1,
          completedAt: DateTime.now().millisecondsSinceEpoch,
        ).toMap(),
        'safety': SafetySettings(
          ageConfirmed18Plus: _ageConfirmed,
          aiDisclosureAccepted: _aiDisclosureAccepted,
          dependencyGuardEnabled: true,
          selfHarmEscalationEnabled: true,
        ).toMap(),
      });

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              _buildHeader(),
              
              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [
                    _buildDisclosurePage(),
                    _buildProfilePage(),
                    _buildBioPage(),
                  ],
                ),
              ),
              
              // Navigation buttons
              _buildNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                width: index == _currentPage ? 32 : 12,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: index <= _currentPage
                      ? AppColors.accent
                      : AppColors.glassBorder,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclosurePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'Before we start',
            style: AppTextStyles.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Please review and accept the following',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: 24),

          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextFormField(
                  initialValue: _preferredName,
                  style: AppTextStyles.titleLarge,
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() => _preferredName = value);
                  },
                ),
                const Divider(color: AppColors.glassBorder, height: 24),
                TextFormField(
                  initialValue: _ageText,
                  style: AppTextStyles.titleLarge,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Your age',
                    hintStyle: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() => _ageText = value);
                  },
                ),
                if (_ageText.isNotEmpty && !_isValidAge()) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Please enter a valid age (18+).',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 24),

          Text(
            'Gender',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // AI Disclosure card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.smart_toy_outlined,
                        color: AppColors.info,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'AI Companion Disclosure',
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Amorae is an AI companion, not a real person. It\'s designed to provide emotional support and companionship, but it\'s not a substitute for professional mental health care, therapy, or human relationships.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCheckbox(
                  value: _aiDisclosureAccepted,
                  label: 'I understand that Amorae is an AI',
                  onChanged: (value) {
                    setState(() => _aiDisclosureAccepted = value ?? false);
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 16),
          
          // Age confirmation card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Age Verification',
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'This app is intended for users who are 18 years of age or older.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCheckbox(
                  value: _ageConfirmed,
                  label: 'I confirm that I am 18 years or older',
                  onChanged: (value) {
                    setState(() => _ageConfirmed = value ?? false);
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'Tell us about yourself',
            style: AppTextStyles.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'This helps us personalize your experience',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: 32),
          
          _buildOptionCard(
            title: 'Male',
            description: 'I identify as male',
            icon: Icons.male,
            iconColor: AppColors.info,
            isSelected: _gender == 'male',
            onTap: () => setState(() => _gender = 'male'),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 12),
          
          _buildOptionCard(
            title: 'Female',
            description: 'I identify as female',
            icon: Icons.female,
            iconColor: AppColors.accent,
            isSelected: _gender == 'female',
            onTap: () => setState(() => _gender = 'female'),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
          
          const SizedBox(height: 12),
          
          _buildOptionCard(
            title: 'Non-binary',
            description: 'I identify as non-binary or other',
            icon: Icons.wc,
            iconColor: AppColors.success,
            isSelected: _gender == 'other',
            onTap: () => setState(() => _gender = 'other'),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          
          const SizedBox(height: 12),
          
          _buildOptionCard(
            title: 'Prefer not to say',
            description: 'I\'d rather not specify',
            icon: Icons.remove_circle_outline,
            iconColor: AppColors.textTertiary,
            isSelected: _gender == 'prefer-not-to-say',
            onTap: () => setState(() => _gender = 'prefer-not-to-say'),
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildBioPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'A little about you',
            style: AppTextStyles.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Optional, but highly recommended. Share what you like, topics you enjoy, or anything you want your companion to understand.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: 24),
          
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: TextFormField(
              initialValue: _bio,
              maxLines: 6,
              minLines: 4,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'I like deep conversations, music, traveling...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
              ),
              onChanged: (value) {
                setState(() => _bio = value);
              },
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        ],
      ),
    );
  }







  Widget _buildCheckbox({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.accent : AppColors.glassBorder,
                width: 2,
              ),
              color: value ? AppColors.accent : Colors.transparent,
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryStart.withOpacity(0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }





  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _previousPage,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            const SizedBox(width: 52),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: GradientButton(
              text: _currentPage == 2 ? 'Finish' : 'Continue',
              icon: _currentPage == 2 ? Icons.check : Icons.arrow_forward,
              iconLeading: false,
              isEnabled: _canContinue(),
              isLoading: _isLoading,
              onPressed: _canContinue() ? _nextPage : null,
            ),
          ),
        ],
      ),
    );
  }




}


