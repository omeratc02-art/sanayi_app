import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Akü & Elektrik" category — kept deliberately short
/// (5 core services) rather than a long subcategory list, matching
/// [OilChangeCategoryPage] / [BrakeSystemCategoryPage] / [MotorCategoryPage]
/// in style but not in count.
class BatteryElectricalCategoryPage extends StatelessWidget {
  const BatteryElectricalCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.battery_charging_full,
      title: 'Akü Değişimi',
      subtitle: 'Aracınız için uygun akü ile değişim hizmeti.',
    ),
    (
      icon: Icons.electrical_services,
      title: 'Marş & Şarj Sistemi',
      subtitle: 'Marş motoru ve şarj sistemi arıza tespiti ve onarımı.',
    ),
    (
      icon: Icons.search_rounded,
      title: 'Elektrik Arıza Tespiti',
      subtitle: 'Elektrik arızalarının profesyonel teşhisi.',
    ),
    (
      icon: Icons.lightbulb_outline,
      title: 'Aydınlatma & Elektrik Aksamı',
      subtitle: 'Far, sinyal ve elektrik aksamı kontrolü ve onarımı.',
    ),
    (
      icon: Icons.memory,
      title: 'OBD Arıza Tespiti',
      subtitle: 'Bilgisayarlı arıza tarama ve teşhis hizmeti.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Akü & Elektrik')),
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
