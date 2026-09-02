import 'package:flutter/material.dart';

import '../../config/feature_flags.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/category_illustrations.dart';
import '../../widgets/home/emergency_help_card.dart';
import '../../widgets/home/greeting_bar.dart';
import '../../widgets/home/hero_emergency_cluster.dart';
import '../../widgets/home/my_vehicles_section.dart';
import '../../widgets/home/premium_hero_header.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/home/service_category_card.dart';
import '../notifications/notifications_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, this.userName, this.onCategoryTap, this.unreadMessageCount = 0});

  /// Null means guest — see [GreetingBar.userName].
  final String? userName;

  /// Live count from MainShell's own ChatRepository.watchUnreadChats
  /// subscription — threaded straight into [GreetingBar] rather than having
  /// it run a second, redundant subscription to the same stream.
  final int unreadMessageCount;

  /// Called with 'Araç Tamiri', 'Ekspertiz', or 'Sigorta' — MainShell maps
  /// each to its own page (see MainShell's onCategoryTap). Sub-service
  /// dispatch (Yağ Değişimi, Fren Sistemi, ...) now lives one level down,
  /// inside VehicleRepairCategoryPage — this page only ever sees the 3
  /// top-level category labels.
  final ValueChanged<String>? onCategoryTap;

  static const _clusterSpacing = AppSpacing.lg;
  static const _sectionPadding = EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, 0);

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // 1. Hero section (+ paired Emergency card).
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
              child: Column(
                children: [
                  GreetingBar(
                    userName: userName,
                    unreadMessageCount: unreadMessageCount,
                    onNotificationTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsPage()),
                    ),
                  ),
                  const SizedBox(height: _clusterSpacing),
                  HeroEmergencyCluster(
                    hero: const PremiumHeroHeader(),
                    emergency: EmergencyHelpCard(
                      onTap: () => _showComingSoon(context, 'Acil yardım özelliği yakında aktif olacak.'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 2. The 3 main service categories.
          SliverToBoxAdapter(
            child: Padding(
              padding: _sectionPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Hangi hizmete ihtiyacınız var?'),
                  const SizedBox(height: AppSpacing.md),
                  _MainServiceCategories(onCategoryTap: onCategoryTap),
                ],
              ),
            ),
          ),
          // 3. "Araçlarım" (My Vehicles).
          const SliverToBoxAdapter(
            child: Padding(
              padding: _sectionPadding,
              child: MyVehiclesSection(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

/// The 3 top-level category cards replacing the old sub-service icon row —
/// side by side above [_wideBreakpoint], stacked below it. No responsive
/// breakpoint system exists elsewhere in this app (every screen here is
/// single-column/mobile-first), so this is a small local LayoutBuilder
/// rather than new app-wide infrastructure; in practice, on the phone
/// widths this app targets, the stacked branch is what actually renders.
class _MainServiceCategories extends StatelessWidget {
  const _MainServiceCategories({required this.onCategoryTap});

  final ValueChanged<String>? onCategoryTap;

  static const _wideBreakpoint = 600.0;
  static const _spacing = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ServiceCategoryCard(
        // Deliberately keeps the original icon+overlay badge (not a custom
        // illustration) — approved and reverted during visual-identity
        // design review. Color moved off the old reserved navy onto
        // AppColors.turquoise so this card reads at the same tier as
        // Ekspertiz/Sigorta below (see AppColors.inspection's doc comment).
        icon: Icons.directions_car_filled,
        overlayIcon: Icons.build,
        title: 'Araç Tamiri',
        subtitle: 'Arızadan bakıma tüm tamir hizmetleri',
        color: AppColors.turquoise,
        onTap: () => onCategoryTap?.call('Araç Tamiri'),
      ),
      ServiceCategoryCard(
        illustration: const EkspertizIllustration(),
        title: 'Ekspertiz',
        subtitle: 'Araç alım, satım ve hasar kontrol hizmetleri',
        color: AppColors.inspection,
        onTap: () => onCategoryTap?.call('Ekspertiz'),
      ),
      // Sigorta: kept in code (route, page, Firestore schema all untouched)
      // but not rendered — see kSigortaEnabled's doc comment. cards' length
      // varies with this, and the layout below is already generic over
      // however many cards it gets, so the remaining 2 lay out correctly
      // with no separate spacing/sizing case needed.
      if (kSigortaEnabled)
        ServiceCategoryCard(
          illustration: const SigortaIllustration(),
          title: 'Sigorta',
          subtitle: 'Trafik, kasko ve tüm sigorta ihtiyaçlarınız',
          color: AppColors.insurance,
          onTap: () => onCategoryTap?.call('Sigorta'),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideBreakpoint) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: _spacing),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: _spacing),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}
