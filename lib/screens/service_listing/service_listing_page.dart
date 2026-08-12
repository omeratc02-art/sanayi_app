import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/service_listing/service_center_card.dart';

/// Shared destination for every "service selection complete" moment in the
/// app — reached from any category's service cards (Motor, Fren Sistemi,
/// Yağ Değişimi, etc.) and from the Periodic Maintenance detail pages
/// alike. Shows every service center sorted by [Mechanic.trustScore] so the
/// most trustworthy option is always first.
class ServiceListingPage extends StatelessWidget {
  const ServiceListingPage({super.key, required this.serviceName});

  final String serviceName;

  @override
  Widget build(BuildContext context) {
    final serviceCenters = [...MockData.allMechanics]
      ..sort((a, b) => b.trustScore.compareTo(a.trustScore));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(serviceName)),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: serviceCenters.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) => ServiceCenterCard(mechanic: serviceCenters[index]),
      ),
    );
  }
}
