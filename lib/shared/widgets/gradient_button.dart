import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// Gradient button with animated effects
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double height;
  final double borderRadius;
  final Gradient? gradient;
  final IconData? icon;
  final bool iconLeading;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
    this.gradient,
    this.icon,
    this.iconLeading = true,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isEnabled && !widget.isLoading;
    final effectiveGradient = widget.gradient ?? AppColors.primaryGradient;

    return GestureDetector(
      onTapDown: isActive ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isActive ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isActive ? () => setState(() => _isPressed = false) : null,
      onTap: isActive ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isActive
              ? effectiveGradient
              : LinearGradient(
                  colors: [
                    AppColors.textTertiary.withOpacity(0.3),
                    AppColors.textTertiary.withOpacity(0.2),
                  ],
                ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: _isPressed ? 8 : 16,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.textOnPrimary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null && widget.iconLeading) ...[
                      Icon(
                        widget.icon,
                        color: AppColors.textOnPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.text,
                      style: AppTextStyles.button.copyWith(
                        color: isActive
                            ? AppColors.textOnPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    if (widget.icon != null && !widget.iconLeading) ...[
                      const SizedBox(width: 10),
                      Icon(
                        widget.icon,
                        color: AppColors.textOnPrimary,
                        size: 20,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Outlined button with glass effect
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;

  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 52,
    this.icon,
    this.borderColor,
    this.textColor,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isPressed
              ? AppColors.glassBg.withOpacity(0.1)
              : AppColors.glassBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.borderColor ?? AppColors.glassBorder,
            width: 1.5,
          ),
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: widget.textColor ?? AppColors.textPrimary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.textColor ?? AppColors.textPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.text,
                      style: AppTextStyles.button.copyWith(
                        color: widget.textColor ?? AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Icon button with glow effect
class GlowIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? glowColor;
  final bool showGlow;

  const GlowIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24,
    this.color,
    this.glowColor,
    this.showGlow = true,
  });

  @override
  State<GlowIconButton> createState() => _GlowIconButtonState();
}

class _GlowIconButtonState extends State<GlowIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? AppColors.accent;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed ? AppColors.glassBg : Colors.transparent,
          boxShadow: widget.showGlow && _isPressed
              ? [
                  BoxShadow(
                    color: widget.glowColor ?? iconColor.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Icon(
          widget.icon,
          size: widget.size,
          color: iconColor,
        ),
      ),
    );
  }
}
