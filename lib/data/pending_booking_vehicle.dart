/// Carries the vehicle a customer picked from "Araçlarım" (see
/// MyVehiclesSection) through the existing Araç Tamiri -> sub-service ->
/// AppointmentRequestPage navigation chain, without threading a new
/// constructor param through every intermediate screen in that chain
/// (VehicleRepairCategoryPage, each sub-category page, ServiceListingPage,
/// ServiceCenterCard) — none of which need to know or care about it.
/// Mirrors BookingHistory's existing minimal in-memory session-singleton
/// pattern. Consumed (read + cleared) exactly once, by
/// AppointmentRequestPage.initState, so a flow abandoned partway through
/// can never leak into a later, unrelated booking.
class PendingBookingVehicle {
  PendingBookingVehicle._();

  static String? _vehicleLabel;
  static String? _licensePlate;

  static void set({required String vehicleLabel, required String licensePlate}) {
    _vehicleLabel = vehicleLabel;
    _licensePlate = licensePlate;
  }

  /// Returns the pending vehicle (if any) and clears it in the same call —
  /// null once nothing is pending, or after a previous consume().
  static ({String vehicleLabel, String licensePlate})? consume() {
    final label = _vehicleLabel;
    final plate = _licensePlate;
    _vehicleLabel = null;
    _licensePlate = null;
    if (label == null) return null;
    return (vehicleLabel: label, licensePlate: plate ?? '');
  }
}
