import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import 'mock_data.dart';
import '../mechanic/appointments/data/appointment.dart';
import '../mechanic/appointments/data/appointment_repository.dart';
import '../models/appointment_request.dart';
import '../utils/chat_id.dart';
import '../utils/identity.dart';

/// In-memory stand-in for the provider side of the request flow — this app
/// has no backend, so a short delay simulates the service provider reviewing
/// a preferred time window and proposing an exact arrival time. Notifies
/// listeners (the Appointments tab, the nav-bar badge) on every change.
class AppointmentRequestStore extends ChangeNotifier {
  AppointmentRequestStore._();

  static final AppointmentRequestStore instance = AppointmentRequestStore._();

  final List<AppointmentRequest> _requests = [];

  // One real-time subscription per authenticated-customer request, keyed
  // by request.id (== the Firestore appointmentId) so a request already
  // being listened to is never subscribed a second time. Guests never get
  // an entry here — they stay on _simulateProviderResponse.
  final Map<String, StreamSubscription<Appointment?>> _subscriptions = {};

  List<AppointmentRequest> get requests => List.unmodifiable(_requests);

  bool get hasActionNeeded => _requests.any(
    (request) =>
        request.status == AppointmentRequestStatus.providerProposed ||
        request.status == AppointmentRequestStatus.declined,
  );

  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  // Converts a Firestore-persisted appointment into the AppointmentRequest
  // view model AppointmentRequestCard already renders. Called directly by
  // AppointmentsTab's own Firestore listener (watchCustomerAppointments) so
  // Upcoming/Past can be built straight from real Firestore results, not
  // only from this store's session-local _requests list — kept here rather
  // than duplicated in the screen because it needs the same
  // businessId->display-name resolution below and the same time formatting
  // _listenToRealAppointment already uses.
  AppointmentRequest appointmentRequestFromAccepted(Appointment appointment) {
    final formattedTime = _formatTimeOfDay(appointment.appointmentTime);
    return AppointmentRequest(
      id: appointment.appointmentId,
      mechanicName: _resolveMechanicName(appointment.businessId),
      date: appointment.appointmentDate,
      preferredWindowLabel: formattedTime,
      serviceLabel: appointment.serviceType,
      vehicleLabel: appointment.vehicleModel.isEmpty ? null : appointment.vehicleModel,
      customerId: appointment.customerId,
      businessId: appointment.businessId,
      status: AppointmentRequestStatus.confirmed,
      proposedTime: formattedTime,
    );
  }

  // appointments/{id}.businessId only ever stores the mechanicChatId slug
  // (see saveAppointment) — this reverses that back to a display name for
  // AppointmentRequestCard, the same way MechanicLoginPage's registration
  // dropdown originally derived the slug from a MockData entry's name.
  // Falls back to the raw slug on no match rather than a made-up label.
  String _resolveMechanicName(String businessId) {
    for (final mechanic in MockData.allMechanics) {
      if (mechanicChatId(mechanic.name) == businessId) return mechanic.name;
    }
    return businessId;
  }

  AppointmentRequest submit({
    required String mechanicName,
    required DateTime date,
    required String preferredWindowLabel,
    required String serviceLabel,
    String? vehicleLabel,
  }) {
    // Same identity patterns already used elsewhere in the app — not a new
    // identity system: customerId mirrors CustomerConversationPage's
    // Firebase-UID-or-guest-fallback sender id, businessId mirrors the same
    // mechanicChatId slug already used for chats/{chatId} and
    // mechanicAccounts.businessId.
    final customerId = resolveCustomerId();
    final businessId = mechanicChatId(mechanicName);
    // One id for the real-world request, shared by both representations.
    // Previously AppointmentRequest.id (a local "1", "2", ... counter) and
    // the persisted Appointment.appointmentId (a separately generated
    // Firestore auto-id) had no relationship at all — this request could
    // never be traced to its own Firestore document. Generating it once,
    // from the exact same source Appointment already uses, fixes that
    // with no schema change (see _persistToFirestore below, which now
    // reuses request.id instead of minting a second one).
    final appointmentId = AppointmentRepository().newAppointmentId();

    final request = AppointmentRequest(
      id: appointmentId,
      mechanicName: mechanicName,
      date: date,
      preferredWindowLabel: preferredWindowLabel,
      serviceLabel: serviceLabel,
      vehicleLabel: vehicleLabel,
      customerId: customerId,
      businessId: businessId,
    );
    _requests.insert(0, request);
    notifyListeners();
    _persistToFirestore(request);
    _startTrackingProviderResponse(request);
    return request;
  }

  // Persists the request to the same appointments collection/repository
  // the mechanic side already reads and writes (AppointmentRepository) —
  // not a new collection or model. This is fire-and-forget: submit() stays
  // synchronous (unchanged contract for its one existing caller,
  // AppointmentRequestPage), and a failed write is logged rather than
  // surfaced, since the request still exists locally either way and this
  // store has never had error-handling for its simulated actions.
  Future<void> _persistToFirestore(AppointmentRequest request) async {
    final appointment = Appointment(
      // Same id as request.id (see submit()) — this write and the request
      // object it came from now refer to the exact same Firestore document.
      appointmentId: request.id,
      customerId: request.customerId,
      customerName: FirebaseAuth.instance.currentUser?.email ?? 'Müşteri',
      customerPhone: '',
      vehicleBrand: '',
      vehicleModel: request.vehicleLabel ?? 'Belirtilmedi',
      licensePlate: '',
      serviceType: request.serviceLabel,
      // No exact time exists yet at request time (the mechanic proposes
      // one) — the preferred window is kept in customerNote instead of a
      // real time, since Appointment has no separate window field and
      // this avoids inventing one.
      appointmentDate: request.date,
      appointmentTime: const TimeOfDay(hour: 0, minute: 0),
      estimatedDuration: const Duration(minutes: 60),
      customerNote: 'Tercih edilen saat aralığı: ${request.preferredWindowLabel}',
      status: AppointmentStatus.pending,
      createdAt: DateTime.now(),
      distance: '',
      businessId: request.businessId,
    );

    try {
      await AppointmentRepository().saveAppointment(appointment);
    } catch (error) {
      debugPrint('APPOINTMENT REQUEST SAVE ERROR: $error');
    }
  }

  // Guests keep the exact original local-only behavior (nothing to write,
  // nothing that could fail). Authenticated customers now make this a real
  // Firestore operation — the local status only ever becomes confirmed
  // once acceptProposedTime actually succeeds; a failure leaves the
  // request's state completely untouched and is logged, never faked as a
  // success. Returns whether the accept actually took effect, so the
  // calling UI can react to a failure.
  Future<bool> accept(AppointmentRequest request) async {
    if (FirebaseAuth.instance.currentUser == null) {
      request.status = AppointmentRequestStatus.confirmed;
      notifyListeners();
      return true;
    }

    try {
      await AppointmentRepository().acceptProposedTime(request.id);
    } catch (error) {
      debugPrint('APPOINTMENT ACCEPT ERROR (${request.id}): $error');
      return false;
    }

    request.status = AppointmentRequestStatus.confirmed;
    notifyListeners();
    return true;
  }

  void requestAnotherTime(AppointmentRequest request, String newWindowLabel) {
    request
      ..status = AppointmentRequestStatus.pendingProvider
      ..proposedTime = null;
    notifyListeners();
    _startTrackingProviderResponse(request);
  }

  // Authenticated customers get the real Firestore document tracked live;
  // guests (no signed-in Firebase user) keep the exact same simulated
  // behavior as before — this is the only branch point between the two,
  // so nothing about the guest path changes.
  void _startTrackingProviderResponse(AppointmentRequest request) {
    if (FirebaseAuth.instance.currentUser != null) {
      _listenToRealAppointment(request);
    } else {
      _simulateProviderResponse(request);
    }
  }

  void _simulateProviderResponse(AppointmentRequest request) {
    Future.delayed(const Duration(seconds: 4), () {
      if (!_requests.contains(request)) return;
      request
        ..status = AppointmentRequestStatus.providerProposed
        ..proposedTime = _proposeArrivalTime(request.preferredWindowLabel);
      notifyListeners();
    });
  }

  // A request's own Firestore document never has an exact time until a
  // mechanic sets one (accepting, or proposing an alternative) — see
  // AppointmentRepository.saveAppointment's callers. This sentinel is the
  // same "no real time yet" convention already used across the mechanic
  // side (e.g. MechanicAppointmentsScreen._toPendingRequest) rather than a
  // new Firestore field.
  static const _noProposedTimeSentinel = TimeOfDay(hour: 0, minute: 0);

  static String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  // Real-time counterpart to _simulateProviderResponse — listens to the
  // exact same document this request was persisted to (see
  // _persistToFirestore/request.id) via the existing AppointmentRepository,
  // so it reacts automatically whenever the mechanic accepts, declines, or
  // proposes another time, with no polling and no second document.
  void _listenToRealAppointment(AppointmentRequest request) {
    // Guards against subscribing twice for the same request (e.g. if
    // requestAnotherTime is called on an authenticated request that's
    // already being tracked) — the existing subscription keeps running.
    if (_subscriptions.containsKey(request.id)) return;
    _subscriptions[request.id] = AppointmentRepository().watchAppointmentById(request.id).listen(
      (appointment) => _applyRealAppointment(request, appointment),
      onError: (Object error) {
        // Covers permission-denied/network errors — logged for debugging,
        // never surfaced as a fake status change. The request keeps
        // whatever state it last had.
        debugPrint('APPOINTMENT LISTENER ERROR (${request.id}): $error');
      },
    );
  }

  void _applyRealAppointment(AppointmentRequest request, Appointment? appointment) {
    // Missing document (not yet written, or removed) — keep existing
    // state stable rather than inventing one.
    if (appointment == null) return;
    if (!_requests.contains(request)) return;

    switch (appointment.status) {
      case AppointmentStatus.accepted:
        request
          ..status = AppointmentRequestStatus.confirmed
          ..proposedTime = _formatTimeOfDay(appointment.appointmentTime);
      case AppointmentStatus.declined:
        request.status = AppointmentRequestStatus.declined;
      case AppointmentStatus.pending:
        if (appointment.appointmentTime == _noProposedTimeSentinel) {
          request
            ..status = AppointmentRequestStatus.pendingProvider
            ..proposedTime = null;
        } else {
          request
            ..status = AppointmentRequestStatus.providerProposed
            ..proposedTime = _formatTimeOfDay(appointment.appointmentTime);
        }
      case AppointmentStatus.inProgress:
      case AppointmentStatus.completed:
      case AppointmentStatus.cancelled:
        // Not produced by any existing mechanic flow and not modeled on
        // the customer side yet — leave the request's current state
        // untouched rather than guessing a mapping.
        break;
    }
    notifyListeners();
  }

  /// Picks a plausible exact arrival time 20 minutes into the requested
  /// window — "İlk Müsait Saat" has no window to anchor to, so it proposes
  /// shortly after the current time instead.
  String _proposeArrivalTime(String windowLabel) {
    final match = RegExp(r'^(\d{2}):(\d{2})').firstMatch(windowLabel);
    int totalMinutes;
    if (match != null) {
      totalMinutes = int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!) + 20;
    } else {
      final upcoming = DateTime.now().add(const Duration(hours: 2));
      totalMinutes = upcoming.hour * 60 + upcoming.minute;
    }
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
