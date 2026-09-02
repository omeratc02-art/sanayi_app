import '../mechanic/appointments/data/appointment.dart';

/// A distinct (model, plate) pair derived from the customer's own past
/// appointment history — see MyVehiclesSection's own doc comment for why
/// there's no dedicated, user-managed vehicle store this reads from
/// instead.
class Vehicle {
  final String modelLabel;
  final String licensePlate;

  const Vehicle({required this.modelLabel, required this.licensePlate});
}

/// Distinct (vehicleModel, licensePlate) pairs out of [appointments], most
/// recently booked first — the one shared derivation MyVehiclesSection (the
/// homepage's 3-item preview) and AllVehiclesPage (the full "Tümünü Gör"
/// list) both call, so the two never risk drifting into different
/// dedup/ordering behavior. Blank vehicleModel entries are skipped — never
/// a made-up label.
List<Vehicle> deriveVehiclesFromAppointments(List<Appointment> appointments) {
  final sorted = [...appointments]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
