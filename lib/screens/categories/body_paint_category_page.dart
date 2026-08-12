import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Kaporta & Boya" category — kept deliberately
/// short (5 core services), matching the other category pages in style
/// but not in count. Reachable only from "Tüm Kategoriler" (see
/// main_shell.dart), since this category doesn't appear in the Home
/// screen's compact teaser row.
class BodyPaintCategoryPage extends StatelessWidget {
  const BodyPaintCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.build_outlined,
      title: 'Kaporta Onarımı',
      subtitle: 'Kaza ve hasar sonrası kaporta onarım hizmetleri.',
    ),
    (
      icon: Icons.format_paint,
      title: 'Boya Hizmetleri',
      subtitle: 'Profesyonel araç boyama ve rötuş hizmetleri.',
    ),
    (
      icon: Icons.auto_fix_high,
      title: 'Boyasız Göçük Düzeltme (PDR)',
      subtitle: 'Boya işlemi gerektirmeden göçük düzeltme.',
    ),
    (
      icon: Icons.car_repair,
      title: 'Tampon Onarımı',
      subtitle: 'Hasarlı tamponların onarım ve değişim hizmeti.',
    ),
    (
      icon: Icons.fact_check_outlined,
      title: 'Hasar Tespiti',
      subtitle: 'Araç hasarının detaylı değerlendirilmesi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Kaporta & Boya')),
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
