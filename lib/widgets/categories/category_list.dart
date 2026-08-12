import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../theme/app_theme.dart';
import 'category_card.dart';

/// Horizontally scrolling row of category tiles for the Home screen (as
/// opposed to [CategoryGrid], which lays every category out in a fixed grid
/// for the "all categories" page). Built with a plain [Row] inside a
/// [SingleChildScrollView] rather than a lazy `ListView.builder` — with only
/// 8 static categories there's no lazy-build benefit, and eager building
/// keeps every tile in the widget tree regardless of scroll position.
class CategoryList extends StatelessWidget {
  const CategoryList({super.key, required this.categories, required this.onCategoryTap, this.padding});

  final List<ServiceCategory> categories;
  final ValueChanged<String> onCategoryTap;
  final EdgeInsets? padding;

  static const _tileWidth = 108.0;
  static const _tileHeight = 118.0;
  static const _spacing = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tileHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: [
            for (var i = 0; i < categories.length; i++) ...[
              if (i > 0) const SizedBox(width: _spacing),
              SizedBox(
                width: _tileWidth,
                child: CategoryCard(category: categories[i], onTap: () => onCategoryTap(categories[i].label)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
