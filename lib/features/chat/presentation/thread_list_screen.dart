import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/router.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/avatar_circle.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/thread_model.dart';
import '../../../shared/models/persona_model.dart';
import '../../../shared/models/custom_companion_model.dart';
import '../../../core/utils/name_validator.dart';
import 'widgets/persona_drawer.dart';

/// Thread list screen (Home)
class ThreadListScreen extends ConsumerWidget {
  const ThreadListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(userThreadsProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      drawer: const PersonaDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, ref, currentUser.valueOrNull),
              Expanded(
                child: threadsAsync.when(
                  data: (threads) => _buildThreadList(context, ref, threads),
                  loading: () => _buildLoadingState(),
                  error: (e, _) => _buildErrorState(e.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Menu button for persona drawer
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Icon(
                  Icons.menu,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // User greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.displayName ?? 'Friend',
                  style: AppTextStyles.headlineMedium,
                ),
              ],
            ),
          ),
          
          // Settings button
          GestureDetector(
            onTap: () => context.push(AppRoutes.settings),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildThreadList(
    BuildContext context,
    WidgetRef ref,
    List<ThreadModel> threads,
  ) {
    if (threads.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              return _buildThreadCard(context, ref, thread, index)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 100 * index))
                  .slideX(begin: 0.1, end: 0);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton.extended(
            onPressed: () => _createNewThread(context, ref),
            backgroundColor: AppColors.primaryStart,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'New Chat',
              style: AppTextStyles.button.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreadCard(
    BuildContext context,
    WidgetRef ref,
    ThreadModel thread,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedThreadIdProvider.notifier).state = thread.id;
        context.push(AppRoutes.chatPath(thread.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // AI Avatar
              const AIAvatar(size: 52),
              
              const SizedBox(width: 14),
              
              // Thread info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${thread.messageCount} messages',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Timestamp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    thread.formattedLastMessageTime,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new chat with your AI companion',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _createNewThread(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Start Chatting',
                      style: AppTextStyles.button,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ThreadShimmer(),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(userThreadsProvider).valueOrNull ?? [];
    final hasContinuableThread = threads.isNotEmpty;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Continue chat FAB (if there are existing threads)
        if (hasContinuableThread)
          FloatingActionButton.extended(
            onPressed: () => _continueChat(context, ref, threads),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Continue'),
            heroTag: 'continue',
            backgroundColor: AppColors.accent,
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: 0.5, end: 0),
        
        if (hasContinuableThread) const SizedBox(height: 12),
        
        // New chat FAB
        FloatingActionButton(
          onPressed: () => _createNewThread(context, ref),
          heroTag: 'new',
          child: const Icon(Icons.add),
        ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  Future<void> _createNewThread(BuildContext context, WidgetRef ref) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final user = await firestoreService.getUser(userId);
    final companions = await firestoreService.getCompanions(userId);

    final selection = await _showPersonaSelectorDialog(
      context,
      user?.prefs.selectedPersona ?? 'amora',
      companions,
    );
    if (selection == null) return;

    CustomCompanionModel? customCompanion;
    String? selectedPersona;
    if (selection.type == _PersonaSelectionType.createCompanion) {
      customCompanion = await _showCreateCompanionDialog(context, ref);
      if (customCompanion == null) return;
    } else if (selection.type == _PersonaSelectionType.customCompanion) {
      customCompanion = selection.companion;
    } else {
      selectedPersona = selection.personaName;
    }

    final thread = await firestoreService.createThread(
      userId: userId,
      persona: selectedPersona,
      customCompanion: customCompanion,
    );

    ref.read(selectedThreadIdProvider.notifier).state = thread.id;
    if (context.mounted) {
      context.push(AppRoutes.chatPath(thread.id));
    }
  }

  Future<CustomCompanionModel?> _showCreateCompanionDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final bioController = TextEditingController();
    String? gender = 'prefer-not-to-say';
    String relationship = 'platonic';
    String? nameError;

    return showDialog<CustomCompanionModel>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Create Companion', style: AppTextStyles.titleMedium),
            content: SingleChildScrollView(
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
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'non-binary', child: Text('Non-binary')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                      DropdownMenuItem(value: 'prefer-not-to-say', child: Text('Prefer not to say')),
                    ],
                    onChanged: (value) => setState(() => gender = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: relationship,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'romantic', child: Text('Romantic')),
                      DropdownMenuItem(value: 'platonic', child: Text('Platonic')),
                      DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                      DropdownMenuItem(value: 'coach', child: Text('Coach')),
                      DropdownMenuItem(value: 'confidant', child: Text('Confidant')),
                      DropdownMenuItem(value: 'professional', child: Text('Professional')),
                    ],
                    onChanged: (value) => setState(() => relationship = value ?? 'platonic'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioController,
                    maxLines: 4,
                    minLines: 3,
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

                  final userId = ref.read(currentUserIdProvider);
                  if (userId == null) return;

                  final firestoreService = ref.read(firestoreServiceProvider);
                  final companion = await firestoreService.createCompanion(
                    userId: userId,
                    name: NameValidator.sanitize(rawName),
                    relationship: relationship,
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

  Future<_PersonaSelection?> _showPersonaSelectorDialog(
    BuildContext context,
    String currentPersona,
    List<CustomCompanionModel> companions,
  ) async {
    final personas = PersonaModel.getDefaultPersonas();

    return showDialog<_PersonaSelection>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Choose Your Companion',
          style: AppTextStyles.titleLarge,
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              InkWell(
                onTap: () => Navigator.pop(
                  context,
                  const _PersonaSelection.createCompanion(),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create New Companion',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (companions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'YOUR COMPANIONS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                ...companions.map((companion) {
                  return InkWell(
                    onTap: () => Navigator.pop(
                      context,
                      _PersonaSelection.customCompanion(companion),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Center(
                              child: Text(
                                companion.name.isNotEmpty
                                    ? companion.name[0].toUpperCase()
                                    : 'C',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  companion.name,
                                  style: AppTextStyles.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatRelationship(companion.relationship),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 16),
              Text(
                'AI COMPANIONS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              ...personas.map((persona) {
                final isSelected = persona.name == currentPersona;
                return InkWell(
                  onTap: () => Navigator.pop(
                    context,
                    _PersonaSelection.defaultPersona(persona.name),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.glassBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: Center(
                            child: Text(
                              persona.displayName[0],
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                persona.displayName,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                persona.description,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: AppColors.accent, size: 24),
                      ],
                    ),
                  ),
                );
              }),
            ],
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
        ],
      ),
    );
  }

  void _continueChat(BuildContext context, WidgetRef ref, List<ThreadModel> threads) {
    // Get the most recent thread
    final mostRecentThread = threads.reduce((a, b) => 
      a.lastMessageAt > b.lastMessageAt ? a : b
    );
    
    ref.read(selectedThreadIdProvider.notifier).state = mostRecentThread.id;
    context.push(AppRoutes.chatPath(mostRecentThread.id));
  }

  String _formatRelationship(String relationship) {
    switch (relationship) {
      case 'romantic':
        return 'Romantic';
      case 'platonic':
        return 'Platonic';
      case 'mentor':
        return 'Mentor';
      case 'coach':
        return 'Coach';
      case 'confidant':
        return 'Confidant';
      case 'professional':
        return 'Professional';
      default:
        return relationship;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

enum _PersonaSelectionType {
  defaultPersona,
  customCompanion,
  createCompanion,
}

class _PersonaSelection {
  final _PersonaSelectionType type;
  final String? personaName;
  final CustomCompanionModel? companion;

  const _PersonaSelection._(this.type, {this.personaName, this.companion});

  const _PersonaSelection.createCompanion()
      : this._(_PersonaSelectionType.createCompanion);

  const _PersonaSelection.defaultPersona(String personaName)
      : this._(_PersonaSelectionType.defaultPersona, personaName: personaName);

  const _PersonaSelection.customCompanion(CustomCompanionModel companion)
      : this._(_PersonaSelectionType.customCompanion, companion: companion);
}
