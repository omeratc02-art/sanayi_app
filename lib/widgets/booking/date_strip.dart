import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/turkish_date.dart';

class DateStrip extends StatelessWidget {
  const DateStrip({super.key, required this.dates, required this.selected, required this.onSelected});

  final List<DateTime> dates;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = dates.isEmpty ? null : dates.first;

    return SizedBox(
      height: 68,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = selected != null && isSameDay(selected!, date);
          final isToday = today != null && isSameDay(today, date);

          return InkWell(
            onTap: () => onSelected(date),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 58,
              height: 68,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'Bugün' : weekdayShort(date),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
