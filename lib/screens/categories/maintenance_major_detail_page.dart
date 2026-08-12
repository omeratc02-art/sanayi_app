import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/maintenance_detail_sections.dart';
import '../service_listing/service_listing_page.dart';

/// Detail page for the "Ağır Bakım" card.
class MaintenanceMajorDetailPage extends StatelessWidget {
  const MaintenanceMajorDetailPage({super.key});

  static const _serviceName = 'Ağır Bakım';

  static const _partsReplacement = [
    'Motor yağı',
    'Yağ filtresi',
    'Hava filtresi',
    'Polen (kabin) filtresi',
    'Yakıt filtresi',
    'Triger kayışı seti',
    'Devirdaim (su pompası)',
    'Şanzıman yağı',
    'Fren hidroliği',
    'Motor soğutma suyu (antifriz)',
  ];

  static const _inspections = [
    'Fren sistemi',
    'Direksiyon sistemi',
    'Süspansiyon ve alt takım',
    'Klima sistemi',
    'Akü sağlık testi',
    'Genel arıza tarama (diagnostik kontrol)',
  ];

  static const _informationText =
      'Ağır bakım işlemleri, aracın markasına, modeline, kilometresine ve üretici bakım programına göre '
      'değişiklik gösterebilir.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(_serviceName)),
      body: const MaintenanceDetailSections(
        partsReplacement: _partsReplacement,
        inspections: _inspections,
        informationText: _informationText,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ServiceListingPage(serviceName: _serviceName)),
                ),
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('Yakındaki Servisleri Gör'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
