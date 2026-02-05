import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/utils/name_validator.dart';

/// Persona selection drawer
class PersonaDrawer extends ConsumerStatefulWidget {
  const PersonaDrawer({super.key});

  @override
  ConsumerState<PersonaDrawer> createState() => _PersonaDrawerState();
}

class _PersonaDrawerState extends ConsumerState<PersonaDrawer> {
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'CUSTOM COMPANION',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, color: AppColors.accent, size: 20),
          ),
          title: Text(
            'Create Companion',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Design your own AI companion',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          onTap: () => _createCompanionAndChat(user),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.glassBorder, height: 1),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'AI COMPANIONS',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...defaultPersonas.map((persona) => _buildPersonaTile(
          persona: persona,
          isSelected: selectedPersona == persona.name,
          user: user,
        )),
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
      onTap: () => _selectPersona(user, persona.name),
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

  Future<void> _createCompanionAndChat(UserModel user) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final companion = await _showCreateCompanionDialog(context, userId);
    if (companion == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final thread = await firestoreService.createThread(
      userId: userId,
      customCompanion: companion,
    );

    if (mounted) {
      Navigator.pop(context);
      context.go('/chat/${thread.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chatting with ${companion.name}'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  Future<CustomCompanionModel?> _showCreateCompanionDialog(
    BuildContext context,
    String userId,
  ) async {
    final nameController = TextEditingController();
    final bioController = TextEditingController();
    final customRelationshipController = TextEditingController();
    String? gender = 'prefer-not-to-say';
    String relationship = 'best_friend';
    String? nameError;
    String? relationshipError;

    const genderOptions = {
      'female': 'Female',
      'male': 'Male',
      'non-binary': 'Non-binary',
      'other': 'Other',
      'prefer-not-to-say': 'Prefer not to say',
    };

    const relationshipOptions = {
      'girlfriend': 'Girlfriend',
      'boyfriend': 'Boyfriend',
      'best_friend': 'Best Friend',
      'therapist': 'Therapist',
      'father': 'Father',
      'mother': 'Mother',
      'custom': 'Custom',
    };

    String relationshipDisplay() {
      if (relationship == 'custom') {
        final customValue = customRelationshipController.text.trim();
        return customValue.isNotEmpty ? customValue : 'Custom';
      }
      return relationshipOptions[relationship] ?? relationship;
    }

    Widget menuField({
      required String label,
      required String value,
      required Map<String, String> options,
      required ValueChanged<String> onChanged,
    }) {
      return PopupMenuButton<String>(
        position: PopupMenuPosition.under,
        onSelected: onChanged,
        itemBuilder: (context) => options.entries
            .map(
              (entry) => PopupMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(value, style: AppTextStyles.bodyLarge),
                  ],
                ),
              ),
              const Icon(Icons.expand_more, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    }

    return showDialog<CustomCompanionModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            title: Text('Create Companion', style: AppTextStyles.titleMedium),
            content: SizedBox(
              width: 360,
              height: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Companion name',
                        errorText: nameError,
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textTertiary,
                        ),
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
                    const SizedBox(height: 12),
                    menuField(
                      label: 'Gender',
                      value: genderOptions[gender] ?? 'Prefer not to say',
                      options: genderOptions,
                      onChanged: (value) => setState(() => gender = value),
                    ),
                    const SizedBox(height: 12),
                    menuField(
                      label: 'Relationship',
                      value: relationshipDisplay(),
                      options: relationshipOptions,
                      onChanged: (value) => setState(() {
                        relationship = value;
                        relationshipError = null;
                      }),
                    ),
                    if (relationship == 'custom') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customRelationshipController,
                        style: AppTextStyles.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Type relationship',
                          errorText: relationshipError,
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.glassBorder),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioController,
                      maxLines: 5,
                      minLines: 4,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Bio (optional, recommended)',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.glassBorder),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final rawName = nameController.text.trim();
                  final validation = NameValidator.validate(rawName);
                  if (validation != null) {
                    setState(() => nameError = validation);
                    return;
                  }

                  if (relationship == 'custom') {
                    final customValue = customRelationshipController.text.trim();
                    if (customValue.isEmpty) {
                      setState(() => relationshipError = 'Please enter a relationship');
                      return;
                    }
                  }

                  final firestoreService = ref.read(firestoreServiceProvider);
                  final customRelationship = relationship == 'custom'
                      ? customRelationshipController.text.trim()
                      : null;
                  final companion = await firestoreService.createCompanion(
                    userId: userId,
                    name: NameValidator.sanitize(rawName),
                    relationship: relationship,
                    customRelationship: customRelationship,
                    gender: gender,
                    bio: bioController.text.trim().isNotEmpty
                        ? bioController.text.trim()
                        : null,
                  );

                  Navigator.pop(context, companion);
                },
                child: Text(
                  'Create',
                  style: AppTextStyles.button.copyWith(color: AppColors.accent),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectPersona(
    UserModel user,
    String personaName,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final firestoreService = ref.read(firestoreServiceProvider);

      await firestoreService.updateUser(userId, {
        'prefs.selectedPersona': personaName,
      });

      final threads = await firestoreService.getUserThreads(userId);
      final existingThread = threads.where((t) => t.persona == personaName).toList();

      if (mounted) {
        Navigator.pop(context);

        if (existingThread.isNotEmpty) {
          existingThread.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
          context.go('/chat/${existingThread.first.id}');
        } else {
          final newThread = await firestoreService.createThread(
            userId: userId,
            persona: personaName,
          );
          context.go('/chat/${newThread.id}');
        }

        final persona = PersonaModel.getByName(personaName);
        final displayName = persona?.displayName ?? personaName;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chatting with $displayName'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

}
