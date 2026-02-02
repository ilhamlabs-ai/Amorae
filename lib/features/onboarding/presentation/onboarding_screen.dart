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
  String _companionMode = 'multiple'; // single or multiple
  String _relationshipMode = 'friendly';
  String _companionStyle = 'warm_supportive';
  String _comfortApproach = 'balanced';
  String _emojiLevel = 'medium';
  bool _petNamesAllowed = false;
  bool _flirtingAllowed = false;
  String _preferredName = '';

  @override
  void initState() {
    super.initState();
    // Pre-fill name from user data
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user?.displayName != null) {
      _preferredName = user!.displayName!.split(' ').first;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
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
        return _gender != null;
      case 2:
      case 3:
      case 4:
        return true;
      default:
        return true;
    }
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
        'prefs': UserPreferences(
          companionMode: _companionMode,
          relationshipMode: _relationshipMode,
          companionStyle: _companionStyle,
          comfortApproach: _comfortApproach,
          emojiLevel: _emojiLevel,
          petNamesAllowed: _petNamesAllowed,
          flirtingAllowed: _flirtingAllowed,
        ).toMap(),
      });

      // Create first thread
      await firestoreService.createThread(
        userId: userId,
        title: 'Chat with Amorae',
      );

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
                    _buildGenderPage(),
                    _buildCompanionModePage(),
                    _buildRelationshipPage(),
                    _buildNamePage(),
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
            children: List.generate(5, (index) {
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
          
          const SizedBox(height: 32),
          
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

  Widget _buildGenderPage() {
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

  Widget _buildCompanionModePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'Choose your companion',
            style: AppTextStyles.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Who would you like to talk to?',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: 32),
          
          _buildOptionCard(
            title: 'Single Companion',
            description: 'One dedicated AI companion (girlfriend, boyfriend, or friend)',
            icon: Icons.person,
            iconColor: AppColors.accent,
            isSelected: _companionMode == 'single',
            onTap: () => setState(() => _companionMode = 'single'),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 12),
          
          _buildOptionCard(
            title: 'Multiple Companions',
            description: 'Access to all 10 AI companions with different personalities',
            icon: Icons.groups,
            iconColor: AppColors.info,
            isSelected: _companionMode == 'multiple',
            onTap: () => setState(() => _companionMode = 'multiple'),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildRelationshipPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'How would you like\nour connection?',
            style: AppTextStyles.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'Choose the type of relationship you prefer',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: 32),
          
          _buildOptionCard(
            title: 'Romantic Partner',
            description: 'A loving, caring companion who\'s always there for you',
            icon: Icons.favorite,
            iconColor: AppColors.accent,
            isSelected: _relationshipMode == 'romantic',
            onTap: () => setState(() => _relationshipMode = 'romantic'),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 12),
          
          _buildOptionCard(
            title: 'Close Friend',
            description: 'A supportive friend who listens and understands',
            icon: Icons.people,
            iconColor: AppColors.info,
            isSelected: _relationshipMode == 'friendly',
            onTap: () => setState(() => _relationshipMode = 'friendly'),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          
          const SizedBox(height: 24),
          
          if (_relationshipMode == 'romantic') ...[
            _buildCheckbox(
              value: _petNamesAllowed,
              label: 'Allow pet names (babe, honey, etc.)',
              onChanged: (value) {
                setState(() => _petNamesAllowed = value ?? false);
              },
            ),
            const SizedBox(height: 8),
            _buildCheckbox(
              value: _flirtingAllowed,
              label: 'Allow flirting and playful banter',
              onChanged: (value) {
                setState(() => _flirtingAllowed = value ?? false);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'Customize your\ncompanion\'s style',
            style: AppTextStyles.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 32),
          
          Text(
            'Personality',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Warm & Supportive', 'warm_supportive', _companionStyle,
                  (v) => setState(() => _companionStyle = v)),
              _buildChip('Playful', 'playful', _companionStyle,
                  (v) => setState(() => _companionStyle = v)),
              _buildChip('Calm', 'calm', _companionStyle,
                  (v) => setState(() => _companionStyle = v)),
              _buildChip('Direct', 'direct', _companionStyle,
                  (v) => setState(() => _companionStyle = v)),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 24),
          
          Text(
            'When you\'re feeling down',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('Validate first', 'validate_then_gentle_advice',
                  _comfortApproach, (v) => setState(() => _comfortApproach = v)),
              _buildChip('Give solutions', 'solution_first', _comfortApproach,
                  (v) => setState(() => _comfortApproach = v)),
              _buildChip('Balanced', 'balanced', _comfortApproach,
                  (v) => setState(() => _comfortApproach = v)),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          
          const SizedBox(height: 24),
          
          Text(
            'Emoji usage',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('None', 'none', _emojiLevel,
                  (v) => setState(() => _emojiLevel = v)),
              _buildChip('Low', 'low', _emojiLevel,
                  (v) => setState(() => _emojiLevel = v)),
              _buildChip('Medium 😊', 'medium', _emojiLevel,
                  (v) => setState(() => _emojiLevel = v)),
              _buildChip('High 🥰💕', 'high', _emojiLevel,
                  (v) => setState(() => _emojiLevel = v)),
            ],
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildNamePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          Text(
            'Almost there!',
            style: AppTextStyles.displaySmall,
          ).animate().fadeIn(duration: 400.ms),
          
          const SizedBox(height: 8),
          
          Text(
            'What should I call you?',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: 32),
          
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: _preferredName,
                  style: AppTextStyles.headlineMedium,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() => _preferredName = value);
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 32),
          
          // Summary
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your companion settings',
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  'Relationship',
                  _relationshipMode == 'romantic' ? 'Romantic Partner' : 'Close Friend',
                ),
                _buildSummaryRow('Style', _formatStyle(_companionStyle)),
                _buildSummaryRow('Comfort', _formatComfort(_comfortApproach)),
                _buildSummaryRow('Emojis', _emojiLevel.capitalize()),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
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

  Widget _buildChip(
    String label,
    String value,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryStart.withOpacity(0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
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
              text: _currentPage == 3 ? 'Start Chatting' : 'Continue',
              icon: _currentPage == 3 ? Icons.favorite : Icons.arrow_forward,
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

  String _formatStyle(String style) {
    switch (style) {
      case 'warm_supportive':
        return 'Warm & Supportive';
      case 'playful':
        return 'Playful';
      case 'calm':
        return 'Calm';
      case 'direct':
        return 'Direct';
      default:
        return style;
    }
  }

  String _formatComfort(String approach) {
    switch (approach) {
      case 'validate_then_gentle_advice':
        return 'Validate First';
      case 'solution_first':
        return 'Solutions';
      case 'balanced':
        return 'Balanced';
      default:
        return approach;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
