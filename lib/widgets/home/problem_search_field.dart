import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ProblemSearchField extends StatelessWidget {
  const ProblemSearchField({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: onTap != null,
      onTap: onTap,
      decoration: const InputDecoration(
        hintText: 'Aracınızdaki sorunu arayın (örn. fren sesi)',
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
      ),
    );
  }
}
