import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/models/message_model.dart';

/// Chat message bubble widget
class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool showTimestamp;
  final bool isStreaming;
  final String? streamingContent;

  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
    this.isStreaming = false,
    this.streamingContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.isUser;
    final content = isStreaming ? (streamingContent ?? '') : message.content;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 60 : 16,
        right: isUser ? 16 : 60,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser ? AppColors.userBubbleGradient : null,
              color: isUser ? null : AppColors.aiBubble,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              border: isUser
                  ? null
                  : Border.all(color: AppColors.aiBubbleBorder, width: 1),
              boxShadow: isUser
                  ? [
                      BoxShadow(
                        color: AppColors.primaryGlow.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attachments
                if (message.hasAttachments) ...[
                  _buildAttachments(),
                  const SizedBox(height: 8),
                ],
                
                // Text content
                if (content.isNotEmpty)
                  Text(
                    content,
                    style: AppTextStyles.chatMessage.copyWith(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                
                // Streaming cursor
                if (isStreaming && content.isNotEmpty)
                  _buildStreamingCursor(),
              ],
            ),
          ),
          
          // Timestamp
          if (showTimestamp && !isStreaming) ...[
            const SizedBox(height: 4),
            Text(
              message.formattedTime,
              style: AppTextStyles.timestamp,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: message.attachments.map((attachment) {
        if (attachment.kind == 'image') {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: attachment.downloadUrl != null
                ? Image.network(
                    attachment.downloadUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        color: AppColors.surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: AppColors.surface,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 200,
                    height: 200,
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildStreamingCursor() {
    return Container(
      margin: const EdgeInsets.only(left: 2),
      child: Container(
        width: 2,
        height: 16,
        color: AppColors.accent,
      )
          .animate(onPlay: (controller) => controller.repeat())
          .fadeIn(duration: 500.ms)
          .then()
          .fadeOut(duration: 500.ms),
    );
  }
}

/// Empty message state for AI message being generated
class StreamingBubble extends StatelessWidget {
  final String content;

  const StreamingBubble({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 60,
        top: 4,
        bottom: 4,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.aiBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: AppColors.aiBubbleBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                content,
                style: AppTextStyles.chatMessage,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 2),
              width: 2,
              height: 16,
              color: AppColors.accent,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 500.ms)
                .then()
                .fadeOut(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
