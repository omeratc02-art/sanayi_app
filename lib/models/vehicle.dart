/// A distinct (model, plate) pair derived from the customer's own past
/// appointment history — see MyVehiclesSection's own doc comment for why
/// there's no dedicated, user-managed vehicle store this reads from
/// instead.
class Vehicle {
  final String modelLabel;
  final String licensePlate;

  const Vehicle({required this.modelLabel, required this.licensePlate});
}
