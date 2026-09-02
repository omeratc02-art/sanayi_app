import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import 'mock_data.dart';
import '../mechanic/appointments/data/appointment.dart';
import '../mechanic/appointments/data/appointment_repository.dart';
import '../models/appointment_request.dart';
import '../utils/chat_id.dart';
import '../utils/firebase_instances.dart';
import '../utils/identity.dart';

/// In-memory stand-in for the provider side of the request flow — this app
/// has no backend, so a short delay simulates the service provider reviewing
/// a preferred time window and proposing an exact arrival time. Notifies
/// listeners (the Appointments tab, the nav-bar badge) on every change.
class AppointmentRequestStore extends ChangeNotifier {
  AppointmentRequestStore._();

  static final AppointmentRequestStore instance = AppointmentRequestStore._();

  final List<AppointmentRequest> _requests = [];

  // One real-time subscription per request, keyed by request.id (== the
  // Firestore appointmentId) so a request already being listened to is
  // never subscribed a second time. Every request goes through this now
  // that guest mode is gone — see _startTrackingProviderResponse.
  final Map<String, StreamSubscription<Appointment?>> _subscriptions = {};

  List<AppointmentRequest> get requests => List.unmodifiable(_requests);

  bool get hasActionNeeded => _requests.any(
    (request) =>
        request.status == AppointmentRequestStatus.providerProposed ||
        request.status == AppointmentRequestStatus.declined,
  );

  /// Session-local count backing the GreetingBar notification badge — same
  /// filter as [hasActionNeeded], just a count instead of a bool. Deliberately
  /// not Firestore-aware (see NotificationsPage for the real, cross-session
  /// list this badge just points at): matches the same session-local scope
  /// the bottom-nav "Randevularım" badge already uses via [hasActionNeeded].
  int get actionNeededCount => _requests
      .where(
        (request) =>
            request.status == AppointmentRequestStatus.providerProposed ||
            request.status == AppointmentRequestStatus.declined,
      )
      .length;

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
    // What the customer actually requested — a real time once one exists,
    // otherwise their original preferred arrival window (or "İlk Müsait
    // Saat" if even that's empty). Same fallback _applyRealAppointment
    // already applies below, and the same one
    // MechanicRequestDetailsPage._preferredTimeLabel applies on the
    // mechanic side — without it, a range-only request rendered as a bogus
    // "00:00" here.
    final preferredWindowLabel = appointment.appointmentTime != _noProposedTimeSentinel
        ? formattedTime
        : (appointment.preferredTimeRangeLabel.isEmpty ? 'İlk Müsait Saat' : appointment.preferredTimeRangeLabel);
    final isNegotiating = appointment.status == AppointmentStatus.timeProposed;
    final isCustomerTurn = isNegotiating && appointment.sonTeklifEden == 'usta';
    final proposalDateTime = isNegotiating && appointment.teklifEdilenTarih != null && appointment.teklifEdilenSaat != null
        ? _combine(appointment.teklifEdilenTarih!, appointment.teklifEdilenSaat!)
        : null;
    return AppointmentRequest(
      id: appointment.appointmentId,
      mechanicName: _resolveMechanicName(appointment.businessId),
      date: appointment.appointmentDate,
      preferredWindowLabel: preferredWindowLabel,
      serviceLabel: appointment.serviceType,
      vehicleLabel: appointment.vehicleModel.isEmpty ? null : appointment.vehicleModel,
      customerId: appointment.customerId,
      businessId: appointment.businessId,
      // Still-pending appointments now reach this mapping too (see
      // AppointmentsTab) — only a genuinely accepted one is "confirmed";
      // a pending one is either awaiting the mechanic's decision, or
      // (appointmentTime no longer the "no real time yet" sentinel)
      // awaiting the customer's response to a mechanic-proposed time.
      status: switch (appointment.status) {
        AppointmentStatus.accepted => AppointmentRequestStatus.confirmed,
        // Explicit — without this, a declined appointment with no real
        // proposed time yet would fall into the `_` arm below and be
        // misread as still pendingProvider.
        AppointmentStatus.declined => AppointmentRequestStatus.declined,
        // A real negotiation (see AppointmentStatus.timeProposed) — only
        // actionable ("your turn") on the customer side while the mechanic
        // made the most recent proposal; otherwise the customer is the one
        // waiting, same as pendingProvider.
        AppointmentStatus.timeProposed => isCustomerTurn
            ? AppointmentRequestStatus.providerProposed
            : AppointmentRequestStatus.pendingProvider,
        _ when appointment.appointmentTime != const TimeOfDay(hour: 0, minute: 0) =>
          AppointmentRequestStatus.providerProposed,
        _ => AppointmentRequestStatus.pendingProvider,
      },
      // Same sentinel-check fallback as preferredWindowLabel above (reused
      // as-is, not recomputed) — without it, a still-unset appointmentTime
      // rendered as a bogus "00:00" here too whenever this branch wasn't
      // actually negotiating a mechanic-proposed teklif time.
      proposedTime: isNegotiating && appointment.teklifEdilenSaat != null
          ? _formatTimeOfDay(appointment.teklifEdilenSaat!)
          : preferredWindowLabel,
      proposedDateTime: isCustomerTurn ? proposalDateTime : null,
    );
  }

  static DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  // randevular/{id}.işletme_kimliği only ever stores the mechanicChatId slug
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

  // Async (was sync) — the caller (AppointmentRequestPage._handleSubmit) now
  // awaits this and only shows its success dialog once the Firestore write
  // underneath (_persistToFirestore) has actually completed, instead of
  // firing it off and reporting success regardless of the real outcome. A
  // failed write now propagates as a thrown exception from this method
  // (see _persistToFirestore) rather than being silently swallowed.
  Future<AppointmentRequest> submit({
    required String mechanicName,
    required DateTime date,
    required String preferredWindowLabel,
    required String serviceLabel,
    String? vehicleLabel,
    String? licensePlate,
    String? customerName,
    String? customerPhone,
    bool kvkkAccepted = false,
    String note = '',
  }) async {
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
    // Awaited now — a failure throws out of submit() before
    // _startTrackingProviderResponse runs, since there's no persisted
    // document to track/simulate a response for in that case.
    await _persistToFirestore(
      request,
      note,
      licensePlate: licensePlate,
      customerName: customerName,
      customerPhone: customerPhone,
      kvkkAccepted: kvkkAccepted,
    );
    _startTrackingProviderResponse(request);
    return request;
  }

  // Persists the request to the real randevular collection/repository the
  // mechanic side already reads and writes (AppointmentRepository) — not a
  // new collection or model. submit() now awaits this, so a failure here
  // (logged, then rethrown) surfaces all the way to AppointmentRequestPage
  // instead of being silently swallowed.
  Future<void> _persistToFirestore(
    AppointmentRequest request,
    String note, {
    String? licensePlate,
    String? customerName,
    String? customerPhone,
    bool kvkkAccepted = false,
  }) async {
    final appointment = Appointment(
      // Same id as request.id (see submit()) — this write and the request
      // object it came from now refer to the exact same Firestore document.
      appointmentId: request.id,
      customerId: request.customerId,
      customerName: customerName != null && customerName.isNotEmpty
          ? customerName
          : firebaseAuthInstance.currentUser?.email ?? 'Müşteri',
      customerPhone: customerPhone ?? '',
      kvkkAccepted: kvkkAccepted,
      kvkkAcceptedAt: kvkkAccepted ? DateTime.now() : null,
      vehicleModel: request.vehicleLabel ?? 'Belirtilmedi',
      licensePlate: licensePlate ?? '',
      serviceType: request.serviceLabel,
      // No exact time exists yet at request time (the mechanic proposes
      // one, or accepts outright) — appointmentTime is written as the
      // "no real time yet" sentinel; the preferred window has no field of
      // its own in the real schema, so it's embedded into customerNote
      // instead (see _composeNote), the same way real production
      // müşteriNotu values already do (e.g. "Tercih edilen saat aralığı:
      // 15:00 - 17:00" — see Appointment._extractPreferredWindow, which
      // reads it back out on the mechanic side).
      appointmentDate: request.date,
      appointmentTime: const TimeOfDay(hour: 0, minute: 0),
      estimatedDuration: const Duration(minutes: 60),
      customerNote: _composeNote(note, request.preferredWindowLabel),
      status: AppointmentStatus.pending,
      createdAt: DateTime.now(),
      distance: '',
      businessId: request.businessId,
    );

    try {
      await AppointmentRepository().saveAppointment(appointment);
    } catch (error) {
      debugPrint('APPOINTMENT REQUEST SAVE ERROR: $error');
      rethrow;
    }
  }

  static String _composeNote(String rawNote, String preferredWindowLabel) {
    final preferenceLine = 'Tercih edilen saat aralığı: $preferredWindowLabel';
    return rawNote.isEmpty ? preferenceLine : '$rawNote\n\n$preferenceLine';
  }

  // This is now always a real Firestore operation — the local status only
  // ever becomes confirmed once the write actually succeeds; a failure
  // leaves the request's state completely untouched and is logged, never
  // faked as a success. Returns whether the accept actually took effect, so
  // the calling UI can react to a failure.
  //
  // request.proposedDateTime distinguishes which real write this is: a real
  // negotiated proposal (Appointment.teklifEdilenTarih/Saat, see
  // appointmentRequestFromAccepted) needs acceptTimeProposal, which moves
  // those fields into randevuTarihi/randevu_zamani and clears the
  // negotiation state; the older "mechanic set an exact time directly" path
  // has no separate proposed date, so it keeps using the narrower
  // durum-only acceptProposedTime exactly as before.
  Future<bool> accept(AppointmentRequest request) async {
    try {
      final proposedDateTime = request.proposedDateTime;
      if (proposedDateTime != null) {
        await AppointmentRepository().acceptTimeProposal(
          request.id,
          date: proposedDateTime,
          time: TimeOfDay(hour: proposedDateTime.hour, minute: proposedDateTime.minute),
        );
      } else {
        await AppointmentRepository().acceptProposedTime(request.id);
      }
    } catch (error) {
      debugPrint('APPOINTMENT ACCEPT ERROR (${request.id}): $error');
      return false;
    }

    request.status = AppointmentRequestStatus.confirmed;
    notifyListeners();
    return true;
  }

  // Real Firestore write: records the customer's counter-proposal
  // (sonTeklifEden: 'musteri') without touching the current confirmed time.
  // Returns whether the write actually succeeded, same pattern as accept()
  // — a failure leaves the request's state untouched rather than
  // optimistically pretending the proposal went through.
  Future<bool> requestAnotherTime(AppointmentRequest request, {required DateTime date, required TimeOfDay time}) async {
    try {
      await AppointmentRepository().proposeNewTime(request.id, date: date, time: time, proposedBy: 'musteri');
    } catch (error) {
      debugPrint('APPOINTMENT COUNTER-PROPOSE ERROR (${request.id}): $error');
      return false;
    }
    request
      ..status = AppointmentRequestStatus.pendingProvider
      ..proposedTime = null
      ..proposedDateTime = null;
    notifyListeners();
    _startTrackingProviderResponse(request);
    return true;
  }

  // Booking requires sign-in now, so this always tracks the real Firestore
  // document — no simulated/guest path anymore.
  void _startTrackingProviderResponse(AppointmentRequest request) {
    _listenToRealAppointment(request);
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
          ..proposedTime = _formatTimeOfDay(appointment.appointmentTime)
          ..proposedDateTime = null;
      case AppointmentStatus.declined:
        request
          ..status = AppointmentRequestStatus.declined
          ..proposedDateTime = null;
      case AppointmentStatus.pending:
        if (appointment.appointmentTime == _noProposedTimeSentinel) {
          request
            ..status = AppointmentRequestStatus.pendingProvider
            ..proposedTime = null
            ..proposedDateTime = null;
        } else {
          request
            ..status = AppointmentRequestStatus.providerProposed
            ..proposedTime = _formatTimeOfDay(appointment.appointmentTime)
            ..proposedDateTime = null;
        }
      case AppointmentStatus.timeProposed:
        // A real negotiation — actionable ("your turn") only while the
        // mechanic made the most recent proposal, same rule
        // appointmentRequestFromAccepted uses for the Firestore-hydrated
        // path, kept consistent here for a request tracked live all
        // session (e.g. one this app itself submitted).
        if (appointment.sonTeklifEden == 'usta' &&
            appointment.teklifEdilenTarih != null &&
            appointment.teklifEdilenSaat != null) {
          request
            ..status = AppointmentRequestStatus.providerProposed
            ..proposedTime = _formatTimeOfDay(appointment.teklifEdilenSaat!)
            ..proposedDateTime = _combine(appointment.teklifEdilenTarih!, appointment.teklifEdilenSaat!);
        } else {
          request
            ..status = AppointmentRequestStatus.pendingProvider
            ..proposedTime = null
            ..proposedDateTime = null;
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
}
