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
  ///
  /// Excludes archived documents — a business claimed via
  /// mechanic_login_page.dart's picker leaves its old script-uploaded
  /// mechanicAccounts document in place (archived: true) rather than
  /// deleting it, specifically so it stops showing up in customer-facing
  /// browse/search like this one, while the new claimed document (no
  /// `archived` field at all, same as every real registration) still does.
  /// Filtered client-side, not via a `where('archived', isNotEqualTo:
  /// true)` query — Firestore's != excludes documents missing the field
  /// entirely, which every real mechanicAccounts document is (archived is
  /// only ever set on a claimed-away document), so that query would hide
  /// everyone, not just the archived ones.
  ///
  /// Also excludes any business whose isVerified isn't explicitly true —
  /// closes a real gap where a freshly-registered/claimed mechanic (or one
  /// of the script-uploaded businesses, which have no isVerified field at
  /// all) was fully visible and bookable before an admin ever reviewed
  /// them. Missing/null/false are all treated identically as "not
  /// visible" (see _isVisible below) — this is a deliberate, expected
  /// change for the script-uploaded businesses too, not a bug: they
  /// reappear once claimed and verified. Same client-side-filter reasoning
  /// as archived above — a combined `where('hizmetTürü', ...).where
  /// ('isVerified', isEqualTo: true)` would need a composite index this
  /// collection doesn't have.
  Future<List<Mechanic>> fetchByHizmetTuru(String hizmetTuru) async {
    final snapshot = await _firestore.collection('mechanicAccounts').where('hizmetTürü', isEqualTo: hizmetTuru).get();
    return snapshot.docs.where((doc) => _isVisible(doc.data())).map((doc) => Mechanic.fromFirestore(doc.data())).toList();
  }

  /// True only for a business that should ever be shown to a customer:
  /// not archived (claimed-away, see fetchByHizmetTuru's doc comment), and
  /// isVerified explicitly true. A missing isVerified field (every
  /// script-uploaded, not-yet-claimed business) and an explicit `false`
  /// (every freshly-registered/claimed-but-not-yet-approved business) are
  /// both "not visible" — there is no third state customers should ever
  /// see.
  static bool _isVisible(Map<String, dynamic> data) => data['archived'] != true && data['isVerified'] == true;

  /// A single real mechanic by its stable businessId — the same id already
  /// used as that business's chats/{chatId} document id (see
  /// mechanicChatId), so a chat screen that only knows its own chatId can
  /// look up the real, live mechanicAccounts record for the other party.
  /// Null if no such business exists — callers must not fall back to
  /// MockData; that's exactly the stale/fake-data path this rewire moved
  /// away from.
  ///
  /// Not `.limit(1)` — a claimed business briefly has two documents
  /// sharing the same businessId (the new claimed one, and the old one
  /// left behind archived; see fetchByHizmetTuru's doc comment), and
  /// Firestore doesn't guarantee which a `.limit(1)` query would return.
  /// Fetching all matches and skipping archived ones deterministically
  /// picks the real, current document instead.
  ///
  /// Also excludes an unverified business, same as fetchByHizmetTuru — a
  /// customer who already has an old link/chat pointing at a business that
  /// has since become unverified again (or was never verified) must not be
  /// able to reach its real detail page this way either.
  Future<Mechanic?> fetchByBusinessId(String businessId) async {
    final snapshot = await _firestore.collection('mechanicAccounts').where('businessId', isEqualTo: businessId).get();
    for (final doc in snapshot.docs) {
      if (!_isVisible(doc.data())) continue;
      return Mechanic.fromFirestore(doc.data());
    }
    return null;
  }
}
