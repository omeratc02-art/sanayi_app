import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Süspansiyon & Direksiyon" category — kept
/// deliberately short (5 core services), matching [MotorCategoryPage] /
/// [BrakeSystemCategoryPage] / [BatteryElectricalCategoryPage] /
/// [TireWheelCategoryPage] / [AcClimateCategoryPage] / [TransmissionClutchCategoryPage]
/// in style but not in count. Reachable only from "Tüm Kategoriler" (see
/// main_shell.dart), since this category doesn't appear in the Home
/// screen's compact teaser row.
class SuspensionSteeringCategoryPage extends StatelessWidget {
  const SuspensionSteeringCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.height,
      title: 'Ön Süspansiyon Kontrolü',
      subtitle: 'Ön süspansiyon sisteminin detaylı kontrolü.',
    ),
    (
      icon: Icons.compress,
      title: 'Amortisör & Yay Değişimi',
      subtitle: 'Aşınmış amortisör ve yayların değişimi.',
    ),
    (
      icon: Icons.tune,
      title: 'Direksiyon Sistemi',
      subtitle: 'Direksiyon sisteminin bakım ve onarım hizmetleri.',
    ),
    (
      icon: Icons.link,
      title: 'Rot Başı, Salıncak & Stabilizer Bağlantıları',
      subtitle: 'Rot başı, salıncak ve stabilizer bağlantılarının onarımı.',
    ),
    (
      icon: Icons.search_rounded,
      title: 'Süspansiyon Arıza Tespiti',
      subtitle: 'Süspansiyon arızalarının profesyonel teşhisi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Süspansiyon & Direksiyon')),
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
