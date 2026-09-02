import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/identity.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/booking/section_label.dart';
import '../../widgets/common/premium_surface.dart';
import '../appointments/data/appointment.dart';
import '../appointments/data/appointment_repository.dart';
import '../appointments/mechanic_request_details_page.dart';
import '../notifications/mechanic_notifications_screen.dart';

/// Mechanic module's "Home" tab — notification bell (mock badge), a compact
/// "Important Updates" card, and a "Pending Requests" list. The pending
/// requests list is backed by the same real `randevular` data source as
/// MechanicAppointmentsScreen's "Yeni Talepler" tab (see
/// AppointmentRepository.watchPendingAppointments) — not a second/duplicate
/// query, the exact same repository method, resolved via the same
/// resolveMyBusinessId() mechanism. The "Important Updates" card is a
/// separate, still-hardcoded section, untouched here.
///
/// Workflow rule: this screen shows ONLY actionable work items (pending
/// appointment requests awaiting a decision) as collapsed previews — a
/// card is never expandable in place. Tapping one pushes the separate
/// MechanicRequestDetailsPage, which is the actual workspace for a
/// request. Customer questions/chat must NEVER be surfaced on this
/// screen — they arrive solely through the notification bell:
///
///   Bell -> MechanicNotificationsScreen -> tap a notification -> Request Details
///   Home -> tap a request card -> Request Details
///
/// The bell must always open the Notifications page first — it must never
/// jump straight to a Request Details workspace. See [_MechanicHomeHeader].
class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  final _appointmentRepository = AppointmentRepository();
  StreamSubscription<List<Appointment>>? _pendingRequestsSubscription;
  List<Appointment> _pendingRequests = [];
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _pendingRequestsSubscription?.cancel();
    super.dispose();
  }

  // Same businessId resolution + live-subscription pattern already used by
  // MechanicAppointmentsScreen._loadAppointments for "Yeni Talepler" — reuses
  // the exact same AppointmentRepository.watchPendingAppointments stream, not
  // a second query. A signed-out account, or one without a resolvable
  // businessId, sees an empty list rather than risking another business's
  // requests (same safe default used elsewhere in the mechanic module).
  Future<void> _loadPendingRequests() async {
    final myBusinessId = await resolveMyBusinessId();
    if (myBusinessId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    _pendingRequestsSubscription?.cancel();
    _pendingRequestsSubscription = _appointmentRepository.watchPendingAppointments(myBusinessId).listen(
      (pendingRequests) {
        if (!mounted) return;
        setState(() {
          // Newest submitted request first — watchPendingAppointments has
          // no orderBy (see AppointmentRepository), so this is sorted
          // client-side by createdAt (request creation time), not by the
          // requested appointment date/time.
          _pendingRequests = pendingRequests..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _isLoading = false;
        });
      },
      onError: (Object error) {
        debugPrint('MECHANIC HOME PENDING REQUESTS ERROR: $error');
        if (!mounted) return;
        setState(() => _isLoading = false);
      },
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MechanicNotificationsScreen()),
    );
  }

  void _openRequestDetails(Appointment appointment) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MechanicRequestDetailsPage(appointment: appointment)),
    );
  }

  static const _noTimeSentinel = TimeOfDay(hour: 0, minute: 0);

  static String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  // Maps a real Appointment onto the same display fields _RequestCard
  // already renders — no card/layout changes, only what feeds it.
  _RequestCardData _toRequestCardData(Appointment appointment) {
    final hasRealTime = appointment.appointmentTime != _noTimeSentinel;
    return _RequestCardData(
      vehicleModel: appointment.vehicleModel,
      service: appointment.serviceType,
      preferredDate: formatFullDate(appointment.appointmentDate),
      preferredTime: hasRealTime
          ? _formatTimeOfDay(appointment.appointmentTime)
          : (appointment.preferredTimeRangeLabel.isEmpty ? 'İlk Müsait Saat' : appointment.preferredTimeRangeLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _MechanicHomeHeader(onNotificationTap: _openNotifications),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const SectionLabel(text: 'Bekleyen Talepler'),
                const SizedBox(height: AppSpacing.md),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_pendingRequests.isEmpty)
                  const _EmptyPendingRequestsState()
                else
                  for (var i = 0; i < _pendingRequests.length; i++) ...[
                    _RequestCard(
                      request: _toRequestCardData(_pendingRequests[i]),
                      onTap: () => _openRequestDetails(_pendingRequests[i]),
                    ),
                    if (i < _pendingRequests.length - 1) const SizedBox(height: AppSpacing.xl),
                  ],
                const SizedBox(height: AppSpacing.xxl),
                const _ImportantUpdatesCard(
                  message: 'Ahmet Yılmaz, önerdiğiniz randevu saatini kabul etti.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified header — title, subtitle, and notification bell laid out as one
/// component (a single row inside a shared background/padding) rather than
/// the previous AppBar title/actions split, so the bell reads as part of
/// the same block as the greeting instead of a disconnected corner icon.
class _MechanicHomeHeader extends StatelessWidget {
  const _MechanicHomeHeader({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 16, AppSpacing.xl, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş geldiniz 👋',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Bekleyen talepleriniz sizi bekliyor.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: IconButton(
                  onPressed: onNotificationTap,
                  icon: const Badge(
                    label: Text('3'),
                    child: Icon(Icons.notifications_outlined, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportantUpdatesCard extends StatelessWidget {
  const _ImportantUpdatesCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: () {},
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Önemli Gelişmeler',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown in place of the request-card list when the signed-in mechanic
/// currently has zero pending requests — replaces the old mock cards for
/// that case instead of leaving the section looking broken/empty.
class _EmptyPendingRequestsState extends StatelessWidget {
  const _EmptyPendingRequestsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Bekleyen talebiniz yok.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Display fields _RequestCard needs — populated from a real Appointment
/// (see _MechanicHomeScreenState._toRequestCardData); no longer mock-only.
class _RequestCardData {
  const _RequestCardData({
    required this.vehicleModel,
    required this.service,
    required this.preferredDate,
    required this.preferredTime,
  });

  final String vehicleModel;
  final String service;
  final String preferredDate;
  final String preferredTime;
}

/// A collapsed, non-expandable preview of a request — tapping it pushes
/// MechanicRequestDetailsPage, the separate screen that is the actual
/// workspace for this request. This card never shows customer note,
/// customer name, or action buttons; those live only on that page.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final _RequestCardData request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 16),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_rounded, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.vehicleModel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ServiceBadge(label: request.service),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  request.preferredDate,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  request.preferredTime,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small rounded chip for the requested service — the card's one
/// turquoise accent, keeping everything else neutral.
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
