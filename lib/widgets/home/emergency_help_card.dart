import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/premium_surface.dart';

/// Not a category — a standalone, high-urgency call to action. Title and
/// subtitle lead, a faint oversized siren icon sits in the corner as a
/// decorative illustration (no custom siren asset exists, so the closest
/// Material icon substitutes for it), and the call-to-action is a distinct
/// white pill button rather than a generic row — it should read as
/// "press this" the way a real emergency button does.
class EmergencyHelpCard extends StatelessWidget {
  const EmergencyHelpCard({super.key, this.onTap});

  final VoidCallback? onTap;

  static const _padding = EdgeInsets.all(AppSpacing.lg);
  static const _titleFontSize = 19.0;
  static const _subtitleFontSize = 12.5;
  static const _titleSubtitleSpacing = AppSpacing.sm - 2;
  static const _subtitleButtonSpacing = AppSpacing.lg;
  static const _illustrationSize = 96.0;
  static const _illustrationAlpha = 0.16;

  static const _gradient = LinearGradient(
    colors: [AppColors.emergency, AppColors.emergencyDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: _padding,
      borderRadius: AppRadius.xxl,
      gradient: _gradient,
      liftScale: 1.015,
      restShadow: AppShadows.coloredCard(AppColors.emergency),
      liftedShadow: AppShadows.coloredCardLifted(AppColors.emergency),
      child: Stack(
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -14,
            right: -14,
            child: Opacity(
              opacity: _illustrationAlpha,
              child: const Icon(Icons.emergency_rounded, size: _illustrationSize, color: Colors.white),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Acil Yardım',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: _titleFontSize, color: Colors.white),
                ),
                const SizedBox(height: _titleSubtitleSpacing),
                const Text(
                  'Yolda mı kaldınız? Size en yakın ustaya hemen ulaşın.',
                  style: TextStyle(fontSize: _subtitleFontSize, color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: _subtitleButtonSpacing),
                const _CallHelpPill(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallHelpPill extends StatelessWidget {
  const _CallHelpPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.call, color: AppColors.emergency, size: 16),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            'Yardım Çağır',
            style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.emergency, size: 18),
        ],
      ),
    );
  }
}
