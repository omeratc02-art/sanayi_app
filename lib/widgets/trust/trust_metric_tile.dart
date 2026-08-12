import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Compact icon + value + label stat, used to build the trust-metric grid on
/// mechanic cards. Shared so future sections (e.g. top-rated) can adopt the
/// same trust signals without duplicating layout code.
class TrustMetricTile extends StatelessWidget {
  const TrustMetricTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  static const _iconSize = 15.0;
  static const _iconSpacing = 6.0;
  static const _valueFontSize = 12.5;
  static const _labelFontSize = 10.0;
  static const _labelMaxLines = 2;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: _iconSize, color: iconColor),
        ),
        const SizedBox(width: _iconSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: _valueFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                maxLines: _labelMaxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: _labelFontSize, color: AppColors.textSecondary, height: 1.15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
