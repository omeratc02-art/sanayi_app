import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/premium_surface.dart';

/// Tappable icon + title + subtitle + chevron card, used across category
/// landing pages (e.g. [MaintenanceSubcategoryPage], oil-change services)
/// as the entry point into a dedicated detail page. Deliberately carries no
/// pricing or action buttons of its own — that's the destination page's job.
class ServiceEntryCard extends StatelessWidget {
  const ServiceEntryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const _iconSize = 52.0;
  static const _iconInnerSize = 26.0;

  static final Color _iconBackground = Color.alphaBlend(AppColors.primary.withValues(alpha: 0.12), Colors.white);

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Row(
        children: [
          Container(
            width: _iconSize,
            height: _iconSize,
            decoration: BoxDecoration(color: _iconBackground, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primaryDark, size: _iconInnerSize),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
