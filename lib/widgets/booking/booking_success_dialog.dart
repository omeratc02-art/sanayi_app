import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class BookingSuccessDialog extends StatelessWidget {
  const BookingSuccessDialog({
    super.key,
    required this.mechanicName,
    required this.dateLabel,
    required this.timeLabel,
    required this.serviceLabel,
    required this.vehicleLabel,
  });

  final String mechanicName;
  final String dateLabel;
  final String timeLabel;
  final String serviceLabel;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Randevunuz Alındı!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              '$mechanicName ustasından onay bekleniyor.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _SummaryRow(icon: Icons.event, label: dateLabel),
                  const SizedBox(height: 8),
                  _SummaryRow(icon: Icons.schedule, label: timeLabel),
                  const SizedBox(height: 8),
                  _SummaryRow(icon: Icons.build_outlined, label: serviceLabel),
                  const SizedBox(height: 8),
                  _SummaryRow(icon: Icons.directions_car_outlined, label: vehicleLabel),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
