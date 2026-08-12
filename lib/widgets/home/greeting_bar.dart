import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Slim, uncolored top row — greeting + notification bell sit directly on
/// the page background instead of inside a colored banner. This is what
/// lets the hero below be a contained card (not a full-bleed website-style
/// header) and keeps the whole top area compact.
class GreetingBar extends StatelessWidget {
  const GreetingBar({super.key, this.userName, this.onNotificationTap});

  /// Null (or empty) means a guest session — see [PremiumHeroHeader].
  final String? userName;
  final VoidCallback? onNotificationTap;

  String get _greeting {
    final trimmedName = userName?.trim();
    return trimmedName == null || trimmedName.isEmpty ? 'Hoş geldiniz 👋' : 'Merhaba $trimmedName 👋';
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Badge(
              label: Text('1'),
              child: Icon(Icons.notifications_outlined, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}
