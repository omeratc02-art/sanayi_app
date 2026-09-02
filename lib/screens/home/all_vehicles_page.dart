import 'package:flutter/material.dart';

import '../../data/pending_booking_vehicle.dart';
import '../../models/vehicle.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/my_vehicles_section.dart' show VehicleRow;

/// "Tümünü Gör" destination for MyVehiclesSection's own "Araçlarım"
/// header — the full list of vehicles derived from the customer's real
/// appointment history, beyond the homepage's 3-item preview. Receives the
/// already-derived list rather than opening its own
/// watchCustomerAppointments subscription, so there's no second live
/// listener on the same query. Reuses VehicleRow verbatim (same look, same
/// tap behavior via the shared openVehicleBooking) so this list never
/// visually or behaviorally diverges from the homepage preview it's an
/// extension of.
class AllVehiclesPage extends StatelessWidget {
  const AllVehiclesPage({super.key, required this.vehicles, this.onCategoryTap});

  final List<Vehicle> vehicles;
  final ValueChanged<String>? onCategoryTap;

  static const _rowSpacing = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Araçlarım')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.xl),
          itemCount: vehicles.length,
          separatorBuilder: (_, _) => const SizedBox(height: _rowSpacing),
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            // Material ancestor for VehicleRow's own InkWell to splash
            // against — VehicleRow already owns its tap handling/InkWell,
            // so this only supplies the ink-rendering surface plus the
            // card border, not a second tap target.
            return Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.divider),
                ),
                child: VehicleRow(
                  vehicle: vehicle,
                  onTap: () => openVehicleBooking(vehicle: vehicle, onCategoryTap: onCategoryTap),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
