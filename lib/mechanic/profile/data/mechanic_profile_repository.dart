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
  Future<int?> fetchRepeatCustomerRate(String businessId) async {
    final snapshot =
        await _firestore.collection('mechanicAccounts').where('businessId', isEqualTo: businessId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final rate = snapshot.docs.first.data()['repeatCustomerRate'];
    return rate is num ? rate.toInt() : null;
  }
}
