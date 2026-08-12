import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shared modern Material 3 bottom sheet explaining a trust metric —
/// used by both the Repeat Preference and Verified Service indicators, on
/// both [ServiceCenterCard] and the mechanic profile page, so the
/// explanation stays identical everywhere it's shown.
Future<void> showTrustInfoSheet(
  BuildContext context, {
  required IconData icon,
  required Color accentColor,
  required String title,
  required String description,
  String? highlight,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(accentColor.withValues(alpha: 0.12), Colors.white),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              if (highlight != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(accentColor.withValues(alpha: 0.1), Colors.white),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: accentColor, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          highlight,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: accentColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      );
    },
  );
}
