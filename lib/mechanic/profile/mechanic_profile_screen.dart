import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../../utils/firebase_instances.dart';
import '../../widgets/booking/section_label.dart';
import '../../widgets/common/premium_surface.dart';
import '../appointments/data/appointment_repository.dart';
import 'data/mechanic_profile.dart';
import 'data/mechanic_profile_repository.dart';

/// "Profile" tab for the mechanic module — shows the signed-in mechanic's
/// real business profile, read from mechanicAccounts/{uid} via
/// MechanicProfileRepository. Previously a structure-only placeholder
/// (SizedBox.shrink()); this is that placeholder's first real content, not
/// a redesign of anything that already worked.
///
/// Fields the real Firestore document doesn't have yet (older accounts
/// registered before phone/address/isVerified/rating were added at
/// registration) fall back to the matching MockData catalog entry, kept
/// available as a temporary source until every account has real data of
/// its own — see _mergedField below.
class MechanicProfileScreen extends StatefulWidget {
  const MechanicProfileScreen({super.key});

  @override
  State<MechanicProfileScreen> createState() => _MechanicProfileScreenState();
}

class _MechanicProfileScreenState extends State<MechanicProfileScreen> {
  bool _loading = true;
  MechanicProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = firebaseAuthInstance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final profile = await MechanicProfileRepository().fetchProfile(uid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Mechanic? _fallbackMechanic(String businessId) {
    for (final mechanic in MockData.allMechanics) {
      if (mechanicChatId(mechanic.name) == businessId) return mechanic;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _profile == null
            ? const _NoProfileState()
            : _ProfileBody(profile: _profile!, fallback: _fallbackMechanic(_profile!.businessId)),
      ),
    );
  }
}

class _NoProfileState extends StatelessWidget {
  const _NoProfileState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_outlined, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Usta hesabı bulunamadı',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Profilinizi görüntülemek için usta hesabınızla giriş yapmalısınız.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.fallback});

  final MechanicProfile profile;

  /// The matching MockData catalog entry, if any — used only to fill in
  /// fields this specific account's real document doesn't have yet.
  final Mechanic? fallback;

  String? _mergedField(String? real, String? fallbackValue) => (real == null || real.isEmpty) ? fallbackValue : real;

  @override
  Widget build(BuildContext context) {
    final phone = _mergedField(profile.phone, fallback?.phone);
    final address = _mergedField(profile.address, fallback?.address);
    final rating = profile.rating ?? fallback?.rating;
    final reviewCount = profile.reviewCount ?? fallback?.reviewCount;
    final isVerified = profile.isVerified || (fallback?.isVerified ?? false);
    final services = profile.hizmetler.isNotEmpty ? profile.hizmetler : (fallback?.hizmetler ?? const <String>[]);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ProfileHeader(businessName: profile.businessName, address: address, isVerified: isVerified),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatsCard(businessId: profile.businessId, rating: rating, reviewCount: reviewCount),
              const SizedBox(height: AppSpacing.xxl),
              const SectionLabel(text: 'İletişim Bilgileri'),
              const SizedBox(height: AppSpacing.md),
              if (phone != null && phone.isNotEmpty) ...[
                _ContactCard(icon: Icons.phone_outlined, label: 'Telefon Numarası', value: phone),
                const SizedBox(height: AppSpacing.sm),
              ],
              // profile.email is a required field — always real and present,
              // unlike phone/address which can be genuinely unset on older
              // accounts.
              _ContactCard(icon: Icons.email_outlined, label: 'E-posta', value: profile.email),
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _ContactCard(icon: Icons.location_on_outlined, label: 'Adres', value: address),
              ],
              // No "İşletme Hakkında" description card: there is no real
              // free-text business-description field anywhere in this
              // account's Firestore document or in the Mechanic/MockData
              // fallback (only short labels like specialty/category exist,
              // which are already shown elsewhere) — per this redesign's
              // explicit "don't fabricate, don't silently substitute
              // something else" instruction, this section is left out
              // rather than rendering a paragraph that isn't real.
              if (services.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                _ServiceChipsSection(services: services),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Cover-banner header — name, location, and the real isVerified badge
/// (reusing this app's own established "Doğrulanmış Servis" wording/style,
/// the same badge shown on the top bar and MechanicDetailPage, rather than
/// inventing new copy). The icon standing in for a cover photo is
/// deliberate, not a placeholder-by-omission: no mechanic cover-photo field
/// exists anywhere in Firestore (see mechanic_home_screen.dart's own
/// avatar/logo comments for this same, already-established "no fabricated
/// photo" convention), so a neutral icon on a brand-gradient background is
/// used instead, exactly like every other "photo slot" elsewhere in this
/// app.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.businessName, required this.address, required this.isVerified});

  final String businessName;
  final String? address;
  final bool isVerified;

  static const _coverGradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
      decoration: const BoxDecoration(
        gradient: _coverGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl),
          bottomRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            businessName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          if (address != null && address!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ),
              ],
            ),
          ],
          if (isVerified) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Doğrulanmış Servis',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tamamlanan İş / Tekrar Eden Müşteri / Değerlendirme — the same three
/// real data sources the previous layout already used
/// (AppointmentRepository.fetchVerifiedCompletedCount,
/// MechanicProfileRepository.fetchRepeatCustomerCount, profile.rating/
/// reviewCount with the same MockData fallback), just combined into one
/// horizontal card instead of three stacked rows.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.businessId, required this.rating, required this.reviewCount});

  final String businessId;
  final double? rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.sm),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FutureBuilder<int>(
              // Same call/data source as before — only the layout changed.
              future: AppointmentRepository().fetchVerifiedCompletedCount(businessId),
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                return _StatColumn(
                  icon: Icons.verified_outlined,
                  value: isLoading ? '...' : '${snapshot.data ?? 0}',
                  label: 'Tamamlanan İş',
                  color: AppColors.turquoise,
                );
              },
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs)),
          Expanded(
            child: FutureBuilder<int?>(
              // Same call/data source as before — only the layout changed.
              future: MechanicProfileRepository().fetchRepeatCustomerCount(businessId),
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                return _StatColumn(
                  icon: Icons.repeat_rounded,
                  value: isLoading ? '...' : '${snapshot.data ?? 0}',
                  label: 'Tekrar Eden Müşteri',
                  color: AppColors.primary,
                );
              },
            ),
          ),
          Container(width: 1, height: 44, color: AppColors.divider, margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs)),
          Expanded(
            child: _StatColumn(
              icon: Icons.star_rounded,
              // '—' (never a fabricated 0.0) when there's no real rating
              // yet — same convention already used elsewhere in this app
              // for a missing rating.
              value: rating != null ? rating!.toStringAsFixed(1) : '—',
              label: reviewCount != null ? 'Değerlendirme ($reviewCount)' : 'Değerlendirme',
              color: AppColors.rating,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.icon, required this.value, required this.label, required this.color});

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.turquoise),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact rounded chips for [MechanicProfile.hizmetler]/[Mechanic.hizmetler]
/// — the same real, already-written Firestore field
/// mechanic_login_page.dart's registration/claim flow sets, just newly
/// exposed on MechanicProfile ([MechanicProfile.fromFirestore]) and
/// rendered here; no new query, no new collection. Capped so a business
/// with many services stays scannable — "Tümünü Gör" expands in place
/// (this screen has no dedicated "all services" page to navigate to, and
/// this redesign must not touch navigation).
class _ServiceChipsSection extends StatefulWidget {
  const _ServiceChipsSection({required this.services});

  final List<String> services;

  @override
  State<_ServiceChipsSection> createState() => _ServiceChipsSectionState();
}

class _ServiceChipsSectionState extends State<_ServiceChipsSection> {
  static const _collapsedCount = 6;

  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.services.length > _collapsedCount;
    final visibleServices = _expanded ? widget.services : widget.services.take(_collapsedCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel(text: 'Hizmetler')),
            if (!_expanded && hasMore)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Text(
                  'Tümünü Gör (${widget.services.length})',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final service in visibleServices) _ServiceChip(label: service)],
        ),
      ],
    );
  }
}

class _ServiceChip extends StatelessWidget {
  const _ServiceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.scheduleTodayBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.turquoise),
      ),
    );
  }
}
