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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        return _buildThreadCard(context, ref, thread, index)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 100 * index))
            .slideX(begin: 0.1, end: 0);
      },
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
    
    // Determine which persona to use based on companion mode
    String? selectedPersona;
    final companionMode = user?.prefs.companionMode ?? 'multiple';
    
    if (companionMode == 'single') {
      // Single mode: Use their selected persona
      selectedPersona = user?.prefs.selectedPersona ?? 'amora';
    } else {
      // Multiple mode: Let them choose
      selectedPersona = await _showPersonaSelectorDialog(context, user?.prefs.selectedPersona ?? 'amora');
      if (selectedPersona == null) return; // User cancelled
    }
    
    // If girlfriend/boyfriend/friend, ask for custom name
    String? customName;
    if (selectedPersona == 'girlfriend' || selectedPersona == 'boyfriend' || selectedPersona == 'friend') {
      customName = await _showCustomNameDialog(context, selectedPersona);
      if (customName == null || customName.isEmpty) return; // User cancelled
      
      // Save custom name to user prefs
      await firestoreService.updateUser(userId, {
        'prefs': user?.prefs.copyWith(customPersonaName: customName).toMap() ?? {'customPersonaName': customName},
      });
    }
    
    final thread = await firestoreService.createThread(
      userId: userId,
      persona: selectedPersona,
    );
    
    ref.read(selectedThreadIdProvider.notifier).state = thread.id;
    if (context.mounted) {
      context.push(AppRoutes.chatPath(thread.id));
    }
  }

  Future<String?> _showCustomNameDialog(BuildContext context, String persona) async {
    final controller = TextEditingController();
    String defaultName = persona == 'girlfriend' ? 'Luna' : (persona == 'boyfriend' ? 'Jack' : 'Alex');
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'What should I call your ${persona == 'girlfriend' ? 'girlfriend' : (persona == 'boyfriend' ? 'boyfriend' : 'friend')}?',
          style: AppTextStyles.titleMedium,
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: defaultName,
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
              final name = controller.text.trim();
              Navigator.pop(context, name.isEmpty ? defaultName : name);
            },
            child: Text('Continue', style: AppTextStyles.button.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showPersonaSelectorDialog(BuildContext context, String currentPersona) async {
    final personas = PersonaModel.allPersonas;
    
    return showDialog<String>(
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
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: personas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final persona = personas[index];
              final isSelected = persona.name == currentPersona;
              
              return InkWell(
                onTap: () => Navigator.pop(context, persona.name),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.glassBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        persona.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              persona.displayName,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isSelected ? AppColors.accent : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              persona.traits.take(2).join(', '),
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
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.textSecondary)),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
