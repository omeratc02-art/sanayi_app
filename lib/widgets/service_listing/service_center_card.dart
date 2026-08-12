import 'package:flutter/material.dart';

import '../../models/mechanic.dart';
import '../../screens/appointments/customer_conversation_page.dart';
import '../../screens/booking/appointment_request_page.dart';
import '../../screens/service_listing/reviews_page.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../common/premium_surface.dart';
import '../trust/trust_info_sheet.dart';

/// Premium horizontal service-center card for the shared Service Listing
/// screen — a shop photo (placeholder illustration, no real asset exists)
/// on the left carrying a large color-coded Trust Score, business identity
/// and trust signals on the right, and two full-width primary actions
/// below. The score is built only from verification, rating, and
/// repeat-customer rate (see [Mechanic.trustScore]); price is deliberately
/// not shown here.
class ServiceCenterCard extends StatelessWidget {
  const ServiceCenterCard({super.key, required this.mechanic});

  final Mechanic mechanic;

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
                      mechanic.specialty,
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
                        builder: (_) => AppointmentRequestPage(mechanic: mechanic, serviceLabel: mechanic.specialty),
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

/// Capsule badge shown inline next to the service name at the top of
/// [_CenterInfo]. Shield icon, large score, small label, and a
/// letter-grade + verification line underneath. Styled in an
/// Apple/Stripe/Linear/Notion register: a neutral hairline border and a
/// barely-there shadow do the framing. The one accent color is tied to
/// actual verification status (green = verified, the same meaning
/// [VerifiedTrustBadge] and the verification chip below already use on
/// this card) rather than an arbitrary brand color, so the badge itself
/// communicates trust at a glance instead of just decorating it.
class _TrustScoreBadge extends StatelessWidget {
  const _TrustScoreBadge({required this.score, required this.isVerified});

  final int score;
  final bool isVerified;

  static const _borderRadius = 13.0;

  Color get _statusColor => isVerified ? Colors.green.shade700 : AppColors.textSecondary;

  String get _letterGrade {
    if (score >= 95) return 'A+';
    if (score >= 90) return 'A';
    if (score >= 85) return 'A-';
    if (score >= 75) return 'B+';
    if (score >= 65) return 'B';
    return 'C';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVerified ? Icons.verified_rounded : Icons.shield_outlined, size: 16, color: _statusColor),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'GÜVEN',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Text(
                '$_letterGrade ${isVerified ? 'Doğrulanmış Servis' : 'Doğrulanmamış Servis'}',
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
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

  String get _locationLabel {
    final segments = mechanic.address.split(',');
    final city = segments.last.trim();
    return '$city · ${mechanic.distanceLabel}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                mechanic.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 14),
            _TrustScoreBadge(score: mechanic.trustScore, isVerified: mechanic.isVerified),
          ],
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
        InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ReviewsPage(mechanic: mechanic)),
          ),
          borderRadius: BorderRadius.circular(20),
          child: _TrustChip(
            icon: Icons.star_rounded,
            color: Colors.amber.shade800,
            label: '${mechanic.rating.toStringAsFixed(1)} (${mechanic.reviewCount} yorum)',
          ),
        ),
        const SizedBox(height: 11),
        InkWell(
          onTap: () => showTrustInfoSheet(
            context,
            icon: Icons.repeat_rounded,
            accentColor: AppColors.primaryDark,
            title: 'Tekrar Tercih Oranı',
            description:
                'Bu oran, bir önceki ziyaretinden sonra müşterilerin başka bir hizmet için bu servis '
                'sağlayıcısına tekrar dönme yüzdesini gösterir. Yüksek bir oran, daha güçlü bir müşteri '
                'memnuniyeti ve güveni olduğunu gösterir.',
            highlight: 'Müşterilerin %${mechanic.repeatCustomerRate}\'i bu hizmeti tekrar tercih etti.',
          ),
          borderRadius: BorderRadius.circular(20),
          child: _TrustChip(
            icon: Icons.repeat_rounded,
            color: AppColors.primaryDark,
            label: '%${mechanic.repeatCustomerRate} Tekrar Tercih',
          ),
        ),
        const SizedBox(height: 11),
        InkWell(
          onTap: () => showTrustInfoSheet(
            context,
            icon: mechanic.isVerified ? Icons.verified_rounded : Icons.remove_circle_outline_rounded,
            accentColor: mechanic.isVerified ? Colors.green.shade700 : AppColors.textSecondary,
            title: 'Doğrulanmış Servis',
            description:
                'Bu işletme, doğrulama sürecimizi başarıyla tamamlamıştır. İşletme bilgileri doğrulanmış '
                've kalite standartlarını korumak amacıyla müşteri geri bildirimleri sürekli olarak '
                'izlenmektedir.',
          ),
          borderRadius: BorderRadius.circular(20),
          child: _TrustChip(
            icon: mechanic.isVerified ? Icons.verified_rounded : Icons.remove_circle_outline_rounded,
            color: mechanic.isVerified ? Colors.green.shade700 : AppColors.textSecondary,
            label: mechanic.isVerified ? 'Doğrulanmış Servis' : 'Doğrulanmamış Servis',
          ),
        ),
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
