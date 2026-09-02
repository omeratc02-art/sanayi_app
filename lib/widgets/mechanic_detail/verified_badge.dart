import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.verifiedBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: AppColors.verified, size: 15),
          SizedBox(width: 4),
          Text(
            'Onaylı Usta',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.verified),
          ),
          SizedBox(width: 4),
          Icon(Icons.info_outline_rounded, size: 14, color: Color(0xB34338CA)),
        ],
      ),
    );
  }
}
