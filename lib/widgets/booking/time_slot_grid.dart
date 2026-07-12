import 'package:flutter/material.dart';

import '../../models/time_slot.dart';
import '../../theme/app_theme.dart';

class TimeSlotGrid extends StatelessWidget {
  const TimeSlotGrid({super.key, required this.slots, required this.selected, required this.onSelected});

  final List<TimeSlot> slots;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: slots.map((slot) {
        final isSelected = selected == slot.label;
        return InkWell(
          onTap: slot.isAvailable ? () => onSelected(slot.label) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 74,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: !slot.isAvailable
                  ? AppColors.divider.withValues(alpha: 0.4)
                  : (isSelected ? AppColors.red : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.red : AppColors.divider),
            ),
            child: Text(
              slot.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: slot.isAvailable ? null : TextDecoration.lineThrough,
                color: !slot.isAvailable
                    ? AppColors.textSecondary
                    : (isSelected ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
