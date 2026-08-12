import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Klima" category — kept deliberately short (5 core
/// services), matching [MotorCategoryPage] / [BrakeSystemCategoryPage] /
/// [BatteryElectricalCategoryPage] / [TireWheelCategoryPage] in style but
/// not in count.
class AcClimateCategoryPage extends StatelessWidget {
  const AcClimateCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.ac_unit,
      title: 'Klima Gazı Dolumu',
      subtitle: 'Serinletme performansı için klima gazı dolumu.',
    ),
    (
      icon: Icons.cleaning_services,
      title: 'Klima Temizliği & Bakımı',
      subtitle: 'Hijyen ve verimlilik için klima temizliği ve bakımı.',
    ),
    (
      icon: Icons.settings_outlined,
      title: 'Klima Kompresörü Onarımı',
      subtitle: 'Klima kompresörünün arıza tespiti ve onarımı.',
    ),
    (
      icon: Icons.search_rounded,
      title: 'Klima Arıza Tespiti',
      subtitle: 'Klima sistemindeki arızaların profesyonel teşhisi.',
    ),
    (
      icon: Icons.whatshot,
      title: 'Kalorifer Sistemi',
      subtitle: 'Kalorifer ve ısıtma sisteminin kontrolü ve onarımı.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Klima')),
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
