import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'brand_mark.dart';

/// A grey shape where content is coming, so a slow connection looks like
/// "on its way" instead of "stuck".
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.lineSoft, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Placeholder cards for a list that is loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3, this.height = 96});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          Container(
            height: height,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(AppRadius.card + 2),
            ),
            child: const Row(
              children: [
                Skeleton(width: 56, height: 56, radius: 14),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Skeleton(width: 160, height: 14),
                      SizedBox(height: 8),
                      Skeleton(width: 110, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Nothing here yet: the brand mark drawn faint, a line, and what to do.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.body, this.action, this.onAction});

  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: const CustomPaint(painter: BrandMarkPainter(color: AppColors.primary, stroke: 0.07)),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          if (body != null) ...[
            const SizedBox(height: 4),
            Text(body!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.inkSoft)),
          ],
          if (action != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
              child: Text(action!),
            ),
          ],
        ],
      ),
    );
  }
}
