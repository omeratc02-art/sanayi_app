import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/vehicle.dart';
import '../../theme/app_theme.dart';
import '../common/premium_surface.dart';
import 'section_header.dart';

/// The user's garage — a simple, standalone list of registered vehicles.
/// Deliberately decoupled from any "request a quote" flow (that flow was
/// removed along with the Quick Price Quote section); this is just vehicle
/// management, matching the same list-card language as Upcoming
/// Maintenance / Recent Service History below it.
class MyVehiclesSection extends StatelessWidget {
  const MyVehiclesSection({super.key});

  static const _headerToContentSpacing = AppSpacing.md;
  static const _listCardPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static const _rowVerticalPadding = EdgeInsets.symmetric(vertical: AppSpacing.md);

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Araçlarım'),
        const SizedBox(height: _headerToContentSpacing),
        PremiumSurface(
          padding: _listCardPadding,
          borderRadius: AppRadius.lg,
          child: Column(
            children: [
              for (final vehicle in MockData.userVehicles) ...[
                Padding(
                  padding: _rowVerticalPadding,
                  child: _VehicleRow(
                    vehicle: vehicle,
                    onTap: () => _showComingSoon(context, 'Araç detayları yakında aktif olacak.'),
                  ),
                ),
                const Divider(height: 1),
              ],
              Padding(
                padding: _rowVerticalPadding,
                child: _AddVehicleRow(
                  onTap: () => _showComingSoon(context, 'Araç ekleme özelliği yakında aktif olacak.'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicle, required this.onTap});

  final Vehicle vehicle;
  final VoidCallback onTap;

  static const _iconSize = 40.0;
  static const _iconInnerSize = 20.0;
  static const _iconTextSpacing = AppSpacing.md;

  static final Color _iconBackground = Color.alphaBlend(AppColors.primary.withValues(alpha: 0.12), Colors.white);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: _iconSize,
            height: _iconSize,
            decoration: BoxDecoration(color: _iconBackground, shape: BoxShape.circle),
            child: const Icon(Icons.directions_car_filled, color: AppColors.primaryDark, size: _iconInnerSize),
          ),
          const SizedBox(width: _iconTextSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.year} modeli',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}

class _AddVehicleRow extends StatelessWidget {
  const _AddVehicleRow({required this.onTap});

  final VoidCallback onTap;

  static const _iconSize = 40.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: _iconSize,
            height: _iconSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Yeni Araç Ekle',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.primary),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}
