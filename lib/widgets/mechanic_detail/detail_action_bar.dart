import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DetailActionBar extends StatelessWidget {
  const DetailActionBar({super.key, required this.onCall, required this.onNavigate, required this.onBook});

  final VoidCallback onCall;
  final VoidCallback onNavigate;
  final VoidCallback onBook;

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              _CircleIconButton(icon: Icons.call_outlined, onTap: onCall),
              const SizedBox(width: 12),
              _CircleIconButton(icon: Icons.directions_outlined, onTap: onNavigate),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onBook,
                  icon: const Icon(Icons.calendar_month, size: 20),
                  label: const Text('Randevu Al'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.red),
        ),
        child: Icon(icon, color: AppColors.red),
      ),
    );
  }
}
