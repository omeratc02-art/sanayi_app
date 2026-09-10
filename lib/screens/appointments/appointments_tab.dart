import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/appointment_request_store.dart';
import '../../mechanic/appointments/data/appointment.dart';
import '../../mechanic/appointments/data/appointment_repository.dart';
import '../../models/appointment_request.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_instances.dart';
import '../../utils/identity.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/appointments/appointment_request_card.dart';
import '../../widgets/common/premium_surface.dart';

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
    final uid = firebaseAuthInstance.currentUser?.uid;
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

    // Real appointments the mechanic has accepted — or is still deciding
    // on/has proposed a time for (AppointmentStatus.pending, e.g. after
    // "Başka Saat Öner") — read directly from Firestore (see initState)
    // rather than only from the block above. This is what makes an
    // approval (or a pending proposal) from an earlier session, or a
    // different device, still show up here.
    final firestoreConfirmed = _firestoreAppointments
        .where(
          (appointment) =>
              appointment.status == AppointmentStatus.accepted || appointment.status == AppointmentStatus.pending,
        )
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

    // Separate from the Upcoming/Past split above — an appointment stays
    // fully visible there too (durum/status is untouched by any of this);
    // this is purely an additional banner for the new completion-
    // verification layer, sourced directly from the real Appointment
    // objects (not the AppointmentRequest conversion used above).
    final pendingVerification = _firestoreAppointments
        .where((appointment) => appointment.tamamlanmaDurumu == 'usta_onayladi_bekleniyor')
        .toList();

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          children: [
            if (pendingVerification.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                child: Column(
                  children: [
                    for (final appointment in pendingVerification) ...[
                      _CompletionVerificationCard(appointment: appointment),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
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

/// Banner card for an appointment the mechanic has marked complete but the
/// customer hasn't verified yet — built directly on the real Appointment
/// (not AppointmentRequest, which has no room for tamamlanmaDurumu/rating).
/// Mechanic name reuses AppointmentRequestStore's existing businessId→name
/// lookup rather than duplicating it. Same PremiumSurface styling as
/// AppointmentRequestCard above.
class _CompletionVerificationCard extends StatefulWidget {
  const _CompletionVerificationCard({required this.appointment});

  final Appointment appointment;

  @override
  State<_CompletionVerificationCard> createState() => _CompletionVerificationCardState();
}

class _CompletionVerificationCardState extends State<_CompletionVerificationCard> {
  var _isSubmitting = false;

  Future<void> _confirmCompleted() async {
    final result = await showDialog<_VerificationResult>(
      context: context,
      builder: (_) => const _VerificationDialog(),
    );
    if (result == null) return;
    setState(() => _isSubmitting = true);
    try {
      await AppointmentRepository().markCustomerVerified(
        widget.appointment.appointmentId,
        rating: result.rating,
        comment: result.comment,
      );
    } catch (error) {
      debugPrint('CUSTOMER APPOINTMENT VERIFICATION ERROR: $error');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  Future<void> _confirmDisputed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Randevu Tamamlanmadı mı?'),
        content: const Text('Bu işlemi onayladığınızda randevu "anlaşmazlık" olarak işaretlenecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Evet, Bildir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isSubmitting = true);
    try {
      await AppointmentRepository().markCustomerDisputed(widget.appointment.appointmentId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final mechanicName = AppointmentRequestStore.instance.appointmentRequestFromAccepted(appointment).mechanicName;
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mechanicName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '${formatFullDate(appointment.appointmentDate)} tarihli randevunuz usta tarafından tamamlandı '
            'olarak işaretlendi. Onaylıyor musunuz?',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _confirmDisputed,
                  child: const Text('Hayır, öyle değildi'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmCompleted,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Evet, tamamlandı'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationResult {
  const _VerificationResult({this.rating, this.comment});

  final int? rating;
  final String? comment;
}

/// Optional 1-5 star rating + optional comment, shown before confirming
/// completion. Both stay optional per spec — "Vazgeç" cancels the whole
/// verification (pops null), "Onayla" always proceeds regardless of
/// whether a rating/comment was entered.
class _VerificationDialog extends StatefulWidget {
  const _VerificationDialog();

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  final _commentController = TextEditingController();
  int? _rating;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Randevu Tamamlandı mı?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İsterseniz servis sağlayıcıyı puanlayabilir ve yorum bırakabilirsiniz (opsiyonel).',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    (_rating ?? 0) >= i ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.turquoise,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Yorumunuz (opsiyonel)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(
            _VerificationResult(
              rating: _rating,
              comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
            ),
          ),
          child: const Text('Onayla'),
        ),
      ],
    );
  }
}
