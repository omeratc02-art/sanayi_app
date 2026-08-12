import 'package:flutter/material.dart';

import '../../models/category.dart';
import 'category_card.dart';

/// Column count adapts to available width instead of a fixed breakpoint —
/// 3 across on a phone, up to 8 across (all categories in one row) on a
/// wide tablet/web layout. Card height is held to a fixed target regardless
/// of column count (the aspect ratio is derived from it), so cards don't
/// end up needlessly tall on mobile or oddly short on wide layouts.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.categories, required this.onCategoryTap});

  final List<ServiceCategory> categories;
  final ValueChanged<String> onCategoryTap;

  static const _gridSpacing = 12.0;
  static const _targetCardWidth = 150.0;
  static const _targetCardHeight = 120.0;
  static const _minColumns = 3;
  static const _maxColumns = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _targetCardWidth).floor().clamp(_minColumns, _maxColumns);
        final cardWidth = (constraints.maxWidth - _gridSpacing * (columns - 1)) / columns;
        final aspectRatio = cardWidth / _targetCardHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: _gridSpacing,
            crossAxisSpacing: _gridSpacing,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(category: category, onTap: () => onCategoryTap(category.label));
          },
        );
      },
    );
  }
}
