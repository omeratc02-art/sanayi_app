import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/categories/maintenance_detail_sections.dart';
import '../service_listing/service_listing_page.dart';

/// Detail page for the "10.000–20.000 km Bakımı" card.
class MaintenanceRoutineDetailPage extends StatelessWidget {
  const MaintenanceRoutineDetailPage({super.key});

  static const _serviceName = '10.000–20.000 km Bakımı';

  static const _partsReplacement = [
    'Motor yağı',
    'Yağ filtresi',
    'Hava filtresi',
    'Polen (kabin) filtresi',
    'Yakıt filtresi',
  ];

  static const _inspections = [
    'Fren balata ve diskleri',
    'Lastik rotasyonu ve diş derinliği',
    'Lastik basıncı',
    'Akü kontrolü',
    'Motor soğutma suyu kontrolü',
    'Fren hidroliği kontrolü',
    'Direksiyon ve süspansiyon kontrolü',
    'Aydınlatma sistemi kontrolü',
    'Silecek lastikleri ve cam suyu kontrolü',
    'Genel arıza tarama (diagnostik kontrol)',
  ];

  static const _informationText =
      'Bakım işlemleri, aracın markasına, modeline, motor tipine ve üretici bakım programına göre '
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
