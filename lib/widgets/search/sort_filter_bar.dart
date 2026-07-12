import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum SortMode { rating, distance, price }

extension SortModeLabel on SortMode {
  String get label => switch (this) {
    SortMode.rating => 'Puan',
    SortMode.distance => 'Mesafe',
    SortMode.price => 'Fiyat',
  };
}

class SortFilterBar extends StatelessWidget {
  const SortFilterBar({
    super.key,
    required this.sortMode,
    required this.onSortChanged,
    required this.openOnly,
    required this.onOpenOnlyChanged,
  });

  final SortMode sortMode;
  final ValueChanged<SortMode> onSortChanged;
  final bool openOnly;
  final ValueChanged<bool> onOpenOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Icon(Icons.swap_vert, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          for (final mode in SortMode.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterPill(
                label: mode.label,
                selected: sortMode == mode,
                onTap: () => onSortChanged(mode),
              ),
            ),
          const SizedBox(width: 4),
          Container(width: 1, height: 20, color: AppColors.divider),
          const SizedBox(width: 12),
          _FilterPill(
            label: 'Şu an açık',
            selected: openOnly,
            onTap: () => onOpenOnlyChanged(!openOnly),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.red,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? AppColors.red : AppColors.divider),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
    );
  }
}
