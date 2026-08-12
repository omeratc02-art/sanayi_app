import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/premium_surface.dart';

/// Shared body for maintenance detail pages (see [MaintenanceRoutineDetailPage]
/// and [MaintenanceMajorDetailPage]) — the same three-card layout (parts
/// replacement, inspections, information note) with different content per
/// maintenance tier. Everything renders at once, no accordions/tabs, since
/// these pages are purely informational.
class MaintenanceDetailSections extends StatelessWidget {
  const MaintenanceDetailSections({
    super.key,
    required this.partsReplacement,
    required this.inspections,
    required this.informationText,
  });

  final List<String> partsReplacement;
  final List<String> inspections;
  final String informationText;

  static const _sectionSpacing = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _MaintenanceSection(
          emoji: '✅',
          title: 'Parça Değişimi',
          items: partsReplacement,
          icon: Icons.check_circle_rounded,
          iconColor: Colors.green.shade600,
        ),
        const SizedBox(height: _sectionSpacing),
        _MaintenanceSection(
          emoji: '🔍',
          title: 'Kontroller',
          items: inspections,
          icon: Icons.search_rounded,
          iconColor: AppColors.primary,
        ),
        const SizedBox(height: _sectionSpacing),
        _InformationSection(text: informationText),
      ],
    );
  }
}

class _MaintenanceSection extends StatelessWidget {
  const _MaintenanceSection({
    required this.emoji,
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  final String emoji;
  final String title;
  final List<String> items;
  final IconData icon;
  final Color iconColor;

  static const _headerSpacing = AppSpacing.md;
  static const _itemSpacing = AppSpacing.sm + 2;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: _headerSpacing),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: _itemSpacing),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('ℹ️', style: TextStyle(fontSize: 18)),
              SizedBox(width: AppSpacing.sm),
              Text('Bilgi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45)),
        ],
      ),
    );
  }
}
