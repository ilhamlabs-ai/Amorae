import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
