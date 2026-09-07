import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../utils/firebase_instances.dart';
import 'appointment.dart';

/// Reads/writes real appointments at `randevular/{randevuId}` — the actual
/// production collection (Turkish field names; see Appointment.fromFirestore
/// /toFirestore for the exact mapping), not the app's earlier English-schema
/// `appointments` collection, which no real customer or mechanic data ever
/// populated. Mirrors ChatRepository's shape (thin wrapper around
/// FirebaseFirestore, no UI code talks to Firestore directly). Defaults to
/// firestoreInstance (see utils/firebase_instances.dart) rather than
/// FirebaseFirestore.instance directly, so every bare `AppointmentRepository()`
/// call site across the app automatically picks up a fake instance in tests.
class AppointmentRepository {
  AppointmentRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? firestoreInstance;

  final FirebaseFirestore _firestore;

  static const _collection = 'randevular';

  /// A fresh, globally-unique id for a new appointment — Firestore's own
  /// auto-id generator, not a locally-incremented counter. A local counter
  /// (e.g. an in-memory sequence starting over at 1 on every app restart)
  /// would eventually generate the same id twice and silently overwrite an
  /// earlier saved appointment; this can't collide.
  String newAppointmentId() => _firestore.collection(_collection).doc().id;

  /// Uses appointment.appointmentId as the document id (like chats/{chatId})
  /// so saving is idempotent rather than accumulating duplicates. See
  /// Appointment.toFirestore for the exact field mapping.
  Future<void> saveAppointment(Appointment appointment) {
    return _firestore.collection(_collection).doc(appointment.appointmentId).set(appointment.toFirestore());
  }

  /// One-time read of every saved appointment — used to restore confirmed
  /// appointments into the mechanic Appointments screen after an app
  /// restart, since local state alone doesn't survive one.
  Future<List<Appointment>> fetchAppointments() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs.map((doc) => Appointment.fromFirestore(doc.data(), doc.id)).toList();
  }

  /// Every pending request belonging to one business — used by
  /// MechanicAppointmentsScreen ("Yeni Talepler") and
  /// MechanicNotificationsScreen. Filters by işletme_kimliği only
  /// server-side; "pending" itself is decided client-side via
  /// AppointmentStatus (see Appointment._statusFromDurum) rather than a
  /// `.where('durum', isEqualTo: ...)` clause, since only the real
  /// "kabul edildi" (accepted) value has actually been confirmed against
  /// production data — filtering server-side on a guessed pending string
  /// risks silently hiding real new requests whose durum uses a different
  /// word for "awaiting decision".
  Future<List<Appointment>> fetchPendingAppointments(String businessId) async {
    final snapshot = await _firestore.collection(_collection).where('işletme_kimliği', isEqualTo: businessId).get();
    return snapshot.docs
        .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
        .where(_needsMechanicAttention)
        .toList();
  }

  /// A request the mechanic still has an actual decision to make on: a
  /// fresh, never-touched request, or a negotiation (see
  /// AppointmentStatus.timeProposed) where the customer made the most
  /// recent proposal — the mechanic's turn to respond. Deliberately
  /// excludes a negotiation the mechanic themselves just proposed a time
  /// for; there's nothing for them to do there until the customer answers,
  /// so it shouldn't clutter "Bekleyen Talepler" as if it still needed
  /// action.
  static bool _needsMechanicAttention(Appointment appointment) =>
      appointment.status == AppointmentStatus.pending ||
      (appointment.status == AppointmentStatus.timeProposed && appointment.sonTeklifEden == 'musteri');

  /// Single-document read by appointmentId — the read-path counterpart to
  /// the shared id AppointmentRequestStore.submit() generates once and uses
  /// for both AppointmentRequest.id and this same document's id. Null if no
  /// such document exists.
  Future<Appointment?> fetchAppointmentById(String appointmentId) async {
    final doc = await _firestore.collection(_collection).doc(appointmentId).get();
    final data = doc.data();
    if (data == null) return null;
    return Appointment.fromFirestore(data, doc.id);
  }

  /// Live updates for a single appointment document — the real-time
  /// counterpart to fetchAppointmentById, used by the customer side
  /// (AppointmentRequestStore) to react automatically when a mechanic
  /// accepts, declines, or proposes another time, without polling. Null
  /// whenever the document doesn't (yet, or no longer) exist.
  Stream<Appointment?> watchAppointmentById(String appointmentId) {
    return _firestore.collection(_collection).doc(appointmentId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return Appointment.fromFirestore(data, snapshot.id);
    });
  }

  /// The customer's side of accepting a mechanic's proposed time — a
  /// narrowly scoped partial update, not saveAppointment's full .set().
  /// Only durum changes; randevu_zamani and every other field on the
  /// document are left exactly as they are, both here and (as the enforced
  /// boundary) in firestore.rules' matching customer update rule.
  Future<void> acceptProposedTime(String appointmentId) {
    return _firestore.collection(_collection).doc(appointmentId).update({'durum': 'kabul edildi'});
  }

  /// Records a new time proposal in an ongoing negotiation — either side
  /// (see [proposedBy], 'usta' | 'musteri') offering an alternative date/time
  /// and waiting on the other side's response. A narrowly scoped partial
  /// update: randevuTarihi/randevu_zamani (the current confirmed time, if
  /// any) are deliberately left untouched — only accepting a proposal (see
  /// [acceptTimeProposal]) ever moves them.
  Future<void> proposeNewTime(
    String appointmentId, {
    required DateTime date,
    required TimeOfDay time,
    required String proposedBy,
  }) {
    return _firestore.collection(_collection).doc(appointmentId).update({
      'durum': 'saat_teklif_edildi',
      'sonTeklifEden': proposedBy,
      'teklifEdilenTarih': Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day, appointmentDateAnchorHourUtc)),
      'teklifEdilenSaat': formatTimeOfDayString(time),
    });
  }

  /// Accepts the other side's pending time proposal — [date]/[time] (the
  /// caller's own already-parsed teklifEdilenTarih/teklifEdilenSaat) become
  /// the real randevuTarihi/randevu_zamani, durum returns to 'kabul edildi',
  /// and the negotiation fields are cleared so a stale proposal can never be
  /// mistaken for a live one later.
  Future<void> acceptTimeProposal(String appointmentId, {required DateTime date, required TimeOfDay time}) {
    return _firestore.collection(_collection).doc(appointmentId).update({
      'durum': 'kabul edildi',
      'randevuTarihi': Timestamp.fromDate(DateTime.utc(date.year, date.month, date.day, appointmentDateAnchorHourUtc)),
      'randevu_zamani': formatTimeOfDayString(time),
      'sonTeklifEden': FieldValue.delete(),
      'teklifEdilenTarih': FieldValue.delete(),
      'teklifEdilenSaat': FieldValue.delete(),
    });
  }

  /// The mechanic's side of the completion-verification flow (see
  /// Appointment.tamamlanmaDurumu) — a narrowly scoped partial update, same
  /// shape as acceptProposedTime. Only ever moves a document from
  /// "beklemede" to "usta_onayladi_bekleniyor"; nothing here or anywhere
  /// else advances it further automatically.
  Future<void> markMechanicCompleted(String appointmentId) {
    return _firestore.collection(_collection).doc(appointmentId).update({
      'tamamlanmaDurumu': 'usta_onayladi_bekleniyor',
      'ustaTamamlamaTarihi': FieldValue.serverTimestamp(),
    });
  }

  /// The customer's confirmation that a mechanic-marked-complete appointment
  /// really was completed. [rating] (1-5) and [comment] are both optional.
  Future<void> markCustomerVerified(String appointmentId, {int? rating, String? comment}) {
    return _firestore.collection(_collection).doc(appointmentId).update({
      'tamamlanmaDurumu': 'dogrulanmis_tamamlandi',
      'musteriOnayTarihi': FieldValue.serverTimestamp(),
      if (rating != null) 'musteriPuani': rating,
      if (comment != null) 'musteriYorumu': comment,
    });
  }

  /// The customer's rejection of a mechanic's completion claim — moves the
  /// document to "anlasmazlik" for manual follow-up. No timestamp/rating
  /// fields are set, per spec; nothing in this app auto-resolves this state.
  Future<void> markCustomerDisputed(String appointmentId) {
    return _firestore.collection(_collection).doc(appointmentId).update({'tamamlanmaDurumu': 'anlasmazlik'});
  }

  /// Live counterpart to fetchPendingAppointments — used by
  /// MechanicAppointmentsScreen's "Yeni Talepler" list so it reflects
  /// newly-submitted (or otherwise changed) requests automatically instead
  /// of only ever showing whatever existed at the moment the screen first
  /// loaded. Same server-side businessId filter + client-side pending
  /// check as fetchPendingAppointments (see its doc comment).
  Stream<List<Appointment>> watchPendingAppointments(String businessId) {
    return _firestore.collection(_collection).where('işletme_kimliği', isEqualTo: businessId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Appointment.fromFirestore(doc.data(), doc.id)).where(_needsMechanicAttention).toList(),
    );
  }

  /// Live counterpart to fetchAppointments, scoped to one business — used
  /// by MechanicAppointmentsScreen's "Tüm Randevular" tab so an appointment
  /// accepted from anywhere in the app (this screen's own "Kabul Et", or
  /// MechanicRequestDetailsPage's "Talebi Kabul Et") appears immediately,
  /// without requiring the screen to be reopened. Unfiltered by status —
  /// same as fetchAppointments(), the caller decides which statuses belong
  /// on the calendar.
  Stream<List<Appointment>> watchAppointmentsForBusiness(String businessId) {
    return _firestore.collection(_collection).where('işletme_kimliği', isEqualTo: businessId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Appointment.fromFirestore(doc.data(), doc.id)).toList(),
    );
  }

  /// Live count of appointment requests created for [businessId] in the
  /// last 7 days — the real data source for the mechanic home screen's
  /// "İşletmeniz İlgi Görüyor" weekly summary card (see
  /// _WeeklyEngagementSummaryCard). A real server-side compound query —
  /// equality on işletme_kimliği + a range filter on oluşturulma_tarihi
  /// (both confirmed against Appointment.fromFirestore/toFirestore, the
  /// exact Firestore field names, not just the Dart property names) —
  /// backed by the composite index declared in firestore.indexes.json
  /// (deployed via `firebase deploy --only firestore:indexes`). This used
  /// to be a client-side count over the unfiltered watchAppointmentsForBusiness
  /// stream, specifically because that index/deploy infrastructure didn't
  /// exist yet; now that it does, the filtering happens in Firestore itself
  /// rather than pulling every appointment for the business over the wire.
  /// A plain `.snapshots()` mapped to `.docs.length` rather than an
  /// aggregate `.count()` query, since `.count()` has no live/streaming
  /// counterpart in this project's cloud_firestore version — this still
  /// updates live as requests arrive or age out of the 7-day window, it's
  /// just not using the aggregate-query API.
  Stream<int> watchRecentAppointmentRequestCount(String businessId) {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    return _firestore
        .collection(_collection)
        .where('işletme_kimliği', isEqualTo: businessId)
        .where('oluşturulma_tarihi', isGreaterThanOrEqualTo: cutoff)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Live counterpart to the customer side's session-only state
  /// (AppointmentRequestStore) — every appointment belonging to one
  /// customer, so a mechanic's accepted/declined decision (or any other
  /// status change) is reflected on the Upcoming/Past tabs even after the
  /// app restarts or the customer never had a live per-document listener
  /// running for that request. Filters only by müşteri_kimliği (the same
  /// field already written by saveAppointment and checked by the security
  /// rules' customer-owned get/list conditions) — status/date splitting
  /// stays a client-side concern, same as the mechanic calendar's own
  /// fetchAppointments() use.
  Stream<List<Appointment>> watchCustomerAppointments(String customerId) {
    return _firestore
        .collection(_collection)
        .where('müşteri_kimliği', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Appointment.fromFirestore(doc.data(), doc.id)).toList());
  }

  /// A mechanic's verified-completed job count — always computed live via
  /// a server-side count query, never a cached counter field, so it can't
  /// drift out of sync with the underlying documents. Counts only
  /// "dogrulanmis_tamamlandi" (customer-verified) — a mechanic marking their
  /// own work complete is not enough on its own.
  Future<int> fetchVerifiedCompletedCount(String businessId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('işletme_kimliği', isEqualTo: businessId)
        .where('tamamlanmaDurumu', isEqualTo: 'dogrulanmis_tamamlandi')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// A mechanic's real rating summary — average musteriPuani and how many
  /// customer-verified completions carry a rating — computed live, same
  /// "no cached counter" reasoning as fetchVerifiedCompletedCount above.
  /// Only tamamlanmaDurumu == 'dogrulanmis_tamamlandi' documents are
  /// eligible, since that's the only point a customer can legitimately
  /// leave musteriPuani (see markCustomerVerified). ratedCount counts every
  /// rated appointment, not just ones with a written musteriYorumu comment
  /// — that field is optional, so requiring it would undercount mechanics
  /// whose customers rated but didn't leave a comment.
  Future<({double averageRating, int ratedCount})> fetchRatingSummary(String businessId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('işletme_kimliği', isEqualTo: businessId)
        .where('tamamlanmaDurumu', isEqualTo: 'dogrulanmis_tamamlandi')
        .get();
    final ratings = snapshot.docs
        .map((doc) => doc.data()['musteriPuani'])
        .whereType<num>()
        .map((value) => value.toInt())
        .toList();
    if (ratings.isEmpty) return (averageRating: 0.0, ratedCount: 0);
    final average = ratings.reduce((a, b) => a + b) / ratings.length;
    return (averageRating: double.parse(average.toStringAsFixed(1)), ratedCount: ratings.length);
  }

  /// Real "did the mechanic finish by the time they committed to" rate —
  /// derived entirely from existing fields, no new schema. Eligible
  /// documents are the same customer-verified-complete set
  /// fetchRatingSummary uses, further narrowed to ones that actually
  /// recorded [Appointment.ustaTamamlamaTarihi] (older documents, from
  /// before that field existed, have no timestamp to judge and are
  /// excluded rather than guessed at). "On time" means the mechanic marked
  /// it complete at or before the appointment's own scheduled end
  /// (appointmentDate + appointmentTime + estimatedDuration) — every one of
  /// those three fields is the same real data already used elsewhere for
  /// this same appointment. Null (not 0%) when there is no eligible
  /// document yet, since a 0% would falsely imply a track record of being
  /// late rather than "no data".
  Future<double?> fetchOnTimeCompletionRate(String businessId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('işletme_kimliği', isEqualTo: businessId)
        .where('tamamlanmaDurumu', isEqualTo: 'dogrulanmis_tamamlandi')
        .get();
    final eligible = snapshot.docs
        .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
        .where((appointment) => appointment.ustaTamamlamaTarihi != null)
        .toList();
    if (eligible.isEmpty) return null;
    final onTime = eligible.where((appointment) {
      final scheduledEnd = DateTime(
        appointment.appointmentDate.year,
        appointment.appointmentDate.month,
        appointment.appointmentDate.day,
        appointment.appointmentTime.hour,
        appointment.appointmentTime.minute,
      ).add(appointment.estimatedDuration);
      return !appointment.ustaTamamlamaTarihi!.isAfter(scheduledEnd);
    }).length;
    return onTime / eligible.length * 100;
  }
}
