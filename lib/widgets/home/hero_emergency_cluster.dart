import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Arranges the hero (search) card and the emergency card responsively:
/// side by side (roughly 70/30) at tablet/web widths, stacked on phones.
/// On the wide layout the two cards are forced to equal height via
/// [IntrinsicHeight] + a stretched [Row] — the emergency card is much
/// narrower but should still visually anchor to the hero card's height
/// rather than floating at its own shorter natural size.
class HeroEmergencyCluster extends StatelessWidget {
  const HeroEmergencyCluster({super.key, required this.hero, required this.emergency});

  final Widget hero;
  final Widget emergency;

  /// Below this width: stacked. At or above: side by side. Matches Material
  /// 3's compact/medium window-size-class cutoff.
  static const _wideBreakpoint = 600.0;
  static const _spacing = AppSpacing.xxl;
  static const _heroFlex = 3;
  static const _emergencyFlex = 1;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: _heroFlex, child: hero),
            const SizedBox(width: _spacing),
            Expanded(flex: _emergencyFlex, child: emergency),
          ],
        ),
      );
    }

    return Column(
      children: [
        hero,
        const SizedBox(height: _spacing),
        emergency,
      ],
    );
  }
}
