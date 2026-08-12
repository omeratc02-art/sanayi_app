enum AppointmentRequestStatus { pendingProvider, providerProposed, confirmed, declined }

/// A "preferred time window" appointment request — the customer picks a
/// window rather than an exact time, and the service provider proposes the
/// exact arrival time afterward based on their workload. See
/// [AppointmentRequestStore] for the (simulated, in-memory) provider side.
class AppointmentRequest {
  AppointmentRequest({
    required this.id,
    required this.mechanicName,
    required this.date,
    required this.preferredWindowLabel,
    required this.serviceLabel,
    required this.customerId,
    required this.businessId,
    this.vehicleLabel,
    this.status = AppointmentRequestStatus.pendingProvider,
    this.proposedTime,
  });

  final String id;
  final String mechanicName;
  final DateTime date;
  final String preferredWindowLabel;
  final String serviceLabel;
  final String? vehicleLabel;
  AppointmentRequestStatus status;
  String? proposedTime;

  /// The submitting customer's identity — the same Firebase Auth UID (or
  /// 'customer-demo' guest fallback) already used for chat sender ids, see
  /// CustomerConversationPage._customerSenderId. Not a new identity system.
  final String customerId;

  /// The stable business id (mechanicChatId(mechanicName)) this request
  /// targets — the same id already used by chats/{chatId} and
  /// mechanicAccounts.businessId, so it can be matched against a signed-in
  /// mechanic's own businessId without comparing free-text names.
  final String businessId;
}
