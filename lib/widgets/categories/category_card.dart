import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../theme/app_theme.dart';
import '../common/premium_surface.dart';

/// Flat, pastel-tinted category tile — the icon sits directly on the
/// card's tinted background rather than inside a separate circular badge,
/// and the card itself carries almost no shadow (a soft one only, no
/// two-layer "floating" treatment), matching a reference design where
/// these read as calm, flat surfaces rather than heavily elevated cards.
class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category, required this.onTap});

  final ServiceCategory category;
  final VoidCallback onTap;

  static const _padding = EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm);
  static const _iconSize = 38.0;
  static const _iconSpacing = AppSpacing.sm + 2;
  static const _titleFontSize = 13.0;
  static const _titleLetterSpacing = -0.1;
  static const _titleSubtitleSpacing = 2.0;
  static const _subtitleFontSize = 10.5;
  static const _liftScale = 1.04;

  static final Color _background = Color.alphaBlend(AppColors.primary.withValues(alpha: 0.08), Colors.white);

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: _padding,
      color: _background,
      liftScale: _liftScale,
      restShadow: AppShadows.soft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(category.icon, size: _iconSize, color: AppColors.primaryDark),
          const SizedBox(height: _iconSpacing),
          Text(
            category.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: _titleFontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: _titleLetterSpacing,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: _titleSubtitleSpacing),
          Text(
            category.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: _subtitleFontSize, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
