import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/firebase_instances.dart';
import '../../utils/identity.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/booking/section_label.dart';
import '../../widgets/common/premium_surface.dart';
import '../appointments/data/appointment.dart';
import '../appointments/data/appointment_repository.dart';
import '../appointments/data/chat_message.dart';
import '../appointments/data/chat_repository.dart';
import '../appointments/mechanic_appointments_screen.dart';
import '../appointments/mechanic_request_details_page.dart';
import '../notifications/mechanic_notifications_screen.dart';
import '../profile/data/mechanic_profile.dart';
import '../profile/data/mechanic_profile_repository.dart';

/// Mechanic module's "Home" tab — a premium work dashboard, ordered so the
/// mechanic can read it top-to-bottom in priority order:
///
///   1. A unified top section (see [_MechanicHomeHeader]) — identity
///      (wordmark, time-aware greeting with the real business name,
///      subtitle) and today's workload (today's confirmed-appointment
///      count, new-request count) as ONE light-background composition,
///      not a colored hero band stacked above a separate stat card.
///   2. "Yeni Talepler" — the actual work needing a decision, shown as real
///      cards (vehicle, service, preferred date/time, how long ago it
///      arrived, a clear "Talebi İncele" action) — see
///      [_NewRequestsSection].
///   3. "Bugünün Randevuları" — a compact timeline of today's confirmed
///      appointments — see [_TodayAppointmentsSection].
///   4. "Servis Performansı" — real rating/repeat-customer/on-time-rate
///      trust metrics, deliberately last and visually smaller than the
///      work above it — see [_ServicePerformanceSection].
///
/// Every number and label traces back to a real Firestore-backed field or
/// live stream — see [scheduleBucketFor] for the one shared date-bucketing
/// rule used by both the top section's workload numbers and each request's
/// status tag, so they can never disagree. Two things this screen
/// deliberately does NOT
/// show, because no real data backs them: an "Estimated Work / Revenue"
/// figure (no per-appointment price/fee field exists anywhere in the
/// schema) and a fabricated "urgent"/"acil" flag (see
/// AppointmentStatus's own field docs) — "Gecikti" (delayed) is a normal,
/// muted workflow state, not an alert; see [AppColors.scheduleOverdue]'s
/// doc comment for why it's a different red from [AppColors.emergency].
///
/// Workflow rule (unchanged): this screen shows ONLY actionable work items
/// (pending appointment requests awaiting a decision) as collapsed
/// previews — a card is never expandable in place. Tapping one, or its
/// "Talebi İncele" button, pushes the separate MechanicRequestDetailsPage,
/// the actual workspace for a request.
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
  var _isLoadingPending = true;

  // Every appointment for this business, unfiltered by status — the same
  // real stream MechanicAppointmentsScreen's "Tüm Randevular" tab already
  // uses (AppointmentRepository.watchAppointmentsForBusiness). Bucketed
  // client-side (see scheduleBucketFor) into the today/upcoming/overdue
  // counts and today's timeline — no new Firestore query or schema field,
  // only new categorization logic over an existing stream.
  StreamSubscription<List<Appointment>>? _scheduleSubscription;
  List<Appointment> _scheduleAppointments = [];
  var _isLoadingSchedule = true;

  StreamSubscription<List<ChatSummary>>? _unreadChatsSubscription;
  var _unreadChatCount = 0;

  MechanicProfile? _profile;

  // One-time fetches (same convention MechanicProfileScreen already uses
  // for these same kinds of numbers), not live streams — a performance
  // metric changing by one completed job doesn't need to update this
  // screen in real time the way a new request or appointment does.
  ({double averageRating, int ratedCount})? _ratingSummary;
  int? _repeatCustomerCount;
  double? _onTimeRate;
  var _isLoadingPerformance = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAppointmentStreams();
    _subscribeToUnreadChats();
  }

  @override
  void dispose() {
    _pendingRequestsSubscription?.cancel();
    _scheduleSubscription?.cancel();
    _unreadChatsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = firebaseAuthInstance.currentUser?.uid;
    if (uid == null) return;
    final profile = await MechanicProfileRepository().fetchProfile(uid);
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  // Same businessId resolution + live-subscription pattern already used by
  // MechanicAppointmentsScreen._loadAppointments for "Yeni Talepler" — reuses
  // the exact same AppointmentRepository streams, not second/duplicate
  // queries. A signed-out account, or one without a resolvable businessId,
  // sees empty lists rather than risking another business's requests (same
  // safe default used elsewhere in the mechanic module).
  Future<void> _loadAppointmentStreams() async {
    final myBusinessId = await resolveMyBusinessId();
    if (myBusinessId == null) {
      if (!mounted) return;
      setState(() {
        _isLoadingPending = false;
        _isLoadingSchedule = false;
        _isLoadingPerformance = false;
      });
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
          // requested appointment date/time. This is also what makes the
          // first entry the "spotlighted" card in _NewRequestsSection.
          _pendingRequests = pendingRequests..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _isLoadingPending = false;
        });
      },
      onError: (Object error) {
        debugPrint('MECHANIC HOME PENDING REQUESTS ERROR: $error');
        if (!mounted) return;
        setState(() => _isLoadingPending = false);
      },
    );

    _scheduleSubscription?.cancel();
    _scheduleSubscription = _appointmentRepository.watchAppointmentsForBusiness(myBusinessId).listen(
      (appointments) {
        if (!mounted) return;
        setState(() {
          _scheduleAppointments = appointments;
          _isLoadingSchedule = false;
        });
      },
      onError: (Object error) {
        debugPrint('MECHANIC HOME SCHEDULE ERROR: $error');
        if (!mounted) return;
        setState(() => _isLoadingSchedule = false);
      },
    );

    unawaited(_loadPerformanceMetrics(myBusinessId));
  }

  // Real rating/repeat-customer/on-time numbers — no new collection, no
  // new schema, just the existing repository methods (see
  // AppointmentRepository.fetchRatingSummary/fetchOnTimeCompletionRate and
  // MechanicProfileRepository.fetchRepeatCustomerCount). ratedCount == 0
  // and onTimeRate == null both mean "no eligible data yet", kept distinct
  // from a real 0 — see _ServicePerformanceSection for how each renders.
  Future<void> _loadPerformanceMetrics(String businessId) async {
    final ratingSummary = await _appointmentRepository.fetchRatingSummary(businessId);
    final repeatCount = await MechanicProfileRepository().fetchRepeatCustomerCount(businessId);
    final onTimeRate = await _appointmentRepository.fetchOnTimeCompletionRate(businessId);
    if (!mounted) return;
    setState(() {
      _ratingSummary = ratingSummary.ratedCount > 0 ? ratingSummary : null;
      _repeatCustomerCount = repeatCount ?? 0;
      _onTimeRate = onTimeRate;
      _isLoadingPerformance = false;
    });
  }

  // Real unread-message count for the bell badge — the same mechanism
  // already used on the customer side (ChatRepository.watchUnreadChats via
  // GreetingBar/MainShell), keyed by the same sender id
  // MechanicConversationPage already sends/marks-read with, so this count
  // can never disagree with what that screen considers "from the other
  // side".
  void _subscribeToUnreadChats() {
    final mechanicSenderId = firebaseAuthInstance.currentUser?.uid ?? 'mechanic-demo';
    _unreadChatsSubscription = ChatRepository().watchUnreadChats(mechanicSenderId).listen(
      (chats) {
        if (!mounted) return;
        setState(() => _unreadChatCount = chats.length);
      },
      onError: (Object error) {
        debugPrint('MECHANIC HOME UNREAD CHATS ERROR: $error');
      },
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MechanicNotificationsScreen()),
    );
  }

  void _openAppointments() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MechanicAppointmentsScreen()),
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

  // Maps a real Appointment onto the display fields the request cards
  // render — no card/layout changes, only what feeds it.
  _RequestCardData _toRequestCardData(Appointment appointment) {
    final hasRealTime = appointment.appointmentTime != _noTimeSentinel;
    return _RequestCardData(
      vehicleModel: appointment.vehicleModel,
      service: appointment.serviceType,
      preferredDate: formatFullDate(appointment.appointmentDate),
      preferredTime: hasRealTime
          ? _formatTimeOfDay(appointment.appointmentTime)
          : (appointment.preferredTimeRangeLabel.isEmpty ? 'İlk Müsait Saat' : appointment.preferredTimeRangeLabel),
      appointmentDate: appointment.appointmentDate,
      createdAt: appointment.createdAt,
      customerNote: appointment.customerNote,
    );
  }

  // Only appointments the mechanic has actually confirmed (accepted or in
  // progress) AND that aren't already customer-verified complete count
  // toward the today/upcoming/overdue numbers. A still-pending request has
  // no confirmed date commitment yet, so it can't be "today's" or
  // "overdue" in the schedule sense — it's already counted separately as a
  // "new request" (see _pendingRequests.length below). The tamamlanmaDurumu
  // check matters because `durum`/status stays 'kabul edildi' (accepted)
  // forever once a job is confirmed — markMechanicCompleted/
  // markCustomerVerified (see AppointmentRepository) only ever change
  // tamamlanmaDurumu, never durum — so without this check, a job completed
  // months ago would count as "overdue" forever.
  static bool _isConfirmedActive(Appointment appointment) =>
      (appointment.status == AppointmentStatus.accepted || appointment.status == AppointmentStatus.inProgress) &&
      appointment.tamamlanmaDurumu != 'dogrulanmis_tamamlandi';

  int _countConfirmed(bool Function(ScheduleBucket) matchesBucket) {
    final now = DateTime.now();
    return _scheduleAppointments
        .where((a) => _isConfirmedActive(a) && matchesBucket(scheduleBucketFor(a.appointmentDate, now)))
        .length;
  }

  // Today's confirmed appointments, earliest first — the real data source
  // for the "Bugünün Randevuları" timeline.
  List<Appointment> get _todaysAppointments {
    final now = DateTime.now();
    final todays = _scheduleAppointments
        .where((a) => _isConfirmedActive(a) && scheduleBucketFor(a.appointmentDate, now) == ScheduleBucket.today)
        .toList()
      ..sort(
        (a, b) => (a.appointmentTime.hour * 60 + a.appointmentTime.minute)
            .compareTo(b.appointmentTime.hour * 60 + b.appointmentTime.minute),
      );
    return todays;
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = _isLoadingSchedule ? null : _countConfirmed((b) => b == ScheduleBucket.today);
    final newRequestsCount = _isLoadingPending ? null : _pendingRequests.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _MechanicHomeHeader(
            businessName: _profile?.businessName,
            unreadChatCount: _unreadChatCount,
            onNotificationTap: _openNotifications,
            // Same values the top section's workload numbers show — not a
            // second query/computation.
            todayCount: todayCount,
            newRequestsCount: newRequestsCount,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
              children: [
                _NewRequestsSection(
                  isLoading: _isLoadingPending,
                  requests: _pendingRequests,
                  toCardData: _toRequestCardData,
                  onOpenRequest: _openRequestDetails,
                  onViewAll: _openAppointments,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _TodayAppointmentsSection(
                  isLoading: _isLoadingSchedule,
                  appointments: _todaysAppointments,
                  onTap: _openAppointments,
                ),
                const SizedBox(height: AppSpacing.xxl),
                _ServicePerformanceSection(
                  isLoading: _isLoadingPerformance,
                  ratingSummary: _ratingSummary,
                  repeatCustomerCount: _repeatCustomerCount,
                  onTimeRate: _onTimeRate,
                  isVerified: _profile?.isVerified ?? false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Which day-relative bucket [appointmentDate] falls into as of [now] — the
/// single date-comparison rule shared by the overview counts (see
/// _MechanicHomeScreenState._countConfirmed) and each request card's
/// Bugün/Yarın/Gecikti/Yaklaşan status (see _OtherRequestCard), so they can
/// never disagree about what counts as "today" or "overdue". A pure
/// function of the two dates — no status involved here; callers decide
/// which appointments/requests it applies to.
enum ScheduleBucket { overdue, today, tomorrow, upcoming }

ScheduleBucket scheduleBucketFor(DateTime appointmentDate, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
  if (date.isBefore(today)) return ScheduleBucket.overdue;
  if (isSameDay(date, today)) return ScheduleBucket.today;
  if (isSameDay(date, today.add(const Duration(days: 1)))) return ScheduleBucket.tomorrow;
  return ScheduleBucket.upcoming;
}

String _bucketLabel(ScheduleBucket bucket) => switch (bucket) {
  ScheduleBucket.overdue => 'Gecikti',
  ScheduleBucket.today => 'Bugün',
  ScheduleBucket.tomorrow => 'Yarın',
  ScheduleBucket.upcoming => 'Yaklaşan',
};

// "Tomorrow" and "upcoming" deliberately share one accent — both are just
// "not today, not overdue" future dates; only the label text distinguishes
// them (see AppColors.scheduleUpcoming's own doc comment).
Color _bucketColor(ScheduleBucket bucket) => switch (bucket) {
  ScheduleBucket.overdue => AppColors.scheduleOverdue,
  ScheduleBucket.today => AppColors.scheduleToday,
  ScheduleBucket.tomorrow => AppColors.scheduleUpcoming,
  ScheduleBucket.upcoming => AppColors.scheduleUpcoming,
};

Color _bucketBackground(ScheduleBucket bucket) => switch (bucket) {
  ScheduleBucket.overdue => AppColors.scheduleOverdueBackground,
  ScheduleBucket.today => AppColors.scheduleTodayBackground,
  ScheduleBucket.tomorrow => AppColors.scheduleUpcomingBackground,
  ScheduleBucket.upcoming => AppColors.scheduleUpcomingBackground,
};

// "Az önce" for <1 min, then minutes/hours/days — real elapsed time since
// appointment.createdAt, computed live against DateTime.now() at build
// time, never a fixed/hardcoded string.
String _timeAgoLabel(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'Az önce geldi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce geldi';
  if (diff.inHours < 24) return '${diff.inHours} saat önce geldi';
  return '${diff.inDays} gün önce geldi';
}

// Purely a function of wall-clock time, not any Firestore data — the
// "Good morning"/"Good afternoon" style variation the redesign asked for.
String _timeAwareGreetingPrefix(DateTime now) {
  final hour = now.hour;
  if (hour < 6) return 'İyi geceler';
  if (hour < 12) return 'Günaydın';
  if (hour < 18) return 'İyi günler';
  return 'İyi akşamlar';
}

/// Unified top section — identity (SanayiGo wordmark, time-aware greeting
/// with the real business name, subtitle) and today's workload (today's
/// confirmed-appointment count, new-request count) as ONE composition on a
/// light/white background, replacing the previous gradient hero band
/// stacked above a separately-boxed "Bugün" overview card. Both numbers are
/// the exact same todayCount/newRequestsCount _MechanicHomeScreenState.build()
/// already computes once — passed straight through, never recomputed.
///
/// Deliberately no full-bleed color gradient here — brand color is used
/// only selectively: the small logo badge, the new-requests number when
/// it's > 0, small icon accents. New-requests carries a touch more
/// emphasis (turquoise color, slightly larger) than today's-appointment
/// count when it's > 0, since it represents something needing a decision —
/// but that's a calm brand-color accent, never red/alert styling, the same
/// "a workflow state, not an emergency" reasoning this file already
/// documents for [AppColors.scheduleOverdue] vs [AppColors.emergency]. Both
/// numbers read visually quieter (muted gray, no accent color) at 0 or
/// while still loading — see [_WorkloadStat].
class _MechanicHomeHeader extends StatelessWidget {
  const _MechanicHomeHeader({
    required this.businessName,
    required this.unreadChatCount,
    required this.onNotificationTap,
    required this.todayCount,
    required this.newRequestsCount,
  });

  final String? businessName;
  final int unreadChatCount;
  final VoidCallback onNotificationTap;
  final int? todayCount;
  final int? newRequestsCount;

  // The real app icon's foreground artwork (see pubspec.yaml's assets
  // entry) — a transparent-background car+wrench mark, the same art used
  // to generate the launcher icon. A newer assets/icon/sanayigo_logo.png
  // was requested to replace this, but that file does not exist anywhere
  // in the project (checked: not on disk, not tracked by git, not
  // gitignored) — pointing at it would just reproduce the exact
  // "asset does not exist" failure a prior change already fixed once.
  // Swap this constant (and pubspec.yaml's assets: entry) to
  // sanayigo_logo.png once that file is actually added.
  static const _logoAssetPath = 'assets/icon/app_icon_foreground.png';

  // Same 3-stop brand gradient PremiumHeroHeader uses on the customer-side
  // home screen — but scoped down to just the small logo badge now (see
  // build()) rather than the whole section's background. The logo art
  // itself is white-on-transparent, so it needs a colored patch behind it
  // to stay visible now that the section around it is white/light, not a
  // full-bleed gradient band.
  static const _logoBadgeGradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final trimmedName = businessName?.trim();
    final prefix = _timeAwareGreetingPrefix(DateTime.now());
    final greeting = (trimmedName == null || trimmedName.isEmpty) ? '$prefix 👋' : '$prefix, $trimmedName 👋';

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          // Noticeably tighter than the old gradient hero's padding — a
          // white background doesn't need as much surrounding room to
          // avoid feeling cramped, and this composition is replacing two
          // stacked pieces with one, so it should read as more efficient,
          // not larger.
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 18, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(gradient: _logoBadgeGradient, borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: Image.asset(
                      _logoAssetPath,
                      height: 20,
                      fit: BoxFit.contain,
                      // Resilience only — falls back to an empty badge (no
                      // broken-image icon) if the asset is ever missing
                      // again. Not a substitute for fixing the real file.
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SanayiGo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppColors.turquoise,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          greeting,
                          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Randevularınızı ve hizmet taleplerinizi yönetin.',
                          style: TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.turquoise.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: onNotificationTap,
                          icon: Badge(
                            isLabelVisible: unreadChatCount > 0,
                            label: Text('$unreadChatCount'),
                            child: const Icon(Icons.notifications_outlined, size: 24, color: AppColors.primaryDark),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Güvenle Yönetin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(height: 1, color: AppColors.divider),
              const SizedBox(height: 16),
              // Today's workload — one composition, not two side-by-side
              // bordered/shadowed boxes: shared typography scale, a single
              // subtle divider between them, icon-plus-label captions above
              // each number instead of big colored icon tiles.
              Row(
                children: [
                  Expanded(
                    child: _WorkloadStat(
                      icon: Icons.event_available_rounded,
                      value: todayCount,
                      label: 'Bugünkü Randevu',
                      emphasize: false,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    color: AppColors.divider,
                  ),
                  Expanded(
                    child: _WorkloadStat(
                      icon: Icons.inbox_rounded,
                      value: newRequestsCount,
                      label: 'Yeni Talep',
                      emphasize: true,
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

/// One of the two "today's workload" numbers. Both share the same quiet
/// treatment (muted gray, no accent color) at 0 or while still loading —
/// [emphasize] (true only for the new-requests count) adds a calm brand-
/// color accent and a touch more size ONLY once the value is real and > 0,
/// never for a loading/zero state and never as red/alert styling.
class _WorkloadStat extends StatelessWidget {
  const _WorkloadStat({required this.icon, required this.value, required this.label, required this.emphasize});

  final IconData icon;
  final int? value;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final isQuiet = value == null || value == 0;
    final numberColor = isQuiet
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : (emphasize ? AppColors.turquoise : AppColors.textPrimary);
    final iconColor = isQuiet ? AppColors.textSecondary.withValues(alpha: 0.5) : numberColor;
    final fontSize = (!isQuiet && emphasize) ? 30.0 : 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value == null ? '...' : '$value',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: numberColor, height: 1.0),
        ),
      ],
    );
  }
}

/// "Yeni Talepler" — the actual work needing a decision. The newest
/// submitted request (this screen has always sorted _pendingRequests this
/// way) gets a slightly more prominent card with a real customer note and
/// an explicit "Talebi İncele" action; up to 2 more show underneath as
/// compact previews; a "Tümünü Gör" link opens the full list
/// (MechanicAppointmentsScreen, already defaulting to its "Yeni Talepler"
/// tab) when there are more than that. Capped so this section stays
/// scannable rather than consuming the whole screen.
class _NewRequestsSection extends StatelessWidget {
  const _NewRequestsSection({
    required this.isLoading,
    required this.requests,
    required this.toCardData,
    required this.onOpenRequest,
    required this.onViewAll,
  });

  final bool isLoading;
  final List<Appointment> requests;
  final _RequestCardData Function(Appointment) toCardData;
  final void Function(Appointment) onOpenRequest;
  final VoidCallback onViewAll;

  static const _maxPreview = 3;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final previewCount = requests.length < _maxPreview ? requests.length : _maxPreview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel(text: 'Yeni Talepler')),
            if (!isLoading && requests.length > _maxPreview)
              GestureDetector(
                onTap: onViewAll,
                child: Text(
                  'Tümünü Gör (${requests.length})',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (requests.isEmpty)
          const _EmptyPendingRequestsState()
        else
          for (var i = 0; i < previewCount; i++) ...[
            i == 0
                ? _PriorityRequestCard(request: toCardData(requests[i]), onTap: () => onOpenRequest(requests[i]))
                : _OtherRequestCard(
                    request: toCardData(requests[i]),
                    bucket: scheduleBucketFor(requests[i].appointmentDate, now),
                    onTap: () => onOpenRequest(requests[i]),
                  ),
            if (i < previewCount - 1) const SizedBox(height: AppSpacing.lg),
          ],
      ],
    );
  }
}

/// Compact timeline of today's confirmed appointments, earliest first — a
/// glance-able "what does my day look like" list (time, vehicle, service).
/// Collapses to a one-line state when the real query result is empty,
/// rather than an empty-looking card.
class _TodayAppointmentsSection extends StatelessWidget {
  const _TodayAppointmentsSection({required this.isLoading, required this.appointments, required this.onTap});

  final bool isLoading;
  final List<Appointment> appointments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(text: 'Bugünün Randevuları'),
        const SizedBox(height: AppSpacing.md),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (appointments.isEmpty)
          _EmptyTodayAppointmentsRow(onTap: onTap)
        else
          PremiumSurface(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.divider),
            child: Column(
              children: [
                for (var i = 0; i < appointments.length; i++) ...[
                  _AppointmentTimelineRow(appointment: appointments[i]),
                  if (i < appointments.length - 1) const Divider(height: 1, color: AppColors.divider),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyTodayAppointmentsRow extends StatelessWidget {
  const _EmptyTodayAppointmentsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textSecondary),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bugün için planlanmış randevu yok',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            // Icon-only affordance, deliberately not a text label — a text
            // like "Randevular" here would collide with the "Randevular"
            // bottom-nav tab's own label, ambiguous for anything (tests
            // included) that finds by that exact text.
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTimelineRow extends StatelessWidget {
  const _AppointmentTimelineRow({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final time =
        '${appointment.appointmentTime.hour.toString().padLeft(2, '0')}:${appointment.appointmentTime.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              time,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.scheduleToday),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(color: AppColors.scheduleToday, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              appointment.vehicleModel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              appointment.serviceType,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Servis Performansı" — real trust/performance metrics, deliberately
/// last in the hierarchy and visually smaller than the work sections
/// above. Repeat-customer count is treated as a real, meaningful number
/// (always shown, 0 included — same "the mechanic looking at their own
/// numbers" reasoning MechanicProfileScreen already uses), not a
/// decorative statistic. Rating and on-time-rate show "—" rather than a
/// fabricated number when there isn't yet a single eligible completed job
/// to compute them from.
class _ServicePerformanceSection extends StatelessWidget {
  const _ServicePerformanceSection({
    required this.isLoading,
    required this.ratingSummary,
    required this.repeatCustomerCount,
    required this.onTimeRate,
    required this.isVerified,
  });

  final bool isLoading;
  final ({double averageRating, int ratedCount})? ratingSummary;
  final int? repeatCustomerCount;
  final double? onTimeRate;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SectionLabel(text: 'Servis Performansı'),
            // Only shown when real — mirrors MechanicDetailPage's own
            // isVerified-gated badge on the customer-facing side; no
            // "unverified" badge is ever shown in the false case.
            if (isVerified) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, size: 16, color: AppColors.turquoise),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Row(
            children: [
              Expanded(
                child: _PerformanceTile(
                  icon: Icons.star_rounded,
                  value: ratingSummary != null ? ratingSummary!.averageRating.toStringAsFixed(1) : '—',
                  label: ratingSummary != null ? '${ratingSummary!.ratedCount} değerlendirme' : 'Puan',
                  color: AppColors.rating,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PerformanceTile(
                  icon: Icons.repeat_rounded,
                  value: '${repeatCustomerCount ?? 0}',
                  label: 'Tekrar Müşteri',
                  color: AppColors.turquoise,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _PerformanceTile(
                  icon: Icons.timer_outlined,
                  value: onTimeRate != null ? '%${onTimeRate!.round()}' : '—',
                  label: 'Zamanında',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PerformanceTile extends StatelessWidget {
  const _PerformanceTile({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Shown in place of the request-card list when the signed-in mechanic
/// currently has zero pending requests.
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

/// Display fields the request cards need — populated from a real
/// Appointment (see _MechanicHomeScreenState._toRequestCardData).
class _RequestCardData {
  const _RequestCardData({
    required this.vehicleModel,
    required this.service,
    required this.preferredDate,
    required this.preferredTime,
    required this.appointmentDate,
    required this.createdAt,
    required this.customerNote,
  });

  final String vehicleModel;
  final String service;
  final String preferredDate;
  final String preferredTime;
  final DateTime appointmentDate;
  final DateTime createdAt;
  final String customerNote;
}

/// The spotlighted top pending request — the newest submitted one (this
/// screen has always sorted _pendingRequests this way; no separate
/// "urgent" concept exists in the data, see this file's class doc). Tagged
/// honestly with what's actually true (a new/today-submitted request), not
/// a fabricated "acil" label. Shows real elapsed time since submission, the
/// real customer note, and an explicit "Talebi İncele" action — the one
/// deliberate exception to "never shows the customer note"; every other
/// card (see _OtherRequestCard) still follows that rule.
class _PriorityRequestCard extends StatelessWidget {
  const _PriorityRequestCard({required this.request, required this.onTap});

  final _RequestCardData request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFromToday = isSameDay(request.createdAt, DateTime.now());
    final tagLabel = isFromToday ? 'Bugün Gelen Talep' : 'Yeni Talep';
    final note = request.customerNote.trim();

    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppRadius.md,
      // A real, solid blue fill — the brand blue already used in the
      // header gradient — instead of the previous barely-there turquoise
      // tint, so this reads unmistakably as "the most relevant item" at a
      // glance. Every text/icon color below is chosen to stay legible
      // against this fill; the note box and service badge are inverted to
      // light-on-blue "cards within a card" rather than trying to keep
      // their old dark-on-light treatment directly on top of the blue.
      color: AppColors.primary,
      border: Border.all(color: AppColors.turquoise, width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.turquoise, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  tagLabel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              // Expanded + ellipsis rather than Spacer — the tag's longer
              // "Bugün Gelen Talep" variant plus this label can otherwise
              // overflow on narrow phone widths; this guarantees the row
              // never overflows regardless of tag/time text length.
              Expanded(
                child: Text(
                  _timeAgoLabel(request.createdAt),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            request.vehicleModel,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 10),
          _ServiceBadge(label: request.service),
          const SizedBox(height: 14),
          // Inlined rather than reusing the shared _DateTimeRow — that
          // widget is also used by _OtherRequestCard (out of scope for
          // this change) with its own dark-on-light colors, which must
          // stay exactly as they are.
          Row(
            children: [
              Icon(Icons.event, size: 14, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  request.preferredDate,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 14, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  request.preferredTime,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '"$note"',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Talebi İncele', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One collapsed preview beneath the spotlighted card — same
/// collapsed-preview rule as always (no customer note, name, or action
/// buttons; those live only on MechanicRequestDetailsPage), plus a real
/// Bugün/Yarın/Gecikti/Yaklaşan status computed from the request's own
/// appointmentDate (see scheduleBucketFor). The status shows twice, both
/// deliberately subtle: a thin colored left border and a small badge —
/// never a filled/colored card background, so this stays a calm,
/// restrained treatment rather than an alert.
class _OtherRequestCard extends StatelessWidget {
  const _OtherRequestCard({required this.request, required this.bucket, required this.onTap});

  final _RequestCardData request;
  final ScheduleBucket bucket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A Border can't mix per-side colors together with a borderRadius
    // (Flutter throws "A borderRadius can only be given on borders with
    // uniform colors" at paint time) — so the colored left accent is drawn
    // as a plain full-height Container inside the card instead of as a
    // Border side, with the surrounding divider border kept uniform.
    // IntrinsicHeight + CrossAxisAlignment.stretch makes the accent bar
    // match the content's real height without needing one hardcoded here.
    return PremiumSurface(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: _bucketColor(bucket)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BucketTag(bucket: bucket),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_car_rounded, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            request.vehicleModel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      request.service,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    _DateTimeRow(date: request.preferredDate, time: request.preferredTime),
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

class _BucketTag extends StatelessWidget {
  const _BucketTag({required this.bucket});

  final ScheduleBucket bucket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _bucketBackground(bucket), borderRadius: BorderRadius.circular(20)),
      child: Text(
        _bucketLabel(bucket),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _bucketColor(bucket)),
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({required this.date, required this.time});

  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.event, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            date,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            time,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Small rounded chip for the requested service — the card's one
/// turquoise accent, keeping everything else neutral.
// Only used by _PriorityRequestCard. Inverted to a white pill with
// primaryDark text (was a turquoise-filled pill with white text) — a
// turquoise fill would sit too close in hue to that card's own solid
// AppColors.primary background to read as a distinct chip; white gives it
// a clean, legible edge against the blue instead of blending into it.
class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
      ),
    );
  }
}
