import 'package:flutter/material.dart';

/// Prominent trust signal shown on its own row on mechanic cards — deliberately
/// distinct from the small "Onaylı Usta" chip on the detail page, since here it
/// needs to read as a standalone reason to trust the mechanic, not a minor tag.
class VerifiedTrustBadge extends StatelessWidget {
  const VerifiedTrustBadge({super.key});

  static const _horizontalPadding = 8.0;
  static const _verticalPadding = 5.0;
  static const _borderRadius = 10.0;
  static const _iconSize = 13.0;
  static const _iconSpacing = 4.0;
  static const _fontSize = 10.5;
  static const _backgroundAlpha = 0.12;
  static const _borderAlpha = 0.3;

  @override
  Widget build(BuildContext context) {
    final verifiedColor = Colors.green[700]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding, vertical: _verticalPadding),
      decoration: BoxDecoration(
        color: verifiedColor.withValues(alpha: _backgroundAlpha),
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: verifiedColor.withValues(alpha: _borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: verifiedColor, size: _iconSize),
          const SizedBox(width: _iconSpacing),
          Flexible(
            child: Text(
              'Doğrulanmış Usta',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w700, color: verifiedColor),
            ),
          ),
        ],
      ),
    );
  }
}
