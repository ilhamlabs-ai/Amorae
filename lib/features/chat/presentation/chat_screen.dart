import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/avatar_circle.dart';
import '../../../shared/widgets/typing_indicator.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/api_client.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_composer.dart';

/// Main chat screen
class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ChatScreen({
    super.key,
    required this.threadId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final _uuid = const Uuid();
  
  bool _isSending = false;
  bool _isTyping = false;
  String _streamingContent = '';
  String? _streamingMessageId;

  @override
  void initState() {
    super.initState();
    // Set selected thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedThreadIdProvider.notifier).state = widget.threadId;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _sendMessage(String content, List<File> images) async {
    if (content.isEmpty && images.isEmpty) return;

    setState(() {
      _isSending = true;
      _isTyping = true;
      _streamingContent = '';
    });

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final firestoreService = ref.read(firestoreServiceProvider);
    final storageService = ref.read(storageServiceProvider);
    final apiClient = ref.read(apiClientProvider);

    try {
      // Upload images first
      List<MessageAttachment> attachments = [];
      for (final image in images) {
        final result = await storageService.uploadImage(
          userId: userId,
          threadId: widget.threadId,
          file: image,
        );
        attachments.add(MessageAttachment(
          kind: 'image',
          storagePath: result.storagePath,
          mimeType: result.mimeType,
          sizeBytes: result.sizeBytes,
          downloadUrl: result.downloadUrl,
        ));
      }

      // Show typing indicator
      setState(() {
        _isTyping = true;
      });

      // Call backend (backend will create both user and assistant messages)
      print('🚀 Sending message to backend for thread: ${widget.threadId}');
      
      final response = await apiClient.sendMessage(
        threadId: widget.threadId,
        content: content,
        attachments: attachments.map((a) => {
          'kind': a.kind,
          'storagePath': a.storagePath,
          'mimeType': a.mimeType,
        }).toList(),
      );

      print('✅ Got response: ${response['content']?.substring(0, response['content'].length > 50 ? 50 : response['content'].length)}...');
      
      // Response is saved to Firestore by backend
      // Firestore listener will update the UI automatically
      
      setState(() {
        _isTyping = false;
      });

      // Scroll to show AI response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
    } catch (e) {
      print('❌ Error in _sendMessage: $e');
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isTyping = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider);
    final threadAsync = ref.watch(selectedThreadProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              _buildHeader(threadAsync.valueOrNull),
              
              // Messages
              Expanded(
                child: messagesAsync.when(
                  data: (messages) => _buildMessageList(messages),
                  loading: () => _buildLoadingState(),
                  error: (e, _) => _buildErrorState(e.toString()),
                ),
              ),
              
              // Composer
              MessageComposer(
                onSend: _sendMessage,
                isSending: _isSending,
                isEnabled: !_isSending,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThreadModel? thread) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AppColors.textSecondary,
          ),
          
          // AI Avatar
          const AIAvatar(size: 40, isTyping: false),
          
          const SizedBox(width: 12),
          
          // Thread info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amorae',
                  style: AppTextStyles.titleMedium,
                ),
                Row(
                  children: [
                    const PulsingDot(size: 8, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      _isTyping ? 'typing...' : 'Online',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // More options
          IconButton(
            onPressed: () => _showOptions(context),
            icon: const Icon(Icons.more_vert),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildMessageList(List<MessageModel> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Streaming message placeholder
        if (_isTyping && index == messages.length) {
          if (_streamingContent.isNotEmpty) {
            return StreamingBubble(content: _streamingContent)
                .animate()
                .fadeIn(duration: 200.ms);
          } else {
            return Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Row(
                children: [
                  const TypingIndicator(),
                ],
              ),
            ).animate().fadeIn(duration: 200.ms);
          }
        }

        final message = messages[index];
        final showTimestamp = _shouldShowTimestamp(messages, index);

        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
          showTimestamp: showTimestamp,
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  bool _shouldShowTimestamp(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final current = messages[index];
    final next = messages[index + 1];
    
    // Show timestamp if next message is from different sender
    if (current.role != next.role) return true;
    
    // Show timestamp if more than 5 minutes apart
    final diff = next.createdAt - current.createdAt;
    return diff > 5 * 60 * 1000;
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return MessageShimmer(isUser: index % 2 == 1);
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Failed to load messages', style: AppTextStyles.titleMedium),
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
    );
  }

  void _showOptions(BuildContext context) {
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
              _buildOptionTile(
                icon: Icons.delete_outline,
                label: 'Delete Chat',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteChat();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(
        label,
        style: AppTextStyles.bodyLarge.copyWith(
          color: color ?? AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  void _confirmDeleteChat() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Delete Chat?', style: AppTextStyles.headlineSmall),
          content: Text(
            'This action cannot be undone. All messages will be permanently deleted.',
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
                final firestoreService = ref.read(firestoreServiceProvider);
                await firestoreService.deleteThread(widget.threadId);
                if (mounted) {
                  context.pop();
                }
              },
              child: Text(
                'Delete',
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
}
