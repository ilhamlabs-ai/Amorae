import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/router.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/avatar_circle.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/user_model.dart';

/// Settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: userAsync.when(
                    data: (user) => _buildContent(user),
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AppColors.textSecondary,
          ),
          const Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildContent(UserModel? user) {
    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile section
          _buildProfileSection(user)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.1, end: 0),
          
          const SizedBox(height: 24),
          
          // Personal Info
          _buildSectionTitle('Personal Info'),
          const SizedBox(height: 12),
          _buildPersonalInfoSection(user)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: 24),
          
          // Companion settings
          _buildSectionTitle('Companion Settings'),
          const SizedBox(height: 12),
          _buildCompanionSettings(user)
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms),
          
          const SizedBox(height: 24),
          
          // Preferences
          _buildSectionTitle('Preferences'),
          const SizedBox(height: 12),
          _buildPreferencesSection(user)
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms),
          
          const SizedBox(height: 24),
          
          // Account
          _buildSectionTitle('Account'),
          const SizedBox(height: 12),
          _buildAccountSection()
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileSection(UserModel user) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          AvatarCircle(
            imageUrl: user.photoUrl,
            initials: user.displayName?.substring(0, 1).toUpperCase(),
            size: 64,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'User',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: user.plan.tier == 'pro'
                        ? AppColors.accent.withOpacity(0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.plan.tier == 'pro' ? 'Pro' : 'Free Plan',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: user.plan.tier == 'pro'
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showNameEditDialog(user),
            icon: const Icon(Icons.edit_outlined),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(UserModel user) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.wc,
            title: 'Gender',
            subtitle: _formatGender(user.gender),
            onTap: () => _showGenderPicker(user),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionSettings(UserModel user) {
    final isSingleMode = user.companionMode == 'single';
    
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSettingsTile(
            icon: isSingleMode ? Icons.person : Icons.groups,
            title: 'Companion Mode',
            subtitle: isSingleMode
                ? 'Single Companion'
                : 'Multiple Companions',
            onTap: () => _showCompanionModePicker(user),
          ),
          // Show companion management for single mode
          if (isSingleMode) ...[
            const Divider(color: AppColors.glassBorder, height: 1),
            _buildSettingsTile(
              icon: Icons.favorite_outline,
              title: 'My Companion',
              subtitle: user.prefs.selectedPersona != null
                  ? _formatPersona(user.prefs.selectedPersona!)
                  : 'Not selected',
              onTap: () => _manageCompanion(user),
            ),
          ],
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSettingsTile(
            icon: Icons.favorite_outline,
            title: 'Relationship Mode',
            subtitle: user.prefs.relationshipMode == 'romantic'
                ? 'Romantic Partner'
                : 'Close Friend',
            onTap: () => _showRelationshipPicker(user),
          ),
          if (user.prefs.selectedPersona == 'girlfriend' ||
              user.prefs.selectedPersona == 'boyfriend' ||
              user.prefs.selectedPersona == 'friend') ...[
            const Divider(color: AppColors.glassBorder, height: 1),
            _buildSettingsTile(
              icon: Icons.badge_outlined,
              title: 'Companion Name',
              subtitle: user.prefs.customPersonaName ?? 'Not set',
              onTap: () => _showCustomNameDialog(user),
            ),
          ],
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSettingsTile(
            icon: Icons.psychology_outlined,
            title: 'Companion Style',
            subtitle: _formatStyle(user.prefs.companionStyle),
            onTap: () => _showCompanionStylePicker(user),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSettingsTile(
            icon: Icons.emoji_emotions_outlined,
            title: 'Emoji Level',
            subtitle: user.prefs.emojiLevel.capitalize(),
            onTap: () => _showEmojiLevelPicker(user),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(UserModel user) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.pets_outlined,
            title: 'Allow Pet Names',
            subtitle: 'Let your companion use affectionate names',
            value: user.prefs.petNamesAllowed,
            onChanged: (value) => _updatePreference('petNamesAllowed', value),
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSwitchTile(
            icon: Icons.favorite_border,
            title: 'Allow Flirting',
            subtitle: 'Enable playful romantic interactions',
            value: user.prefs.flirtingAllowed,
            onChanged: (value) => _updatePreference('flirtingAllowed', value),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Manage your data',
            onTap: () {},
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help with Amorae',
            onTap: () {},
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            titleColor: AppColors.error,
            onTap: _deleteAccount,
          ),
          const Divider(color: AppColors.glassBorder, height: 1),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Sign Out',
            titleColor: AppColors.error,
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: titleColor ?? AppColors.textSecondary, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
      ),
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accent,
      ),
    );
  }

  void _showRelationshipPicker(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Relationship Mode', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              _buildRelationshipOption(
                title: 'Romantic Partner',
                icon: Icons.favorite,
                isSelected: user.prefs.relationshipMode == 'romantic',
                onTap: () {
                  Navigator.pop(context);
                  _updatePreference('relationshipMode', 'romantic');
                },
              ),
              _buildRelationshipOption(
                title: 'Close Friend',
                icon: Icons.people,
                isSelected: user.prefs.relationshipMode == 'friendly',
                onTap: () {
                  Navigator.pop(context);
                  _updatePreference('relationshipMode', 'friendly');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showGenderPicker(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Select Gender', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              _buildGenderOption(
                title: 'Male',
                icon: Icons.male,
                isSelected: user.gender == 'male',
                onTap: () {
                  Navigator.pop(context);
                  _updateGender('male');
                },
              ),
              _buildGenderOption(
                title: 'Female',
                icon: Icons.female,
                isSelected: user.gender == 'female',
                onTap: () {
                  Navigator.pop(context);
                  _updateGender('female');
                },
              ),
              _buildGenderOption(
                title: 'Non-binary',
                icon: Icons.wc,
                isSelected: user.gender == 'other',
                onTap: () {
                  Navigator.pop(context);
                  _updateGender('other');
                },
              ),
              _buildGenderOption(
                title: 'Prefer not to say',
                icon: Icons.remove_circle_outline,
                isSelected: user.gender == 'prefer-not-to-say',
                onTap: () {
                  Navigator.pop(context);
                  _updateGender('prefer-not-to-say');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCompanionModePicker(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Companion Mode', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              _buildRelationshipOption(
                title: 'Single Companion',
                icon: Icons.person,
                isSelected: user.prefs.companionMode == 'single',
                onTap: () {
                  Navigator.pop(context);
                  _updatePreference('companionMode', 'single');
                },
              ),
              _buildRelationshipOption(
                title: 'Multiple Companions',
                icon: Icons.groups,
                isSelected: user.prefs.companionMode == 'multiple',
                onTap: () {
                  Navigator.pop(context);
                  _updatePreference('companionMode', 'multiple');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCustomNameDialog(UserModel user) {
    final controller = TextEditingController(text: user.prefs.customPersonaName ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Companion Name', style: AppTextStyles.headlineSmall),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Enter name',
              hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updatePreference('customPersonaName', controller.text.trim());
              },
              child: Text('Save', style: AppTextStyles.button.copyWith(color: AppColors.accent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenderOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.1) : null,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showCompanionStylePicker(UserModel user) {
    final styles = [
      {'key': 'warm_supportive', 'title': 'Warm & Supportive', 'icon': Icons.favorite},
      {'key': 'playful', 'title': 'Playful', 'icon': Icons.mood},
      {'key': 'calm', 'title': 'Calm', 'icon': Icons.spa},
      {'key': 'direct', 'title': 'Direct', 'icon': Icons.arrow_forward},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Companion Style', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ...styles.map((style) => _buildRelationshipOption(
                title: style['title'] as String,
                icon: style['icon'] as IconData,
                isSelected: user.prefs.companionStyle == style['key'],
                onTap: () {
                  Navigator.pop(context);
                  _updatePreference('companionStyle', style['key']);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEmojiLevelPicker(UserModel user) {
    final levels = [
      {'key': 'none', 'title': 'None', 'icon': Icons.remove_circle_outline},
      {'key': 'minimal', 'title': 'Minimal', 'icon': Icons.sentiment_satisfied},
      {'key': 'moderate', 'title': 'Moderate', 'icon': Icons.sentiment_very_satisfied},
      {'key': 'expressive', 'title': 'Expressive', 'icon': Icons.emoji_emotions},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Emoji Level', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ...levels.map((level) => _buildRelationshipOption(
                title: level['title'] as String,
                icon: level['icon'] as IconData,
                isSelected: user.prefs.emojiLevel == level['key'],
                onTap: () {
                  Navigator.pop(context);
                  _updatePreference('emojiLevel', level['key']);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showNameEditDialog(UserModel user) {
    final controller = TextEditingController(text: user.displayName);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Edit Name', style: AppTextStyles.headlineSmall),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accent, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final userId = ref.read(currentUserIdProvider);
                if (userId != null && controller.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    final firestoreService = ref.read(firestoreServiceProvider);
                    await firestoreService.updateUser(userId, {
                      'displayName': controller.text.trim(),
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name updated'),
                          duration: Duration(seconds: 1),
                          backgroundColor: AppColors.accent,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                }
              },
              child: Text(
                'Save',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRelationshipOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
      title: Text(title, style: AppTextStyles.titleMedium),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.accent)
          : null,
      onTap: onTap,
    );
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;
      
      if (currentUser != null) {
        // Get current prefs and update the specific key
        final updatedPrefs = currentUser.prefs.toMap();
        updatedPrefs[key] = value;
        
        await firestoreService.updateUser(userId, {
          'prefs': updatedPrefs,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings updated'),
              duration: Duration(seconds: 1),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateGender(String gender) async {
    setState(() => _isLoading = true);
    
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.updateUser(userId, {
          'gender': gender,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gender updated'),
              duration: Duration(seconds: 1),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              const SizedBox(width: 12),
              Text('Delete Account?', style: AppTextStyles.headlineSmall),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone. All your data will be permanently deleted:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeleteItem('All conversations and messages'),
              _buildDeleteItem('All companion settings'),
              _buildDeleteItem('All personal preferences'),
              _buildDeleteItem('Your account and profile'),
              const SizedBox(height: 12),
              Text(
                'Are you absolutely sure?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmDeleteAccount();
              },
              child: Text(
                'Delete Forever',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.close, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        final authService = ref.read(authServiceProvider);
        
        // Delete all user data from Firestore
        await firestoreService.deleteUser(userId);
        
        // Delete Firebase Auth account
        await authService.deleteAccount();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go(AppRoutes.login);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Sign Out?', style: AppTextStyles.headlineSmall),
          content: Text(
            'Are you sure you want to sign out?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                if (mounted) {
                  context.go(AppRoutes.login);
                }
              },
              child: Text(
                'Sign Out',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
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

  String _formatGender(String? gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Non-binary';
      case 'prefer-not-to-say':
        return 'Prefer not to say';
      default:
        return 'Not set';
    }
  }

  String _formatPersona(String persona) {
    switch (persona) {
      case 'girlfriend':
        return 'Girlfriend';
      case 'boyfriend':
        return 'Boyfriend';
      case 'friend':
        return 'Friend';
      default:
        return persona.capitalize();
    }
  }

  Future<void> _manageCompanion(UserModel user) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Companion',
              style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Change Companion Type'),
              subtitle: Text('Current: ${_formatPersona(user.prefs.selectedPersona ?? '')}'),
              onTap: () {
                Navigator.pop(context);
                context.push('/companion-selection');
              },
            ),
            if (user.prefs.selectedPersona == 'girlfriend' ||
                user.prefs.selectedPersona == 'boyfriend' ||
                user.prefs.selectedPersona == 'friend')
              ListTile(
                leading: const Icon(Icons.badge, color: AppColors.accent),
                title: const Text('Change Companion Name'),
                subtitle: Text(user.prefs.customPersonaName ?? 'Not set'),
                onTap: () {
                  Navigator.pop(context);
                  _showCustomNameDialog(user);
                },
              ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
