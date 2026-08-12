import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'appointment.dart';

/// Reads/writes confirmed appointments at `appointments/{appointmentId}`.
/// Mirrors ChatRepository's shape (thin wrapper around FirebaseFirestore,
/// no UI code talks to Firestore directly) — this is the first appointment
/// write path, so there's no existing repository to extend, only the same
/// pattern to follow.
class AppointmentRepository {
  AppointmentRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// A fresh, globally-unique id for a new appointment — Firestore's own
  /// auto-id generator, not a locally-incremented counter. A local counter
  /// (e.g. an in-memory sequence starting over at 1 on every app restart)
  /// would eventually generate the same id twice and silently overwrite an
  /// earlier saved appointment; this can't collide.
  String newAppointmentId() => _firestore.collection('appointments').doc().id;

  static String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// Uses appointment.appointmentId as the document id (like chats/{chatId})
  /// so saving is idempotent rather than accumulating duplicates.
  /// DateTimes are stored as Firestore Timestamps (not strings) so they sort
  /// and round-trip correctly; TimeOfDay has no native Firestore type, so
  /// it's stored as a zero-padded "HH:mm" string; Duration is stored as
  /// whole minutes.
  Future<void> saveAppointment(Appointment appointment) {
    return _firestore.collection('appointments').doc(appointment.appointmentId).set({
      'appointmentId': appointment.appointmentId,
      'customerId': appointment.customerId,
      'customerName': appointment.customerName,
      'customerPhone': appointment.customerPhone,
      'vehicleBrand': appointment.vehicleBrand,
      'vehicleModel': appointment.vehicleModel,
      'licensePlate': appointment.licensePlate,
      'serviceType': appointment.serviceType,
      'appointmentDate': Timestamp.fromDate(appointment.appointmentDate),
      'appointmentTime': _formatTimeOfDay(appointment.appointmentTime),
      'estimatedDurationMinutes': appointment.estimatedDuration.inMinutes,
      'customerNote': appointment.customerNote,
      'status': appointment.status.name,
      'createdAt': Timestamp.fromDate(appointment.createdAt),
      'distance': appointment.distance,
      'businessId': appointment.businessId,
    });
  }

  /// One-time read of every saved appointment — used to restore confirmed
  /// appointments into the mechanic Appointments screen after an app
  /// restart, since local state alone doesn't survive one.
  Future<List<Appointment>> fetchAppointments() async {
    final snapshot = await _firestore.collection('appointments').get();
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc.data())).toList();
  }

  /// Server-side filtered read of only one business's pending requests —
  /// used by MechanicAppointmentsScreen ("Yeni Talepler") and
  /// MechanicNotificationsScreen, replacing what used to be two
  /// independent fetchAppointments() calls each followed by an identical
  /// client-side filter. fetchAppointments() itself is untouched and still
  /// used wherever a broader, multi-status read is needed (e.g. the
  /// calendar).
  Future<List<Appointment>> fetchPendingAppointments(String businessId) async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('businessId', isEqualTo: businessId)
        .where('status', isEqualTo: AppointmentStatus.pending.name)
        .get();
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc.data())).toList();
  }

  /// Single-document read by appointmentId — the read-path counterpart to
  /// the shared id AppointmentRequestStore.submit() now generates once and
  /// uses for both AppointmentRequest.id and this same document's id. Not
  /// yet called from any UI; establishes the capability for a future step
  /// to let the customer side look up its own request's real Firestore
  /// state. Reuses the existing Appointment.fromFirestore mapping — no new
  /// parsing logic. Null if no such document exists.
  Future<Appointment?> fetchAppointmentById(String appointmentId) async {
    final doc = await _firestore.collection('appointments').doc(appointmentId).get();
    final data = doc.data();
    if (data == null) return null;
    return Appointment.fromFirestore(data);
  }

  /// Live updates for a single appointment document — the real-time
  /// counterpart to fetchAppointmentById, used by the customer side
  /// (AppointmentRequestStore) to react automatically when a mechanic
  /// accepts, declines, or proposes another time, without polling. Same
  /// document, same Appointment.fromFirestore mapping — no new collection
  /// or model. Null whenever the document doesn't (yet, or no longer)
  /// exist.
  Stream<Appointment?> watchAppointmentById(String appointmentId) {
    return _firestore.collection('appointments').doc(appointmentId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return Appointment.fromFirestore(data);
    });
  }

  /// The customer's side of accepting a mechanic's proposed time — a
  /// narrowly scoped partial update, not saveAppointment's full .set().
  /// Only the status field changes; appointmentTime and every other field
  /// on the document are left exactly as they are, both here and (as the
  /// enforced boundary) in firestore.rules' matching customer update rule.
  Future<void> acceptProposedTime(String appointmentId) {
    return _firestore.collection('appointments').doc(appointmentId).update({
      'status': AppointmentStatus.accepted.name,
    });
  }

  /// Live counterpart to fetchPendingAppointments — used by
  /// MechanicAppointmentsScreen's "Yeni Talepler" list so it reflects
  /// newly-submitted (or otherwise changed) requests automatically instead
  /// of only ever showing whatever existed at the moment the screen first
  /// loaded. A one-time fetch left that list stale for the screen's whole
  /// lifetime, which is what let a mechanic act on an outdated request
  /// object pointing at the wrong document; this fixes that at the source.
  /// fetchPendingAppointments itself is untouched and still used by
  /// MechanicNotificationsScreen.
  Stream<List<Appointment>> watchPendingAppointments(String businessId) {
    return _firestore
        .collection('appointments')
        .where('businessId', isEqualTo: businessId)
        .where('status', isEqualTo: AppointmentStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Appointment.fromFirestore(doc.data())).toList());
  }

  /// Live counterpart to the customer side's session-only state
  /// (AppointmentRequestStore) — every appointment belonging to one
  /// customer, so a mechanic's accepted/declined decision (or any other
  /// status change) is reflected on the Upcoming/Past tabs even after the
  /// app restarts or the customer never had a live per-document listener
  /// running for that request. Filters only by customerId (the same field
  /// already written by saveAppointment and checked by the security
  /// rules' customer-owned get/list conditions) — status/date splitting
  /// stays a client-side concern, same as the mechanic calendar's own
  /// fetchAppointments() use.
  Stream<List<Appointment>> watchCustomerAppointments(String customerId) {
    return _firestore
        .collection('appointments')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Appointment.fromFirestore(doc.data())).toList());
  }
}
