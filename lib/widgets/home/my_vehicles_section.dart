import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/pending_booking_vehicle.dart';
import '../../mechanic/appointments/data/appointment.dart';
import '../../mechanic/appointments/data/appointment_repository.dart';
import '../../models/vehicle.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_instances.dart';
import '../common/premium_surface.dart';
import 'section_header.dart';

/// The customer's garage — derived live from their own real appointment
/// history (distinct (araçModeli, plaka) pairs out of
/// AppointmentRepository.watchCustomerAppointments), most recently used
/// first. Deliberately not a separate user-managed vehicle store: no such
/// Firestore collection exists, and inventing one (plus the "add/edit
/// vehicle" UI it would need) was explicitly scoped out — this is "vehicles
/// you've booked with before", not a garage a customer curates by hand.
/// "Yeni Araç Ekle" stays a stub for the same reason.
///
/// Tapping a real vehicle reuses the exact same "Araç Tamiri" entry point
/// [onCategoryTap] the homepage's own Araç Tamiri card calls (see
/// HomeTab/MainShell._openVehicleRepair) — it only additionally stashes the
/// tapped vehicle in [PendingBookingVehicle] first, so
/// AppointmentRequestPage can pre-fill from it once the customer reaches
/// the end of that same, unmodified sub-service -> mechanic -> booking-form
/// flow every other entry point already uses.
class MyVehiclesSection extends StatefulWidget {
  const MyVehiclesSection({super.key, this.onCategoryTap});

  final ValueChanged<String>? onCategoryTap;

  @override
  State<MyVehiclesSection> createState() => _MyVehiclesSectionState();
}

class _MyVehiclesSectionState extends State<MyVehiclesSection> {
  StreamSubscription<List<Appointment>>? _subscription;
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    // Guests (no signed-in Firebase user) have no real customerId to query
    // by — same "left on empty" treatment as every other guest path in
    // this app (see AppointmentsTab), not a fabricated vehicle list.
    final uid = firebaseAuthInstance.currentUser?.uid;
    if (uid == null) return;
    _subscription = AppointmentRepository().watchCustomerAppointments(uid).listen(
      (appointments) {
        if (!mounted) return;
        setState(() => _appointments = appointments);
      },
      onError: (Object error) {
        debugPrint('MY VEHICLES LISTENER ERROR: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // Distinct (vehicleModel, licensePlate) pairs, most recently booked
  // first. Blank vehicleModel entries are skipped — never a made-up label.
  List<Vehicle> get _vehicles {
    final sorted = [..._appointments]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final seen = <String>{};
    final vehicles = <Vehicle>[];
    for (final appointment in sorted) {
      final model = appointment.vehicleModel.trim();
      if (model.isEmpty) continue;
      final plate = appointment.licensePlate.trim();
      final key = '$model|$plate';
      if (!seen.add(key)) continue;
      vehicles.add(Vehicle(modelLabel: model, licensePlate: plate));
    }
    return vehicles;
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openBookingFor(Vehicle vehicle) {
    PendingBookingVehicle.set(vehicleLabel: vehicle.modelLabel, licensePlate: vehicle.licensePlate);
    widget.onCategoryTap?.call('Araç Tamiri');
  }

  static const _headerToContentSpacing = AppSpacing.md;
  static const _listCardPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  static const _rowVerticalPadding = EdgeInsets.symmetric(vertical: AppSpacing.md);

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehicles;
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
              if (vehicles.isEmpty)
                const Padding(padding: _rowVerticalPadding, child: _NoVehiclesYet())
              else
                for (final vehicle in vehicles) ...[
                  Padding(
                    padding: _rowVerticalPadding,
                    child: _VehicleRow(vehicle: vehicle, onTap: () => _openBookingFor(vehicle)),
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

class _NoVehiclesYet extends StatelessWidget {
  const _NoVehiclesYet();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.directions_car_outlined, color: AppColors.textSecondary, size: 22),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Henüz aracınız yok. Randevu aldığınızda araçlarınız burada görünecek.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
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
                  vehicle.modelLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  // No made-up plate when the customer's own past booking
                  // never had one entered — same "omit, don't invent" rule
                  // as everywhere else real data is missing in this app.
                  vehicle.licensePlate.isEmpty ? 'Plaka belirtilmemiş' : vehicle.licensePlate,
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
