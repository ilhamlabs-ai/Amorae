import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/widgets/widgets.dart';

/// Persona selection drawer
class PersonaDrawer extends ConsumerStatefulWidget {
  const PersonaDrawer({super.key});

  @override
  ConsumerState<PersonaDrawer> createState() => _PersonaDrawerState();
}

class _PersonaDrawerState extends ConsumerState<PersonaDrawer> {
  bool _showCustomPersonas = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: userAsync.when(
                data: (user) => _buildPersonaList(user),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Persona',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Choose who you want to talk to',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaList(UserModel? user) {
    if (user == null) return const SizedBox();

    final defaultPersonas = PersonaModel.getDefaultPersonas();
    final selectedPersona = user.prefs.selectedPersona;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Relationships Section
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'RELATIONSHIPS',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        _buildCustomPersonaTile(
          type: PersonaType.girlfriend,
          icon: Icons.favorite,
          title: 'Girlfriend',
          defaultName: 'Luna',
          user: user,
        ),
        _buildCustomPersonaTile(
          type: PersonaType.boyfriend,
          icon: Icons.favorite_border,
          title: 'Boyfriend',
          defaultName: 'Jack',
          user: user,
        ),
        _buildCustomPersonaTile(
          type: PersonaType.friend,
          icon: Icons.people,
          title: 'Close Friend',
          defaultName: 'Alex',
          user: user,
        ),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.glassBorder, height: 1),
        ),

        // AI Companions Section (expandable)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI COMPANIONS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showCustomPersonas ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showCustomPersonas = !_showCustomPersonas;
                  });
                },
              ),
            ],
          ),
        ),
        if (_showCustomPersonas) ...[
          ...defaultPersonas.map((persona) => _buildPersonaTile(
            persona: persona,
            isSelected: selectedPersona == persona.name,
            user: user,
          )),
        ],
      ],
    );
  }

  Widget _buildPersonaTile({
    required PersonaModel persona,
    required bool isSelected,
    required UserModel user,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          _getPersonaIcon(persona.type),
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        persona.displayName,
        style: AppTextStyles.titleMedium.copyWith(
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        persona.description,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20)
          : null,
      onTap: () => _selectPersona(user, persona.name, null),
    );
  }

  Widget _buildCustomPersonaTile({
    required PersonaType type,
    required IconData icon,
    required String title,
    required String defaultName,
    required UserModel user,
  }) {
    final isSelected = user.prefs.selectedPersona == type.name;
    final customName = user.prefs.customPersonaName ?? defaultName;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.accent : AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        isSelected ? customName : title,
        style: AppTextStyles.titleMedium.copyWith(
          color: isSelected ? AppColors.accent : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        isSelected ? 'Tap to rename' : 'Create $title persona',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () => _showRenameDialog(user, type, customName),
                ),
                const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
              ],
            )
          : null,
      onTap: () {
        if (isSelected) {
          _showRenameDialog(user, type, customName);
        } else {
          _showCreateCustomDialog(user, type, defaultName);
        }
      },
    );
  }

  IconData _getPersonaIcon(PersonaType type) {
    switch (type) {
      case PersonaType.einstein:
        return Icons.lightbulb_outline;
      case PersonaType.gandhi:
        return Icons.spa;
      case PersonaType.tesla:
        return Icons.flash_on;
      case PersonaType.davinci:
        return Icons.brush;
      case PersonaType.socrates:
        return Icons.question_answer;
      case PersonaType.aurelius:
        return Icons.self_improvement;
      case PersonaType.cleopatra:
        return Icons.stars;
      case PersonaType.sherlock:
        return Icons.search;
      case PersonaType.athena:
        return Icons.wb_twilight;
      case PersonaType.amora:
        return Icons.favorite;
      default:
        return Icons.person;
    }
  }

  Future<void> _selectPersona(
    UserModel user,
    String personaName,
    String? customName,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateUser(userId, {
        'prefs.selectedPersona': personaName,
        if (customName != null) 'prefs.customPersonaName': customName,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${customName ?? personaName}'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch persona: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCreateCustomDialog(
    UserModel user,
    PersonaType type,
    String defaultName,
  ) {
    final controller = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Create ${type.name.capitalize()} Persona', style: AppTextStyles.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Give your ${type.name} a name:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter name',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                _selectPersona(user, type.name, name);
              }
            },
            child: Text('Create', style: AppTextStyles.button.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    UserModel user,
    PersonaType type,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Persona', style: AppTextStyles.headlineSmall),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter new name',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
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
            child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                _selectPersona(user, type.name, name);
              }
            },
            child: Text('Save', style: AppTextStyles.button.copyWith(color: AppColors.accent)),
          ),
        ],
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
