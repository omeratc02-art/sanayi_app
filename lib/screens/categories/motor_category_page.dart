import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Motor" category — a flat list of the specific
/// engine services, each its own entry point into a dedicated detail page.
/// No pricing or actions here, matching [OilChangeCategoryPage] /
/// [BrakeSystemCategoryPage].
class MotorCategoryPage extends StatelessWidget {
  const MotorCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.search_rounded,
      title: 'Motor Arıza Tespiti',
      subtitle: 'Motor arızalarının ve uyarı lambalarının profesyonel teşhisi.',
    ),
    (
      icon: Icons.build_outlined,
      title: 'Motor Mekanik Onarımı',
      subtitle: 'Motor iç aksamının onarımı ve bakımı.',
    ),
    (
      icon: Icons.speed,
      title: 'Turbo Sistemi',
      subtitle: 'Turbo şarj sisteminin teşhis, onarım ve değişim hizmetleri.',
    ),
    (
      icon: Icons.ac_unit,
      title: 'Soğutma Sistemi',
      subtitle: 'Soğutma sistemi kontrolü, onarımı ve bakımı.',
    ),
    (
      icon: Icons.local_gas_station,
      title: 'Yakıt Sistemi',
      subtitle: 'Yakıt sistemi teşhis, onarım ve bakım hizmetleri.',
    ),
    (
      icon: Icons.air,
      title: 'Emme & Egzoz Sistemi',
      subtitle: 'Emme ve egzoz sisteminin kontrolü ve onarımı.',
    ),
    (
      icon: Icons.link,
      title: 'Triger & Kayış Sistemi',
      subtitle: 'Triger kayışı, aksesuar kayışı ve ilgili parça hizmetleri.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Motor')),
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
