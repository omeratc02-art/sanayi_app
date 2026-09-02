import 'package:flutter/material.dart';

import '../../mechanic/appointments/data/appointment_repository.dart';
import '../../mechanic/profile/data/mechanic_profile_repository.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../../widgets/mechanic_detail/detail_action_bar.dart';
import '../../widgets/mechanic_detail/open_status_badge.dart';
import '../../widgets/mechanic_detail/stat_tile.dart';
import '../../widgets/mechanic_detail/verified_badge.dart';
import '../../widgets/trust/trust_info_sheet.dart';
import '../../widgets/verified_jobs_badge.dart';
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
              mechanic.specialtyLabel,
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
                // Omitted entirely when isOpen is null (no working hours
                // entered yet) — unknown, not a default "closed".
                if (mechanic.isOpen != null) OpenStatusBadge(isOpen: mechanic.isOpen!),
                VerifiedJobsBadge(mechanicId: mechanicChatId(mechanic.name)),
              ],
            ),
            const SizedBox(height: 20),
            _RatingSummaryRow(mechanic: mechanic),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _RepeatCustomerRateTile(mechanic: mechanic)),
                const SizedBox(width: 12),
                // No distance tile: real mechanicAccounts have no real
                // geolocation data yet (see Mechanic.distanceLabel).
                Expanded(
                  child: StatTile(icon: Icons.payments, label: 'Fiyat Aralığı', value: mechanic.priceRangeLabel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              icon: Icons.schedule,
              title: 'Çalışma Saatleri',
              subtitle: mechanic.workingHoursLabel,
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
            builder: (_) => AppointmentRequestPage(mechanic: mechanic, serviceLabel: mechanic.specialtyLabel),
          ),
        ),
      ),
    );
  }
}

class _RatingSummaryRow extends StatelessWidget {
  const _RatingSummaryRow({required this.mechanic});

  final Mechanic mechanic;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({double averageRating, int ratedCount})>(
      future: AppointmentRepository().fetchRatingSummary(mechanicChatId(mechanic.name)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final summary = snapshot.data;
        final hasRatings = !snapshot.hasError && summary != null && summary.ratedCount > 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: !hasRatings
              ? const Text(
                  'Henüz değerlendirme yok',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                )
              : InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ReviewsPage(mechanic: mechanic)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        summary.averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${summary.ratedCount} değerlendirme)',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.info_outline_rounded, size: 17, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

/// A fixed-position StatTile in the 3-column stats Row (alongside Distance
/// and Price, which are synchronous), so unlike [_RatingSummaryRow] this
/// keeps the same StatTile container visible throughout — collapsing to
/// SizedBox.shrink() while loading would leave a blank gap next to the two
/// already-populated sibling tiles.
class _RepeatCustomerRateTile extends StatelessWidget {
  const _RepeatCustomerRateTile({required this.mechanic});

  final Mechanic mechanic;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int?>(
      future: MechanicProfileRepository().fetchRepeatCustomerRate(mechanicChatId(mechanic.name)),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final rate = snapshot.hasError ? null : snapshot.data;
        final valueLabel = isLoading ? '...' : (rate == null ? '—' : '%$rate');
        return InkWell(
          onTap: rate == null
              ? null
              : () => showTrustInfoSheet(
                    context,
                    icon: Icons.repeat_rounded,
                    accentColor: AppColors.primaryDark,
                    title: 'Tekrar Tercih Oranı',
                    description:
                        'Bu oran, bir önceki ziyaretinden sonra müşterilerin başka bir hizmet için bu '
                        'servis sağlayıcısına tekrar dönme yüzdesini gösterir. Yüksek bir oran, daha '
                        'güçlü bir müşteri memnuniyeti ve güveni olduğunu gösterir.',
                    highlight: 'Müşterilerin %$rate\'i bu hizmeti tekrar tercih etti.',
                  ),
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              StatTile(icon: Icons.repeat, label: 'Tekrar Müşteri', value: valueLabel),
              if (rate != null)
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
        );
      },
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
