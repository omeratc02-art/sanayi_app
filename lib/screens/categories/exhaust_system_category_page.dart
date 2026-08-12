import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Egzoz Sistemi" category — kept deliberately
/// short (5 core services), matching the other category pages in style
/// but not in count. Reachable only from "Tüm Kategoriler" (see
/// main_shell.dart), since this category doesn't appear in the Home
/// screen's compact teaser row.
class ExhaustSystemCategoryPage extends StatelessWidget {
  const ExhaustSystemCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.search_rounded,
      title: 'Egzoz Arıza Tespiti',
      subtitle: 'Egzoz sistemindeki arızaların profesyonel teşhisi.',
    ),
    (
      icon: Icons.build_outlined,
      title: 'Egzoz Onarımı',
      subtitle: 'Hasarlı egzoz parçalarının onarım hizmeti.',
    ),
    (
      icon: Icons.air,
      title: 'Katalitik Konvertör',
      subtitle: 'Katalitik konvertör kontrol ve değişim hizmeti.',
    ),
    (
      icon: Icons.report_problem_outlined,
      title: 'Egzoz Kaçak Onarımı',
      subtitle: 'Egzoz sistemindeki kaçakların tespiti ve onarımı.',
    ),
    (
      icon: Icons.fact_check_outlined,
      title: 'Emisyon Muayenesi',
      subtitle: 'Egzoz emisyon değerlerinin ölçüm ve kontrolü.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Egzoz Sistemi')),
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
