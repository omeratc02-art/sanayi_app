import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class EmptySearchState extends StatelessWidget {
  const EmptySearchState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.divider, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded, size: 30, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Sonuç bulunamadı', style: AppTextStyles.cardTitle),
            const SizedBox(height: 4),
            const Text(
              'Farklı bir kategori veya arama terimi deneyin.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
      ),
    );
  }
}
