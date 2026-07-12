import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class OpenStatusBadge extends StatelessWidget {
  const OpenStatusBadge({super.key, required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isOpen ? Colors.green : AppColors.textSecondary).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Şu an açık' : 'Şu an kapalı',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOpen ? Colors.green[700] : AppColors.textSecondary,
        ),
      ),
    );
  }
}
