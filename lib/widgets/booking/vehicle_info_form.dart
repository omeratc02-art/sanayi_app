import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class VehicleInfoForm extends StatelessWidget {
  const VehicleInfoForm({super.key, required this.brandController, required this.plateController});

  final TextEditingController brandController;
  final TextEditingController plateController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: brandController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Marka ve Model',
              hintText: 'örn. Renault Clio',
              prefixIcon: Icon(Icons.directions_car_outlined, color: AppColors.textSecondary),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Marka ve model girin' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: plateController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Plaka',
              hintText: 'örn. 42 ABC 123',
              prefixIcon: Icon(Icons.pin_outlined, color: AppColors.textSecondary),
            ),
            validator: (value) =>
                (value == null || value.trim().length < 5) ? 'Geçerli bir plaka girin' : null,
          ),
        ],
      ),
    );
  }
}
