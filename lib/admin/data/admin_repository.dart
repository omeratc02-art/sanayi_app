import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/firebase_instances.dart';
import 'admin_mechanic_row.dart';

/// Backs the hidden admin approval flow: checking whether the signed-in
/// user is an admin (an `admins/{uid}` doc existing — see firestore.rules),
/// listing every real mechanicAccounts document, and toggling a single
/// mechanic's isVerified field. No mock data anywhere here — every method
/// reads/writes the real Firestore collections.
class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? firestoreInstance;

  final FirebaseFirestore _firestore;

  /// True only when a signed-in user's own UID has a matching
  /// `admins/{uid}` document — false for a signed-out user, and false (not
  /// an error) for a signed-in non-admin, since "not an admin" and "no
  /// admin doc found" are the same outcome here.
  Future<bool> isCurrentUserAdmin() async {
    final uid = firebaseAuthInstance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await _firestore.collection('admins').doc(uid).get();
    return doc.exists;
  }

  /// Every real mechanicAccounts document — the admin screen's own list,
  /// not filtered by hizmetTürü the way MechanicDirectoryRepository's
  /// customer-facing queries are, since an admin needs to see and approve
  /// every business type.
  Future<List<AdminMechanicRow>> fetchAllMechanicAccounts() async {
    final snapshot = await _firestore.collection('mechanicAccounts').get();
    return snapshot.docs.map(AdminMechanicRow.fromFirestore).toList();
  }

  /// Writes only the isVerified field on one mechanicAccounts document —
  /// an update(), not a set(), so every other field on that document
  /// (name, phone, hizmetler, ...) is left exactly as it was.
  Future<void> setMechanicVerified(String mechanicAccountId, bool isVerified) {
    return _firestore.collection('mechanicAccounts').doc(mechanicAccountId).update({'isVerified': isVerified});
  }
}
