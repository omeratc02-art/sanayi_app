import 'package:flutter/material.dart';

import '../../data/booking_history.dart';
import '../../data/mock_data.dart';
import '../../models/mechanic.dart';
import '../../models/review.dart';
import '../../theme/app_theme.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/common/premium_surface.dart';
import '../../widgets/service_listing/write_review_sheet.dart';

enum _ReviewFilter { newest, highestRated, mostHelpful }

/// Destination for tapping the rating row on [ServiceCenterCard] and the
/// mechanic profile page — average rating, star distribution, a filterable
/// review list, and photo indicators where a review includes one. Reviews
/// are a shared mock sample (see [MockData.sampleReviews]) rather than
/// per-business data, since no such dataset exists in this app yet.
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key, required this.mechanic});

  final Mechanic mechanic;

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  _ReviewFilter _filter = _ReviewFilter.newest;

  List<Review> get _sortedReviews {
    final reviews = [...MockData.sampleReviews];
    switch (_filter) {
      case _ReviewFilter.newest:
        reviews.sort((a, b) => b.date.compareTo(a.date));
      case _ReviewFilter.highestRated:
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
      case _ReviewFilter.mostHelpful:
        reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
    }
    return reviews;
  }

  Map<int, int> get _distribution {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in MockData.sampleReviews) {
      counts[review.rating] = (counts[review.rating] ?? 0) + 1;
    }
    return counts;
  }

  void _handleWriteReview() {
    if (!BookingHistory.hasCompleted(widget.mechanic.name)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Yorum yapabilmek için bu işletmeden bir hizmet tamamlamış olmanız gerekir.'),
          ),
        );
      return;
    }

    showWriteReviewSheet(
      context,
      onSubmitted: (review) => setState(() => MockData.sampleReviews.insert(0, review)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distribution = _distribution;
    final totalSampled = MockData.sampleReviews.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.mechanic.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleWriteReview,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Yorum Yaz'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _RatingSummaryCard(mechanic: widget.mechanic, distribution: distribution, total: totalSampled),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Değerlendirmeler',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          _FilterRow(selected: _filter, onSelected: (filter) => setState(() => _filter = filter)),
          const SizedBox(height: AppSpacing.lg),
          for (final review in _sortedReviews) ...[
            _ReviewCard(review: review),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.mechanic, required this.distribution, required this.total});

  final Mechanic mechanic;
  final Map<int, int> distribution;
  final int total;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                mechanic.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < mechanic.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${mechanic.reviewCount} yorum',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var stars = 5; stars >= 1; stars--) ...[
                  _DistributionRow(stars: stars, count: distribution[stars] ?? 0, total: total),
                  if (stars > 1) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.stars, required this.count, required this.total});

  final int stars;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        Text('$stars', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        const SizedBox(width: 3),
        const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 16,
          child: Text('$count', textAlign: TextAlign.end, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});

  final _ReviewFilter selected;
  final ValueChanged<_ReviewFilter> onSelected;

  static const _labels = {
    _ReviewFilter.newest: 'En Yeni',
    _ReviewFilter.highestRated: 'En Yüksek Puanlı',
    _ReviewFilter.mostHelpful: 'En Faydalı',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _ReviewFilter.values) ...[
            ChoiceChip(
              label: Text(_labels[filter]!),
              selected: selected == filter,
              showCheckmark: false,
              onSelected: (_) => onSelected(filter),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(color: selected == filter ? AppColors.primary : AppColors.divider),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected == filter ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppRadius.lg,
      border: Border.all(color: AppColors.divider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 13,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${review.date.day} ${monthFull(review.date)} ${review.date.year}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (review.hasPhoto) const _PhotoThumbnail(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          if (review.comment.isNotEmpty) ...[
            Text(
              review.comment,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 13, color: AppColors.primary.withValues(alpha: 0.85)),
              const SizedBox(width: 4),
              Text(
                'Doğrulanmış Hizmet Sonrası Yorum',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primary.withValues(alpha: 0.85)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Faydalı (${review.helpfulCount})',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail();

  static const _gradient = LinearGradient(
    colors: [AppColors.turquoise, AppColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(gradient: _gradient, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: const Icon(Icons.image_rounded, color: Colors.white70, size: 20),
    );
  }
}
