import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Reusable "İletişim Bilgileri" bottom sheet — collects a name, phone
/// number, and KVKK consent. Not yet wired into any flow: the "Devam Et"
/// button is intentionally left unconnected and there is no validation, per
/// the current scope. Follows the same Material 3 sheet pattern as
/// [showWriteReviewSheet]/[showRequestAnotherTimeSheet] (rounded top
/// corners, drag handle, keyboard-aware bottom padding).
Future<void> showContactInfoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => const _ContactInfoSheetContent(),
  );
}

class _ContactInfoSheetContent extends StatefulWidget {
  const _ContactInfoSheetContent();

  @override
  State<_ContactInfoSheetContent> createState() => _ContactInfoSheetContentState();
}

class _ContactInfoSheetContentState extends State<_ContactInfoSheetContent> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _kvkkAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text(
              'İletişim Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Randevu talebinizi oluşturabilmek için lütfen iletişim bilgilerinizi girin.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon Numarası'),
            ),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              onTap: () => setState(() => _kvkkAccepted = !_kvkkAccepted),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _kvkkAccepted,
                    tristate: false,
                    onChanged: (value) => setState(() => _kvkkAccepted = value ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      "KVKK Aydınlatma Metni'ni okudum ve kabul ediyorum.",
                      style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                child: const Text('Devam Et'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
