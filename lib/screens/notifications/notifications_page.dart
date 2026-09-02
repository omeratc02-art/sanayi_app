import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/appointment_request_store.dart';
import '../../mechanic/appointments/data/appointment.dart';
import '../../mechanic/appointments/data/appointment_repository.dart';
import '../../mechanic/appointments/data/chat_message.dart';
import '../../mechanic/appointments/data/chat_repository.dart';
import '../../models/appointment_request.dart';
import '../../theme/app_theme.dart';
import '../../utils/firebase_instances.dart';
import '../../utils/identity.dart';
import '../../utils/relative_time.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/appointments/propose_time_dialog.dart';
import '../../widgets/common/premium_surface.dart';
import '../appointments/customer_conversation_page.dart';

/// Customer Notifications screen, reached via the bell in GreetingBar
/// (see home/home_tab.dart). A unified notification center: appointment
/// status changes (provider proposed / declined) and unread chat messages,
/// shown as two visually distinct card types. Mirrors the mechanic side's
/// equivalent (mechanic/notifications/mechanic_notifications_screen.dart)
/// but uses the customer app's PremiumSurface card language instead of that
/// screen's flat list tiles. See AppointmentRequestCard._StatusSection,
/// which deliberately renders nothing for the providerProposed status
/// because this screen is where it belongs instead.
///
/// Both sources are sourced the same way AppointmentsTab's Upcoming/Past
/// lists are: merge/subscribe to the real, live Firestore data
/// (AppointmentRepository.watchCustomerAppointments,
/// ChatRepository.watchUnreadChats) so a mechanic's proposal, decline, or
/// message from an earlier app session — or made while this app wasn't
/// running at all — still shows up here, not only one from the current
/// session.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  StreamSubscription<List<Appointment>>? _firestoreSubscription;
  List<Appointment> _firestoreAppointments = [];

  StreamSubscription<List<ChatSummary>>? _unreadChatsSubscription;
  List<ChatSummary> _unreadChats = [];

  @override
  void initState() {
    super.initState();
    AppointmentRequestStore.instance.addListener(_onStoreChanged);

    // Guests (no signed-in Firebase user) have no real customerId to query
    // by — same guard AppointmentsTab uses, left on the session-local path
    // only, same as every other guest path in this app.
    final uid = firebaseAuthInstance.currentUser?.uid;
    if (uid != null) {
      _firestoreSubscription = AppointmentRepository().watchCustomerAppointments(uid).listen(
        (appointments) {
          if (!mounted) return;
          setState(() => _firestoreAppointments = appointments);
        },
        onError: (Object error) {
          debugPrint('CUSTOMER NOTIFICATIONS LISTENER ERROR: $error');
        },
      );
    }

    // resolveCustomerId() already falls back to 'customer-demo' for guests
    // — no separate guard needed here, unlike the appointments subscription
    // above, which genuinely requires a real uid.
    _unreadChatsSubscription = ChatRepository().watchUnreadChats(resolveCustomerId()).listen(
      (chats) {
        if (!mounted) return;
        setState(() => _unreadChats = chats);
      },
      onError: (Object error) {
        debugPrint('CUSTOMER UNREAD CHATS LISTENER ERROR: $error');
      },
    );
  }

  @override
  void dispose() {
    AppointmentRequestStore.instance.removeListener(_onStoreChanged);
    _firestoreSubscription?.cancel();
    _unreadChatsSubscription?.cancel();
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  // accept() is now a real Firestore operation for authenticated customers
  // (see AppointmentRequestStore.accept) — await it and only report a
  // failure; a success needs no extra handling here since the store's own
  // notifyListeners() already updates this page's UI via _onStoreChanged.
  Future<void> _acceptSuggestion(AppointmentRequest request) async {
    final success = await AppointmentRequestStore.instance.accept(request);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Randevu onaylanamadı. Lütfen tekrar deneyin.')),
      );
    }
  }

  // Counter-proposes a new date/time — a real Firestore write (see
  // AppointmentRequestStore.requestAnotherTime), not the old local-only
  // reset. No confirmed appointment is created; this just records the
  // customer's own proposal and waits on the mechanic's response.
  Future<void> _requestAnotherTime(AppointmentRequest request) async {
    final picked = await pickProposedDateTime(context);
    if (picked == null || !mounted) return;
    final (date, time) = picked;
    final success = await AppointmentRequestStore.instance.requestAnotherTime(request, date: date, time: time);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Farklı bir saat öneriniz iletildi.' : 'Öneriniz gönderilemedi. Lütfen tekrar deneyin.',
        ),
      ),
    );
  }

  static const _noProposedTimeSentinel = TimeOfDay(hour: 0, minute: 0);

  @override
  Widget build(BuildContext context) {
    // Session-local requests submitted this session — same filter as
    // before, now also scoped to the signed-in customer (matching
    // AppointmentsTab's own localConfirmed filter) since _requests is one
    // shared list, not partitioned by customer.
    final localProposals = AppointmentRequestStore.instance.requests.where(
      (request) =>
          request.customerId == resolveCustomerId() &&
          (request.status == AppointmentRequestStatus.providerProposed ||
              request.status == AppointmentRequestStatus.declined),
    );

    // Real appointments read directly from Firestore (see initState) —
    // what makes a mechanic's proposal or decline from an earlier session
    // still show up here. Pre-filtered to exactly the two real
    // AppointmentStatus values that map to providerProposed/declined via
    // appointmentRequestFromAccepted, same convention AppointmentsTab uses
    // for its own accepted/pending pre-filter.
    final firestoreProposals = _firestoreAppointments
        .where(
          (appointment) =>
              appointment.status == AppointmentStatus.declined ||
              appointment.status == AppointmentStatus.timeProposed ||
              (appointment.status == AppointmentStatus.pending &&
                  appointment.appointmentTime != _noProposedTimeSentinel),
        )
        .map(AppointmentRequestStore.instance.appointmentRequestFromAccepted)
        // A timeProposed appointment maps to pendingProvider, not
        // providerProposed, when it's genuinely not the customer's turn
        // (sonTeklifEden == 'musteri', waiting on the mechanic) — exclude
        // those here rather than in the raw-Appointment filter above, since
        // only appointmentRequestFromAccepted knows how to resolve that.
        .where(
          (request) =>
              request.status == AppointmentRequestStatus.declined ||
              request.status == AppointmentRequestStatus.providerProposed,
        );

    // Merged by id — Firestore, being the authoritative persisted state,
    // wins on conflict. Same merge pattern as AppointmentsTab.
    final byId = {for (final request in localProposals) request.id: request};
    for (final request in firestoreProposals) {
      byId[request.id] = request;
    }
    final proposals = byId.values.toList();

    final isEmpty = proposals.isEmpty && _unreadChats.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bildirimler')),
      body: isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                for (final request in proposals) ...[
                  request.status == AppointmentRequestStatus.declined
                      ? _DeclinedRequestCard(request: request)
                      : _NewTimeSuggestedCard(
                          request: request,
                          onAccept: () => _acceptSuggestion(request),
                          onRequestAnotherTime: () => _requestAnotherTime(request),
                        ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (final chat in _unreadChats) ...[
                  _UnreadMessageCard(chat: chat),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
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
            const Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Bildiriminiz yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bir usta size yeni bir randevu saati önerdiğinde ya da mesaj gönderdiğinde burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The message-notification card (type 2) — one per conversation with an
/// unread message from the mechanic, not per-message (see
/// ChatRepository.watchUnreadChats, the same real data source the
/// Mesajlar-tab badge and bell badge total read from). Deliberately a
/// different visual language from the appointment cards (turquoise
/// chat-bubble icon, no action buttons, just a message preview) so the two
/// notification types are clearly distinguishable at a glance. Tapping it
/// opens the real conversation — reading it there is what actually clears
/// this card (see CustomerConversationPage's markMessagesRead call).
class _UnreadMessageCard extends StatelessWidget {
  const _UnreadMessageCard({required this.chat});

  final ChatSummary chat;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      borderRadius: 20,
      color: Colors.white,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerConversationPage(chatId: chat.chatId, mechanicName: chat.mechanicName),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: AppColors.turquoise, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.mechanicName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                    if (chat.lastMessageAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        formatRelativeTime(chat.lastMessageAt!),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  chat.lastMessageText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A mechanic's decline notification — same card language (avatar circle,
/// name, message) as _NewTimeSuggestedCard below, but purely informational:
/// there's nothing to accept or request again for a declined request, so
/// no action row.
class _DeclinedRequestCard extends StatelessWidget {
  const _DeclinedRequestCard({required this.request});

  final AppointmentRequest request;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      borderRadius: 20,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy_rounded, color: Colors.red, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request.mechanicName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Usta randevu talebinizi reddetti.',
                  style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A mechanic's proposed-time notification card. Fully tappable actions —
/// no navigation, just the two responses the request state machine
/// actually supports (AppointmentRequestStatus.providerProposed ->
/// confirmed or back to pendingProvider).
class _NewTimeSuggestedCard extends StatelessWidget {
  const _NewTimeSuggestedCard({
    required this.request,
    required this.onAccept,
    required this.onRequestAnotherTime,
  });

  final AppointmentRequest request;
  final VoidCallback onAccept;
  final VoidCallback onRequestAnotherTime;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      borderRadius: 20,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + name + message grouped as a single header block —
                // name and message sit in one tightly-spaced Column, read
                // as one visual unit, with the icon aligned beside them.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            request.mechanicName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Size yeni bir randevu saati önerdi.',
                            style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Original request vs. the mechanic's new proposal.
                const Text(
                  'Talep Ettiğiniz',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Flexible, not a bare Text: formatFullDate can produce
                    // strings long enough (e.g. "26 Ağustos, Çarşamba") to
                    // overflow this Row's width alongside the time text on
                    // narrower phones.
                    Flexible(
                      child: Text(
                        '📅 ${formatFullDate(request.date)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('🕒 ${request.preferredWindowLabel}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                const Text(
                  'Ustanın Yeni Önerisi',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.turquoise),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '📅 ${formatFullDate(request.date)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text('🕒 ${request.proposedTime}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Unread dot on the trailing edge — top-padded to stay vertically
          // centered against the avatar+name row now that the outer Row is
          // top-aligned (needed so the avatar/name align with each other
          // rather than the much taller content column).
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
            ),
          ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.turquoise,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onAccept,
                    child: const Text('Kabul Et'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.turquoise,
                      side: const BorderSide(color: AppColors.turquoise),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onRequestAnotherTime,
                    child: const Text('Farklı Saat Öner'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
