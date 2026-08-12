import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/appointment_request.dart';
import '../../theme/app_theme.dart';
import '../booking/time_slot_grid.dart';

/// Lets the customer pick a different preferred time window after the
/// provider has proposed one that doesn't work — mirrors the same window
/// picker used on the original appointment request form.
Future<void> showRequestAnotherTimeSheet(
  BuildContext context, {
  required AppointmentRequest request,
  required ValueChanged<String> onSubmitted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => _RequestAnotherTimeSheetContent(request: request, onSubmitted: onSubmitted),
  );
}

class _RequestAnotherTimeSheetContent extends StatefulWidget {
  const _RequestAnotherTimeSheetContent({required this.request, required this.onSubmitted});

  final AppointmentRequest request;
  final ValueChanged<String> onSubmitted;

  @override
  State<_RequestAnotherTimeSheetContent> createState() => _RequestAnotherTimeSheetContentState();
}

class _RequestAnotherTimeSheetContentState extends State<_RequestAnotherTimeSheetContent> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final windows = MockData.timeWindowsFor(widget.request.date);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
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
            'Başka Saat İste',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Yeni bir tercih saati seçin, isteğinizi servis sağlayıcıya tekrar ileteceğiz.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          TimeSlotGrid(
            slots: windows,
            selected: _selected,
            onSelected: (time) => setState(() => _selected = time),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      widget.onSubmitted(_selected!);
                      Navigator.of(context).pop();
                    },
              child: const Text('Gönder'),
            ),
          ),
        ],
      ),
    );
  }
}
