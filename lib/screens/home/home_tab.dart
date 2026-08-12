import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/categories/category_list.dart';
import '../../widgets/home/emergency_help_card.dart';
import '../../widgets/home/greeting_bar.dart';
import '../../widgets/home/hero_emergency_cluster.dart';
import '../../widgets/home/my_vehicles_section.dart';
import '../../widgets/home/premium_hero_header.dart';
import '../../widgets/home/section_header.dart';
import '../notifications/notifications_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, this.userName, this.onCategoryTap, this.onSeeAllCategories});

  /// Null means guest — see [GreetingBar.userName].
  final String? userName;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onSeeAllCategories;

  static const _clusterSpacing = AppSpacing.lg;
  static const _headerToContentSpacing = AppSpacing.md;
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
          // 2. "Hangi hizmete ihtiyacınız var?"
          SliverToBoxAdapter(
            child: Padding(
              padding: _sectionPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Hangi hizmete ihtiyacınız var?', onSeeAll: onSeeAllCategories),
                  const SizedBox(height: _headerToContentSpacing),
                  CategoryList(
                    categories: MockData.categories,
                    onCategoryTap: (label) => onCategoryTap?.call(label),
                  ),
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
