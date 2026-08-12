import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/booking/section_label.dart';
import '../../widgets/common/premium_surface.dart';
import '../appointments/mechanic_request_details_page.dart';
import '../notifications/mechanic_notifications_screen.dart';

/// First functional version of the mechanic module's "Home" tab —
/// notification bell (mock badge), a compact "Important Updates" card, and
/// a "Pending Requests" list of mock request cards. All data here is
/// hardcoded; no backend/API/business logic is wired up yet.
///
/// Workflow rule: this screen shows ONLY actionable work items (pending
/// appointment requests awaiting a decision) as collapsed previews — a
/// card is never expandable in place. Tapping one pushes the separate
/// MechanicRequestDetailsPage, which is the actual workspace for a
/// request. Customer questions/chat must NEVER be surfaced on this
/// screen — they arrive solely through the notification bell:
///
///   Bell -> MechanicNotificationsScreen -> tap a notification -> Request Details
///   Home -> tap a request card -> Request Details
///
/// The bell must always open the Notifications page first — it must never
/// jump straight to a Request Details workspace. See [_MechanicHomeHeader].
class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  static const _requests = [
    _MockRequest(
      customerName: 'Ahmet Yılmaz',
      vehicleModel: 'Renault Clio',
      vehicleInfo: 'Renault Clio · 34 ABC 123',
      service: 'Yağ Değişimi',
      note: 'Aracımda ayrıca hafif bir fren sesi var, kontrol edebilir misiniz?',
      preferredDate: '22 Temmuz, Çarşamba',
      preferredTime: '10:00 – 12:00',
    ),
    _MockRequest(
      customerName: 'Elif Kaya',
      vehicleModel: 'Fiat Egea',
      vehicleInfo: 'Fiat Egea · 06 XYZ 456',
      service: 'Fren Bakımı',
      note: 'Öğleden sonra müsaitim, sabah saatleri bana uygun değil.',
      preferredDate: '23 Temmuz, Perşembe',
      preferredTime: 'İlk Müsait Saat',
    ),
  ];

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MechanicNotificationsScreen()),
    );
  }

  // TODO: MechanicRequestDetailsPage currently always shows the same
  // hardcoded (Ahmet Yılmaz) mock data regardless of which request card
  // was tapped — it doesn't accept the tapped request yet. Wire real data
  // passing once the page is parameterized.
  void _openRequestDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MechanicRequestDetailsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _MechanicHomeHeader(onNotificationTap: _openNotifications),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                const SectionLabel(text: 'Bekleyen Talepler'),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < _requests.length; i++) ...[
                  _RequestCard(
                    request: _requests[i],
                    onTap: _openRequestDetails,
                  ),
                  if (i < _requests.length - 1) const SizedBox(height: AppSpacing.xl),
                ],
                const SizedBox(height: AppSpacing.xxl),
                const _ImportantUpdatesCard(
                  message: 'Ahmet Yılmaz, önerdiğiniz randevu saatini kabul etti.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified header — title, subtitle, and notification bell laid out as one
/// component (a single row inside a shared background/padding) rather than
/// the previous AppBar title/actions split, so the bell reads as part of
/// the same block as the greeting instead of a disconnected corner icon.
class _MechanicHomeHeader extends StatelessWidget {
  const _MechanicHomeHeader({required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 16, AppSpacing.xl, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş geldiniz 👋',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Bekleyen talepleriniz sizi bekliyor.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.normal,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: IconButton(
                  onPressed: onNotificationTap,
                  icon: const Badge(
                    label: Text('3'),
                    child: Icon(Icons.notifications_outlined, size: 30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportantUpdatesCard extends StatelessWidget {
  const _ImportantUpdatesCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: () {},
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Önemli Gelişmeler',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MockRequest {
  const _MockRequest({
    required this.customerName,
    required this.vehicleModel,
    required this.vehicleInfo,
    required this.service,
    required this.note,
    required this.preferredDate,
    required this.preferredTime,
  });

  final String customerName;
  final String vehicleModel;
  final String vehicleInfo;
  final String service;
  final String note;
  final String preferredDate;
  final String preferredTime;
}

/// A collapsed, non-expandable preview of a request — tapping it pushes
/// MechanicRequestDetailsPage, the separate screen that is the actual
/// workspace for this request. This card never shows customer note,
/// customer name, or action buttons; those live only on that page.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final _MockRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 16),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_rounded, size: 20, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.vehicleModel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ServiceBadge(label: request.service),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(request.preferredDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(request.preferredTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small rounded chip for the requested service — the card's one
/// turquoise accent, keeping everything else neutral.
class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.turquoise,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
