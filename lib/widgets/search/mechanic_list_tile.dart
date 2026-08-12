import 'package:flutter/material.dart';

import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../common/premium_surface.dart';

/// Generic mechanic result row used by the search results list.
class MechanicListTile extends StatelessWidget {
  const MechanicListTile({super.key, required this.mechanic, this.onTap});

  final Mechanic mechanic;
  final VoidCallback? onTap;

  static const _borderRadius = AppRadius.md;
  static const _padding = EdgeInsets.all(AppSpacing.md);
  static const _margin = EdgeInsets.only(bottom: AppSpacing.md);
  static const _avatarSize = 60.0;
  static const _avatarIconSize = 28.0;

  static final Color _avatarBackground = Color.alphaBlend(AppColors.primary.withValues(alpha: 0.12), Colors.white);

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: _padding,
      margin: _margin,
      borderRadius: _borderRadius,
      child: Row(
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            decoration: BoxDecoration(
              color: _avatarBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
            child: const Icon(Icons.build_circle, color: AppColors.primaryDark, size: _avatarIconSize),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mechanic.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  mechanic.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 3,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 15),
                    Text(
                      '${mechanic.rating} (${mechanic.reviewCount})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 7),
                    const Icon(Icons.location_on, color: AppColors.textSecondary, size: 14),
                    Text(
                      mechanic.distanceLabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mechanic.priceFromLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (mechanic.isOpen ? Colors.green : AppColors.textSecondary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mechanic.isOpen ? 'Açık' : 'Kapalı',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mechanic.isOpen ? Colors.green[700] : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
