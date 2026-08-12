import 'package:flutter/material.dart';

import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mechanic_detail/detail_action_bar.dart';
import '../../widgets/mechanic_detail/open_status_badge.dart';
import '../../widgets/mechanic_detail/stat_tile.dart';
import '../../widgets/mechanic_detail/verified_badge.dart';
import '../../widgets/trust/trust_info_sheet.dart';
import '../booking/appointment_request_page.dart';
import '../service_listing/reviews_page.dart';

class MechanicDetailPage extends StatelessWidget {
  const MechanicDetailPage({super.key, required this.mechanic});

  final Mechanic mechanic;

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(mechanic.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.car_repair, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              mechanic.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              mechanic.specialty,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (mechanic.isVerified)
                  InkWell(
                    onTap: () => showTrustInfoSheet(
                      context,
                      icon: Icons.verified_rounded,
                      accentColor: Colors.blue[700]!,
                      title: 'Doğrulanmış Servis',
                      description:
                          'Bu işletme, doğrulama sürecimizi başarıyla tamamlamıştır. İşletme bilgileri '
                          'doğrulanmış ve kalite standartlarını korumak amacıyla müşteri geri bildirimleri '
                          'sürekli olarak izlenmektedir.',
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: const VerifiedBadge(),
                  ),
                OpenStatusBadge(isOpen: mechanic.isOpen),
              ],
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReviewsPage(mechanic: mechanic)),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      mechanic.rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${mechanic.reviewCount} değerlendirme)',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.info_outline_rounded, size: 17, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => showTrustInfoSheet(
                      context,
                      icon: Icons.repeat_rounded,
                      accentColor: AppColors.primaryDark,
                      title: 'Tekrar Tercih Oranı',
                      description:
                          'Bu oran, bir önceki ziyaretinden sonra müşterilerin başka bir hizmet için bu '
                          'servis sağlayıcısına tekrar dönme yüzdesini gösterir. Yüksek bir oran, daha '
                          'güçlü bir müşteri memnuniyeti ve güveni olduğunu gösterir.',
                      highlight: 'Müşterilerin %${mechanic.repeatCustomerRate}\'i bu hizmeti tekrar tercih etti.',
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        StatTile(
                          icon: Icons.repeat,
                          label: 'Tekrar Müşteri',
                          value: '%${mechanic.repeatCustomerRate}',
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(icon: Icons.location_on, label: 'Mesafe', value: mechanic.distanceLabel),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(icon: Icons.payments, label: 'Fiyat Aralığı', value: mechanic.priceRangeLabel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              icon: Icons.schedule,
              title: 'Çalışma Saatleri',
              subtitle: mechanic.workingHours,
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.location_on_outlined,
              title: 'Adres',
              subtitle: mechanic.address,
            ),
          ],
        ),
      ),
      bottomNavigationBar: DetailActionBar(
        onCall: () => _showFeedback(context, '${mechanic.phone} aranıyor...'),
        onNavigate: () => _showFeedback(context, 'Yol tarifi açılıyor: ${mechanic.address}'),
        onBook: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AppointmentRequestPage(mechanic: mechanic, serviceLabel: mechanic.specialty),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
