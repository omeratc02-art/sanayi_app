import 'package:flutter/material.dart';

import '../../data/appointment_request_store.dart';
import '../../theme/app_theme.dart';

/// Slim, uncolored top row — greeting + notification bell sit directly on
/// the page background instead of inside a colored banner. This is what
/// lets the hero below be a contained card (not a full-bleed website-style
/// header) and keeps the whole top area compact.
class GreetingBar extends StatelessWidget {
  const GreetingBar({super.key, this.userName, this.onNotificationTap, this.unreadMessageCount = 0});

  /// Null (or empty) means a guest session — see [PremiumHeroHeader].
  final String? userName;
  final VoidCallback? onNotificationTap;

  /// Live unread-chat-conversation count, passed down from MainShell (see
  /// HomeTab.unreadMessageCount) — added to the appointment count below so
  /// the bell reflects both notification types this app now has.
  final int unreadMessageCount;

  String get _greeting {
    final trimmedName = userName?.trim();
    return trimmedName == null || trimmedName.isEmpty ? 'Hoş geldiniz 👋' : 'Merhaba $trimmedName 👋';
  }

  @override
  Widget build(BuildContext context) {
    // Appointment count is the same session-local value the bottom-nav
    // "Randevularım" badge already uses (AppointmentRequestStore — see
    // main_shell.dart); message count is real, live, cross-session data
    // (see ChatRepository.watchUnreadChats via MainShell). Summed, not a
    // fixed placeholder — hidden entirely, not a fake "0", when there's
    // nothing real to show.
    final totalCount = AppointmentRequestStore.instance.actionNeededCount + unreadMessageCount;

    return Row(
      children: [
        Expanded(
          child: Text(
            _greeting,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
        // Same bell as the mechanic app's _MechanicHomeHeader (see
        // mechanic/home/mechanic_home_screen.dart) — plain IconButton with
        // the default Material Badge, no custom colors/background circle.
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: IconButton(
            onPressed: onNotificationTap,
            icon: Badge(
              isLabelVisible: totalCount > 0,
              label: Text('$totalCount'),
              child: const Icon(Icons.notifications_outlined, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}
