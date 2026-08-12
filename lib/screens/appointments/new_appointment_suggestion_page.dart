import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/premium_surface.dart';

/// Design-only screen shown to the customer when a mechanic proposes a new
/// appointment time (the customer-facing counterpart of the mechanic
/// module's "Başka Saat Öner" flow). Static placeholder content only — no
/// navigation, dialogs, animations, or backend wiring; both bottom buttons
/// are currently no-ops.
class NewAppointmentSuggestionPage extends StatelessWidget {
  const NewAppointmentSuggestionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('New Appointment Suggestion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _MechanicInfoCard(),
            SizedBox(height: AppSpacing.lg),
            _AppointmentDetailsCard(),
            SizedBox(height: AppSpacing.lg),
            _InfoMessage(),
          ],
        ),
      ),
      bottomNavigationBar: const _ActionBar(),
    );
  }
}

/// Who proposed the new time — same avatar-circle identity treatment used
/// on MechanicDetailPage, condensed into a horizontal summary row.
class _MechanicInfoCard extends StatelessWidget {
  const _MechanicInfoCard();

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.car_repair, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mehmet Usta',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                SizedBox(height: 2),
                Text('Şahin Otomotiv', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('4.9 (328 değerlendirme)', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The proposed appointment's facts — same icon + label row treatment as
/// AppointmentRequestCard's _InfoRow elsewhere in the customer app.
class _AppointmentDetailsCard extends StatelessWidget {
  const _AppointmentDetailsCard();

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Randevu Detayları',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          SizedBox(height: AppSpacing.md),
          _DetailRow(icon: Icons.event, label: '08 Ağustos 2026 Cumartesi'),
          SizedBox(height: 10),
          _DetailRow(icon: Icons.schedule, label: '10:30'),
          SizedBox(height: 10),
          _DetailRow(icon: Icons.build_outlined, label: 'Yağ Değişimi'),
          SizedBox(height: 10),
          _DetailRow(icon: Icons.directions_car_outlined, label: 'Renault Clio'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

/// Explanatory note — same tinted, rounded info-box treatment already used
/// for AppointmentRequestCard's "providerProposed" status section.
class _InfoMessage extends StatelessWidget {
  const _InfoMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu saat mekanik tarafından önerilmiştir. Öneriyi kabul ederseniz randevunuz bu saate göre onaylanacaktır.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom action pair — same white bar + top divider + SafeArea shell as
/// AppointmentRequestPage's _SubmitBar, with two Expanded buttons matching
/// AppointmentRequestCard's outlined/primary pairing. Both are no-ops.
class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 12, AppSpacing.xl, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Request Another Time'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Accept Suggestion'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
