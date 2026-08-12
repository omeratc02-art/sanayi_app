import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/identity.dart';
import '../appointments/data/appointment.dart';
import '../appointments/data/appointment_repository.dart';
import '../appointments/data/chat_message.dart';
import '../appointments/data/chat_repository.dart';
import '../appointments/mechanic_conversation_page.dart';

/// What a notification is about — determines where tapping it should
/// eventually navigate. See [_handleNotificationTap] for the per-type
/// destinations (all placeholders for now).
enum _NotificationType {
  customerQuestion,
  newAppointmentRequest,
  photosUploaded,
  appointmentTimeAccepted,
  appointmentCancelled,
}

/// Dedicated Notifications page for mechanics — reached only via the bell
/// in the Home header (see MechanicHomeScreen). Shows a chronological list
/// of mock notifications; this is the correct workflow stop between the
/// bell and a request's "Request Details" workspace:
///
///   Bell -> Notifications page -> tap a notification -> destination varies by type
///
/// Notifications must NOT all navigate to the same place — see
/// [_handleNotificationTap] for the type-specific routing rules.
class MechanicNotificationsScreen extends StatefulWidget {
  const MechanicNotificationsScreen({super.key});

  @override
  State<MechanicNotificationsScreen> createState() => _MechanicNotificationsScreenState();
}

class _MechanicNotificationsScreenState extends State<MechanicNotificationsScreen> {
  // Resolved once per screen instance: the signed-in mechanic's own stable
  // business id (mechanicAccounts/{uid}.businessId — the same id used as
  // that business's chats/{chatId} document id, see mechanicChatId), used
  // to filter chats down to the ones that belong to this mechanic. Matching
  // by this id rather than by name means an account only sees a business's
  // chat if it was actually linked to that business at registration, not
  // whenever its account name happens to resemble one. Null when there's no
  // signed-in user (dev/test flow) or when the account predates this field.
  late final Future<String?> _myBusinessIdFuture = resolveMyBusinessId();

  // Same appointments/{appointmentId} results MechanicAppointmentsScreen
  // already queries for "Yeni Talepler" (AppointmentRepository.
  // fetchAppointments), filtered by the same businessId identity resolved
  // above — not a new query type, not a new collection. Each document is
  // fetched once, so a given request can only ever produce one tile here.
  late final Future<List<Appointment>> _pendingAppointmentsFuture = _loadPendingAppointments();

  Future<List<Appointment>> _loadPendingAppointments() async {
    final businessId = await _myBusinessIdFuture;
    if (businessId == null) return const [];
    // Server-side filtered instead of fetching the whole collection and
    // filtering client-side — same businessId + status == pending
    // condition as before, now scoped in the query itself.
    return AppointmentRepository().fetchPendingAppointments(businessId);
  }

  // This app has no multi-customer system yet — MechanicConversationPage
  // and every other mechanic-side screen already hardcode this same one
  // customer identity for the shared demo conversation, so real
  // "new message" notifications reuse it too rather than inventing a
  // second one.
  static const _customerName = 'Ahmet Yılmaz';

  static const _notifications = [
    _MockNotification(
      icon: Icons.help_outline_rounded,
      title: 'Ahmet Yılmaz size bir soru gönderdi.',
      time: '2 dk önce',
      isRead: false,
      type: _NotificationType.customerQuestion,
    ),
    _MockNotification(
      icon: Icons.event_available_outlined,
      title: 'Mehmet Kaya, önerdiğiniz randevu saatini kabul etti.',
      time: '1 saat önce',
      isRead: false,
      type: _NotificationType.appointmentTimeAccepted,
    ),
    _MockNotification(
      icon: Icons.event_note_outlined,
      title: 'Ayşe Demir yeni bir randevu talebi oluşturdu.',
      time: 'Dün',
      isRead: true,
      type: _NotificationType.newAppointmentRequest,
    ),
    _MockNotification(
      icon: Icons.photo_camera_outlined,
      title: 'Hasan Yılmaz yeni fotoğraflar yükledi.',
      time: 'Dün',
      isRead: true,
      type: _NotificationType.photosUploaded,
    ),
    _MockNotification(
      icon: Icons.event_busy_outlined,
      title: 'Ali Can randevuyu iptal etti.',
      time: '1 hafta önce',
      isRead: true,
      type: _NotificationType.appointmentCancelled,
    ),
  ];

  // TODO: Every branch below except customerQuestion currently just closes
  // this page (placeholder behavior — no destination screens/sections
  // exist for those yet). Once Request Details grows a Photos section,
  // replace each remaining Navigator.pop with the real navigation
  // described in its comment. All of these also need a real reference
  // from the notification to "which request" — not modeled yet.
  void _handleNotificationTap(BuildContext context, _MockNotification notification) {
    switch (notification.type) {
      case _NotificationType.customerQuestion:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MechanicConversationPage(chatId: 'ahmet-yilmaz-yag-degisimi')),
        );
      case _NotificationType.newAppointmentRequest:
        // TODO: Open the Request Details page for the new request.
        Navigator.of(context).pop();
      case _NotificationType.photosUploaded:
        // TODO: Open the related request's Request Details page, focused
        // on its Photos section.
        Navigator.of(context).pop();
      case _NotificationType.appointmentTimeAccepted:
        // TODO: Open the Request Details page with the accepted
        // appointment information visible.
        Navigator.of(context).pop();
      case _NotificationType.appointmentCancelled:
        // TODO: Open the Request Details page with the cancellation
        // status visible.
        Navigator.of(context).pop();
    }
  }

  static String _formatChatTime(DateTime? sentAt) {
    if (sentAt == null) return '';
    final difference = DateTime.now().difference(sentAt);
    if (difference.inMinutes < 1) return 'Şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
    if (difference.inHours < 24) return '${difference.inHours} saat önce';
    return '${difference.inDays} gün önce';
  }

  // One tile per pending appointments/{appointmentId} document belonging
  // to this mechanic's business (see _loadPendingAppointments) — same
  // _MockNotification/_NotificationTile representation, and the same
  // _handleNotificationTap dispatch, as every other notification here;
  // its newAppointmentRequest case already exists (currently a TODO
  // placeholder, same as before this change).
  Widget _buildPendingRequestTile(BuildContext context, Appointment appointment) {
    final notification = _MockNotification(
      icon: Icons.event_note_outlined,
      title: '${appointment.customerName} yeni bir randevu talebi oluşturdu.',
      time: _formatChatTime(appointment.createdAt),
      isRead: false,
      type: _NotificationType.newAppointmentRequest,
    );
    return _NotificationTile(
      notification: notification,
      onTap: () => _handleNotificationTap(context, notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bildirimler')),
      body: FutureBuilder<String?>(
        future: _myBusinessIdFuture,
        builder: (context, idSnapshot) {
          // Wait for the signed-in mechanic's business id to resolve before
          // showing any chat-derived notifications, so we never briefly
          // show chats that don't actually belong to this mechanic.
          if (idSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final isSignedIn = FirebaseAuth.instance.currentUser != null;
          final myBusinessId = idSnapshot.data;

          return FutureBuilder<List<Appointment>>(
            future: _pendingAppointmentsFuture,
            builder: (context, appointmentsSnapshot) {
              final pendingAppointments = appointmentsSnapshot.data ?? const <Appointment>[];

              return StreamBuilder<List<ChatSummary>>(
            stream: ChatRepository().watchChats(),
            builder: (context, snapshot) {
              final chats = snapshot.data ?? const <ChatSummary>[];
              // No signed-in user (dev/test flow): keep showing every chat,
              // unfiltered, exactly like before. Signed in: only this
              // mechanic's own chat — matched by the stable chatId/businessId
              // (chats/{chatId} is already keyed by mechanicChatId(business
              // name), the same id stored as mechanicAccounts.businessId), not
              // by comparing display names. If signed in but the account has
              // no businessId yet (predates this field), show none rather
              // than risk surfacing another business's conversation.
              final myChats = !isSignedIn
                  ? chats
                  : (myBusinessId == null
                      ? const <ChatSummary>[]
                      : chats.where((chat) => chat.chatId == myBusinessId).toList());
              // A chat is awaiting the mechanic's reply exactly when the
              // customer sent the most recent message — tagged explicitly at
              // send time (see ChatRepository.sendMessage), not inferred by
              // comparing lastMessageSenderId to whichever Firebase user
              // happens to be signed in right now. That comparison isn't
              // reliable in the dev/test flow, where the same account can
              // send both customer and mechanic test messages in one
              // session. Replying naturally clears it, since the latest
              // message then becomes a 'mechanic'-tagged one.
              final awaitingReply = myChats.where((chat) => chat.lastMessageSenderRole == 'customer').toList();

              final items = [
                for (final appointment in pendingAppointments)
                  _buildPendingRequestTile(context, appointment),
                for (final chat in awaitingReply)
                  _NotificationTile(
                    notification: _MockNotification(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: '$_customerName size yeni bir mesaj gönderdi.',
                      time: _formatChatTime(chat.lastMessageAt),
                      isRead: false,
                      type: _NotificationType.customerQuestion,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => MechanicConversationPage(chatId: chat.chatId)),
                    ),
                  ),
                for (final notification in _notifications)
                  _NotificationTile(
                    notification: notification,
                    onTap: () => _handleNotificationTap(context, notification),
                  ),
              ];

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: AppSpacing.xl, endIndent: AppSpacing.xl),
                itemBuilder: (_, index) => items[index],
              );
            },
          );
            },
          );
        },
      ),
    );
  }
}

class _MockNotification {
  const _MockNotification({
    required this.icon,
    required this.title,
    required this.time,
    required this.isRead,
    required this.type,
  });

  final IconData icon;
  final String title;
  final String time;
  final bool isRead;
  final _NotificationType type;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final _MockNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notification.icon, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.time,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
