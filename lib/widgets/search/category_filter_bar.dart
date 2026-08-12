import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({super.key, required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <String?>[null, ...MockData.categories.map((c) => c.label)];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = items[index];
          final isSelected = selected == value;
          return ChoiceChip(
            label: Text(value ?? 'Tümü'),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(value),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          );
        },
      ),
    );
  }
}
