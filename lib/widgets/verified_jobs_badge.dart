// VerifiedJobsBadge
//
// Displays the mechanic's verified completed job count on their profile.
// Uses AppointmentRepository.fetchVerifiedCompletedCount() — the real,
// live Firestore-backed count query (see
// lib/mechanic/appointments/data/appointment_repository.dart).

import 'package:flutter/material.dart';

import '../mechanic/appointments/data/appointment_repository.dart';

class VerifiedJobsBadge extends StatelessWidget {
  final String mechanicId;
  final int minThreshold;

  const VerifiedJobsBadge({
    super.key,
    required this.mechanicId,
    this.minThreshold = 10,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: AppointmentRepository().fetchVerifiedCompletedCount(mechanicId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final count = snapshot.data!;
        if (count < minThreshold) {
          return const SizedBox.shrink();
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, size: 15, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text(
                '$count Doğrulanmış İş',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
