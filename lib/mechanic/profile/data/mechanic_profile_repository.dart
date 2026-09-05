import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firebase_instances.dart';
import 'mechanic_profile.dart';

/// Reads the signed-in mechanic's own real business profile from the
/// existing `mechanicAccounts` collection — no new collection, no schema
/// change to what mechanicAccounts already is, just a typed read of it
/// (mirroring AppointmentRepository/ChatRepository's "thin wrapper around
/// FirebaseFirestore" pattern). mechanicAccounts is unchanged as a
/// collection: still open per firestore.rules, still keyed by uid, still
/// used exactly as before by identity.dart's resolveMyBusinessId and by
/// the appointments security rules' exists() checks.
class MechanicProfileRepository {
  MechanicProfileRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? firestoreInstance;

  final FirebaseFirestore _firestore;

  /// Null when there's no mechanicAccounts/{uid} document at all (not
  /// signed in as a registered mechanic) — distinct from a document that
  /// exists but predates the newer profile fields, which
  /// MechanicProfile.fromFirestore already handles by leaving those
  /// fields null rather than failing.
  Future<MechanicProfile?> fetchProfile(String uid) async {
    final doc = await _firestore.collection('mechanicAccounts').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return MechanicProfile.fromFirestore(uid, data);
  }

  /// A business's real repeat-customer rate, written by the scheduled
  /// updateRepeatCustomerRates Cloud Function (functions/src/index.ts) —
  /// looked up by the businessId field rather than doc id, since callers
  /// here are customer-facing screens that only know a business's public
  /// id, not the owning mechanic's uid (mirrors that function's own
  /// write-back query, and AppointmentRepository.fetchRatingSummary's
  /// businessId-based lookups on the customer side). Null both when no
  /// matching mechanicAccounts document exists yet and when one exists but
  /// the function hasn't run for this business yet (field not written) —
  /// either way there's no real rate to show, distinct from an actual
  /// computed 0%.
  ///
  /// Not `.limit(1)` — a claimed business briefly has two documents
  /// sharing the same businessId (see
  /// MechanicDirectoryRepository.fetchByBusinessId's doc comment for the
  /// full reasoning); skipping archived matches here picks the real,
  /// current document deterministically instead of an arbitrary one.
  Future<int?> fetchRepeatCustomerRate(String businessId) async {
    final snapshot = await _firestore.collection('mechanicAccounts').where('businessId', isEqualTo: businessId).get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['archived'] == true) continue;
      final rate = data['repeatCustomerRate'];
      return rate is num ? rate.toInt() : null;
    }
    return null;
  }

  /// A business's raw repeat-customer count — how many distinct customers
  /// completed more than one verified appointment with them — written by
  /// the same updateRepeatCustomerRates Cloud Function run alongside
  /// repeatCustomerRate (see that function's own writeRepeatCustomerRate).
  /// Same lookup/null/archived-skip reasoning as fetchRepeatCustomerRate
  /// above, just a different field: null both when no matching document
  /// exists and when the function hasn't run for this business yet.
  Future<int?> fetchRepeatCustomerCount(String businessId) async {
    final snapshot = await _firestore.collection('mechanicAccounts').where('businessId', isEqualTo: businessId).get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['archived'] == true) continue;
      final count = data['repeatCustomerCount'];
      return count is num ? count.toInt() : null;
    }
    return null;
  }
}
