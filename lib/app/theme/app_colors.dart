import 'package:flutter/material.dart';

/// Amorae App Color Palette
/// Modern, aesthetic colors with romantic/companion feel
class AppColors {
  AppColors._();

  // Primary Gradient Colors
  static const Color primaryStart = Color(0xFF7C3AED); // Vibrant violet
  static const Color primaryEnd = Color(0xFFDB2777); // Deep pink
  static const Color primaryMid = Color(0xFFA855F7); // Purple

  // Secondary/Accent Colors
  static const Color accent = Color(0xFFF472B6); // Rose pink
  static const Color accentLight = Color(0xFFFBCFE8); // Light pink
  static const Color accentDark = Color(0xFFBE185D); // Dark rose

  // Background Colors (Dark Theme)
  static const Color background = Color(0xFF0A0A0F); // Deep dark
  static const Color backgroundSecondary = Color(0xFF12121A); // Slightly lighter
  static const Color surface = Color(0xFF1A1A24); // Card surfaces
  static const Color surfaceLight = Color(0xFF252532); // Elevated surfaces

  // Glass Effect Colors
  static const Color glassBg = Color(0x0DFFFFFF); // 5% white
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white
  static const Color glassHighlight = Color(0x33FFFFFF); // 20% white

  // Text Colors
  static const Color textPrimary = Color(0xFFF9FAFB); // Almost white
  static const Color textSecondary = Color(0xFFA1A1AA); // Muted gray
  static const Color textTertiary = Color(0xFF71717A); // Darker gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Pure white

  // Status Colors
  static const Color success = Color(0xFF34D399); // Mint green
  static const Color successDark = Color(0xFF059669); // Dark green
  static const Color warning = Color(0xFFFBBF24); // Amber
  static const Color error = Color(0xFFF87171); // Coral red
  static const Color errorDark = Color(0xFFDC2626); // Dark red
  static const Color info = Color(0xFF60A5FA); // Sky blue

  // Chat Bubble Colors
  static const Color userBubbleStart = Color(0xFF7C3AED);
  static const Color userBubbleEnd = Color(0xFF9333EA);
  static const Color aiBubble = Color(0xFF1F1F2E);
  static const Color aiBubbleBorder = Color(0xFF2A2A3C);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryStart, primaryEnd],
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryStart, primaryEnd],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF12121A),
      Color(0xFF0A0A0F),
    ],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1A24),
      Color(0xFF12121A),
    ],
  );

  static const LinearGradient userBubbleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [userBubbleStart, userBubbleEnd],
  );

  // Glow/Shadow Colors
  static const Color primaryGlow = Color(0x407C3AED); // 25% violet
  static const Color accentGlow = Color(0x40F472B6); // 25% pink
  static const Color shadowColor = Color(0x40000000); // 25% black

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFF1A1A24);
  static const Color shimmerHighlight = Color(0xFF2A2A3C);
}
