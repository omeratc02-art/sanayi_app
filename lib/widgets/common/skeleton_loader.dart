import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A single shimmering placeholder block — the base unit every skeleton
/// screen in the app should compose from, so every loading state gets the
/// same shimmer speed/color instead of each screen hand-rolling its own.
/// Hand-rolled (AnimationController + a moving gradient), not a package —
/// the effect is simple enough that a dependency isn't worth it.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.borderRadius = AppRadius.sm});

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sweeps a lighter band left-to-right, looping — the classic
        // shimmer read as "loading", not just a static gray block.
        final sweep = _controller.value * 2.6 - 0.8;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(sweep - 0.4, 0),
              end: Alignment(sweep + 0.4, 0),
              colors: [
                AppColors.divider,
                AppColors.divider.withValues(alpha: 0.4),
                AppColors.divider,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder matching [MechanicListTile]'s exact layout — same avatar
/// size, same padding/margin, same PremiumSurface shell — so the swap from
/// skeleton to real content on load doesn't cause a visible layout jump.
class MechanicListTileSkeleton extends StatelessWidget {
  const MechanicListTileSkeleton({super.key});

  static const _avatarSize = 60.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: _avatarSize, height: _avatarSize, borderRadius: AppRadius.sm + 2),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 140, height: 15),
                const SizedBox(height: 8),
                const SkeletonBox(width: 96, height: 12),
                const SizedBox(height: 10),
                SkeletonBox(width: 64, height: 12, borderRadius: AppRadius.sm),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: const [
              SkeletonBox(width: 46, height: 14),
              SizedBox(height: 8),
              SkeletonBox(width: 52, height: 18, borderRadius: 20),
            ],
          ),
        ],
      ),
    );
  }
}

/// A vertical stack of [count] [MechanicListTileSkeleton]s — drop-in
/// replacement for a bare spinner wherever a mechanic list is loading.
class MechanicListSkeleton extends StatelessWidget {
  const MechanicListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: count,
      itemBuilder: (context, index) => const MechanicListTileSkeleton(),
    );
  }
}
