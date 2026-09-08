import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  MechanicProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? firestoreInstance,
       _storageOverride = storage;

  final FirebaseFirestore _firestore;

  // Deliberately NOT resolved eagerly in the constructor (unlike
  // _firestore above) — every other method on this repository
  // (fetchProfile, fetchRepeatCustomerCount, watchProfileViewCount, ...)
  // never touches Storage at all, so constructing a MechanicProfileRepository
  // for one of those must not force firebaseStorageInstance's real
  // FirebaseStorage.instance to be evaluated. This getter defers that
  // until something actually calls uploadCoverPhoto.
  final FirebaseStorage? _storageOverride;
  FirebaseStorage get _storage => _storageOverride ?? firebaseStorageInstance;

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
    final snapshot = await _firestore
        .collection('mechanicAccounts')
        .where('businessId', isEqualTo: businessId)
        .get();
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
    final snapshot = await _firestore
        .collection('mechanicAccounts')
        .where('businessId', isEqualTo: businessId)
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['archived'] == true) continue;
      final count = data['repeatCustomerCount'];
      return count is num ? count.toInt() : null;
    }
    return null;
  }

  /// Live profileViewCount for the signed-in mechanic's own account — the
  /// real data source for the mechanic home screen's "İşletmeniz İlgi
  /// Görüyor" card (see mechanic_home_screen.dart's
  /// _WeeklyEngagementSummaryCard). Reads the same mechanicAccounts/{uid}
  /// document [fetchProfile] already reads once, just as a live stream
  /// instead, so a new view recorded elsewhere (see [recordProfileView])
  /// shows up without the mechanic needing to manually refresh. 0 (not
  /// null) once the document itself exists but has never had a view
  /// recorded — a real, known zero, not "unknown"; "unknown/still loading"
  /// is represented by the Stream not having emitted yet, which the caller
  /// already models as a nullable field starting null.
  Stream<int> watchProfileViewCount(String uid) {
    return _firestore
        .collection('mechanicAccounts')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['profileViewCount'] as int? ?? 0);
  }

  /// Records one real profile view of [businessId] by [customerId] — the
  /// write path behind [watchProfileViewCount]. A deliberate no-op (no
  /// writes at all) in three cases, matching the agreed product design
  /// exactly:
  ///   - [customerId] is null/empty — no signed-in Firebase Auth customer,
  ///     so there's no real per-customer identity to dedupe against
  ///     (anonymous/guest views are never counted).
  ///   - No matching, non-archived mechanicAccounts document for
  ///     [businessId] exists.
  ///   - [customerId] equals the business's own owning uid — the
  ///     mechanicAccounts document id itself IS the owning mechanic's
  ///     Firebase Auth uid (see [fetchProfile]; there is no separate stored
  ///     "owner uid" field), so the business owner viewing their own
  ///     profile never counts as a view.
  ///
  /// Otherwise, at most one view per (customer, business, calendar day)
  /// counts: a small marker document at
  /// mechanicAccounts/{businessDocId}/dailyViewers/{customerId}_{yyyy-MM-dd}
  /// records that this customer has already been counted today (a new day
  /// is a new document id, so the count resets naturally the next day
  /// without any cleanup job). The marker write and the profileViewCount
  /// increment happen inside one Firestore transaction, so a failure
  /// partway through can never increment the counter without the marker
  /// (or vice versa) — see firestore.rules' own dailyViewers/
  /// profileViewCount rules for how this exact one-per-day guarantee is
  /// also enforced server-side, not just here: the marker collection only
  /// grants `create` (never `update`), so Firestore itself rejects a
  /// second same-day write as an unauthorized update, independent of
  /// whether this client-side check ever runs.
  Future<void> recordProfileView({
    required String businessId,
    required String? customerId,
  }) async {
    if (customerId == null || customerId.isEmpty) return;

    final matches = await _firestore
        .collection('mechanicAccounts')
        .where('businessId', isEqualTo: businessId)
        .get();
    QueryDocumentSnapshot<Map<String, dynamic>>? businessDoc;
    for (final doc in matches.docs) {
      if (doc.data()['archived'] == true) continue;
      businessDoc = doc;
      break;
    }
    if (businessDoc == null) return;
    if (businessDoc.id == customerId) return;

    final today = DateTime.now();
    final dayKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final viewerDocRef = businessDoc.reference
        .collection('dailyViewers')
        .doc('${customerId}_$dayKey');
    final businessDocRef = businessDoc.reference;

    await _firestore.runTransaction((transaction) async {
      // All reads before any writes — required by Firestore transactions.
      final viewerDoc = await transaction.get(viewerDocRef);
      if (viewerDoc.exists) return; // Already counted today — a real no-op.

      transaction.set(viewerDocRef, {
        'customerId': customerId,
        'viewedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(businessDocRef, {
        'profileViewCount': FieldValue.increment(1),
      });
    });
  }

  /// Uploads [bytes] as the signed-in mechanic's real cover photo — one file
  /// per account at Firebase Storage path mechanic_covers/{uid}/cover.jpg
  /// (keyed by uid, not businessId — see storage.rules' own doc comment on
  /// this path for why: cross-service firestore.get() ownership checks
  /// aren't usable in this project, so the path itself carries the
  /// ownership check instead, via a plain request.auth.uid == uid rule); a
  /// fresh upload simply overwrites whatever was there before (this screen
  /// only ever needs the current photo, not a history of old ones). On
  /// success, writes the resulting real download URL to
  /// mechanicAccounts/{uid}.coverPhotoUrl and returns it.
  ///
  /// Throws on failure (a real Storage/network/permission error) rather
  /// than swallowing it — the caller is responsible for catching this,
  /// logging it (see mechanic_profile_screen.dart's debugPrint convention),
  /// and showing the mechanic real error feedback instead of a fake
  /// success state.
  Future<String> uploadCoverPhoto({
    required String uid,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('mechanic_covers/$uid/cover.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await _firestore.collection('mechanicAccounts').doc(uid).update({
      'coverPhotoUrl': url,
    });
    return url;
  }

  /// Resolves a full [MechanicProfile] by businessId rather than uid — for
  /// customer-facing screens like MechanicDetailPage, which only ever know
  /// a business's public slug, never the owning mechanic's Firebase Auth
  /// uid (same businessId-based lookup [fetchRepeatCustomerRate] and
  /// [recordProfileView] already use). Reuses
  /// [MechanicProfile.fromFirestore] directly rather than hand-picking
  /// individual fields, so MechanicDetailPage gets exactly the same
  /// coverPhotoUrl/galleryPhotoUrls parsing (padding, null-handling)
  /// MechanicProfileScreen already relies on, not a second, parallel
  /// implementation of the same logic.
  ///
  /// Same not-`.limit(1)`/archived-skip reasoning as
  /// [fetchRepeatCustomerRate] above. Null both when no matching document
  /// exists and when only an archived one does.
  Future<MechanicProfile?> fetchProfileByBusinessId(String businessId) async {
    final snapshot = await _firestore
        .collection('mechanicAccounts')
        .where('businessId', isEqualTo: businessId)
        .get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['archived'] == true) continue;
      return MechanicProfile.fromFirestore(doc.id, data);
    }
    return null;
  }

  /// Uploads [bytes] as one of the signed-in mechanic's up to 3 gallery
  /// photos — Firebase Storage path mechanic_gallery/{uid}/{index}.jpg
  /// (same uid-keyed reasoning as [uploadCoverPhoto]; see storage.rules'
  /// own doc comment on that path). A fresh upload to an already-filled
  /// [index] overwrites it (replace), same "no history of old ones"
  /// behavior as the cover photo.
  ///
  /// On success, writes the resulting real download URL into
  /// mechanicAccounts/{uid}.galleryPhotoUrls at position [index] — read the
  /// current 3-element array first (via [padGalleryPhotoUrls], so a
  /// document with no field yet or a shorter/malformed array is handled
  /// the same defensive way [MechanicProfile.fromFirestore] already is),
  /// mutate just that one index, then write the whole array back:
  /// Firestore has no atomic "update index N of an array" operation, so
  /// this read-mutate-write is the real mechanism, not a shortcut.
  ///
  /// Throws on failure, same as [uploadCoverPhoto] — the caller is
  /// responsible for catching this, logging it, and showing the mechanic
  /// real error feedback instead of a fake success state.
  Future<String> uploadGalleryPhoto({
    required String uid,
    required int index,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('mechanic_gallery/$uid/$index.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();

    final docRef = _firestore.collection('mechanicAccounts').doc(uid);
    final doc = await docRef.get();
    final gallery = padGalleryPhotoUrls(
      doc.data()?['galleryPhotoUrls'] as List<dynamic>?,
    );
    gallery[index] = url;
    await docRef.update({'galleryPhotoUrls': gallery});
    return url;
  }

  /// Removes the gallery photo at [index] — deletes the real Storage file
  /// and clears mechanicAccounts/{uid}.galleryPhotoUrls at that position
  /// back to null, leaving a real, permanent gap at [index] rather than
  /// shifting the remaining photos left (see [MechanicProfile.galleryPhotoUrls]'s
  /// own doc comment for why: a slot's index always identifies the same
  /// Storage file across adds/removes, so shifting would require also
  /// renaming/moving the other Storage files to stay in sync — real
  /// complexity this 3-slot feature doesn't need).
  ///
  /// Same read-mutate-write array update as [uploadGalleryPhoto], and same
  /// throws-on-failure contract as [uploadCoverPhoto].
  Future<void> removeGalleryPhoto({
    required String uid,
    required int index,
  }) async {
    await _storage.ref('mechanic_gallery/$uid/$index.jpg').delete();

    final docRef = _firestore.collection('mechanicAccounts').doc(uid);
    final doc = await docRef.get();
    final gallery = padGalleryPhotoUrls(
      doc.data()?['galleryPhotoUrls'] as List<dynamic>?,
    );
    gallery[index] = null;
    await docRef.update({'galleryPhotoUrls': gallery});
  }
}
