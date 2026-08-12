import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/service_entry_card.dart';

/// Landing page for the "Cam & Aydınlatma" category — kept deliberately
/// short (5 core services), matching the other category pages in style
/// but not in count. Reachable only from "Tüm Kategoriler" (see
/// main_shell.dart), since this category doesn't appear in the Home
/// screen's compact teaser row.
class GlassLightingCategoryPage extends StatelessWidget {
  const GlassLightingCategoryPage({super.key, required this.onServiceSelected});

  final ValueChanged<String> onServiceSelected;

  static const _cardSpacing = AppSpacing.md;

  static const _services = [
    (
      icon: Icons.window,
      title: 'Ön Cam & Cam Değişimi',
      subtitle: 'Çatlak veya kırık camların değişim hizmeti.',
    ),
    (
      icon: Icons.healing,
      title: 'Cam Tamiri',
      subtitle: 'Küçük çatlak ve hasarlarda cam tamiri.',
    ),
    (
      icon: Icons.lightbulb_outline,
      title: 'Far & Stop Lambaları',
      subtitle: 'Far ve stop lambalarının onarım ve değişimi.',
    ),
    (
      icon: Icons.auto_fix_high,
      title: 'Far Parlatma',
      subtitle: 'Matlaşmış farların parlatma ve yenileme hizmeti.',
    ),
    (
      icon: Icons.wb_sunny_outlined,
      title: 'Sunroof (Cam Tavan) Onarımı',
      subtitle: 'Cam tavan mekanizmasının onarım hizmeti.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Cam & Aydınlatma')),
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
