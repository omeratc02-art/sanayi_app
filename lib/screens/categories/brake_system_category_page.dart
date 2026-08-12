import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Fren Sistemi" category — a flat list of the
/// specific brake services, each its own entry point into a dedicated
/// detail page. No pricing or actions here, matching [OilChangeCategoryPage].
class BrakeSystemCategoryPage extends StatelessWidget {
  const BrakeSystemCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.layers_outlined,
      title: 'Fren Balatası Değişimi',
      subtitle: 'Güvenli ve güvenilir fren performansı için aşınmış fren balatalarının değişimi.',
    ),
    (
      icon: Icons.album,
      title: 'Fren Diski Değişimi',
      subtitle: 'Hasarlı veya aşınmış fren disklerinin değişimi.',
    ),
    (
      icon: Icons.opacity,
      title: 'Fren Hidroliği Değişimi',
      subtitle: 'Optimal fren performansı için fren hidroliği değişimi.',
    ),
    (
      icon: Icons.settings_outlined,
      title: 'Fren Merkezi Tamiri / Değişimi',
      subtitle: 'Gerektiğinde fren merkezinin tamiri veya değişimi.',
    ),
    (
      icon: Icons.handyman_outlined,
      title: 'Kaliper Tamiri / Revizyonu',
      subtitle: 'Doğru fren çalışması için kaliperlerin tamiri veya revizyonu.',
    ),
    (
      icon: Icons.report_problem_outlined,
      title: 'ABS Arıza Tespiti ve Onarımı',
      subtitle: 'ABS sistemi arızalarının tespiti ve onarımı.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Fren Sistemi')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: _services.length,
        separatorBuilder: (_, _) => const SizedBox(height: _cardSpacing),
        itemBuilder: (context, index) {
          final service = _services[index];
          return ServiceEntryCard(
            icon: service.icon,
            title: service.title,
            subtitle: service.subtitle,
            onTap: () => onServiceSelected(service.title),
          );
        },
      ),
    );
  }
}
