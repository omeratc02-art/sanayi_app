import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/category_item.dart';
import '../../widgets/home/popular_mechanic_card.dart';
import '../../widgets/home/problem_search_field.dart';
import '../../widgets/home/section_header.dart';
import '../../widgets/home/top_rated_mechanic_tile.dart';
import '../mechanic_detail/mechanic_detail_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    this.onSearchTap,
    this.onCategoryTap,
    this.onSeeAllPopular,
    this.onSeeAllTopRated,
  });

  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onCategoryTap;
  final VoidCallback? onSeeAllPopular;
  final VoidCallback? onSeeAllTopRated;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Merhaba 👋',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aracınıza ne oldu?',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none, color: AppColors.red),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: ProblemSearchField(onTap: onSearchTap),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Kategoriler'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: MockData.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => CategoryItem(
                        category: MockData.categories[index],
                        onTap: () => onCategoryTap?.call(MockData.categories[index].label),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: 'Popüler Ustalar', onSeeAll: onSeeAllPopular),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 190,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: MockData.popularMechanics.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => PopularMechanicCard(
                        mechanic: MockData.popularMechanics[index],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MechanicDetailPage(mechanic: MockData.popularMechanics[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: SectionHeader(title: 'En Yüksek Puanlılar', onSeeAll: onSeeAllTopRated),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            sliver: SliverList.builder(
              itemCount: MockData.topRatedMechanics.length,
              itemBuilder: (context, index) => TopRatedMechanicTile(
                mechanic: MockData.topRatedMechanics[index],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MechanicDetailPage(mechanic: MockData.topRatedMechanics[index]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
