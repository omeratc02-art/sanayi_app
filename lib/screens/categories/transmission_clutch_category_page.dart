import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Şanzıman ve Debriyaj" category — kept
/// deliberately short (5 core services), matching [MotorCategoryPage] /
/// [BrakeSystemCategoryPage] / [BatteryElectricalCategoryPage] /
/// [TireWheelCategoryPage] / [AcClimateCategoryPage] in style but not in
/// count. Reachable only from "Tüm Kategoriler" (see main_shell.dart), since
/// this category doesn't appear in the Home screen's compact teaser row.
class TransmissionClutchCategoryPage extends StatelessWidget {
  const TransmissionClutchCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.search_rounded,
      title: 'Şanzıman Arıza Tespiti',
      subtitle: 'Şanzıman arızalarının profesyonel teşhisi.',
    ),
    (
      icon: Icons.auto_mode,
      title: 'Otomatik Şanzıman',
      subtitle: 'Otomatik şanzıman bakım ve onarım hizmetleri.',
    ),
    (
      icon: Icons.pan_tool_outlined,
      title: 'Manuel Şanzıman',
      subtitle: 'Manuel şanzıman bakım ve onarım hizmetleri.',
    ),
    (
      icon: Icons.build_outlined,
      title: 'Debriyaj Tamiri & Değişimi',
      subtitle: 'Debriyaj setinin tamiri veya değişimi.',
    ),
    (
      icon: Icons.oil_barrel,
      title: 'Şanzıman Yağı Değişimi',
      subtitle: 'Manuel ve otomatik şanzımanlar için yağ değişim hizmeti.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Şanzıman ve Debriyaj')),
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
