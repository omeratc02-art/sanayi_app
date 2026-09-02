import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/premium_surface.dart';

/// One of the homepage's 3 main service-category cards (Araç Tamiri,
/// Ekspertiz, Sigorta) — a full-width, solid-color PremiumSurface with an
/// icon, title, one-line subtitle, and a small circular arrow affordance
/// pinned to the bottom-right. Deliberately generic/reusable rather than 3
/// near-identical bespoke widgets, since all 3 only differ in color/icon/text.
class ServiceCategoryCard extends StatelessWidget {
  const ServiceCategoryCard({
    super.key,
    required this.icon,
    this.overlayIcon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;

  /// Small badge icon overlapping [icon]'s bottom-right corner — e.g. a
  /// wrench over the car icon for Araç Tamiri, making "repair" explicit
  /// rather than relying on a single icon to carry both car + repair
  /// meaning. Null (the default, used by Ekspertiz/Sigorta) renders just
  /// [icon] alone with no overlap.
  final IconData? overlayIcon;
  final String title;
  final String subtitle;

  /// One of AppColors.vehicleRepair/inspection/insurance — see that file's
  /// doc comment for why these get their own reserved colors instead of
  /// the app's usual turquoise-only accent.
  final Color color;
  final VoidCallback? onTap;

  static const _padding = EdgeInsets.all(AppSpacing.lg);
  static const _iconSize = 32.0;
  static const _iconBadgeSize = 60.0;
  static const _overlayIconSize = 17.0;
  static const _overlayBadgeSize = 26.0;
  static const _titleFontSize = 16.0;
  static const _subtitleFontSize = 12.5;
  static const _arrowButtonSize = 32.0;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: _padding,
      borderRadius: AppRadius.lg,
      color: color,
      liftScale: 1.01,
      restShadow: AppShadows.coloredCard(color),
      liftedShadow: AppShadows.coloredCardLifted(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: _iconBadgeSize,
                height: _iconBadgeSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: _iconSize),
              ),
              if (overlayIcon != null)
                Positioned(
                  right: -4,
                  bottom: -4,
                  // Same white-circle-plus-card-color-icon treatment as the
                  // arrow button below, for visual consistency between the
                  // two overlapping-badge elements on this card.
                  child: Container(
                    width: _overlayBadgeSize,
                    height: _overlayBadgeSize,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Icon(overlayIcon, color: color, size: _overlayIconSize),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: _titleFontSize, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: TextStyle(fontSize: _subtitleFontSize, color: Colors.white.withValues(alpha: 0.85), height: 1.35),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: _arrowButtonSize,
              height: _arrowButtonSize,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_rounded, size: 16, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
