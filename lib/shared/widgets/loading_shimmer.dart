import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_colors.dart';

/// Shimmer loading effect for skeleton screens
class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Message bubble skeleton
class MessageShimmer extends StatelessWidget {
  final bool isUser;

  const MessageShimmer({
    super.key,
    this.isUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            LoadingShimmer(
              width: 36,
              height: 36,
              borderRadius: 18,
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              LoadingShimmer(
                width: 200,
                height: 16,
                borderRadius: 8,
              ),
              const SizedBox(height: 6),
              LoadingShimmer(
                width: 150,
                height: 16,
                borderRadius: 8,
              ),
              const SizedBox(height: 6),
              LoadingShimmer(
                width: 100,
                height: 16,
                borderRadius: 8,
              ),
            ],
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            LoadingShimmer(
              width: 36,
              height: 36,
              borderRadius: 18,
            ),
          ],
        ],
      ),
    );
  }
}

/// Thread list item skeleton
class ThreadShimmer extends StatelessWidget {
  const ThreadShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          LoadingShimmer(
            width: 52,
            height: 52,
            borderRadius: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingShimmer(
                  width: 120,
                  height: 16,
                  borderRadius: 8,
                ),
                const SizedBox(height: 8),
                LoadingShimmer(
                  width: double.infinity,
                  height: 14,
                  borderRadius: 7,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          LoadingShimmer(
            width: 40,
            height: 12,
            borderRadius: 6,
          ),
        ],
      ),
    );
  }
}

/// Card skeleton for general content
class CardShimmer extends StatelessWidget {
  final double height;

  const CardShimmer({
    super.key,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
