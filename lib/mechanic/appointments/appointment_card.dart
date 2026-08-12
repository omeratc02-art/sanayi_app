import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'data/dummy_appointment.dart';

/// Reusable card for a single upcoming appointment — currently used only by
/// the Appointments screen's "Yaklaşan" (Upcoming) tab, but built as a
/// standalone, independently-parameterized widget (not tied to how its
/// data source is fetched) so it can be reused elsewhere and swapped onto
/// real Firestore-backed data later without any layout changes.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment});

  final DummyAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReminderBanner(daysUntil: appointment.daysUntil),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StatusBadge(status: appointment.status),
                const Spacer(),
                Text(
                  appointment.date,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              appointment.service,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(appointment.mechanicName, style: _AppointmentCardStyles.infoText),
                const SizedBox(width: 10),
                Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade800),
                const SizedBox(width: 2),
                Text(
                  '${appointment.mechanicRating} (${appointment.mechanicReviewCount})',
                  style: _AppointmentCardStyles.infoText,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.directions_car_rounded, text: appointment.vehicle),
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.storefront_outlined, text: appointment.shopName),
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.location_on_outlined, text: appointment.location),
            const SizedBox(height: 8),
            _InfoLine(icon: Icons.schedule, text: appointment.time),
            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: const Text('Ara'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Mesaj'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.directions_outlined, size: 16),
                    label: const Text('Yol Tarifi'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCardStyles {
  _AppointmentCardStyles._();

  static const infoText = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
}

/// Small turquoise-tinted reminder strip at the top of the card — kept
/// visually separate from the rest of the content via its own background
/// and the spacing after it.
class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.daysUntil});

  final int daysUntil;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.turquoise),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Randevunuza $daysUntil gün kaldı',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.turquoise),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status pill — same dot+label pill treatment already used elsewhere in
/// the mechanic module (see MechanicAppointmentsScreen's _NewRequestBadge),
/// generalized to the four appointment statuses and their colors.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, size: 8, color: color),
          const SizedBox(width: 6),
          Text(status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Icon + plain text row for the card's info lines (vehicle, shop,
/// location, time).
class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
