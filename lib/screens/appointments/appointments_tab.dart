import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/appointment_request_store.dart';
import '../../mechanic/appointments/data/appointment.dart';
import '../../mechanic/appointments/data/appointment_repository.dart';
import '../../models/appointment_request.dart';
import '../../theme/app_theme.dart';
import '../../utils/identity.dart';
import '../../widgets/appointments/appointment_request_card.dart';

/// "Randevularım" tab — lists the customer's preferred-time-window
/// appointment requests and their status. Upcoming/Past are built from two
/// sources: [AppointmentRequestStore]'s session-local state (the (simulated)
/// provider responses submitted from [AppointmentRequestPage], and guests'
/// local-only confirmations), and this screen's own direct, live Firestore
/// query for the signed-in customer's real persisted appointments — so a
/// mechanic's approval shows up here even after an app restart, not only
/// within the session that submitted the request.
class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  StreamSubscription<List<Appointment>>? _firestoreSubscription;
  List<Appointment> _firestoreAppointments = [];

  @override
  void initState() {
    super.initState();
    AppointmentRequestStore.instance.addListener(_onStoreChanged);

    // Real, persisted appointments read straight from Firestore for the
    // signed-in customer — guests (no signed-in Firebase user) have no
    // real customerId to query by, so they're left on the session-local
    // path only, same as every other guest path in this app.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _firestoreSubscription = AppointmentRepository().watchCustomerAppointments(uid).listen(
        (appointments) {
          if (!mounted) return;
          setState(() => _firestoreAppointments = appointments);
        },
        onError: (Object error) {
          debugPrint('CUSTOMER APPOINTMENTS LISTENER ERROR: $error');
        },
      );
    }
  }

  @override
  void dispose() {
    AppointmentRequestStore.instance.removeListener(_onStoreChanged);
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    // Session-local confirmed requests — a request only reaches "confirmed"
    // once the customer has accepted either the originally requested time
    // or a mechanic-proposed alternative (see AppointmentRequestStore.accept),
    // or (guests only) the simulated provider-response flow. Everything
    // still pending lives in the Notifications/Messages flow instead.
    final localConfirmed = AppointmentRequestStore.instance.requests.where(
      (request) => request.status == AppointmentRequestStatus.confirmed && request.customerId == resolveCustomerId(),
    );

    // Real appointments the mechanic has accepted, read directly from
    // Firestore (see initState) rather than only from the block above —
    // this is what makes an approval from an earlier session, or a
    // different device, still show up here.
    final firestoreConfirmed = _firestoreAppointments
        .where((appointment) => appointment.status == AppointmentStatus.accepted)
        .map(AppointmentRequestStore.instance.appointmentRequestFromAccepted);

    // Merged by id — the same request can legitimately appear in both
    // sources (e.g. accepted this session, before the Firestore listener's
    // own update arrives); Firestore, being the authoritative persisted
    // state, wins on conflict.
    final byId = {for (final request in localConfirmed) request.id: request};
    for (final request in firestoreConfirmed) {
      byId[request.id] = request;
    }
    final confirmed = byId.values.toList();

    // Split into Upcoming/Past by date — there's no separate "completed"
    // status in this dummy-data app, so a confirmed appointment whose date
    // has already passed is treated as past.
    final today = _dateOnly(DateTime.now());
    final upcoming = confirmed.where((request) => !_dateOnly(request.date).isBefore(today)).toList();
    final past = confirmed.where((request) => _dateOnly(request.date).isBefore(today)).toList();

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AppointmentList(requests: upcoming),
                  _AppointmentList(requests: past),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({required this.requests});

  final List<AppointmentRequest> requests;

  @override
  Widget build(BuildContext context) {
    return requests.isEmpty
        ? const _EmptyState()
        : ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => AppointmentRequestCard(request: requests[index]),
          );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Henüz randevu talebiniz yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bir servis sağlayıcıdan randevu talep ettiğinizde burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
