import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mechanic.dart';
import '../utils/firebase_instances.dart';

/// Customer-facing browsing queries against the real `mechanicAccounts`
/// collection — replaces MockData.allMechanics as the data source for the
/// category grid → search → service listing flow. Mirrors
/// MechanicProfileRepository's "thin wrapper around FirebaseFirestore"
/// pattern.
class MechanicDirectoryRepository {
  MechanicDirectoryRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? firestoreInstance;

  final FirebaseFirestore _firestore;

  /// Every real mechanic under one top-level category ('tamir' | 'ekspertiz'
  /// | 'sigorta') — used by ServiceListingPage, which (like the MockData
  /// version it replaces) shows every business in scope rather than
  /// filtering down to the exact sub-service tapped.
  Future<List<Mechanic>> fetchByHizmetTuru(String hizmetTuru) async {
    final snapshot = await _firestore.collection('mechanicAccounts').where('hizmetTürü', isEqualTo: hizmetTuru).get();
    return snapshot.docs.map((doc) => Mechanic.fromFirestore(doc.data())).toList();
  }

  /// A single real mechanic by its stable businessId — the same id already
  /// used as that business's chats/{chatId} document id (see
  /// mechanicChatId), so a chat screen that only knows its own chatId can
  /// look up the real, live mechanicAccounts record for the other party.
  /// Null if no such business exists — callers must not fall back to
  /// MockData; that's exactly the stale/fake-data path this rewire moved
  /// away from.
  Future<Mechanic?> fetchByBusinessId(String businessId) async {
    final snapshot = await _firestore
        .collection('mechanicAccounts')
        .where('businessId', isEqualTo: businessId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Mechanic.fromFirestore(snapshot.docs.first.data());
  }
}
