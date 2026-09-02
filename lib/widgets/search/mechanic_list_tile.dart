import 'package:flutter/material.dart';

import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../common/premium_surface.dart';

/// Generic mechanic result row used by the search results list.
class MechanicListTile extends StatelessWidget {
  const MechanicListTile({super.key, required this.mechanic, this.onTap});

  final Mechanic mechanic;
  final VoidCallback? onTap;

  static const _borderRadius = AppRadius.md;
  static const _padding = EdgeInsets.all(AppSpacing.md);
  static const _margin = EdgeInsets.only(bottom: AppSpacing.md);
  static const _avatarSize = 60.0;

  static final Color _avatarBackground = Color.alphaBlend(AppColors.primary.withValues(alpha: 0.12), Colors.white);

  // First letter of the first two words (e.g. "Hızlı Lastikçi" -> "HL") —
  // an identity mark in place of a generic icon, same idea as the approved
  // mockup's avatar. Falls back to a single '?' for an empty name rather
  // than crashing on an empty word list.
  String get _initials {
    final words = mechanic.name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '?';
    final first = words.first.substring(0, 1);
    final second = words.length > 1 ? words[1].substring(0, 1) : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: _padding,
      margin: _margin,
      borderRadius: _borderRadius,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _avatarBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
            ),
            child: Text(
              _initials,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mechanic.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle,
                      ),
                    ),
                    if (mechanic.isVerified) ...[
                      const SizedBox(width: 5),
                      const _VerifiedMark(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mechanic.specialtyLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 8),
                _RatingPill(rating: mechanic.rating, reviewCount: mechanic.reviewCount),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mechanic.priceFromLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              // No open/closed chip when isOpen is null (no working hours
              // entered yet) — unknown, not a default "closed".
              if (mechanic.isOpen != null) ...[
                const SizedBox(height: 6),
                _StatusPill(isOpen: mechanic.isOpen!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Small filled checkmark disc next to a verified mechanic's name — the
/// same [AppColors.verified] token everywhere else "Doğrulanmış" appears,
/// instead of a plain green icon with no dedicated meaning of its own.
class _VerifiedMark extends StatelessWidget {
  const _VerifiedMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: const BoxDecoration(color: AppColors.verified, shape: BoxShape.circle),
      child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating, required this.reviewCount});

  final double rating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ratingBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.rating, size: 14),
          const SizedBox(width: 3),
          Text(
            '$rating ($reviewCount)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92720A)),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.open : AppColors.closed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.openBackground : AppColors.closedBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'Açık' : 'Kapalı',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
