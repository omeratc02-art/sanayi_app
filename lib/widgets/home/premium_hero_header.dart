import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A large, saturated turquoise-to-primary gradient card — the app's
/// single most "branded" surface. No search field here: the hero's only
/// job is to explain what the app is (a trusted-mechanic discovery
/// platform), so it's kept compact and text-led rather than built around
/// an input the user needs to act on.
class PremiumHeroHeader extends StatelessWidget {
  const PremiumHeroHeader({super.key});

  static const _padding = EdgeInsets.all(AppSpacing.xl);
  static const _illustrationSpacing = AppSpacing.md;
  static const _titleSpacing = AppSpacing.sm;
  static const _titleFontSize = 18.0;
  static const _subtitleFontSize = 12.0;
  static const _decorIconSize = 110.0;
  static const _decorIconAlpha = 0.10;

  static const _gradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.primary,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -22,
            right: -22,
            child: Opacity(
              opacity: _decorIconAlpha,
              child: const Icon(Icons.directions_car_filled, size: _decorIconSize, color: Colors.white),
            ),
          ),
          Padding(
            padding: _padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _HeroIllustration(),
                const SizedBox(width: _illustrationSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Find the right mechanic with confidence."
                      const Text(
                        'Doğru ustayı güvenle bulun.',
                        style: TextStyle(
                          fontSize: _titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: _titleSpacing),
                      Text(
                        'Doğrulanmış ustaları keşfedin, gerçek müşteri yorumlarını inceleyin, '
                        'güvenilir hizmet sağlayıcılarını karşılaştırın ve randevunuzu güvenle oluşturun.',
                        style: TextStyle(
                          fontSize: _subtitleFontSize,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  static const _size = 60.0;
  static const _circleSize = 52.0;
  static const _carIconSize = 30.0;
  static const _badgeSize = 24.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: _circleSize,
              height: _circleSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car_filled, size: _carIconSize, color: Colors.white),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: _badgeSize,
              height: _badgeSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primary, size: 13),
            ),
          ),
        ],
      ),
    );
  }
}
