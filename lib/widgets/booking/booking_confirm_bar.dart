import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class BookingConfirmBar extends StatelessWidget {
  const BookingConfirmBar({super.key, required this.priceRangeLabel, required this.onConfirm});

  final String priceRangeLabel;
  final VoidCallback onConfirm;

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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tahmini Ücret', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    priceRangeLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.red),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 190,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('Randevuyu Onayla'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
