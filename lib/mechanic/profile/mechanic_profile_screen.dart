import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../../widgets/common/premium_surface.dart';
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
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

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        PremiumSurface(
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.divider),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.businessName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  if (isVerified)
                    const Icon(Icons.verified_rounded, color: AppColors.turquoise, size: 20),
                ],
              ),
              if (rating != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      reviewCount != null ? '${rating.toStringAsFixed(1)} ($reviewCount değerlendirme)' : rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              _InfoRow(icon: Icons.email_outlined, label: profile.email),
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.phone_outlined, label: phone),
              ],
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.location_on_outlined, label: address),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
