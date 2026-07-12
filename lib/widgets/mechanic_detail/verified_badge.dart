import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.blue[700], size: 15),
          const SizedBox(width: 4),
          Text(
            'Onaylı Usta',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }
}
