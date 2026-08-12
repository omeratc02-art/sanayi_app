import 'package:cloud_firestore/cloud_firestore.dart';

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
  MechanicProfileRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

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
}
