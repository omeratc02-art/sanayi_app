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

/// Mechanic module's "Home" tab — rebuilt to match a visual reference
/// mockup while keeping every number/name/status honestly tied to real
/// Firestore-backed data. Top to bottom / left to right:
///
///   1. [_MechanicHomeTopBar] — logo + "SanayiGo" wordmark + static
///      tagline, the real unread-message bell badge, and a profile chip
///      (real business name + real isVerified badge, neutral icon avatar —
///      no fabricated photo).
///   2. [_MechanicHomeGreetingHero] — the real time-aware greeting +
///      subtitle, beside a purely decorative icon-based hero graphic and a
///      static quote line (brand chrome, not data).
///   3. [_MechanicHomeStatsRow] — today's confirmed-appointment count,
///      new-request count (a small dot when > 0 — never red/alert
///      styling, same "workflow state, not an emergency" principle as
///      [AppColors.scheduleOverdue]), and real average rating.
///   4. A responsive two-column body (stacks below [_twoColumnBreakpoint],
///      side by side above it):
///        - Main column: every pending request rendered uniformly — same
///          size, same style, same "Yeni Talep" tag — in one list
///          ([_PendingRequestsList]). There is no real distinction in the
///          data between the newest request and the rest (all are the same
///          pending status), so none is visually spotlighted over another.
///        - Sidebar: today's confirmed appointments
///          ([_TodayScheduleCard]) and real rating/repeat-customer/
///          on-time-rate trust metrics ([_ServicePerformanceCard]).
///
/// Deliberately NOT shown, because no real data backs them: a "Bu Hafta /
/// Toplam İş" weekly metric, a repeat-customer PERCENTAGE (this app always
/// shows a raw count — see ServiceCenterCard's own "Tekrar Müşteri" chip),
/// any vehicle or mechanic photo (no such field exists in Firestore — a
/// neutral icon stands in for both), and a fabricated "urgent"/"acil" flag.
///
/// Workflow rule (unchanged): this screen shows ONLY actionable work items
/// (pending appointment requests awaiting a decision) as collapsed
/// previews — a card is never expandable in place. Tapping one, or its
/// "Talebi İncele" action, pushes the separate MechanicRequestDetailsPage,
/// the actual workspace for a request.
///
///   Bell -> MechanicNotificationsScreen -> tap a notification -> Request Details
///   Home -> tap a request card -> Request Details
///
/// The bell must always open the Notifications page first — it must never
/// jump straight to a Request Details workspace.
class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

// Above this width, the main content and sidebar render side by side (as
// in the reference mockup); below it, they stack vertically. Set well
// above typical phone widths (360-430px) — a genuine two-column card
// layout (vehicle name + service + date/time + an action button, next to
// a real sidebar) doesn't fit legibly at phone width, so virtually all
// phones get the stacked fallback and only tablets/foldables/desktop-width
// windows get the true two-column view.
const double _twoColumnBreakpoint = 700;
const double _sidebarWidth = 240;

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  final _appointmentRepository = AppointmentRepository();

  StreamSubscription<List<Appointment>>? _pendingRequestsSubscription;
  List<Appointment> _pendingRequests = [];
  var _isLoadingPending = true;

  // Every appointment for this business, unfiltered by status — the same
  // real stream MechanicAppointmentsScreen's "Tüm Randevular" tab already
  // uses (AppointmentRepository.watchAppointmentsForBusiness). Bucketed
  // client-side (see scheduleBucketFor) into today's confirmed-appointment
  // count and today's timeline — no new Firestore query or schema field,
  // only categorization logic over an existing stream.
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
          // first entry the spotlighted card.
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
  // from a real 0 — see _ServicePerformanceCard for how each renders.
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

  // Also the real destination for "Uygunluk durumunu düzenle" — there is no
  // availability-editing feature built yet, so this button opens the
  // closest existing real screen instead of inventing new functionality
  // or being a dead button.
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
  // toward today's confirmed-appointment number. A still-pending request
  // has no confirmed date commitment yet, so it can't be "today's" in the
  // schedule sense — it's already counted separately as a "new request"
  // (see _pendingRequests.length below). The tamamlanmaDurumu check
  // matters because `durum`/status stays 'kabul edildi' (accepted) forever
  // once a job is confirmed — markMechanicCompleted/markCustomerVerified
  // (see AppointmentRepository) only ever change tamamlanmaDurumu, never
  // durum — so without this check, a job completed months ago would still
  // count as scheduled.
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
  // for the "Bugünün Programı" card.
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
    final businessName = _profile?.businessName;
    final isVerified = _profile?.isVerified ?? false;

    final mainColumnChildren = <Widget>[
      if (_isLoadingPending)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_pendingRequests.isEmpty)
        const _EmptyPendingRequestsState()
      else
        _PendingRequestsList(
          requests: _pendingRequests,
          toCardData: _toRequestCardData,
          onOpenRequest: _openRequestDetails,
          onViewAll: _openAppointments,
        ),
    ];

    final sidebarColumnChildren = <Widget>[
      _TodayScheduleCard(
        isLoading: _isLoadingSchedule,
        appointments: _todaysAppointments,
        onViewAll: _openAppointments,
        onEditAvailability: _openAppointments,
      ),
      const SizedBox(height: AppSpacing.xxl),
      _ServicePerformanceCard(
        isLoading: _isLoadingPerformance,
        ratingSummary: _ratingSummary,
        repeatCustomerCount: _repeatCustomerCount,
        onTimeRate: _onTimeRate,
        isVerified: isVerified,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            _MechanicHomeTopBar(
              businessName: businessName,
              isVerified: isVerified,
              unreadChatCount: _unreadChatCount,
              onNotificationTap: _openNotifications,
            ),
            const SizedBox(height: AppSpacing.xl),
            _MechanicHomeGreetingHero(businessName: businessName),
            const SizedBox(height: AppSpacing.xl),
            _MechanicHomeStatsRow(
              todayCount: todayCount,
              newRequestsCount: newRequestsCount,
              ratingSummary: _ratingSummary,
            ),
            const SizedBox(height: AppSpacing.xxl),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= _twoColumnBreakpoint) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: mainColumnChildren),
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      SizedBox(
                        width: _sidebarWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sidebarColumnChildren,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...mainColumnChildren,
                    const SizedBox(height: AppSpacing.xxl),
                    ...sidebarColumnChildren,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Which day-relative bucket [appointmentDate] falls into as of [now] —
/// used to decide whether a confirmed appointment counts toward today's
/// schedule (see _MechanicHomeScreenState._countConfirmed/
/// _todaysAppointments). A pure function of the two dates.
enum ScheduleBucket { overdue, today, tomorrow, upcoming }

ScheduleBucket scheduleBucketFor(DateTime appointmentDate, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
  if (date.isBefore(today)) return ScheduleBucket.overdue;
  if (isSameDay(date, today)) return ScheduleBucket.today;
  if (isSameDay(date, today.add(const Duration(days: 1)))) return ScheduleBucket.tomorrow;
  return ScheduleBucket.upcoming;
}

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
// "Good morning"/"Good afternoon" style greeting variation.
String _timeAwareGreetingPrefix(DateTime now) {
  final hour = now.hour;
  if (hour < 6) return 'İyi geceler';
  if (hour < 12) return 'Günaydın';
  if (hour < 18) return 'İyi günler';
  return 'İyi akşamlar';
}

/// Top bar — logo badge + "SanayiGo" wordmark with a static tagline, the
/// real unread-message bell badge, and a profile chip. The chip shows the
/// real business name and the real isVerified badge (same convention
/// [_ServicePerformanceCard] uses) next to a neutral icon avatar — there is
/// no mechanic profile-photo field in Firestore, so a fabricated photo is
/// never used.
class _MechanicHomeTopBar extends StatelessWidget {
  const _MechanicHomeTopBar({
    required this.businessName,
    required this.isVerified,
    required this.unreadChatCount,
    required this.onNotificationTap,
  });

  final String? businessName;
  final bool isVerified;
  final int unreadChatCount;
  final VoidCallback onNotificationTap;

  // The real app icon's foreground artwork (see pubspec.yaml's assets
  // entry) — a transparent-background car+wrench mark, the same art used
  // to generate the launcher icon. The file and the pubspec.yaml
  // declaration are both correct (verified directly: 79526-byte valid PNG
  // on disk, listed under pubspec.yaml's assets: with correct 2/4-space
  // YAML indentation). If this ever renders blank again, it is almost
  // certainly NOT a code/pubspec problem — it's a stale build: this asset
  // entry was added after some existing `flutter run`/`flutter build web`
  // output was produced, and Flutter web bakes AssetManifest.bin into the
  // build at build time — a hot reload does not regenerate it, only a full
  // stop + rebuild does. (Diagnosed exactly this way once already: a
  // build/web/ output whose AssetManifest predated this pubspec entry had
  // no record of the file at all.) See errorBuilder below, which now logs
  // the real exception instead of failing silently, so this is
  // diagnosable from the console instead of just "no logo".
  static const _logoAssetPath = 'assets/icon/app_icon_foreground.png';

  static const _logoBadgeGradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final trimmedName = businessName?.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          // Was 40x40 with a 20px logo — bumped up so the brand mark carries
          // more visual weight instead of reading as a small afterthought.
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(gradient: _logoBadgeGradient, borderRadius: BorderRadius.all(Radius.circular(13))),
          child: Image.asset(
            _logoAssetPath,
            height: 22,
            fit: BoxFit.contain,
            // Falls back to an empty badge (no broken-image icon) rather
            // than crashing, but this is NOT a silent fallback — the real
            // exception is logged, so a failure here is diagnosable from
            // the console (see _logoAssetPath's own doc comment for the
            // one real cause this has actually had: a stale build).
            errorBuilder: (context, error, stackTrace) {
              debugPrint('SanayiGo logo asset failed to load ($_logoAssetPath): $error');
              return const SizedBox.shrink();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SanayiGo',
                // Was fontSize 15/w800/AppColors.primary — AppColors.primary
                // (a sky blue) has weak contrast against white for text this
                // small; primaryDark reads as a clearly stronger, darker
                // wordmark, and the larger w900 size/weight gives it more
                // visual mass to match the strengthened logo badge.
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 2),
              Text(
                'Ustanın Gücü, Yolda Güven',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Was fontSize 10.5/textSecondary (unweighted) — a touch
                // bigger, semibold, and a darker gray (textPrimary at
                // reduced alpha, rather than the lighter textSecondary
                // token) so it no longer nearly disappears next to the
                // strengthened wordmark above it.
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.turquoise.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onNotificationTap,
            icon: Badge(
              isLabelVisible: unreadChatCount > 0,
              label: Text('$unreadChatCount'),
              child: const Icon(Icons.notifications_outlined, size: 21, color: AppColors.primaryDark),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
          // Neutral placeholder avatar — there is no mechanic profile-photo
          // field anywhere in Firestore, so a generic business icon stands
          // in rather than a fabricated photo.
          child: const Icon(Icons.storefront_rounded, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 92),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (trimmedName == null || trimmedName.isEmpty) ? 'Usta' : trimmedName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              // Only shown when real — mirrors MechanicDetailPage's own
              // isVerified-gated badge on the customer-facing side; no
              // "unverified" state is ever shown.
              if (isVerified) ...[
                const SizedBox(height: 2),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 11, color: AppColors.turquoise),
                    SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'Doğrulanmış Servis',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Greeting + a purely decorative hero graphic. The greeting/subtitle are
/// real (time-aware prefix + real business name); the hero graphic and
/// quote are static brand chrome, not data — an icon composition rather
/// than a stock photo, since no real "car in a service bay" image exists
/// in this project's assets.
class _MechanicHomeGreetingHero extends StatelessWidget {
  const _MechanicHomeGreetingHero({required this.businessName});

  final String? businessName;

  static const _heroGradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final trimmedName = businessName?.trim();
    final prefix = _timeAwareGreetingPrefix(DateTime.now());
    final greeting = (trimmedName == null || trimmedName.isEmpty) ? '$prefix 👋' : '$prefix, $trimmedName 👋';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                // Was fontSize 22/w800 — AppColors.textPrimary is already
                // this app's darkest neutral token (near-black), so the
                // color itself was already correct/maximally dark; the
                // faintness read as a weight problem instead, so this goes
                // up to w900 (the heaviest weight the variable font
                // supports) with a slightly larger size, so it reads as the
                // unmistakably dominant element on this row.
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Randevularınızı ve hizmet taleplerinizi yönetin.',
                // Was fontSize 13.5/textSecondary (unweighted). Still
                // clearly secondary to the greeting above, but darker
                // (textPrimary at reduced alpha, rather than the lighter
                // textSecondary token) and semibold so it holds up instead
                // of nearly disappearing.
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          width: 96,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(gradient: _heroGradient, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 26),
              const SizedBox(height: 6),
              Text(
                'İyi bakım,\ndaha uzun yollar.',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact stats row — today's confirmed-appointment count, new-request
/// count (a small dot when > 0), and real average rating. Every value is
/// the same one already computed in _MechanicHomeScreenState.build().
class _MechanicHomeStatsRow extends StatelessWidget {
  const _MechanicHomeStatsRow({required this.todayCount, required this.newRequestsCount, required this.ratingSummary});

  final int? todayCount;
  final int? newRequestsCount;
  final ({double averageRating, int ratedCount})? ratingSummary;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.event_available_rounded,
              value: todayCount == null ? '...' : '$todayCount',
              label: 'Bugün / Randevu',
              color: AppColors.scheduleToday,
            ),
          ),
          Container(width: 1, height: 34, color: AppColors.divider),
          Expanded(
            child: _StatItem(
              icon: Icons.inbox_rounded,
              value: newRequestsCount == null ? '...' : '$newRequestsCount',
              label: 'Yeni Talepler',
              color: AppColors.turquoise,
              // A small, calm dot — never red-alarming animation — the
              // same "honest, no fabricated urgency" principle this file
              // already applies to "Gecikti" elsewhere.
              showDot: (newRequestsCount ?? 0) > 0,
            ),
          ),
          Container(width: 1, height: 34, color: AppColors.divider),
          Expanded(
            child: _StatItem(
              icon: Icons.star_rounded,
              value: ratingSummary != null ? ratingSummary!.averageRating.toStringAsFixed(1) : '—',
              label: 'Müşteri Puanı',
              color: AppColors.rating,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.showDot = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 20, color: color),
            if (showDot)
              Positioned(
                right: -3,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.scheduleOverdue, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Shown in place of the request card when the signed-in mechanic
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

/// All pending requests, rendered uniformly — no item is visually bigger,
/// more colorful, or more prominent than another, since there is no real
/// distinction in the data between the newest request and the rest (every
/// one is the same "pending" status). Capped so this stays scannable; a
/// "Tümünü Gör" link opens the full list (MechanicAppointmentsScreen,
/// already defaulting to its "Yeni Talepler" tab) when there are more.
class _PendingRequestsList extends StatelessWidget {
  const _PendingRequestsList({
    required this.requests,
    required this.toCardData,
    required this.onOpenRequest,
    required this.onViewAll,
  });

  final List<Appointment> requests;
  final _RequestCardData Function(Appointment) toCardData;
  final void Function(Appointment) onOpenRequest;
  final VoidCallback onViewAll;

  static const _maxPreview = 3;

  @override
  Widget build(BuildContext context) {
    final previewCount = requests.length < _maxPreview ? requests.length : _maxPreview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel(text: 'Yeni Talepler')),
            if (requests.length > _maxPreview)
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
        PremiumSurface(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.divider),
          child: Column(
            children: [
              for (var i = 0; i < previewCount; i++) ...[
                _PendingRequestRow(request: toCardData(requests[i]), onTap: () => onOpenRequest(requests[i])),
                if (i < previewCount - 1) const Divider(height: 1, color: AppColors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One uniform row — every pending request gets exactly this treatment
/// (vehicle, service, real elapsed time since submitted, a "Yeni Talep"
/// tag, and a chevron as the only "tap for details" affordance), regardless
/// of how recently it arrived.
class _PendingRequestRow extends StatelessWidget {
  const _PendingRequestRow({required this.request, required this.onTap});

  final _RequestCardData request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Neutral vehicle icon placeholder — there is no real vehicle
            // photo field anywhere in Firestore, so no stock/fabricated
            // image is used here (same icon this file already uses for
            // vehicles elsewhere).
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car_rounded, size: 20, color: AppColors.turquoise),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    request.vehicleModel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.service,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reuses the existing light-teal token pair (its value is a
                // teal tint that pairs with turquoise, even though its name
                // was originally chosen for the schedule-today accent) —
                // avoids inventing a new inline hex for this chip.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.scheduleTodayBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Yeni Talep',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.turquoise),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeAgoLabel(request.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(width: 4),
            // The same small "tap for details" affordance on every row —
            // no row gets a large button while the rest get nothing.
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// "Bugünün Programı" — today's confirmed appointments, earliest first, in
/// a compact card with a "Tümünü Gör" link and an "Uygunluk durumunu
/// düzenle" button. There is no availability-editing feature built yet, so
/// that button opens the existing appointments screen (see
/// _MechanicHomeScreenState._openAppointments) instead of inventing new
/// functionality.
class _TodayScheduleCard extends StatelessWidget {
  const _TodayScheduleCard({
    required this.isLoading,
    required this.appointments,
    required this.onViewAll,
    required this.onEditAvailability,
  });

  final bool isLoading;
  final List<Appointment> appointments;
  final VoidCallback onViewAll;
  final VoidCallback onEditAvailability;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel(text: 'Bugünün Programı')),
              if (!isLoading)
                GestureDetector(
                  onTap: onViewAll,
                  child: const Text(
                    'Tümünü Gör',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 30, color: AppColors.textSecondary),
                  SizedBox(height: 8),
                  Text(
                    'Bugün için planlanmış randevu yok',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < appointments.length; i++) ...[
                  _AppointmentTimelineRow(appointment: appointments[i]),
                  if (i < appointments.length - 1) const Divider(height: 1, color: AppColors.divider),
                ],
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onEditAvailability,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
              child: const Text(
                'Uygunluk durumunu düzenle',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
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

/// "Servis Performansınız" — real rating, real repeat-customer count (kept
/// as a raw integer, never a percentage — this app always shows a real
/// count for this metric, see ServiceCenterCard's own "Tekrar Müşteri"
/// chip), and real on-time-completion rate, plus the existing
/// isVerified-gated "Doğrulanmış Servis" badge.
class _ServicePerformanceCard extends StatelessWidget {
  const _ServicePerformanceCard({
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
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(text: 'Servis Performansınız'),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _PerformanceRow(
              icon: Icons.star_rounded,
              value: ratingSummary != null ? ratingSummary!.averageRating.toStringAsFixed(1) : '—',
              label: ratingSummary != null ? 'Müşteri Puanı (${ratingSummary!.ratedCount} yorum)' : 'Müşteri Puanı',
              color: AppColors.rating,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PerformanceRow(
              icon: Icons.repeat_rounded,
              // Deliberately a raw count, not a percentage — see this
              // class's own doc comment.
              value: '${repeatCustomerCount ?? 0}',
              label: 'Tekrar Müşteri',
              color: AppColors.turquoise,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PerformanceRow(
              icon: Icons.timer_outlined,
              value: onTimeRate != null ? '%${onTimeRate!.round()}' : '—',
              label: 'Zamanında Teslim',
              color: AppColors.primary,
            ),
            // Only shown when real — same isVerified check
            // _MechanicHomeTopBar's profile chip uses, no new check added.
            if (isVerified) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.openBackground,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_rounded, size: 16, color: AppColors.open),
                    SizedBox(width: 6),
                    // Flexible + ellipsis rather than an unconstrained
                    // Text — the fixed 240px sidebar column (see
                    // _sidebarWidth) is narrower than this same card gets
                    // in the stacked (phone-width) layout, so this text
                    // needs to be able to shrink instead of forcing a
                    // RenderFlex overflow in two-column mode.
                    Flexible(
                      child: Text(
                        'Doğrulanmış Servis',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.open),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: AppSpacing.sm + 2),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }
}
