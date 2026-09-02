import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../utils/identity.dart';
import '../../widgets/common/premium_surface.dart';
import 'appointment_calendar_view.dart';
import 'data/appointment.dart';
import 'data/appointment_repository.dart';

const _weekdayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
const _monthNames = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String _formatRequestedDate(DateTime date) => '${date.day} ${_monthNames[date.month - 1]}, ${_weekdayNames[date.weekday - 1]}';

String _formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

String _formatPreferredTimeRange(TimeOfDay start, Duration duration) {
  final startMinutes = start.hour * 60 + start.minute;
  final endMinutes = startMinutes + duration.inMinutes;
  final end = TimeOfDay(hour: (endMinutes ~/ 60) % 24, minute: endMinutes % 60);
  return '${_formatTimeOfDay(start)} – ${_formatTimeOfDay(end)}';
}


// Day + month + year only (no weekday) — the confirmation dialog's summary
// layout, unlike _formatRequestedDate above which includes the weekday.
String _formatDateWithYear(DateTime date) => '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

// Zero-padded day + month + year + weekday — e.g. "08 Ağustos 2026
// Cumartesi", for the "Başka Saat Öner" slot-selection confirmation dialog.
String _formatFullDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_monthNames[date.month - 1]} ${date.year} ${_weekdayNames[date.weekday - 1]}';

/// One "Label: value" line in the confirmation dialog's appointment
/// summary — label semi-bold and higher-contrast (textPrimary) so it reads
/// as a field name, value regular weight at the dialog's normal
/// (textSecondary) content color. Font size/spacing/layout are untouched:
/// both spans inherit the ambient DialogContentText style, only weight and
/// color differ between them.
Widget _summaryLine(String label, String value) => Text.rich(
  TextSpan(
    children: [
      TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.normal, color: AppColors.textSecondary)),
    ],
  ),
);

/// Icon + text row for the "Suggest Appointment Time" confirmation
/// dialog's appointment info section — small Material icon, 12px gap,
/// then the value. No labels; the icon itself conveys what the value is.
class _SuggestInfoRow extends StatelessWidget {
  const _SuggestInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
          ),
        ),
      ],
    );
  }
}

/// Floating top-of-screen success banner shown after a slot suggestion is
/// sent — fades in, holds for 2 seconds, then fades out and removes
/// itself via [onDismissed]. Wrapped in IgnorePointer so it never blocks
/// taps on whatever's underneath.
class _SuggestionSentBanner extends StatefulWidget {
  const _SuggestionSentBanner({required this.onDismissed});

  final VoidCallback onDismissed;

  @override
  State<_SuggestionSentBanner> createState() => _SuggestionSentBannerState();
}

class _SuggestionSentBannerState extends State<_SuggestionSentBanner> with SingleTickerProviderStateMixin {
  static const _fadeDuration = Duration(milliseconds: 250);
  static const _visibleDuration = Duration(seconds: 2);

  late final AnimationController _controller = AnimationController(vsync: this, duration: _fadeDuration);
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future.delayed(_fadeDuration + _visibleDuration, () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Saat önerisi müşteriye gönderildi.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mechanic Panel > Appointments screen. Two top tabs — Yeni Talepler
/// (New Requests) / Tüm Randevular (All Appointments) — with "Yeni
/// Talepler" selected by default. The former "Bugün" (Today), "Yaklaşan"
/// (Upcoming), and "Geçmiş" (History) tabs were merged into the single
/// "Tüm Randevular" calendar-agenda tab (see AppointmentCalendarView).
/// Both tabs are backed by the real `randevular` collection (see
/// data/appointment_repository.dart) — no dummy/hardcoded appointment data.
class MechanicAppointmentsScreen extends StatefulWidget {
  const MechanicAppointmentsScreen({super.key});

  @override
  State<MechanicAppointmentsScreen> createState() => _MechanicAppointmentsScreenState();
}

class _MechanicAppointmentsScreenState extends State<MechanicAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late final TabController _tabController = TabController(length: 2, vsync: this);
  // Populated from Firestore in _loadAppointments — no dummy fallback, so
  // the calendar genuinely shows nothing rather than fake appointments
  // while the fetch is in flight or if it fails.
  List<Appointment> _appointments = [];
  final _appointmentRepository = AppointmentRepository();

  // Non-null while "Başka Saat Öner" is active for this request — the
  // "Tüm Randevular" tab shows the instructional banner and its calendar's
  // empty slots become selectable (see build() and _handleSlotSelected).
  _PendingRequest? _suggestingTimeFor;

  // Root cause of a real bug: this used to be populated by a one-time
  // fetch in initState, so "Yeni Talepler" silently went stale for the
  // entire lifetime of this screen — a request submitted after the screen
  // first loaded never appeared, and a mechanic acting on whatever was
  // still visible could end up sending "Başka Saat Öner" against an old,
  // unrelated request's document instead of the one they actually meant.
  // Kept live instead, and cancelled in dispose() so it doesn't outlive
  // this screen.
  StreamSubscription<List<Appointment>>? _pendingAppointmentsSubscription;

  // Same root cause, same fix, for "Tüm Randevular": _appointments used to
  // be a single fetchAppointments() call in initState, so an appointment
  // accepted anywhere in the app after this screen first loaded (this
  // screen's own "Kabul Et", or MechanicRequestDetailsPage's "Talebi Kabul
  // Et") never showed up here — MechanicHomePage keeps this screen mounted
  // via IndexedStack for the whole app session, so that first load was
  // effectively permanent staleness, not a one-time cost.
  StreamSubscription<List<Appointment>>? _appointmentsSubscription;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  // Restores appointments confirmed in earlier sessions (see
  // AppointmentRepository.saveAppointment) so they survive an app restart,
  // merging by appointmentId so nothing shows up twice. Also starts the
  // live "Yeni Talepler" subscription (see _pendingAppointmentsSubscription)
  // — a signed-out account, or one without a resolvable businessId, sees
  // none rather than risking another business's requests (same safe-default
  // already used by MechanicNotificationsScreen).
  Future<void> _loadAppointments() async {
    final myBusinessId = await resolveMyBusinessId();
    // A signed-out account, or one without a resolvable businessId, sees
    // none rather than risking another business's requests/appointments
    // (same safe-default already used by MechanicNotificationsScreen).
    if (!mounted || myBusinessId == null) return;

    // Only this mechanic's own accepted appointments belong on the
    // calendar — declined and pending (awaiting-decision) ones are
    // decisions in progress, not scheduled services. Server-side filtered
    // by businessId, same as watchPendingAppointments below.
    _appointmentsSubscription?.cancel();
    _appointmentsSubscription = _appointmentRepository.watchAppointmentsForBusiness(myBusinessId).listen(
      (appointments) {
        if (!mounted) return;
        setState(() {
          _appointments = appointments.where((appointment) => appointment.status == AppointmentStatus.accepted).toList();
        });
      },
      onError: (Object error) {
        debugPrint('APPOINTMENTS LISTENER ERROR: $error');
      },
    );

    // Server-side filtered, same businessId + status == pending condition
    // as before, now a live stream instead of a single fetch — a new
    // request, or one the mechanic already acted on, updates this list
    // automatically without requiring the screen to be reopened.
    _pendingAppointmentsSubscription?.cancel();
    _pendingAppointmentsSubscription = _appointmentRepository.watchPendingAppointments(myBusinessId).listen(
      (pendingAppointments) {
        if (!mounted) return;
        setState(() {
          _pendingRequests = pendingAppointments.map(_toPendingRequest).toList();
        });
      },
      onError: (Object error) {
        debugPrint('PENDING APPOINTMENTS LISTENER ERROR: $error');
      },
    );
  }

  // AppointmentRequest (the customer-side model) has no exact time at
  // request time — only a preferred window, kept in customerNote (see
  // AppointmentRequestStore._persistToFirestore) — so Appointment's
  // required appointmentTime is written as a 00:00 sentinel; mapped back
  // to null here, matching _PendingRequest's existing "no time yet" case.
  static const _noTimeSentinel = TimeOfDay(hour: 0, minute: 0);

  _PendingRequest _toPendingRequest(Appointment appointment) {
    // TEMP DEBUG — remove after root-causing the service-label mismatch.
    debugPrint(
      'TRACE _toPendingRequest id=${appointment.appointmentId} serviceType=${appointment.serviceType}',
    );
    return _PendingRequest(
    appointmentId: appointment.appointmentId,
    businessId: appointment.businessId,
    customerId: appointment.customerId,
    customerName: appointment.customerName,
    customerPhone: appointment.customerPhone,
    vehicleModel: appointment.vehicleModel,
    licensePlate: appointment.licensePlate,
    service: appointment.serviceType,
    problem: appointment.customerNote,
    preferredTimeRangeLabel: appointment.preferredTimeRangeLabel,
    appointmentDate: appointment.appointmentDate,
    appointmentTime: appointment.appointmentTime == _noTimeSentinel ? null : appointment.appointmentTime,
    estimatedDuration: appointment.estimatedDuration,
    distance: appointment.distance,
    priceRange: '',
    createdAt: appointment.createdAt,
    sonTeklifEden: appointment.sonTeklifEden,
    teklifEdilenTarih: appointment.teklifEdilenTarih,
    teklifEdilenSaat: appointment.teklifEdilenSaat,
  );
  }

  // Mirrors _acceptRequest's confirmation-dialog + Firestore-write shape,
  // but for the opposite outcome: persists a declined record (reusing the
  // same Appointment model/repository as an accepted one, just tagged
  // AppointmentStatus.declined) and removes the request from the pending
  // list only once that write succeeds.
  void _declineRequest(_PendingRequest request) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Talebi Reddet'),
        content: Text(
          '${request.customerName} adlı müşterinin randevu talebi reddedilecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _confirmDecline(request);
            },
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDecline(_PendingRequest request) async {
    final declined = Appointment(
      // Overwrites the same Firestore document the request was read from
      // (see _toPendingRequest), transitioning it pending -> declined,
      // instead of creating an orphaned second document.
      appointmentId: request.appointmentId,
      businessId: request.businessId,
      customerId: request.customerId,
      customerName: request.customerName,
      customerPhone: request.customerPhone,
      vehicleModel: request.vehicleModel,
      licensePlate: request.licensePlate,
      serviceType: request.service,
      appointmentDate: request.appointmentDate,
      // A declined request has no confirmed time — Appointment requires
      // one, but it's meaningless here since there will be no appointment;
      // this record only exists to remember the decision.
      appointmentTime: request.appointmentTime ?? const TimeOfDay(hour: 0, minute: 0),
      estimatedDuration: request.estimatedDuration,
      customerNote: request.problem,
      status: AppointmentStatus.declined,
      createdAt: DateTime.now(),
      distance: request.distance,
      preferredTimeRangeLabel: request.preferredTimeRangeLabel,
    );

    try {
      await _appointmentRepository.saveAppointment(declined);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Talep reddedilemedi: $error')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _pendingRequests.remove(request));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Talep reddedildi.')),
    );
  }

  @override
  void dispose() {
    _pendingAppointmentsSubscription?.cancel();
    _appointmentsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _acceptRequest(_PendingRequest request) {
    // A customer counter-proposal (see AppointmentRepository.
    // _needsMechanicAttention) must be summarized and accepted from
    // teklifEdilenTarih/teklifEdilenSaat, not request.appointmentTime/
    // preferredTimeRangeLabel — those stay whatever they were before the
    // negotiation started (see Appointment.teklifEdilenTarih doc) and
    // accepting them here would silently ignore what the customer actually
    // proposed.
    final isCounterProposal = request.isCustomerCounterProposal;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Randevuyu Onayla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryLine('Müşteri', request.customerName),
            _summaryLine('Araç', request.vehicleModel),
            _summaryLine('Hizmet', request.service),
            _summaryLine(
              'Tarih',
              _formatDateWithYear(isCounterProposal ? request.teklifEdilenTarih! : request.appointmentDate),
            ),
            // The appointment time must come from either the customer's own
            // selection, a mechanic-proposed alternative the customer
            // accepted, or (isCounterProposal) the customer's own
            // counter-proposal — never a made-up value. Neither exists yet
            // for a request whose appointmentTime is still null (e.g. the
            // customer asked for "İlk Müsait Saat" instead of picking a
            // time) — see _PendingRequest.appointmentTime doc.
            _summaryLine(
              'Saat',
              isCounterProposal
                  ? _formatTimeOfDay(request.teklifEdilenSaat!)
                  : switch (request.appointmentTime) {
                      final time? => _formatTimeOfDay(time),
                      null when request.preferredTimeRangeLabel.isNotEmpty => request.preferredTimeRangeLabel,
                      null => 'Henüz belirlenmedi',
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Onayladığınızda müşteriye bildirim gönderilecek ve randevu oluşturulacaktır.'),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.turquoise, foregroundColor: Colors.white),
              onPressed: () {
                if (isCounterProposal) {
                  // Same acceptTimeProposal() path MechanicRequestDetailsPage's
                  // "Kabul Et" already uses for this exact negotiation state.
                  Navigator.of(dialogContext).pop();
                  _acceptTimeProposal(request);
                  return;
                }
                final time = request.appointmentTime;
                if (time != null) {
                  // A real time already exists (set via "Başka Saat Öner"),
                  // so accepting it uses exactly its own already-stored
                  // estimatedDuration — this path is unchanged.
                  Navigator.of(dialogContext).pop();
                  _confirmAppointment(request, time);
                  return;
                }
                // No exact time yet — accept the customer's own already-
                // selected preferred window directly (no second customer
                // confirmation for the same window), preserving its full
                // span via (start, duration) rather than collapsing it to
                // a single point. "İlk Müsait Saat"/empty/malformed labels
                // don't parse, so they correctly fall through to the
                // existing "needs Başka Saat Öner" error below instead of
                // inventing a time.
                final parsedRange = parsePreferredTimeRange(request.preferredTimeRangeLabel);
                if (parsedRange != null) {
                  Navigator.of(dialogContext).pop();
                  _confirmAppointment(request, parsedRange.start, duration: parsedRange.duration);
                  return;
                }
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bu talep için henüz onaylanmış bir saat yok. Bir saat seçilmeden randevu onaylanamaz.'),
                  ),
                );
              },
              child: const Text('Randevuyu Onayla'),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the Appointment up front (so the id used for the Firestore write
  // matches exactly what ends up in local state), persists it, and only
  // shows the existing success dialog / advances the local list + tab once
  // that write actually succeeds — a failed write shows an error instead,
  // with nothing added locally and no success dialog shown.
  //
  // [duration] overrides request.estimatedDuration only for the "accept the
  // customer's own preferred window directly" path (see _acceptRequest),
  // where it's the actual (end - start) span of that window rather than the
  // otherwise-always-60-minute default a fresh request is submitted with.
  // Omitted (null) for the existing "Başka Saat Öner" -> accept path, which
  // keeps using request.estimatedDuration exactly as before.
  Future<void> _confirmAppointment(_PendingRequest request, TimeOfDay time, {Duration? duration}) async {
    final appointment = Appointment(
      // Overwrites the same Firestore document the request was read from
      // (see _toPendingRequest), transitioning it pending -> accepted,
      // instead of creating an orphaned second document.
      appointmentId: request.appointmentId,
      businessId: request.businessId,
      customerId: request.customerId,
      customerName: request.customerName,
      customerPhone: request.customerPhone,
      vehicleModel: request.vehicleModel,
      licensePlate: request.licensePlate,
      serviceType: request.service,
      appointmentDate: request.appointmentDate,
      appointmentTime: time,
      estimatedDuration: duration ?? request.estimatedDuration,
      customerNote: request.problem,
      status: AppointmentStatus.accepted,
      createdAt: DateTime.now(),
      distance: request.distance,
      preferredTimeRangeLabel: request.preferredTimeRangeLabel,
    );

    try {
      await _appointmentRepository.saveAppointment(appointment);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu kaydedilemedi: $error')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _pendingRequests.remove(request);
      _appointments = [..._appointments, appointment];
    });
    _showAppointmentConfirmedDialog();
  }

  // Finalizes a customer's counter-proposal (request.isCustomerCounterProposal)
  // — the same acceptTimeProposal() path MechanicRequestDetailsPage's
  // "Kabul Et" already uses for this exact state, instead of
  // _confirmAppointment/saveAppointment, which would silently accept the
  // stale request.appointmentTime/preferredTimeRangeLabel rather than what
  // the customer actually proposed (teklifEdilenTarih/teklifEdilenSaat).
  // _appointments isn't updated manually here — the live
  // watchAppointmentsForBusiness subscription (see initState) picks up the
  // change on its own, same as the calendar's propose flow already relies on.
  Future<void> _acceptTimeProposal(_PendingRequest request) async {
    final date = request.teklifEdilenTarih;
    final time = request.teklifEdilenSaat;
    if (date == null || time == null) return;
    try {
      await _appointmentRepository.acceptTimeProposal(request.appointmentId, date: date, time: time);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu onaylanamadı: $error')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _pendingRequests.remove(request);
    });
    _showAppointmentConfirmedDialog();
  }

  void _showAppointmentConfirmedDialog() {
    showDialog<void>(
      context: context,
      builder: (successContext) => AlertDialog(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: AppSpacing.sm),
            Text('Randevu Onaylandı', textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          'Randevu başarıyla oluşturuldu. Müşteriye bildirim gönderildi.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(successContext).pop();
                _tabController.animateTo(1);
              },
              child: const Text('Tamam'),
            ),
          ),
        ],
      ),
    );
  }

  // "Başka Saat Öner" reuses the existing "Tüm Randevular" calendar tab
  // instead of a dedicated screen/dialog — switching to it and turning on
  // slot-selection mode (see build()'s use of _suggestingTimeFor and
  // AppointmentCalendarView's onSlotSelected) rather than building new UI.
  void _suggestAnotherTime(_PendingRequest request) {
    setState(() => _suggestingTimeFor = request);
    _tabController.animateTo(1);
  }

  void _handleSlotSelected(DateTime slotStart) {
    // onSlotSelected is only ever wired up while _suggestingTimeFor is
    // non-null (see build()), but guard anyway rather than force-unwrap.
    final request = _suggestingTimeFor;
    if (request == null) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSending = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu randevu saatini müşteriye önermek istiyor musunuz?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SuggestInfoRow(icon: Icons.person_outline, text: request.customerName),
                const SizedBox(height: 12),
                _SuggestInfoRow(
                  icon: Icons.directions_car_outlined,
                  text: request.vehicleModel,
                ),
                const SizedBox(height: 12),
                _SuggestInfoRow(icon: Icons.build_outlined, text: request.service),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatFullDate(slotStart),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('🕒', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _formatTimeOfDay(TimeOfDay(hour: slotStart.hour, minute: slotStart.minute)),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                  ),
                ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
            ],
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: isSending ? null : () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              foregroundColor: Colors.white,
              // Wider, balanced horizontal padding so "Öneriyi Gönder" has
              // comfortable room — vertical stays at the theme's default
              // (14), so button height is unchanged.
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            onPressed: isSending
                ? null
                : () async {
                    setDialogState(() {
                      isSending = true;
                      errorMessage = null;
                    });

                    // Real negotiation proposal — same path
                    // MechanicRequestDetailsPage's own "Başka Saat Öner" now
                    // uses (see AppointmentRepository.proposeNewTime), not a
                    // direct overwrite of randevuTarihi/randevu_zamani. A
                    // narrow partial update: durum, sonTeklifEden, and the
                    // teklif fields change; the request's current
                    // date/time (still the sentinel/preferred window at
                    // this point) is left alone, same as that other entry
                    // point.
                    try {
                      await _appointmentRepository.proposeNewTime(
                        request.appointmentId,
                        date: DateTime(slotStart.year, slotStart.month, slotStart.day),
                        time: TimeOfDay(hour: slotStart.hour, minute: slotStart.minute),
                        proposedBy: 'usta',
                      );
                    } catch (error) {
                      setDialogState(() {
                        isSending = false;
                        errorMessage = 'Öneri gönderilemedi: $error';
                      });
                      return;
                    }

                    if (!mounted) return;
                    Navigator.of(dialogContext).pop();
                    // Proposing removes this request from "Yeni Talepler"
                    // immediately, same snappy-UI convention Accept/Decline
                    // already use — it's no longer actionable for the
                    // mechanic (sonTeklifEden is now 'usta'), the same
                    // "needs mechanic attention" rule
                    // AppointmentRepository.watchPendingAppointments applies
                    // itself once the next live snapshot arrives.
                    setState(() {
                      _pendingRequests.remove(request);
                      _suggestingTimeFor = null;
                    });
                    _showSuggestionSentOverlay();
                  },
            child: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Öneriyi Gönder'),
          ),
        ],
          ),
        );
      },
    );
  }

  // Custom top overlay instead of a SnackBar (which Flutter always
  // bottom-anchors) — inserted directly into the Navigator's Overlay, so
  // it floats above everything without blocking input and removes itself
  // once its fade-out finishes.
  void _showSuggestionSentOverlay() {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SuggestionSentBanner(onDismissed: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  // Populated from Firestore in _loadAppointments (businessId + status ==
  // pending) — no more hardcoded dummy requests; a real customer request
  // now has to actually exist for this list to show anything.
  List<_PendingRequest> _pendingRequests = [];

  // Earlier "Today" tab data source, feeding the now-inactive _TimelineRow.
  // Kept available for future reuse.
  // ignore: unused_field
  static const _todayAppointments = [
    _TodayAppointment(
      time: '09:00',
      customerName: 'Mehmet Demir',
      vehicleModel: 'Toyota Corolla',
      licensePlate: '35 DEF 789',
      service: 'Akü Değişimi',
      note: 'Sabahları araç bazen zor çalışıyor, kontrol edilmesini istiyorum.',
      distance: '2.1 km',
      estimatedDuration: '45 dk',
    ),
    _TodayAppointment(
      time: '10:30',
      customerName: 'Ahmet Yılmaz',
      vehicleModel: 'Renault Clio',
      licensePlate: '34 ABC 123',
      service: 'Yağ Değişimi',
      note: 'Aracımda ayrıca hafif bir fren sesi var, kontrol edebilir misiniz?',
      distance: '3.2 km',
      estimatedDuration: '30 dk',
    ),
    _TodayAppointment(
      time: '13:00',
      customerName: 'Elif Kaya',
      vehicleModel: 'Fiat Egea',
      licensePlate: '06 XYZ 456',
      service: 'Fren Bakımı',
      note: 'Öğleden sonra müsaitim, sabah saatleri bana uygun değil.',
      distance: '5.8 km',
      estimatedDuration: '40 dk',
    ),
  ];

  // Former "Today" tab data source — chronological time-range slots, some
  // occupied (an accepted appointment) and some open ("Müsait"). Kept
  // available for future reuse now that the Today tab has been removed.
  // ignore: unused_field
  static const _todaySchedule = [
    _TimeSlot(
      timeRange: '09:00–10:00',
      appointment: _TodayAppointment(
        time: '09:00',
        customerName: 'Mehmet Demir',
        vehicleModel: 'Toyota Corolla',
        licensePlate: '35 DEF 789',
        service: 'Akü Değişimi',
        note: 'Sabahları araç bazen zor çalışıyor, kontrol edilmesini istiyorum.',
        distance: '2.1 km',
        estimatedDuration: '45 dk',
      ),
    ),
    _TimeSlot(timeRange: '10:00–11:00'),
    _TimeSlot(
      timeRange: '11:00–12:00',
      appointment: _TodayAppointment(
        time: '11:00',
        customerName: 'Ahmet Yılmaz',
        vehicleModel: 'Renault Clio',
        licensePlate: '34 ABC 123',
        service: 'Yağ Değişimi',
        note: 'Aracımda ayrıca hafif bir fren sesi var, kontrol edebilir misiniz?',
        distance: '3.2 km',
        estimatedDuration: '30 dk',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_suggestingTimeFor != null ? 'Başka Saat Öner' : 'Randevular'),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined, size: 33),
          ),
        ],
        // Hidden while suggesting an alternative time — this becomes a
        // focused single-purpose view (see title above and the banner/info
        // card below), so the "Yeni Talepler"/"Tüm Randevular" tab switcher
        // shouldn't be reachable.
        bottom: _suggestingTimeFor != null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Yeni Talepler'),
                  Tab(text: 'Tüm Randevular'),
                ],
              ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              for (var i = 0; i < _pendingRequests.length; i++) ...[
                _NewRequestCard(
                  request: _pendingRequests[i],
                  onAccept: () => _acceptRequest(_pendingRequests[i]),
                  onSuggestAnotherTime: () => _suggestAnotherTime(_pendingRequests[i]),
                  onDecline: () => _declineRequest(_pendingRequests[i]),
                ),
                if (i < _pendingRequests.length - 1) const SizedBox(height: AppSpacing.xl),
              ],
            ],
          ),
          Column(
            children: [
              if (_suggestingTimeFor case final request?) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: AppColors.turquoise.withValues(alpha: 0.08),
                  child: const Text(
                    'Lütfen müşteri için uygun boş bir saat seçin.',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                  child: PremiumSurface(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.divider, width: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryLine('Müşteri', request.customerName),
                        const SizedBox(height: 4),
                        _summaryLine('Araç', request.vehicleModel),
                        const SizedBox(height: 4),
                        _summaryLine('Hizmet', request.service),
                      ],
                    ),
                  ),
                ),
              ],
              Expanded(
                child: AppointmentCalendarView(
                  selectedDate: _selectedDate,
                  appointments: _appointments,
                  onSlotSelected: _suggestingTimeFor != null ? _handleSlotSelected : null,
                  onWeekChanged: _suggestingTimeFor != null ? null : (date) => setState(() => _selectedDate = date),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingRequest {
  _PendingRequest({
    required this.appointmentId,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleModel,
    required this.licensePlate,
    required this.service,
    required this.problem,
    required this.preferredTimeRangeLabel,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.estimatedDuration,
    required this.distance,
    required this.priceRange,
    required this.createdAt,
    this.sonTeklifEden,
    this.teklifEdilenTarih,
    this.teklifEdilenSaat,
  });

  // The Firestore document this request maps to — reused (not
  // regenerated) when Accept/Decline persist the outcome, so the same
  // document transitions status rather than an orphaned copy being
  // created (see _confirmAppointment/_confirmDecline).
  final String appointmentId;
  final String businessId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String vehicleModel;
  final String licensePlate;
  final String service;
  final String problem;

  /// The customer's originally requested arrival window (e.g. "15:00 –
  /// 17:00", or "İlk Müsait Saat") — see Appointment.preferredTimeRangeLabel.
  /// Distinct from [appointmentTime]: this never changes once the customer
  /// submits the request, regardless of what the mechanic later proposes
  /// or accepts.
  final String preferredTimeRangeLabel;
  final DateTime appointmentDate;

  /// The customer's selected time, or a mechanic-proposed alternative the
  /// customer accepted. Null when neither exists yet (e.g. the customer
  /// asked for "İlk Müsait Saat" instead of picking a time) — never
  /// defaulted to a made-up value. See MechanicAppointmentsScreen's
  /// _acceptRequest, which refuses to convert a request into a confirmed
  /// Appointment while this is null.
  final TimeOfDay? appointmentTime;
  final Duration estimatedDuration;
  final String distance;
  final String priceRange;

  /// The original Firestore document's own createdAt — preserved so a
  /// counter-proposal (see MechanicAppointmentsScreen._handleSlotSelected)
  /// doesn't clobber the request's real submission time with "now" on
  /// every full-document .set().
  final DateTime createdAt;

  /// Negotiation fields (see Appointment.sonTeklifEden/teklifEdilenTarih/
  /// teklifEdilenSaat) — only meaningful together. Null unless this request
  /// is on "Yeni Talepler" because the customer just countered a proposal
  /// (see AppointmentRepository._needsMechanicAttention), in which case
  /// [isCustomerCounterProposal] is true and Kabul Et must accept exactly
  /// this date/time via acceptTimeProposal, not whatever [appointmentTime]/
  /// [preferredTimeRangeLabel] already holds.
  final String? sonTeklifEden;
  final DateTime? teklifEdilenTarih;
  final TimeOfDay? teklifEdilenSaat;

  bool get isCustomerCounterProposal =>
      sonTeklifEden == 'musteri' && teklifEdilenTarih != null && teklifEdilenSaat != null;
}

class _NewRequestCard extends StatelessWidget {
  const _NewRequestCard({
    required this.request,
    required this.onAccept,
    required this.onSuggestAnotherTime,
    required this.onDecline,
  });

  final _PendingRequest request;
  final VoidCallback onAccept;
  final VoidCallback onSuggestAnotherTime;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    // TEMP DEBUG — remove after root-causing the service-label mismatch.
    debugPrint('TRACE _NewRequestCard.build id=${request.appointmentId} service=${request.service}');
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 16),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NewRequestBadge(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_rounded, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      request.vehicleModel,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.licensePlate,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ServiceBadge(label: request.service),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(icon: Icons.person_outline, label: 'Müşteri', value: request.customerName),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Telefon',
                      value: request.customerPhone.isEmpty ? 'Belirtilmedi' : request.customerPhone,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.location_on_outlined, label: 'Mesafe', value: request.distance),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(icon: Icons.event, label: 'Tarih', value: _formatRequestedDate(request.appointmentDate)),
                    const SizedBox(height: 10),
                    if (request.appointmentTime case final time?)
                      // The mechanic has already set a specific time via
                      // "Başka Saat Öner" — the request is still pending
                      // (only Accept moves it to confirmed), so this reads
                      // as a proposal, not a confirmation.
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Önerilen Saat',
                        value: _formatPreferredTimeRange(time, request.estimatedDuration),
                      )
                    else
                      // Fresh request — nothing proposed yet, so this is
                      // exactly what the customer originally selected (a
                      // preferred window, or "İlk Müsait Saat"), never a
                      // confirmed or specific time.
                      _InfoRow(
                        icon: Icons.schedule,
                        label: 'Tercih Edilen Saat Aralığı',
                        value: request.preferredTimeRangeLabel,
                      ),
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.payments_outlined, label: 'Tahmini Fiyat', value: request.priceRange),
                  ],
                ),
              ),
            ],
          ),
          if (request.problem.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.description_outlined, label: 'Sorun', value: request.problem, maxLines: 2),
          ],
          if (request.isCustomerCounterProposal) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.compare_arrows_rounded,
              label: 'Müşterinin Önerdiği Saat',
              value:
                  '${_formatRequestedDate(request.teklifEdilenTarih!)} • ${_formatTimeOfDay(request.teklifEdilenSaat!)}',
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: request.customerPhone.isEmpty
                  ? null
                  : () => launchUrl(Uri(scheme: 'tel', path: request.customerPhone.replaceAll(' ', ''))),
              icon: const Icon(Icons.call_rounded, size: 17),
              label: const Text('Ara'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSuggestAnotherTime,
                  child: const Text('Başka Saat Öner'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('Kabul Et'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: onDecline,
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Reddet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayAppointment {
  const _TodayAppointment({
    required this.time,
    required this.customerName,
    required this.vehicleModel,
    required this.licensePlate,
    required this.service,
    required this.note,
    required this.distance,
    required this.estimatedDuration,
  });

  final String time;
  final String customerName;
  final String vehicleModel;
  final String licensePlate;
  final String service;
  final String note;
  final String distance;
  final String estimatedDuration;
}

/// One slot of the daily schedule — a time range that's either occupied
/// (an accepted appointment) or open. Used by the active _DailyScheduleRow
/// design below.
class _TimeSlot {
  const _TimeSlot({required this.timeRange, this.appointment});

  final String timeRange;
  final _TodayAppointment? appointment;
}

/// One row of a chronological daily schedule — the time column stays fixed
/// on the left, occupied rows show vehicle/plate/service on the right,
/// open ones show a subtle green "Müsait" badge. Tapping an occupied row
/// opens MechanicAppointmentDetailsPage — a separate, read-only detail
/// screen for already-accepted appointments (distinct from
/// MechanicRequestDetailsPage, which is for pending requests still
/// awaiting an accept/decline decision). Open rows are still tappable but
/// currently do nothing. Reuses _TimeSlot/_TodayAppointment (the existing
/// models) — was the active Today tab design; kept for future reuse now
/// that the Today tab has been removed.
// ignore: unused_element
class _DailyScheduleRow extends StatelessWidget {
  const _DailyScheduleRow({required this.slot});

  final _TimeSlot slot;

  @override
  Widget build(BuildContext context) {
    final appointment = slot.appointment;
    return InkWell(
      // Reserved/unused row (see class doc) — no longer has a way to
      // construct MechanicAppointmentDetailsPage's now-required Appointment
      // from a _TodayAppointment, so this is a no-op rather than a broken
      // navigation call.
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 96,
              child: Text(
                slot.timeRange,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: appointment == null
                  ? const _AvailableBadge()
                  : Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.vehicleModel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appointment.licensePlate,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          _ServiceBadge(label: appointment.service),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle green "available" pill for an open schedule slot — same pill
/// shape as _ServiceBadge/_NewRequestBadge, tinted rather than solid-filled
/// so it reads as "nothing to see here" next to the bold turquoise service
/// badge on occupied rows.
class _AvailableBadge extends StatelessWidget {
  const _AvailableBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'MÜSAİT',
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.green.shade800),
      ),
    );
  }
}

/// Earlier "Today" tab design — the connecting dot-and-line timeline.
/// Kept available for future reuse; not part of the active Today tab UI,
/// which is now _DailyScheduleRow above.
// ignore: unused_element
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.appointment, required this.isLast});

  final _TodayAppointment appointment;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Reserved/unused row (see class doc) — no longer has a way to
      // construct MechanicRequestDetailsPage's now-required Appointment
      // from a _TodayAppointment, so this is a no-op rather than a broken
      // navigation call (same treatment as _DailyScheduleRow below).
      onTap: () {},
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  appointment.time,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 18),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
                if (!isLast) const Expanded(child: VerticalDivider(width: 2, thickness: 2, color: AppColors.divider)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.vehicleModel,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${appointment.customerName} · ${appointment.service}',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small amber status pill — the card's "new / needs a decision" signal.
class _NewRequestBadge extends StatelessWidget {
  const _NewRequestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, size: 8, color: Colors.amber.shade800),
          const SizedBox(width: 6),
          Text(
            'Yeni Talep',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber.shade800),
          ),
        ],
      ),
    );
  }
}

/// Small rounded chip for the requested service — same treatment as the
/// service badge already used on MechanicHomeScreen's request cards.
class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.turquoise,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

/// Icon + "Label: value" row — same treatment as MechanicRequestDetailsPage's
/// _InfoRow, with an optional line clamp for longer values (e.g. the
/// customer's problem description).
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.maxLines});

  final IconData icon;
  final String label;
  final String value;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
            text: TextSpan(
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Was used by the "Yaklaşan"/"Geçmiş" tabs before they were merged into
// AppointmentCalendarView. Kept available for future reuse (e.g. an empty
// state within the calendar view itself).
// ignore: unused_element
class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({required this.message});

  final String message;

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
