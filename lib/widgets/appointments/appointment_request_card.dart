import 'package:flutter/material.dart';

import '../../models/appointment_request.dart';
import '../../screens/appointments/appointment_detail_page.dart';
import '../../screens/appointments/customer_conversation_page.dart';
import '../../theme/app_theme.dart';
import '../../utils/chat_id.dart';
import '../../utils/turkish_date.dart';
import '../common/premium_surface.dart';

class AppointmentRequestCard extends StatelessWidget {
  const AppointmentRequestCard({super.key, required this.request});

  final AppointmentRequest request;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AppointmentDetailPage(request: request)),
      ),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
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
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.turquoise, size: 20),
                tooltip: 'Mesaj Gönder',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(icon: Icons.event, label: '${formatFullDate(request.date)} · ${request.preferredWindowLabel}'),
          const SizedBox(height: 4),
          _InfoRow(icon: Icons.build_outlined, label: request.serviceLabel),
          if (request.vehicleLabel != null) ...[
            const SizedBox(height: 4),
            _InfoRow(icon: Icons.directions_car_outlined, label: request.vehicleLabel!),
          ],
          const SizedBox(height: AppSpacing.md),
          _StatusSection(request: request),
        ],
      ),
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
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.request});

  final AppointmentRequest request;

  @override
  Widget build(BuildContext context) {
    switch (request.status) {
      case AppointmentRequestStatus.pendingProvider:
        return _StatusPill(
          icon: Icons.hourglass_top_rounded,
          color: AppColors.primary,
          label: 'Servis sağlayıcı onayı bekleniyor',
        );
      case AppointmentRequestStatus.providerProposed:
        // The Appointments screen only ever shows confirmed requests now
        // (see AppointmentsTab), so this state never actually renders
        // there — pending/proposed requests live in the
        // Notifications/Messages flow instead. The "Suggested arrival
        // time" box that used to show here has been removed entirely,
        // with no placeholder space left behind.
        return const SizedBox.shrink();
      case AppointmentRequestStatus.confirmed:
        return _StatusPill(
          icon: Icons.check_circle_rounded,
          color: Colors.green,
          label: 'Randevu onaylandı · ${request.proposedTime}',
        );
      case AppointmentRequestStatus.declined:
        return _StatusPill(
          icon: Icons.cancel_outlined,
          color: Colors.red,
          label: 'Usta talebinizi reddetti',
        );
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
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
