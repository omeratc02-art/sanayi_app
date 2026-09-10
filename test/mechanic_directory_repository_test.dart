import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/data/mechanic_directory_repository.dart';

/// Covers the fix for a real vulnerability: an unverified mechanic account
/// (freshly registered, freshly claimed, or one of the script-uploaded
/// businesses that has no isVerified field at all) was previously fully
/// visible to customers via fetchByHizmetTuru/fetchByBusinessId, with
/// isVerified only ever controlling a cosmetic badge. Both methods now
/// exclude any business whose isVerified isn't explicitly true — missing,
/// null, and false must all be treated identically as "not visible".
void main() {
  late FakeFirebaseFirestore firestore;
  late MechanicDirectoryRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = MechanicDirectoryRepository(firestore: firestore);
  });

  Future<void> seed(
    String docId, {
    required String name,
    required String businessId,
    Object? isVerified = _omit,
    bool archived = false,
  }) {
    return firestore.collection('mechanicAccounts').doc(docId).set({
      'name': name,
      'businessId': businessId,
      'hizmetTürü': 'tamir',
      if (isVerified != _omit) 'isVerified': isVerified,
      if (archived) 'archived': true,
    });
  }

  group('fetchByHizmetTuru', () {
    test('A verified business (isVerified: true) is returned', () async {
      await seed('m1', name: 'Doğrulanmış Usta', businessId: 'dogrulanmis-usta', isVerified: true);

      final results = await repository.fetchByHizmetTuru('tamir');

      expect(results.map((m) => m.name), contains('Doğrulanmış Usta'));
    });

    test('A business with isVerified: false is excluded', () async {
      await seed('m1', name: 'Onaysız Usta', businessId: 'onaysiz-usta', isVerified: false);

      final results = await repository.fetchByHizmetTuru('tamir');

      expect(results, isEmpty);
    });

    test('A business missing the isVerified field entirely is excluded — same as the 13 real '
        'script-uploaded, not-yet-claimed businesses', () async {
      await seed('m1', name: 'Script Usta', businessId: 'script-usta');

      final results = await repository.fetchByHizmetTuru('tamir');

      expect(results, isEmpty);
    });

    test('A business with isVerified: null is excluded', () async {
      await seed('m1', name: 'Null Usta', businessId: 'null-usta', isVerified: null);

      final results = await repository.fetchByHizmetTuru('tamir');

      expect(results, isEmpty);
    });

    test('An archived-but-verified business is still excluded (claimed away, archived takes precedence)', () async {
      await seed('m1', name: 'Arşivlenmiş Usta', businessId: 'arsivlenmis-usta', isVerified: true, archived: true);

      final results = await repository.fetchByHizmetTuru('tamir');

      expect(results, isEmpty);
    });

    test('A mix of verified and unverified businesses returns only the verified ones', () async {
      await seed('m1', name: 'Görünür Usta', businessId: 'gorunur-usta', isVerified: true);
      await seed('m2', name: 'Gizli Usta', businessId: 'gizli-usta', isVerified: false);
      await seed('m3', name: 'Yeni Usta', businessId: 'yeni-usta');

      final results = await repository.fetchByHizmetTuru('tamir');

      expect(results.map((m) => m.name).toList(), ['Görünür Usta']);
    });
  });

  group('fetchByBusinessId', () {
    test('A verified business is returned', () async {
      await seed('m1', name: 'Doğrulanmış Usta', businessId: 'dogrulanmis-usta', isVerified: true);

      final result = await repository.fetchByBusinessId('dogrulanmis-usta');

      expect(result?.name, 'Doğrulanmış Usta');
    });

    test('An unverified business (isVerified: false) resolves to null, not the hidden record', () async {
      await seed('m1', name: 'Onaysız Usta', businessId: 'onaysiz-usta', isVerified: false);

      final result = await repository.fetchByBusinessId('onaysiz-usta');

      expect(result, isNull);
    });

    test('A business missing isVerified entirely resolves to null', () async {
      await seed('m1', name: 'Script Usta', businessId: 'script-usta');

      final result = await repository.fetchByBusinessId('script-usta');

      expect(result, isNull);
    });

    test(
      'A claimed business (new verified doc + old archived doc sharing the same businessId) '
      'still deterministically resolves to the new one',
      () async {
        await seed('old-doc', name: 'Eski Kayıt', businessId: 'claimed-usta', isVerified: true, archived: true);
        await seed('new-doc', name: 'Yeni Kayıt', businessId: 'claimed-usta', isVerified: true);

        final result = await repository.fetchByBusinessId('claimed-usta');

        expect(result?.name, 'Yeni Kayıt');
      },
    );
  });
}

/// Sentinel distinguishing "don't write this field at all" from "write it
/// as null" in [seed] above — a bare `Object?` default of null can't tell
/// those two cases apart.
const _omit = Object();
