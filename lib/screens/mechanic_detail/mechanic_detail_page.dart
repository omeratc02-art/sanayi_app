import 'package:flutter/material.dart';

import '../../mechanic/appointments/data/appointment_repository.dart';
import '../../mechanic/profile/data/mechanic_profile.dart';
import '../../mechanic/profile/data/mechanic_profile_repository.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../../utils/firebase_instances.dart';
import '../../widgets/mechanic_detail/detail_action_bar.dart';
import '../../widgets/mechanic_detail/open_status_badge.dart';
import '../../widgets/mechanic_detail/stat_tile.dart';
import '../../widgets/mechanic_detail/verified_badge.dart';
import '../../widgets/trust/trust_info_sheet.dart';
import '../../widgets/verified_jobs_badge.dart';
import '../booking/appointment_request_page.dart';
import '../service_listing/reviews_page.dart';

class MechanicDetailPage extends StatefulWidget {
  const MechanicDetailPage({super.key, required this.mechanic});

  final Mechanic mechanic;

  @override
  State<MechanicDetailPage> createState() => _MechanicDetailPageState();
}

class _MechanicDetailPageState extends State<MechanicDetailPage> {
  @override
  void initState() {
    super.initState();
    _recordProfileView();
  }

  // Fire-and-forget — a failed view-count write must never block or
  // interrupt browsing this page. Real signed-in customer only
  // (firebaseAuthInstance.currentUser?.uid, not resolveCustomerId()'s
  // 'customer-demo' fallback used elsewhere in this app for booking/chat —
  // that fallback is exactly the anonymous/guest case this feature must
  // NOT count); MechanicProfileRepository.recordProfileView itself is a
  // no-op for a null/empty customerId, the business owner viewing their
  // own profile, or a repeat view from the same customer already counted
  // today. Errors are logged, not swallowed silently — same debugPrint
  // convention already used for other non-critical background writes
  // (see e.g. mechanic_home_screen.dart's *_ERROR debugPrints).
  void _recordProfileView() {
    MechanicProfileRepository()
        .recordProfileView(
          businessId: mechanicChatId(widget.mechanic.name),
          customerId: firebaseAuthInstance.currentUser?.uid,
        )
        .catchError(
          (Object error) =>
              debugPrint('MECHANIC DETAIL PROFILE VIEW ERROR: $error'),
        );
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final mechanic = widget.mechanic;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          mechanic.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Real cover photo + gallery strip (see
            // MechanicProfileRepository.uploadCoverPhoto/uploadGalleryPhoto)
            // — full-bleed above the padded content below, same reason
            // MechanicProfileScreen's own ListView keeps this section
            // outside its own body padding.
            _CoverPhotoAndGallery(mechanic: mechanic),
            Padding(
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
                    child: const Icon(
                      Icons.car_repair,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    mechanic.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 20),
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
                      if (mechanic.isOpen != null)
                        OpenStatusBadge(isOpen: mechanic.isOpen!),
                      VerifiedJobsBadge(
                        mechanicId: mechanicChatId(mechanic.name),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _RatingSummaryRow(mechanic: mechanic),
                  const SizedBox(height: 16),
                  FutureBuilder<int?>(
                    future: MechanicProfileRepository()
                        .fetchRepeatCustomerCount(
                          mechanicChatId(mechanic.name),
                        ),
                    builder: (context, snapshot) {
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting;
                      final count = snapshot.hasError ? null : snapshot.data;
                      // No distance tile: real mechanicAccounts have no real
                      // geolocation data yet (see Mechanic.distanceLabel).
                      final resolvedPriceTile = StatTile(
                        icon: Icons.payments,
                        label: 'Fiyat Aralığı',
                        value: mechanic.priceRangeLabel,
                      );

                      // Once resolved with nothing to show, the repeat-customer
                      // tile is fully hidden — not a muted placeholder — same
                      // "hide below threshold" reasoning as VerifiedJobsBadge (a
                      // raw 0 reads as a bad signal here, the same problem a "%0
                      // Tekrar Tercih" percentage had for a new business with no
                      // data yet). The price tile then takes the full row alone,
                      // rather than leaving an empty half next to it.
                      if (!isLoading && (count == null || count == 0)) {
                        return resolvedPriceTile;
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: isLoading
                                ? const StatTile(
                                    icon: Icons.repeat,
                                    label: 'Tekrar Müşteri',
                                    value: '...',
                                  )
                                : InkWell(
                                    onTap: () => showTrustInfoSheet(
                                      context,
                                      icon: Icons.repeat_rounded,
                                      accentColor: AppColors.primaryDark,
                                      title: 'Tekrar Tercih Eden Müşteriler',
                                      description:
                                          'Bu sayı, bir önceki ziyaretinden sonra başka bir hizmet için bu servis '
                                          'sağlayıcısına tekrar dönen farklı müşteri sayısını gösterir. Yüksek bir '
                                          'sayı, daha güçlü bir müşteri memnuniyeti ve güveni olduğunu gösterir.',
                                      highlight:
                                          '$count müşteri bu hizmeti tekrar tercih etti.',
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      children: [
                                        StatTile(
                                          icon: Icons.repeat,
                                          label: 'Tekrar Müşteri',
                                          value: '$count',
                                        ),
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Icon(
                                            Icons.info_outline_rounded,
                                            size: 16,
                                            color: AppColors.textSecondary
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: resolvedPriceTile),
                        ],
                      );
                    },
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
          ],
        ),
      ),
      bottomNavigationBar: DetailActionBar(
        onCall: () => _showFeedback(context, '${mechanic.phone} aranıyor...'),
        onNavigate: () =>
            _showFeedback(context, 'Yol tarifi açılıyor: ${mechanic.address}'),
        onBook: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AppointmentRequestPage(
              mechanic: mechanic,
              serviceLabel: mechanic.specialtyLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Real cover photo (if any) plus the gallery strip (if any real gallery
/// photos exist) — one fetch feeds both, since they live on the same
/// MechanicProfile document. Resolves that profile by businessId, the same
/// way every other real data source on this page already does
/// (fetchRepeatCustomerCount/fetchRatingSummary/recordProfileView all take
/// mechanicChatId(mechanic.name), never a uid this customer-facing page
/// has no way to know) — see
/// MechanicProfileRepository.fetchProfileByBusinessId's own doc comment.
class _CoverPhotoAndGallery extends StatelessWidget {
  const _CoverPhotoAndGallery({required this.mechanic});

  final Mechanic mechanic;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MechanicProfile?>(
      future: MechanicProfileRepository().fetchProfileByBusinessId(
        mechanicChatId(mechanic.name),
      ),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final coverPhotoUrl = profile?.coverPhotoUrl;
        // Only the real, non-empty photos — never a placeholder for a
        // missing slot (unlike MechanicProfileScreen's own gallery
        // section, which is the mechanic's management view and shows all
        // 3 slots including empty ones as an "add a photo" affordance;
        // this is the customer-facing view, where an empty slot isn't a
        // real thing to show).
        final galleryUrls =
            (profile?.galleryPhotoUrls ?? const <String?>[null, null, null])
                .whereType<String>()
                .where((url) => url.isNotEmpty)
                .toList();

        return Column(
          children: [
            _CoverPhotoHeader(coverPhotoUrl: coverPhotoUrl),
            if (galleryUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _GalleryStrip(urls: galleryUrls),
            ],
          ],
        );
      },
    );
  }
}

/// Full-width cover photo header — same Alignment.topCenter + BoxFit.cover
/// treatment as MechanicProfileScreen's own _ProfileHeader, and the same
/// "gradient fallback, never a fabricated stock photo" convention when no
/// real coverPhotoUrl exists yet. Deliberately simpler than
/// _ProfileHeader's own two variants (no edit button, no overlapping
/// avatar, no business name/address/verified badge baked in) — this page
/// already shows all of that separately, right below, so this widget's
/// only job is the photo itself.
class _CoverPhotoHeader extends StatelessWidget {
  const _CoverPhotoHeader({required this.coverPhotoUrl});

  final String? coverPhotoUrl;

  static const _height = 160.0;
  static const _gradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final hasPhoto = coverPhotoUrl != null && coverPhotoUrl!.isNotEmpty;
    if (!hasPhoto) {
      return Container(
        width: double.infinity,
        height: _height,
        decoration: const BoxDecoration(gradient: _gradient),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: _height,
      child: Image.network(
        coverPhotoUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('MECHANIC DETAIL COVER PHOTO LOAD ERROR: $error');
          return Container(
            width: double.infinity,
            height: _height,
            decoration: const BoxDecoration(gradient: _gradient),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: double.infinity,
            height: _height,
            color: AppColors.divider,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        },
      ),
    );
  }
}

/// Horizontal strip of the business's real gallery photos — [urls] is
/// already filtered to only real, non-empty entries by
/// [_CoverPhotoAndGallery] (this widget is never built with an empty list;
/// see that class's own `if (galleryUrls.isNotEmpty)` guard).
class _GalleryStrip extends StatelessWidget {
  const _GalleryStrip({required this.urls});

  final List<String> urls;

  static const _thumbSize = 80.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _thumbSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: urls.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = urls[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: _thumbSize,
              height: _thumbSize,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('MECHANIC DETAIL GALLERY PHOTO LOAD ERROR: $error');
                return Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  color: AppColors.divider,
                );
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: _thumbSize,
                  height: _thumbSize,
                  color: AppColors.divider,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          );
        },
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
      future: AppointmentRepository().fetchRatingSummary(
        mechanicChatId(mechanic.name),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final summary = snapshot.data;
        final hasRatings =
            !snapshot.hasError && summary != null && summary.ratedCount > 0;
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
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                )
              : InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReviewsPage(mechanic: mechanic),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        summary.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${summary.ratedCount} değerlendirme)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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
