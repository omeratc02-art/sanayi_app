/// Minimal in-memory record of which service providers the current session
/// has completed a booking with — this app has no backend/auth, so this is
/// the closest simulable stand-in for "the user has completed a service
/// through the app" used to gate review submission. Resets on app restart.
class BookingHistory {
  BookingHistory._();

  static final Set<String> _completedMechanicNames = {};

  static void markCompleted(String mechanicName) => _completedMechanicNames.add(mechanicName);

  static bool hasCompleted(String mechanicName) => _completedMechanicNames.contains(mechanicName);
}
