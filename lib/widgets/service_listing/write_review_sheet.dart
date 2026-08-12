import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../theme/app_theme.dart';

/// Deliberately minimal review form: a required star rating and an
/// optional comment — nothing else — to keep submission fast and reduce
/// friction. The "verified service completed" label is added automatically
/// wherever reviews are displayed, not something the user sets here.
Future<void> showWriteReviewSheet(BuildContext context, {required ValueChanged<Review> onSubmitted}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => _WriteReviewSheetContent(onSubmitted: onSubmitted),
  );
}

class _WriteReviewSheetContent extends StatefulWidget {
  const _WriteReviewSheetContent({required this.onSubmitted});

  final ValueChanged<Review> onSubmitted;

  @override
  State<_WriteReviewSheetContent> createState() => _WriteReviewSheetContentState();
}

class _WriteReviewSheetContentState extends State<_WriteReviewSheetContent> {
  final _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating == 0) return;
    widget.onSubmitted(
      Review(
        authorName: 'Siz',
        rating: _rating,
        date: DateTime.now(),
        comment: _commentController.text.trim(),
      ),
    );
    Navigator.of(context).pop();
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
              'Yorum Yaz',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Puanınız',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Yorumunuz (opsiyonel)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Deneyiminizi paylaşın...'),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating == 0 ? null : _submit,
                child: const Text('Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
