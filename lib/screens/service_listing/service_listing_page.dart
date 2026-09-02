import 'package:flutter/material.dart';

import '../../data/mechanic_directory_repository.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../widgets/service_listing/service_center_card.dart';

/// Shared destination for every "service selection complete" moment in the
/// app — reached from any category's service cards (Motor, Fren Sistemi,
/// Yağ Değişimi, etc.) across all three top-level categories (Araç Tamiri,
/// Ekspertiz, Sigorta) alike. Shows every real mechanicAccounts business
/// under [hizmetTuru] (mirrors the Firestore field `hizmetTürü`), sorted by
/// [Mechanic.trustScore] so the most trustworthy option is always first —
/// same "show everyone in scope, unfiltered by the exact sub-service
/// tapped" behavior this page always had, just backed by Firestore instead
/// of MockData now.
class ServiceListingPage extends StatefulWidget {
  const ServiceListingPage({super.key, required this.serviceName, required this.hizmetTuru});

  final String serviceName;
  final String hizmetTuru;

  @override
  State<ServiceListingPage> createState() => _ServiceListingPageState();
}

class _ServiceListingPageState extends State<ServiceListingPage> {
  late final Future<List<Mechanic>> _future;

  @override
  void initState() {
    super.initState();
    _future = MechanicDirectoryRepository().fetchByHizmetTuru(widget.hizmetTuru);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.serviceName)),
      body: FutureBuilder<List<Mechanic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final serviceCenters = [...?snapshot.data]..sort((a, b) => b.trustScore.compareTo(a.trustScore));
          if (serviceCenters.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Bu kategoride henüz kayıtlı servis sağlayıcı yok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: serviceCenters.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) =>
                ServiceCenterCard(mechanic: serviceCenters[index], serviceName: widget.serviceName),
          );
        },
      ),
    );
  }
}
