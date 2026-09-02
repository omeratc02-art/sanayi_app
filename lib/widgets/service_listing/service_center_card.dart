import 'package:flutter/material.dart';

import '../../models/mechanic.dart';
import '../../screens/appointments/customer_conversation_page.dart';
import '../../screens/booking/appointment_request_page.dart';
import '../../screens/service_listing/reviews_page.dart';
import '../../mechanic/appointments/data/appointment_repository.dart';
import '../../mechanic/profile/data/mechanic_profile_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../common/premium_surface.dart';
import '../trust/trust_info_sheet.dart';
import '../verified_jobs_badge.dart';

/// Premium horizontal service-center card for the shared Service Listing
/// screen — a shop photo (placeholder illustration, no real asset exists)
/// on the left, business identity and trust signals on the right, and two
/// full-width primary actions below. Price is deliberately not shown here.
///
/// No trust-score badge: it used to show a hand-weighted formula that
/// wasn't backed by any real metric, overstating its authority next to
/// the real Firestore-backed signals below (rating, repeat-customer rate,
/// verification). ServiceListingPage now sorts results by real rating
/// data instead, so nothing on this card depends on that formula any
/// more.
class ServiceCenterCard extends StatelessWidget {
  const ServiceCenterCard({super.key, required this.mechanic, required this.serviceName});

  final Mechanic mechanic;

  /// The specific service the customer picked upstream (e.g. "Fren
  /// Balatası Değişimi", from ServiceListingPage's own serviceName — see
  /// BrakeSystemCategoryPage and friends) — passed to AppointmentRequestPage
  /// so the actual requested service is booked, not the mechanic's general
  /// specialty label shown elsewhere on this card.
  final String serviceName;

  static const _actionsPadding = EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm + 2, AppSpacing.lg, AppSpacing.lg);
  static const _buttonSpacing = AppSpacing.sm + 2;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ShopPhoto(mechanic: mechanic),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _CenterInfo(mechanic: mechanic),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 0, AppSpacing.sm + 2),
            child: Row(
              children: [
                SizedBox(
                  width: _ShopPhoto._width,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      mechanic.specialtyLabel,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: _actionsPadding,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerConversationPage(
                          chatId: mechanicChatId(mechanic.name),
                          mechanicName: mechanic.name,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                    label: const Text('Ustaya Sor'),
                  ),
                ),
                const SizedBox(width: _buttonSpacing),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppointmentRequestPage(mechanic: mechanic, serviceLabel: serviceName),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month_outlined, size: 17),
                    label: const Text('Randevu Al'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Left-hand photo panel — fixed width, stretched to match the info
/// column's natural height via the parent [IntrinsicHeight] + stretch.
/// Uses picsum.photos (a standard placeholder-photo CDN, no API key
/// needed) seeded per shop name so each card gets a distinct, stable photo
/// — no real shop photography exists to embed, so this is the closest
/// available substitute for "a real photo" rather than an icon illustration.
class _ShopPhoto extends StatelessWidget {
  const _ShopPhoto({required this.mechanic});

  final Mechanic mechanic;

  static const _width = 118.0;

  String get _photoUrl => 'https://picsum.photos/seed/${Uri.encodeComponent(mechanic.name)}/300/300';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppRadius.lg),
        bottomLeft: Radius.circular(AppRadius.lg),
      ),
      child: SizedBox(
        width: _width,
        child: Image.network(
          _photoUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null ? child : const _ShopPhotoFallback(),
          errorBuilder: (context, error, stackTrace) => const _ShopPhotoFallback(),
        ),
      ),
    );
  }
}

/// Shown while the real photo loads, or if it fails to load at all.
class _ShopPhotoFallback extends StatelessWidget {
  const _ShopPhotoFallback();

  static const _gradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _gradient),
      child: const Align(
        alignment: Alignment(0, 0.65),
        child: Icon(Icons.storefront_rounded, size: 34, color: Colors.white70),
      ),
    );
  }
}

/// Right-hand identity + trust column — name, specialty, location, then
/// exactly the three requested trust signals (rating, repeat rate,
/// verification) as compact chips. No price here by design.
class _CenterInfo extends StatelessWidget {
  const _CenterInfo({required this.mechanic});

  final Mechanic mechanic;

  // No distance suffix: real mechanicAccounts have no real geolocation data
  // yet (see Mechanic.distanceLabel) — showing just the city avoids
  // presenting a fabricated distance as real.
  String get _locationLabel {
    final segments = mechanic.address.split(',');
    return segments.last.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // No sibling to share the row with any more (the trust-score
        // badge that used to sit here is gone), so the name gets the
        // full available width instead of a flex share of it.
        Text(
          mechanic.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Expanded(
              child: Text(
                _locationLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FutureBuilder<({double averageRating, int ratedCount})>(
          future: AppointmentRepository().fetchRatingSummary(mechanicChatId(mechanic.name)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            final summary = snapshot.data;
            if (snapshot.hasError || summary == null || summary.ratedCount == 0) {
              return const _TrustChip(
                icon: Icons.star_border_rounded,
                color: AppColors.textSecondary,
                label: 'Henüz değerlendirme yok',
              );
            }
            return InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReviewsPage(mechanic: mechanic)),
              ),
              borderRadius: BorderRadius.circular(20),
              child: _TrustChip(
                icon: Icons.star_rounded,
                color: AppColors.rating,
                label: '${summary.averageRating.toStringAsFixed(1)} (${summary.ratedCount} değerlendirme)',
              ),
            );
          },
        ),
        const SizedBox(height: 11),
        FutureBuilder<int?>(
          future: MechanicProfileRepository().fetchRepeatCustomerRate(mechanicChatId(mechanic.name)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }
            final rate = snapshot.hasError ? null : snapshot.data;
            if (rate == null) {
              return const _TrustChip(
                icon: Icons.repeat_rounded,
                color: AppColors.textSecondary,
                label: 'Tekrar tercih verisi yok',
              );
            }
            return InkWell(
              onTap: () => showTrustInfoSheet(
                context,
                icon: Icons.repeat_rounded,
                accentColor: AppColors.primaryDark,
                title: 'Tekrar Tercih Oranı',
                description:
                    'Bu oran, bir önceki ziyaretinden sonra müşterilerin başka bir hizmet için bu servis '
                    'sağlayıcısına tekrar dönme yüzdesini gösterir. Yüksek bir oran, daha güçlü bir müşteri '
                    'memnuniyeti ve güveni olduğunu gösterir.',
                highlight: 'Müşterilerin %$rate\'i bu hizmeti tekrar tercih etti.',
              ),
              borderRadius: BorderRadius.circular(20),
              child: _TrustChip(
                icon: Icons.repeat_rounded,
                color: AppColors.primaryDark,
                label: '%$rate Tekrar Tercih',
              ),
            );
          },
        ),
        const SizedBox(height: 11),
        InkWell(
          onTap: () => showTrustInfoSheet(
            context,
            icon: mechanic.isVerified ? Icons.verified_rounded : Icons.remove_circle_outline_rounded,
            accentColor: mechanic.isVerified ? AppColors.verified : AppColors.textSecondary,
            title: 'Doğrulanmış Servis',
            description:
                'Bu işletme, doğrulama sürecimizi başarıyla tamamlamıştır. İşletme bilgileri doğrulanmış '
                've kalite standartlarını korumak amacıyla müşteri geri bildirimleri sürekli olarak '
                'izlenmektedir.',
          ),
          borderRadius: BorderRadius.circular(20),
          child: _TrustChip(
            icon: mechanic.isVerified ? Icons.verified_rounded : Icons.remove_circle_outline_rounded,
            color: mechanic.isVerified ? AppColors.verified : AppColors.textSecondary,
            label: mechanic.isVerified ? 'Doğrulanmış Servis' : 'Doğrulanmamış Servis',
          ),
        ),
        const SizedBox(height: 11),
        VerifiedJobsBadge(mechanicId: mechanicChatId(mechanic.name)),
      ],
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  static final Color _background = Color.alphaBlend(Colors.black.withValues(alpha: 0.04), Colors.white);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.12), _background),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}
