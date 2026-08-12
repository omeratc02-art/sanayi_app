import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Lastik & Jant" category — kept deliberately short
/// (5 core services), matching [MotorCategoryPage] / [BrakeSystemCategoryPage]
/// / [BatteryElectricalCategoryPage] in style but not in count.
class TireWheelCategoryPage extends StatelessWidget {
  const TireWheelCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.tire_repair,
      title: 'Lastik Değişimi',
      subtitle: 'Aracınız için uygun lastiklerle değişim hizmeti.',
    ),
    (
      icon: Icons.track_changes,
      title: 'Lastik Balansı',
      subtitle: 'Sürüş konforu için lastik balans ayarı.',
    ),
    (
      icon: Icons.adjust,
      title: 'Rot Ayarı',
      subtitle: 'Düzgün sürüş ve lastik ömrü için rot ayarı.',
    ),
    (
      icon: Icons.healing,
      title: 'Lastik Tamiri',
      subtitle: 'Delinme ve hasarlarda lastik tamiri.',
    ),
    (
      icon: Icons.build_circle_outlined,
      title: 'Jant Tamiri',
      subtitle: 'Hasarlı jantların onarım hizmeti.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lastik & Jant')),
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
