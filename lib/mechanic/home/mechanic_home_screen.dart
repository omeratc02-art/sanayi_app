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
import '../profile/data/mechanic_profile_repository.dart';

/// Mechanic module's "Home" tab — designed to feel like a work environment
/// ("this is where I manage my work"), not a statistics dashboard: a
/// compact branded header (real business name + live today's/new-request
/// counts + a real unread-message bell badge), a deliberately de-emphasized
/// "Bugüne Bakış" overview row (see [_TodayOverviewRow] — same four real
/// numbers a larger stat-card grid used to show, just visually
/// de-prioritized), a "today's schedule" quick-access banner that collapses
/// to a one-line state on a real empty day, and the actual work — the
/// pending-requests list — as the dominant content: one highlighted
/// "priority" card (the newest submitted request — same one this screen
/// has always sorted first) plus an "other requests" list, each carrying a
/// real, restrained Bugün/Yarın/Gecikti/Yaklaşan status (a thin colored
/// left border + small badge, never a filled card background). Every
/// number and label here traces back to a real Firestore-backed field or
/// live stream — see [scheduleBucketFor] for the one shared date-bucketing
/// rule used by both the overview row and the per-request status, so they
/// can never disagree.
///
/// There is no real per-request "urgent"/"acil" flag anywhere in the data
/// model (see Appointment's field docs), and that concept was deliberately
/// removed from this product — the priority card is labelled "Yeni Talep" /
/// "Bugün Gelen Talep" (both honestly true of the request), never
/// "Acil"/"Urgent", and nothing on this screen (color, icon, animation)
/// should ever read as an emergency/alert. "Gecikti" (delayed) is a normal,
/// muted workflow state — see [AppColors.scheduleOverdue]'s own doc
/// comment for why it's a different red from [AppColors.emergency].
///
/// Workflow rule (unchanged): this screen shows ONLY actionable work items
/// (pending appointment requests awaiting a decision) as collapsed
/// previews — a card is never expandable in place. Tapping one pushes the
/// separate MechanicRequestDetailsPage, which is the actual workspace for a
/// request. The priority card is the one deliberate exception to "never
/// shows the customer note" (see _PriorityRequestCard) — every other card
/// stays a collapsed preview with no note, name, or action buttons.
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
  // stat-card counts; no new Firestore query or schema field needed for
  // these three cards, only new categorization logic over an existing
  // stream.
  StreamSubscription<List<Appointment>>? _scheduleSubscription;
  List<Appointment> _scheduleAppointments = [];
  var _isLoadingSchedule = true;

  StreamSubscription<List<ChatSummary>>? _unreadChatsSubscription;
  var _unreadChatCount = 0;

  String? _businessName;

  @override
  void initState() {
    super.initState();
    _loadBusinessName();
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

  Future<void> _loadBusinessName() async {
    final uid = firebaseAuthInstance.currentUser?.uid;
    if (uid == null) return;
    final profile = await MechanicProfileRepository().fetchProfile(uid);
    if (!mounted) return;
    setState(() => _businessName = profile?.businessName);
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
          // first entry the "priority" card below.
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
  }

  // Real unread-message count for the bell badge — the same mechanism
  // already used on the customer side (ChatRepository.watchUnreadChats via
  // GreetingBar/MainShell), keyed by the same sender id
  // MechanicConversationPage already sends/marks-read with, so this count
  // can never disagree with what that screen considers "from the other
  // side". Replaces the previous hardcoded Badge(label: Text('3')).
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
  // toward the today/upcoming/overdue stat cards. A still-pending request
  // has no confirmed date commitment yet, so it can't be "today's" or
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

  @override
  Widget build(BuildContext context) {
    final todayCount = _isLoadingSchedule ? null : _countConfirmed((b) => b == ScheduleBucket.today);
    final overdueCount = _isLoadingSchedule ? null : _countConfirmed((b) => b == ScheduleBucket.overdue);
    final upcomingCount = _isLoadingSchedule
        ? null
        : _countConfirmed((b) => b == ScheduleBucket.tomorrow || b == ScheduleBucket.upcoming);
    final newRequestsCount = _isLoadingPending ? null : _pendingRequests.length;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _MechanicHomeHeader(
            businessName: _businessName,
            todayCount: todayCount,
            newRequestsCount: newRequestsCount,
            unreadChatCount: _unreadChatCount,
            onNotificationTap: _openNotifications,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                _TodayOverviewRow(
                  today: todayCount,
                  newRequests: newRequestsCount,
                  upcoming: upcomingCount,
                  overdue: overdueCount,
                ),
                const SizedBox(height: AppSpacing.lg),
                _TodayScheduleBanner(count: todayCount, onTap: _openAppointments),
                const SizedBox(height: AppSpacing.xxl),
                const SectionLabel(text: 'Yeni ve Öncelikli Talepler'),
                const SizedBox(height: AppSpacing.md),
                if (_isLoadingPending)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_pendingRequests.isEmpty)
                  const _EmptyPendingRequestsState()
                else ...[
                  _PriorityRequestCard(
                    request: _toRequestCardData(_pendingRequests.first),
                    onTap: () => _openRequestDetails(_pendingRequests.first),
                  ),
                  if (_pendingRequests.length > 1) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    const SectionLabel(text: 'Diğer Talepler'),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 1; i < _pendingRequests.length; i++) ...[
                      _OtherRequestCard(
                        request: _toRequestCardData(_pendingRequests[i]),
                        bucket: scheduleBucketFor(_pendingRequests[i].appointmentDate, now),
                        onTap: () => _openRequestDetails(_pendingRequests[i]),
                      ),
                      if (i < _pendingRequests.length - 1) const SizedBox(height: AppSpacing.lg),
                    ],
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Which day-relative bucket [appointmentDate] falls into as of [now] — the
/// single date-comparison rule shared by the stat cards (today/upcoming/
/// overdue counts, see _MechanicHomeScreenState._countConfirmed) and the
/// "Diğer Talepler" list's Bugün/Yarın/Gecikti/Yaklaşan tags (see
/// _OtherRequestCard), so the two can never disagree about what counts as
/// "today" or "overdue". A pure function of the two dates — no status
/// involved here; callers decide which appointments/requests it applies to.
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

/// Branded header — real business name in the greeting, real today's/new
/// counts in the subtitle, and a bell whose badge is a real unread-message
/// count (all null-safe: shows a neutral fallback while the underlying
/// stream/future is still loading, never a fake number).
class _MechanicHomeHeader extends StatelessWidget {
  const _MechanicHomeHeader({
    required this.businessName,
    required this.todayCount,
    required this.newRequestsCount,
    required this.unreadChatCount,
    required this.onNotificationTap,
  });

  final String? businessName;
  final int? todayCount;
  final int? newRequestsCount;
  final int unreadChatCount;
  final VoidCallback onNotificationTap;

  // Same 3-stop brand gradient PremiumHeroHeader already uses on the
  // customer-side home screen (see widgets/home/premium_hero_header.dart)
  // — reused here for visual consistency instead of inventing a new one.
  static const _gradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final trimmedName = businessName?.trim();
    final greeting = (trimmedName == null || trimmedName.isEmpty) ? 'Hoş geldiniz 👋' : 'Merhaba, $trimmedName 👋';
    final subtitle = (todayCount == null || newRequestsCount == null)
        ? 'Panelinize hoş geldiniz.'
        : 'Bugün $todayCount randevunuz, $newRequestsCount yeni talebiniz var.';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: _gradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          // Tighter than before — this header's job is a quick "who am I /
          // what's the day look like" glance, not a full-height hero; the
          // work list below needs the room instead (see this file's class
          // doc). No eyebrow line, smaller type, tighter spacing.
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 12, AppSpacing.xl, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, height: 1.3, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onNotificationTap,
                icon: Badge(
                  isLabelVisible: unreadChatCount > 0,
                  label: Text('$unreadChatCount'),
                  child: const Icon(Icons.notifications_outlined, size: 26, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact "Bugüne Bakış" (Today's Overview) row — the same four real
/// numbers the old 2x2 stat-card grid showed (today/new/upcoming/overdue,
/// still derived from _MechanicHomeScreenState._countConfirmed and
/// _pendingRequests.length; no metric added, removed, or recomputed here),
/// just deliberately de-emphasized: one slim card instead of four large
/// ones, so this reads as context for the work list below rather than the
/// main content of the screen. '...' while the underlying stream's first
/// value hasn't arrived yet; real 0 shown otherwise, never hidden — same
/// "the mechanic looking at their own real numbers" reasoning
/// MechanicProfileScreen already uses for its own unthresholded stats.
class _TodayOverviewRow extends StatelessWidget {
  const _TodayOverviewRow({
    required this.today,
    required this.newRequests,
    required this.upcoming,
    required this.overdue,
  });

  final int? today;
  final int? newRequests;
  final int? upcoming;
  final int? overdue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BUGÜNE BAKIŞ',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PremiumSurface(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2, horizontal: AppSpacing.sm),
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.divider),
          child: Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.today_rounded,
                  value: today,
                  label: 'Bugün',
                  color: AppColors.scheduleToday,
                ),
              ),
              const _MiniStatDivider(),
              Expanded(
                child: _MiniStat(
                  icon: Icons.inbox_rounded,
                  value: newRequests,
                  label: 'Yeni',
                  color: AppColors.turquoise,
                ),
              ),
              const _MiniStatDivider(),
              Expanded(
                child: _MiniStat(
                  icon: Icons.event_available_rounded,
                  value: upcoming,
                  label: 'Yaklaşan',
                  color: AppColors.scheduleUpcoming,
                ),
              ),
              const _MiniStatDivider(),
              Expanded(
                child: _MiniStat(
                  icon: Icons.schedule_rounded,
                  value: overdue,
                  label: 'Gecikti',
                  color: AppColors.scheduleOverdue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final int? value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              value == null ? '...' : '$value',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MiniStatDivider extends StatelessWidget {
  const _MiniStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: AppColors.divider);
  }
}

/// Quick-access banner into the real appointments/calendar screen — reuses
/// MechanicAppointmentsScreen (the same screen the "Randevular" bottom-nav
/// tab already shows) via a plain push, rather than a new route. When the
/// real count is genuinely 0, this collapses to a compact one-line state
/// (per this file's redesign) instead of the full card — an empty day
/// shouldn't take as much visual room as a day with real appointments to
/// show. [count] is only ever null (still loading) or a real number from
/// _MechanicHomeScreenState._countConfirmed; never a placeholder.
class _TodayScheduleBanner extends StatelessWidget {
  const _TodayScheduleBanner({required this.count, required this.onTap});

  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Bugün için planlanmış randevu yok',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ),
              // Icon-only affordance, deliberately not a text label — a
              // text like "Randevular" here would collide with the
              // "Randevular" bottom-nav tab's own label, ambiguous for
              // anything (tests included) that finds by that exact text.
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    final subtitle = count == null ? 'Randevularınızı görüntüleyin.' : 'Bugün $count randevunuz var.';

    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bugünün Programı',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
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

/// The highlighted top pending request — the newest submitted one (this
/// screen has always sorted _pendingRequests this way; no separate
/// "urgent" concept exists in the data, see this file's class doc). Tagged
/// honestly with what's actually true (a new/today-submitted request), not
/// a fabricated "acil" label. Shows real elapsed time since submission and
/// the real customer note — a deliberate, intentional reversal of this
/// screen's older rule that pending-request cards never show the note;
/// every other card (see _OtherRequestCard) still follows that rule.
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
      // A little more visual weight than _OtherRequestCard — a thin
      // turquoise border plus a barely-there tint (never a filled/strongly
      // colored background) — so this reads as "the most relevant item",
      // not a separate alert-styled component.
      color: AppColors.turquoise.withValues(alpha: 0.05),
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
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_rounded, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.vehicleModel,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(
                width: 40,
                height: 40,
                child: Center(child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ServiceBadge(label: request.service),
          const SizedBox(height: 14),
          _DateTimeRow(date: request.preferredDate, time: request.preferredTime),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.divider),
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
        ],
      ),
    );
  }
}

/// One collapsed preview in "Diğer Talepler" — same collapsed-preview rule
/// as always (no customer note, name, or action buttons; those live only
/// on MechanicRequestDetailsPage), plus a real Bugün/Yarın/Gecikti/Yaklaşan
/// status computed from the request's own appointmentDate (see
/// scheduleBucketFor). The status shows twice, both deliberately subtle: a
/// thin colored left border and a small badge — never a filled/colored
/// card background, so this stays a calm, restrained treatment rather than
/// an alert. Same overall structure as _PriorityRequestCard (status row,
/// then vehicle row with a chevron) so the two read as one design system.
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
