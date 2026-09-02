import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/booking/section_label.dart';
import '../../widgets/common/premium_surface.dart';
import 'appointment_calendar_view.dart';
import 'data/appointment.dart';
import 'data/appointment_repository.dart';
import 'mechanic_conversation_page.dart';

// Same "no real time yet" sentinel already used across the mechanic side
// (e.g. MechanicAppointmentsScreen's pending-request cards).
const _noTimeSentinel = TimeOfDay(hour: 0, minute: 0);

/// The mechanic's primary workspace for a single request — receives the
/// real, tapped Appointment from MechanicHomeScreen's "Bekleyen Talepler"
/// list (same required-Appointment-param pattern already used by
/// MechanicAppointmentDetailsPage) as a starting point, then tracks it live
/// via AppointmentRepository.watchAppointmentById so a proposal/response
/// from the customer shows up here without leaving and reopening this page.
/// "Talebi Kabul Et" (first-time accept of a plain pending request) is real,
/// unchanged. "Başka Saat Öner"/"Kabul Et" are the real negotiation flow
/// (see AppointmentRepository.proposeNewTime/acceptTimeProposal) — no
/// longer stubs. The Photos section still shows placeholder thumbnails
/// only, since Appointment has no photo field.
class MechanicRequestDetailsPage extends StatefulWidget {
  const MechanicRequestDetailsPage({super.key, required this.appointment});

  final Appointment appointment;

  @override
  State<MechanicRequestDetailsPage> createState() => _MechanicRequestDetailsPageState();
}

class _MechanicRequestDetailsPageState extends State<MechanicRequestDetailsPage> {
  static const _photoCount = 3;

  late Appointment _appointment = widget.appointment;
  StreamSubscription<Appointment?>? _subscription;

  @override
  void initState() {
    super.initState();
    // Properly disposed below (see dispose()) — unlike
    // AppointmentRequestStore's own per-request watchAppointmentById
    // subscriptions, which only ever get cancelled via a store-wide
    // dispose() that never actually fires for that permanent singleton.
    _subscription = AppointmentRepository().watchAppointmentById(widget.appointment.appointmentId).listen((
      appointment,
    ) {
      if (!mounted || appointment == null) return;
      setState(() => _appointment = appointment);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  static String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  // A real time only exists once the mechanic has proposed one (or the
  // customer picked one outright) — until then, show the customer's
  // originally requested preferred window instead of a made-up time.
  String get _preferredTimeLabel {
    if (_appointment.appointmentTime != _noTimeSentinel) {
      return _formatTimeOfDay(_appointment.appointmentTime);
    }
    return _appointment.preferredTimeRangeLabel.isEmpty ? 'İlk Müsait Saat' : _appointment.preferredTimeRangeLabel;
  }

  String get _vehicleLabel => _appointment.vehicleModel;

  @override
  Widget build(BuildContext context) {
    final appointment = _appointment;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Talep Detayı')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _RequestSummaryCard(
            vehicleName: _vehicleLabel,
            service: appointment.serviceType,
            preferredDate: formatFullDate(appointment.start),
            preferredTime: _preferredTimeLabel,
            status: appointment.status.label,
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(text: 'Müşteri Bilgileri'),
          const SizedBox(height: AppSpacing.md),
          _CustomerInfoCard(
            customerName: appointment.customerName,
            customerPhone: appointment.customerPhone,
            vehiclePlate: appointment.licensePlate,
            vehicleModel: _vehicleLabel,
          ),
          if (appointment.customerNote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            const SectionLabel(text: 'Müşteri Notu'),
            const SizedBox(height: AppSpacing.md),
            _NoteCard(note: appointment.customerNote),
          ],
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(text: 'Fotoğraflar'),
          const SizedBox(height: AppSpacing.md),
          const _PhotosCard(count: _photoCount),
        ],
      ),
      bottomNavigationBar: _RequestActionBar(appointment: appointment, phoneNumber: appointment.customerPhone),
    );
  }
}

/// Hero section — the first thing a mechanic sees for this request.
class _RequestSummaryCard extends StatelessWidget {
  const _RequestSummaryCard({
    required this.vehicleName,
    required this.service,
    required this.preferredDate,
    required this.preferredTime,
    required this.status,
  });

  final String vehicleName;
  final String service;
  final String preferredDate;
  final String preferredTime;
  final String status;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_rounded, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vehicleName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ServiceBadge(label: service),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  preferredDate,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  preferredTime,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Durum: $status',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small rounded chip for the requested service — the page's one turquoise
/// accent, matching the same badge already used on the Home screen's
/// Pending Requests cards.
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

class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard({
    required this.customerName,
    required this.customerPhone,
    required this.vehiclePlate,
    required this.vehicleModel,
  });

  final String customerName;
  final String customerPhone;
  final String vehiclePlate;
  final String vehicleModel;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(icon: Icons.person_outline, label: 'Müşteri', value: customerName),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.phone_outlined, label: 'Telefon', value: customerPhone),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.pin_outlined, label: 'Plaka', value: vehiclePlate),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.directions_car_outlined, label: 'Araç Modeli', value: vehicleModel),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
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

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Text(
        note,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
      ),
    );
  }
}

/// Placeholder photo thumbnails only — no photo viewer yet.
class _PhotosCard extends StatelessWidget {
  const _PhotosCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm + 2),
            Expanded(child: _PhotoPlaceholder()),
          ],
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_outlined, size: 22, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Negotiation-aware action row:
/// - status == pending (no negotiation started): "Talebi Kabul Et" (unchanged
///   first-accept flow) + "Başka Saat Öner" (real — opens the mechanic's own
///   appointment calendar, see _ProposeTimeCalendarPage, so they pick an
///   actually-open slot instead of typing blind, then writes a proposal via
///   AppointmentRepository.proposeNewTime).
/// - status == timeProposed && sonTeklifEden == 'musteri' (the customer's
///   counter-proposal, the mechanic's turn to respond): "Kabul Et" (finalizes
///   the teklif fields via acceptTimeProposal) + "Farklı Saat Öner" (mechanic
///   counter-proposes again).
/// - status == timeProposed && sonTeklifEden == 'usta' (the mechanic's own
///   proposal, waiting on the customer): an informational waiting banner,
///   no action buttons — nothing for the mechanic to do until the customer
///   responds.
/// - any other status (already accepted, etc.): a plain status line, no
///   action buttons.
/// Mesajlaş/Ara stay available in every case.
class _RequestActionBar extends StatefulWidget {
  const _RequestActionBar({required this.appointment, required this.phoneNumber});

  final Appointment appointment;
  final String phoneNumber;

  @override
  State<_RequestActionBar> createState() => _RequestActionBarState();
}

class _RequestActionBarState extends State<_RequestActionBar> {
  var _isBusy = false;

  Future<void> _acceptRequest() async {
    final appointment = widget.appointment;
    final TimeOfDay resolvedTime;
    final Duration resolvedDuration;
    if (appointment.appointmentTime != _noTimeSentinel) {
      // A real time already exists (set via "Başka Saat Öner") — same
      // source of truth MechanicAppointmentsScreen's own "Kabul Et" uses
      // (see its _acceptRequest).
      resolvedTime = appointment.appointmentTime;
      resolvedDuration = appointment.estimatedDuration;
    } else {
      // No exact time yet — accept the customer's own already-selected
      // preferred window directly, preserving its full span via (start,
      // duration) rather than collapsing it to a single point or leaving
      // randevu_zamani at the "no time yet" sentinel (the root cause of a
      // real bug: an appointment accepted with that sentinel still intact
      // rendered its calendar block far off-screen, since _positionedBlock
      // positions blocks by hour-of-day). Exactly mirrors
      // MechanicAppointmentsScreen._acceptRequest's own fallback.
      final parsedRange = parsePreferredTimeRange(appointment.preferredTimeRangeLabel);
      if (parsedRange == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu talep için henüz onaylanmış bir saat yok. Bir saat seçilmeden randevu onaylanamaz.'),
          ),
        );
        return;
      }
      resolvedTime = parsedRange.start;
      resolvedDuration = parsedRange.duration;
    }

    setState(() => _isBusy = true);
    // Reconstructs the full document (every field copied from the real
    // appointment this page was opened for) with only status/time/duration
    // changed, then overwrites via saveAppointment — the exact same
    // mechanism MechanicAppointmentsScreen._confirmAppointment already uses
    // successfully, rather than a narrow durum-only update that would leave
    // randevu_zamani unset.
    final updated = Appointment(
      appointmentId: appointment.appointmentId,
      customerId: appointment.customerId,
      customerName: appointment.customerName,
      customerPhone: appointment.customerPhone,
      vehicleModel: appointment.vehicleModel,
      licensePlate: appointment.licensePlate,
      serviceType: appointment.serviceType,
      appointmentDate: appointment.appointmentDate,
      appointmentTime: resolvedTime,
      estimatedDuration: resolvedDuration,
      customerNote: appointment.customerNote,
      status: AppointmentStatus.accepted,
      createdAt: appointment.createdAt,
      distance: appointment.distance,
      businessId: appointment.businessId,
      preferredTimeRangeLabel: appointment.preferredTimeRangeLabel,
      kvkkAccepted: appointment.kvkkAccepted,
      kvkkAcceptedAt: appointment.kvkkAcceptedAt,
      tamamlanmaDurumu: appointment.tamamlanmaDurumu,
      ustaTamamlamaTarihi: appointment.ustaTamamlamaTarihi,
      musteriOnayTarihi: appointment.musteriOnayTarihi,
      musteriYorumu: appointment.musteriYorumu,
      musteriPuani: appointment.musteriPuani,
    );
    try {
      await AppointmentRepository().saveAppointment(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Talep kabul edilemedi: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isBusy = false);
    await showDialog<void>(
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
          'Randevu başarıyla onaylandı. Müşteriye bildirim gönderildi.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(successContext).pop(),
              child: const Text('Tamam'),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // Opens the mechanic's own appointment calendar (_ProposeTimeCalendarPage)
  // — same AppointmentCalendarView widget and watchAppointmentsForBusiness
  // data source MechanicAppointmentsScreen's "Tüm Randevular" tab already
  // uses, so occupied slots are visibly occupied instead of the mechanic
  // typing a date/time from memory — and writes the mechanic's proposal.
  // Used both for the initial "Başka Saat Öner" (no negotiation yet) and
  // for re-proposing after the customer's counter-proposal. The live
  // watchAppointmentById subscription on the parent page picks up the
  // result automatically; no local state update needed here.
  Future<void> _proposeNewTime() async {
    final appointment = widget.appointment;
    final picked = await Navigator.of(context).push<(DateTime, TimeOfDay)>(
      MaterialPageRoute(
        builder: (_) => _ProposeTimeCalendarPage(appointment: appointment),
      ),
    );
    if (picked == null || !mounted) return;
    final (date, time) = picked;
    setState(() => _isBusy = true);
    try {
      await AppointmentRepository().proposeNewTime(
        appointment.appointmentId,
        date: date,
        time: time,
        proposedBy: 'usta',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öneri gönderilemedi: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yeni saat öneriniz müşteriye iletildi.')),
    );
  }

  // Finalizes the customer's pending counter-proposal — teklifEdilenTarih/
  // Saat become the real appointment time, same as accepting outright.
  Future<void> _acceptTimeProposal() async {
    final appointment = widget.appointment;
    final date = appointment.teklifEdilenTarih;
    final time = appointment.teklifEdilenSaat;
    if (date == null || time == null) return;
    setState(() => _isBusy = true);
    try {
      await AppointmentRepository().acceptTimeProposal(appointment.appointmentId, date: date, time: time);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Randevu onaylanamadı: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Randevu onaylandı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final isNegotiating = appointment.status == AppointmentStatus.timeProposed;
    final isMechanicTurn = isNegotiating && appointment.sonTeklifEden == 'musteri';
    final isWaitingOnCustomer = isNegotiating && appointment.sonTeklifEden == 'usta';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWaitingOnCustomer)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Önerdiğiniz saat için müşteri onayı bekleniyor.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )
              else if (appointment.status == AppointmentStatus.pending || isMechanicTurn) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : (isMechanicTurn ? _acceptTimeProposal : _acceptRequest),
                    child: _isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(isMechanicTurn ? 'Kabul Et' : 'Talebi Kabul Et'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isBusy ? null : _proposeNewTime,
                    child: const Text('Başka Saat Öner'),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Durum: ${appointment.status.label}',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm + 2),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MechanicConversationPage(chatId: 'ahmet-yilmaz-yag-degisimi'),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('Mesajlaş'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri(scheme: 'tel', path: widget.phoneNumber.replaceAll(' ', ''))),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: const Text('Ara'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatSlotTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

/// Calendar-based slot picker for "Başka Saat Öner" — replaces the old
/// generic date/time text-entry picker (propose_time_dialog.dart, still
/// used unchanged by the customer-side "Farklı Saat Öner" flow) with the
/// mechanic's own real calendar, so they see their existing accepted
/// bookings and pick an actually-open slot instead of typing one from
/// memory. Reuses the exact same widget (AppointmentCalendarView) and data
/// source (AppointmentRepository.watchAppointmentsForBusiness, filtered to
/// AppointmentStatus.accepted) MechanicAppointmentsScreen's own "Tüm
/// Randevular" tab already uses for this same businessId — same
/// appointments, same mechanic, no new data source. Pops with a (date,
/// time) record once the mechanic confirms a slot, or null if they cancel.
class _ProposeTimeCalendarPage extends StatefulWidget {
  const _ProposeTimeCalendarPage({required this.appointment});

  /// The same Appointment MechanicRequestDetailsPage already has — source
  /// of businessId (for the calendar's data source), the week to initialize
  /// to (teklifEdilenTarih ?? appointmentDate, unchanged from before), and
  /// the customer's originally requested date/time shown in the info
  /// banner. No separate fetch.
  final Appointment appointment;

  @override
  State<_ProposeTimeCalendarPage> createState() => _ProposeTimeCalendarPageState();
}

class _ProposeTimeCalendarPageState extends State<_ProposeTimeCalendarPage> {
  StreamSubscription<List<Appointment>>? _subscription;
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    // Same client-side "only accepted appointments are scheduled bookings"
    // filter MechanicAppointmentsScreen applies to this exact stream for
    // "Tüm Randevular" — a pending/declined document isn't an occupied
    // slot, so it must not render as one here either.
    _subscription = AppointmentRepository().watchAppointmentsForBusiness(widget.appointment.businessId).listen(
      (appointments) {
        if (!mounted) return;
        setState(() {
          _appointments = appointments.where((appointment) => appointment.status == AppointmentStatus.accepted).toList();
        });
      },
      onError: (Object error) {
        debugPrint('PROPOSE TIME CALENDAR LISTENER ERROR: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleSlotSelected(DateTime slotStart) async {
    final date = DateTime(slotStart.year, slotStart.month, slotStart.day);
    final time = TimeOfDay(hour: slotStart.hour, minute: slotStart.minute);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bu saati müşteriye önermek istiyor musunuz?'),
        content: Text('${formatFullDate(date)} · ${_formatSlotTime(time)}'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop((date, time));
  }

  // The customer's originally requested date/time — same pair
  // MechanicRequestDetailsPage's own hero card already shows (see
  // _preferredTimeLabel there): a real appointmentTime once one exists,
  // otherwise the customer's original preferred arrival window. Pulled
  // straight from widget.appointment, already passed into this page — no
  // new data fetch.
  String get _requestedTimeLabel {
    final appointment = widget.appointment;
    if (appointment.appointmentTime != _noTimeSentinel) {
      return _formatSlotTime(appointment.appointmentTime);
    }
    return appointment.preferredTimeRangeLabel.isEmpty ? 'İlk Müsait Saat' : appointment.preferredTimeRangeLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Başka Saat Öner')),
      body: Column(
        children: [
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
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded, size: 18, color: AppColors.turquoise),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Müşterinin talebi: ${formatFullDate(widget.appointment.appointmentDate)}, $_requestedTimeLabel',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.turquoise),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AppointmentCalendarView(
              selectedDate: widget.appointment.teklifEdilenTarih ?? widget.appointment.appointmentDate,
              appointments: _appointments,
              onSlotSelected: _handleSlotSelected,
            ),
          ),
        ],
      ),
    );
  }
}
