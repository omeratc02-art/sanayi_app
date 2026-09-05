import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Periyodik Bakım" category — a flat list of the 2
/// real maintenance groupings, matching every other vehicle-repair category
/// (e.g. [TireWheelCategoryPage]) in style and in behavior: one tap on
/// either entry goes straight to ServiceListingPage via onServiceSelected,
/// with no detail/checklist page in between. Replaces the previous 3-screen
/// flow (a subcategory picker, then a separate informational parts/
/// inspection-checklist page per entry, with the "Yakındaki Servisleri
/// Gör" button buried at the bottom of that) — "10.000–20.000 km Bakımı"
/// vs "Ağır Bakım" is still a real choice the customer should make, it's
/// just used as the serviceName label from here on, same as any other
/// category's specific service.
class PeriodicMaintenanceCategoryPage extends StatelessWidget {
  const PeriodicMaintenanceCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.build_circle_outlined,
      title: '10.000–20.000 km Bakımı',
      subtitle: 'Rutin periyodik bakım hizmetleri.',
    ),
    (
      icon: Icons.construction_outlined,
      title: 'Ağır Bakım',
      subtitle: 'Kapsamlı bakım ve kritik parça değişim işlemleri.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Periyodik Bakım')),
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
