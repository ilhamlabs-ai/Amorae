import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/theme/app_colors.dart';

/// Avatar widget with glow effect for AI companion
class AvatarCircle extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final bool showGlow;
  final Color? glowColor;
  final bool isOnline;
  final bool isAI;
  final VoidCallback? onTap;

  const AvatarCircle({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 48,
    this.showGlow = false,
    this.glowColor,
    this.isOnline = false,
    this.isAI = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isAI ? AppColors.primaryGradient : null,
        color: !isAI ? AppColors.surface : null,
        border: Border.all(
          color: AppColors.glassBorder,
          width: 2,
        ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: glowColor ??
                      (isAI ? AppColors.primaryGlow : AppColors.accentGlow),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(),
                errorWidget: (context, url, error) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );

    Widget result = avatar;

    // Add online indicator
    if (isOnline || isAI) {
      result = Stack(
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAI ? AppColors.accent : AppColors.success,
                border: Border.all(
                  color: AppColors.background,
                  width: 2,
                ),
              ),
              child: isAI
                  ? Icon(
                      Icons.auto_awesome,
                      size: size * 0.14,
                      color: AppColors.textOnPrimary,
                    )
                  : null,
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: result,
      );
    }

    return result;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildInitials() {
    return Container(
      decoration: BoxDecoration(
        gradient: isAI ? AppColors.primaryGradient : null,
        color: !isAI ? AppColors.surfaceLight : null,
      ),
      child: Center(
        child: initials != null
            ? Text(
                initials!,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(
                isAI ? Icons.auto_awesome : Icons.person,
                size: size * 0.45,
                color: AppColors.textSecondary,
              ),
      ),
    );
  }
}

/// AI Companion Avatar with animated glow
class AIAvatar extends StatefulWidget {
  final double size;
  final bool isTyping;
  final String? imageUrl;

  const AIAvatar({
    super.key,
    this.size = 48,
    this.isTyping = false,
    this.imageUrl,
  });

  @override
  State<AIAvatar> createState() => _AIAvatarState();
}

class _AIAvatarState extends State<AIAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isTyping) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AIAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTyping && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isTyping && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryStart
                    .withOpacity(widget.isTyping ? _glowAnimation.value : 0.3),
                blurRadius: widget.isTyping ? 24 : 12,
                spreadRadius: widget.isTyping ? 2 : 0,
              ),
            ],
          ),
          child: ClipOval(
            child: widget.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.favorite,
                      size: widget.size * 0.45,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
