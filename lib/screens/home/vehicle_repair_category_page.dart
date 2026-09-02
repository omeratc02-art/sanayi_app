import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/categories/category_grid.dart';
import '../../widgets/home/section_header.dart';

/// The "Araç Tamiri" landing page — shows every real sub-service category
/// at once via [CategoryGrid] (the same responsive grid the shared "Tüm
/// Kategoriler" page already used elsewhere), instead of a horizontally
/// truncated strip behind a "Tümünü Gör"/"Tüm Hizmetler" tap-through. 3
/// columns on a phone, more on wider layouts, wrapped in a scroll view so a
/// tall device sees it all with no scrolling and a short one just scrolls
/// naturally — no separate "show all" page needed for this category.
/// onCategoryTap is passed straight through from MainShell — the same
/// dispatch closure that used to go directly to HomeTab, now also covering
/// the categories that were previously only reachable via the old
/// "Tüm Hizmetler" hop (see MainShell._openVehicleRepair).
class VehicleRepairCategoryPage extends StatelessWidget {
  const VehicleRepairCategoryPage({super.key, required this.onCategoryTap});

  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Araç Tamiri')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Hangi hizmete ihtiyacınız var?'),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: CategoryGrid(categories: MockData.allServiceCategories, onCategoryTap: onCategoryTap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
