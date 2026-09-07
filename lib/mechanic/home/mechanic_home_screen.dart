import 'dart:async';
import 'dart:math' as math;

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
///   2. [_MechanicHomeGreetingHero] — a fixed "Merhaba 👋" greeting +
///      static subtitle, beside a purely decorative icon-based hero graphic
///      and a static quote line (all brand chrome, not data — the real
///      business name is already shown in the top bar's profile chip).
///   3. [_WeeklyEngagementSummaryCard] — "İşletmeniz İlgi Görüyor": a
///      weekly business-engagement summary. Both counts are real: the
///      new-request count (AppointmentRepository.watchRecentAppointmentRequestCount,
///      last 7 days) and the profile-view count
///      (MechanicProfileRepository.watchProfileViewCount/recordProfileView,
///      incremented from a customer opening MechanicDetailPage — see that
///      repository method's own doc comment for the daily-uniqueness/
///      owner-exclusion rules). Only the sparkline shape is still a static
///      placeholder — a separate, still-open task.
///   4. Every pending request rendered uniformly, full-width — same size,
///      same style, same "Yeni Talep" tag — in one list
///      ([_PendingRequestsList]). There is no real distinction in the data
///      between the newest request and the rest (all are the same pending
///      status), so none is visually spotlighted over another. This is now
///      the screen's only body content besides the summary card above it —
///      the former sidebar ("Bugünün Programı" today's-schedule card and
///      "Servis Performansınız" rating/repeat-customer/on-time-rate card)
///      was removed outright, not collapsed into this column.
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

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  final _appointmentRepository = AppointmentRepository();

  StreamSubscription<List<Appointment>>? _pendingRequestsSubscription;
  List<Appointment> _pendingRequests = [];
  var _isLoadingPending = true;

  // Null while loading (or if the stream errors) — never a stale/fabricated
  // number. See AppointmentRepository.watchRecentAppointmentRequestCount.
  StreamSubscription<int>? _recentRequestCountSubscription;
  int? _recentRequestCount;

  // Same null-while-loading convention as _recentRequestCount above. See
  // MechanicProfileRepository.watchProfileViewCount.
  StreamSubscription<int>? _profileViewCountSubscription;
  int? _profileViewCount;

  StreamSubscription<List<ChatSummary>>? _unreadChatsSubscription;
  var _unreadChatCount = 0;

  MechanicProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAppointmentStreams();
    _subscribeToUnreadChats();
    _subscribeToProfileViewCount();
  }

  @override
  void dispose() {
    _pendingRequestsSubscription?.cancel();
    _recentRequestCountSubscription?.cancel();
    _profileViewCountSubscription?.cancel();
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
      setState(() => _isLoadingPending = false);
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

    _recentRequestCountSubscription?.cancel();
    _recentRequestCountSubscription = _appointmentRepository.watchRecentAppointmentRequestCount(myBusinessId).listen(
      (count) {
        if (!mounted) return;
        setState(() => _recentRequestCount = count);
      },
      onError: (Object error) {
        // Same convention as the pending-requests error above: log the real
        // exception, then leave _recentRequestCount as-is (null on first
        // failure) rather than falling back to a fabricated number — the
        // card shows its loading affordance instead of a stale/fake count.
        debugPrint('MECHANIC HOME RECENT REQUEST COUNT ERROR: $error');
      },
    );
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

  // Real live profileViewCount for the signed-in mechanic's own account —
  // see MechanicProfileRepository.watchProfileViewCount/recordProfileView.
  // A separate subscription (own uid lookup, like _subscribeToUnreadChats
  // above) rather than folding into _loadProfile's one-time fetch, since
  // this needs to be live: a customer viewing this business's detail page
  // while the mechanic happens to have this screen open should update the
  // count without a manual refresh.
  void _subscribeToProfileViewCount() {
    final uid = firebaseAuthInstance.currentUser?.uid;
    if (uid == null) return;
    _profileViewCountSubscription = MechanicProfileRepository().watchProfileViewCount(uid).listen(
      (count) {
        if (!mounted) return;
        setState(() => _profileViewCount = count);
      },
      onError: (Object error) {
        // Same convention as the other *_ERROR debugPrints in this state
        // class: log the real exception, leave _profileViewCount as-is
        // (null on first failure) rather than a fabricated fallback.
        debugPrint('MECHANIC HOME PROFILE VIEW COUNT ERROR: $error');
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

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: AppSpacing.xxl),
            const _MechanicHomeGreetingHero(),
            const SizedBox(height: AppSpacing.lg),
            _WeeklyEngagementSummaryCard(
              profileViewCount: _profileViewCount,
              appointmentRequestCount: _recentRequestCount,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ...mainColumnChildren,
          ],
        ),
      ),
    );
  }
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
                'Güvenle Büyüyen İşletmeler',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // Was fontSize 10.5/textSecondary (unweighted), then 11 —
                // bumped once more so it reads proportionate to the logo
                // beside it, semibold, and a darker gray (textPrimary at
                // reduced alpha, rather than the lighter textSecondary
                // token) so it no longer nearly disappears next to the
                // strengthened wordmark above it.
                style: TextStyle(
                  fontSize: 12,
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

/// Greeting block — fixed, static brand chrome, not time-aware and not
/// personalized with the business name, which is already shown in the top
/// bar's profile chip (see [_MechanicHomeTopBar]). No decorative side
/// graphic/promo any more — this is just the greeting + subtitle text.
class _MechanicHomeGreetingHero extends StatelessWidget {
  const _MechanicHomeGreetingHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Merhaba 👋',
          // Was fontSize 22/w800 — AppColors.textPrimary is already
          // this app's darkest neutral token (near-black), so the
          // color itself was already correct/maximally dark; the
          // faintness read as a weight problem instead, so this goes
          // up to w900 (the heaviest weight the variable font
          // supports) with a slightly larger size, so it reads as the
          // unmistakably dominant element on this row.
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'İşletme Paneline Hoş Geldiniz',
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
    );
  }
}

/// "İşletmeniz İlgi Görüyor" — a weekly business-engagement summary card
/// (profile-view count, new-request count, a supporting sparkline). Both
/// counts are real now, passed in by [_MechanicHomeScreenState]:
/// [profileViewCount] from MechanicProfileRepository.watchProfileViewCount/
/// recordProfileView (incremented from MechanicDetailPage — see that
/// repository method's own doc comment for the full daily-uniqueness/
/// owner-exclusion design), [appointmentRequestCount] from
/// AppointmentRepository.watchRecentAppointmentRequestCount. Only the
/// sparkline shape below is still a static placeholder (a separate,
/// still-open task — it isn't yet tied to either real count's actual
/// day-by-day history).
class _WeeklyEngagementSummaryCard extends StatelessWidget {
  const _WeeklyEngagementSummaryCard({required this.profileViewCount, required this.appointmentRequestCount});

  /// Real count of profile views in the current implementation's tracked
  /// history (see MechanicProfileRepository.watchProfileViewCount) — null
  /// while that stream is still loading (or if it errored), never a
  /// stale/fabricated number.
  final int? profileViewCount;

  /// Real count of appointment requests created in the last 7 days — null
  /// while AppointmentRepository.watchRecentAppointmentRequestCount is still
  /// loading (or if it errored), never a stale/fabricated number.
  final int? appointmentRequestCount;

  // Purely decorative shape for the sparkline below — this one is still a
  // static placeholder (unlike both real counts above), not a real
  // day-by-day breakdown of either metric.
  static const _weeklySparklineValues = [3.0, 5.0, 4.0, 7.0, 6.0, 9.0, 8.0];
  static const _weekdayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      // Zero here — the header block below needs to sit flush against the
      // card's own top edge so its top corners can share the card's
      // rounding. PremiumSurface's own `color` is left unset (defaults to
      // AppColors.surface/white), since the tint must NOT cover the whole
      // card — only the header block below applies it, on its own
      // Container, scoped to just that area.
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header zone — the ONLY tinted part of this card. A flat,
          // low-alpha Container (not PremiumSurface's own `color`, which
          // would otherwise tint the whole card) so the tint stays scoped
          // to exactly this block.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            decoration: BoxDecoration(
              // Was 0.05 — bumped up so the strip reads as clearly visible
              // rather than pale, while staying soft (not saturated/loud).
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu haftanın özeti',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'İşletmeniz ilgi görüyor 📈',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  'Daha fazla sürücü sizi keşfediyor.',
                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary.withValues(alpha: 0.72)),
                ),
              ],
            ),
          ),
          // Body zone — plain white (PremiumSurface's own default surface
          // color), no tint: both stat numbers, the sparkline, and the
          // weekday labels all sit here.
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // Not const any more — profileViewCount is a real
                      // runtime value (null while loading), not a
                      // compile-time constant.
                      child: _EngagementStat(
                        icon: Icons.visibility_rounded,
                        value: profileViewCount == null ? '...' : '$profileViewCount',
                        label: 'kişi işletmenizi görüntüledi',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 44,
                      color: AppColors.divider,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    ),
                    Expanded(
                      // Not const any more — appointmentRequestCount is a
                      // real runtime value (null while loading), not a
                      // compile-time constant.
                      child: _EngagementStat(
                        icon: Icons.calendar_month_rounded,
                        value: appointmentRequestCount == null ? '...' : '$appointmentRequestCount',
                        // The number itself is the bold value in the
                        // icon+number row above this label — this label
                        // completes the sentence to read "N kişi randevu
                        // talebi oluşturdu", the same value-then-label
                        // pattern the eye stat already uses.
                        label: 'kişi randevu talebi oluşturdu',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 40,
                  width: double.infinity,
                  child: CustomPaint(painter: _WeeklySparklinePainter(_weeklySparklineValues)),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final label in _weekdayLabels)
                      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One side of [_WeeklyEngagementSummaryCard]'s two-stat row: the icon (in
/// its own small rounded chip) sits inline to the left of the bold number,
/// both vertically centered, with the secondary label underneath that row.
/// Both stats share this exact same widget/style definition (icon chip
/// size/radius/fill, number size, spacing), so the eye stat and the
/// calendar stat can never visually diverge — there is nothing per-stat to
/// keep in sync by hand.
class _EngagementStat extends StatelessWidget {
  const _EngagementStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  // Was 32/16 — bumped up proportionally (modest increase, same 2:1
  // chip-to-icon ratio) so the icon isn't cramped inside its chip.
  static const _iconChipSize = 36.0;
  static const _iconSize = 18.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: _iconChipSize,
              height: _iconChipSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: _iconSize, color: AppColors.turquoise),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 2,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// Thin, minimal weekly sparkline — a supporting visual, not a dominant
/// one. A lightweight CustomPainter rather than a charting dependency, per
/// this feature's explicit "don't add a new heavy charting package" scope.
class _WeeklySparklinePainter extends CustomPainter {
  const _WeeklySparklinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final range = maxValue == minValue ? 1.0 : maxValue - minValue;
    final stepX = size.width / (values.length - 1);

    Offset pointAt(int i) {
      final normalized = (values[i] - minValue) / range;
      return Offset(stepX * i, size.height - (normalized * size.height));
    }

    final linePath = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      final point = pointAt(i);
      linePath.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = AppColors.turquoise.withValues(alpha: 0.08));

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.turquoise
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // A small emphasized dot on the most recent (final) day, echoing the
    // "endpoint" treatment this app already favors for charts/timelines.
    canvas.drawCircle(pointAt(values.length - 1), 3, Paint()..color = AppColors.turquoise);
  }

  @override
  bool shouldRepaint(covariant _WeeklySparklinePainter oldDelegate) => oldDelegate.values != values;
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

