import 'package:flutter/material.dart';

import '../../models/appointment_request.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/common/premium_surface.dart';
import 'customer_conversation_page.dart';

/// Minimal detail view for one appointment, pushed from
/// AppointmentRequestCard when the customer taps a card on the
/// Upcoming/Past tabs (see AppointmentsTab). Uses only the AppointmentRequest
/// data the tapped card already had — no new Firestore query.
class AppointmentDetailPage extends StatelessWidget {
  const AppointmentDetailPage({super.key, required this.request});

  final AppointmentRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Randevu Detayı')),
      body: SafeArea(
        child: ListView(
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
                          request.mechanicName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerConversationPage(
                              chatId: mechanicChatId(request.mechanicName),
                              mechanicName: request.mechanicName,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.turquoise, size: 22),
                        tooltip: 'Ustaya Sor',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DetailRow(icon: Icons.build_outlined, label: request.serviceLabel),
                  const SizedBox(height: 10),
                  _DetailRow(icon: Icons.event, label: formatFullDate(request.date)),
                  const SizedBox(height: 10),
                  _DetailRow(icon: Icons.schedule, label: request.proposedTime ?? request.preferredWindowLabel),
                  if (request.vehicleLabel != null) ...[
                    const SizedBox(height: 10),
                    _DetailRow(icon: Icons.directions_car_outlined, label: request.vehicleLabel!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _DetailStatusPill(status: request.status, proposedTime: request.proposedTime),
                ],
              ),
            ),
          ],
        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

/// Same status→icon/color/label mapping as AppointmentRequestCard's
/// _StatusSection/_StatusPill — kept as its own small copy here rather than
/// exporting those private widgets, since this page only needs the display,
/// not any of that file's tap/navigation behavior.
class _DetailStatusPill extends StatelessWidget {
  const _DetailStatusPill({required this.status, required this.proposedTime});

  final AppointmentRequestStatus status;
  final String? proposedTime;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      AppointmentRequestStatus.pendingProvider => (
        Icons.hourglass_top_rounded,
        AppColors.primary,
        'Servis sağlayıcı onayı bekleniyor',
      ),
      AppointmentRequestStatus.providerProposed => (
        Icons.schedule_rounded,
        AppColors.primary,
        'Önerilen saat: ${proposedTime ?? '-'}',
      ),
      AppointmentRequestStatus.confirmed => (Icons.check_circle_rounded, Colors.green, 'Randevu onaylandı · $proposedTime'),
      AppointmentRequestStatus.declined => (Icons.cancel_outlined, Colors.red, 'Usta talebinizi reddetti'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}
