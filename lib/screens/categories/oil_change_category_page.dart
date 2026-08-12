import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Yağ Değişimi" category — a flat list of the
/// specific oil-change services, each its own entry point into a dedicated
/// detail page. No pricing or actions here, matching [MaintenanceSubcategoryPage].
class OilChangeCategoryPage extends StatelessWidget {
  const OilChangeCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.oil_barrel,
      title: 'Motor Yağı Değişimi',
      subtitle: 'Üretici onaylı yağlarla profesyonel motor yağı değişimi.',
    ),
    (
      icon: Icons.sync_alt,
      title: 'Şanzıman Yağı Değişimi',
      subtitle: 'Manuel ve otomatik şanzımanlar için şanzıman yağı değişim hizmeti.',
    ),
    (
      icon: Icons.album,
      title: 'Fren Hidroliği Değişimi',
      subtitle: 'Güvenli ve güvenilir fren performansı için fren hidroliği değişimi.',
    ),
    (
      icon: Icons.tune,
      title: 'Direksiyon Hidrolik Yağı Değişimi',
      subtitle: 'Hidrolik direksiyon sistemine sahip araçlar için direksiyon yağı değişimi.',
    ),
    (
      icon: Icons.settings,
      title: 'Diferansiyel Yağı Değişimi',
      subtitle: 'Periyodik diferansiyel bakımı gerektiren araçlar için diferansiyel yağı değişimi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Yağ Değişimi')),
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
