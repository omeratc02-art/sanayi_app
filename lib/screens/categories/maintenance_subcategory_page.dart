import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Periyodik Bakım" category — exactly two
/// top-level maintenance groupings. Deliberately no pricing, checklists or
/// action buttons here: each card is just an entry point into its own
/// dedicated detail page.
class MaintenanceSubcategoryPage extends StatelessWidget {
  const MaintenanceSubcategoryPage({
    super.key,
    required this.onRoutineMaintenanceSelected,
    required this.onMajorMaintenanceSelected,
  });

  final VoidCallback onRoutineMaintenanceSelected;
  final VoidCallback onMajorMaintenanceSelected;

  static const _cardSpacing = AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Periyodik Bakım')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          ServiceEntryCard(
            icon: Icons.build_circle_outlined,
            title: '10.000–20.000 km Bakımı',
            subtitle: 'Rutin periyodik bakım hizmetleri.',
            onTap: onRoutineMaintenanceSelected,
          ),
          const SizedBox(height: _cardSpacing),
          ServiceEntryCard(
            icon: Icons.construction_outlined,
            title: 'Ağır Bakım',
            subtitle: 'Kapsamlı bakım ve kritik parça değişim işlemleri.',
            onTap: onMajorMaintenanceSelected,
          ),
        ],
      ),
    );
  }
}
