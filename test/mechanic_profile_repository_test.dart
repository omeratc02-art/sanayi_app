import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanayi_app/mechanic/profile/data/mechanic_profile_repository.dart';

/// MechanicProfileRepository.recordProfileView/watchProfileViewCount — the
/// real data source behind the mechanic home screen's "İşletmeniz İlgi
/// Görüyor" profile-view stat (see mechanic_home_screen.dart's
/// _WeeklyEngagementSummaryCard). These tests exercise the repository
/// directly against a fake Firestore, covering exactly the agreed design:
/// daily per-customer uniqueness, no counting for anonymous/no-uid views,
/// and no counting when the business owner views their own profile.
void main() {
  late FakeFirebaseFirestore firestore;
  late MechanicProfileRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = MechanicProfileRepository(firestore: firestore);
  });

  Future<void> seedBusiness(String uid, {String businessId = 'test-isletme', bool archived = false}) {
    return firestore.collection('mechanicAccounts').doc(uid).set({
      'name': 'Test Usta',
      'businessId': businessId,
      'email': 'usta@example.com',
      if (archived) 'archived': true,
    });
  }

  Future<int> currentCount(String uid) async {
    final doc = await firestore.collection('mechanicAccounts').doc(uid).get();
    return (doc.data()?['profileViewCount'] as num?)?.toInt() ?? 0;
  }

  test('A real signed-in customer viewing a business increments profileViewCount by 1', () async {
    await seedBusiness('mechanic-uid-1');

    await repository.recordProfileView(businessId: 'test-isletme', customerId: 'customer-1');

    expect(await currentCount('mechanic-uid-1'), 1);
  });

  test('The same customer viewing the same business again the same day does not increment a second time', () async {
    await seedBusiness('mechanic-uid-1');

    await repository.recordProfileView(businessId: 'test-isletme', customerId: 'customer-1');
    await repository.recordProfileView(businessId: 'test-isletme', customerId: 'customer-1');
    await repository.recordProfileView(businessId: 'test-isletme', customerId: 'customer-1');

    expect(await currentCount('mechanic-uid-1'), 1);
  });

  test('A different customer viewing the same business the same day increments again', () async {
    await seedBusiness('mechanic-uid-1');

    await repository.recordProfileView(businessId: 'test-isletme', customerId: 'customer-1');
    await repository.recordProfileView(businessId: 'test-isletme', customerId: 'customer-2');

    expect(await currentCount('mechanic-uid-1'), 2);
  });

  test('An old-day marker does not suppress today\'s view — the daily-uniqueness key resets by calendar day', () async {
    await seedBusiness('mechanic-uid-1');
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayKey =
        '${yesterday.year.toString().padLeft(4, '0')}-'
        '${yesterday.month.toString().padLeft(2, '0')}-'
        '${yesterday.day.toString().padLeft(2, '0')}';
    // Simulates "this customer already viewed yesterday" without needing to
    // control DateTime.now() from the test — recordProfileView keys its
    // real marker by today's actual date, which never matches this
    // pre-seeded old-day key, so it must not be suppressed by it.
    await firestore
        .collection('mechanicAccounts')
        .doc('mechanic-uid-1')
        .collection('dailyViewers')
        .doc('customer-1_$yesterdayKey')
        .set({'customerId': 'customer-1'});

    await repository.recordProfileView(businessId: 'test-isletme', customerId: 'customer-1');

    expect(await currentCount('mechanic-uid-1'), 1);
  });

  test('A null customerId (anonymous/guest view) does not increment', () async {
    await seedBusiness('mechanic-uid-1');

    await repository.recordProfileView(businessId: 'test-isletme', customerId: null);

    expect(await currentCount('mechanic-uid-1'), 0);
  });

  test('An empty-string customerId does not increment', () async {
    await seedBusiness('mechanic-uid-1');

    await repository.recordProfileView(businessId: 'test-isletme', customerId: '');

    expect(await currentCount('mechanic-uid-1'), 0);
  });

  test('The business owner viewing their own profile does not increment', () async {
    await seedBusiness('mechanic-uid-1');

    // The mechanicAccounts document id IS the owning mechanic's uid — this
    // customerId matches it exactly, simulating the owner viewing their own
    // MechanicDetailPage.
    await repository.recordProfileView(businessId: 'test-isletme', customerId: 'mechanic-uid-1');

    expect(await currentCount('mechanic-uid-1'), 0);
  });

  test('No matching business (wrong businessId, or only an archived match) does not increment or throw', () async {
    await seedBusiness('mechanic-uid-1', businessId: 'archived-isletme', archived: true);

    await repository.recordProfileView(businessId: 'archived-isletme', customerId: 'customer-1');
    await repository.recordProfileView(businessId: 'does-not-exist-at-all', customerId: 'customer-1');

    expect(await currentCount('mechanic-uid-1'), 0);
  });

  test('watchProfileViewCount emits a real 0 before any view, then the real count after one is recorded', () async {
    await seedBusiness('mechanic-uid-1');

    final values = <int>[];
    final subscription = repository.watchProfileViewCount('mechanic-uid-1').listen(values.add);
    await Future<void>.delayed(Duration.zero);

    await repository.recordProfileView(businessId: 'test-isletme', customerId: 'customer-1');
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(values, contains(0));
    expect(values.last, 1);
  });
}
