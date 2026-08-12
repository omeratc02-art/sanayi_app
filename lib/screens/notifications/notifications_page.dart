import 'package:flutter/material.dart';

import '../../data/appointment_request_store.dart';
import '../../models/appointment_request.dart';
import '../../theme/app_theme.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/common/premium_surface.dart';

/// Customer Notifications screen, reached via the bell in GreetingBar
/// (see home/home_tab.dart). Mirrors the mechanic side's equivalent
/// (mechanic/notifications/mechanic_notifications_screen.dart) but uses the
/// customer app's PremiumSurface card language instead of that screen's
/// flat list tiles. Shows one card per AppointmentRequestStore request
/// that's awaiting the customer's response to a mechanic's proposed time —
/// see AppointmentRequestCard._StatusSection, which deliberately renders
/// nothing for that same status because this screen is where it belongs
/// instead.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    AppointmentRequestStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    AppointmentRequestStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  // accept() is now a real Firestore operation for authenticated customers
  // (see AppointmentRequestStore.accept) — await it and only report a
  // failure; a success needs no extra handling here since the store's own
  // notifyListeners() already updates this page's UI via _onStoreChanged.
  Future<void> _acceptSuggestion(AppointmentRequest request) async {
    final success = await AppointmentRequestStore.instance.accept(request);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Randevu onaylanamadı. Lütfen tekrar deneyin.')),
      );
    }
  }

  // Rejects the proposed time — reuses the store's existing
  // requestAnotherTime exactly as designed (resets to pendingProvider and
  // re-triggers its simulated provider response) rather than inventing a
  // separate "reject" flow; no confirmed appointment is created.
  void _requestAnotherTime(AppointmentRequest request) {
    AppointmentRequestStore.instance.requestAnotherTime(request, request.preferredWindowLabel);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Farklı bir saat isteğiniz iletildi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proposals = AppointmentRequestStore.instance.requests
        .where(
          (request) =>
              request.status == AppointmentRequestStatus.providerProposed ||
              request.status == AppointmentRequestStatus.declined,
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bildirimler')),
      body: proposals.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: proposals.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final request = proposals[index];
                if (request.status == AppointmentRequestStatus.declined) {
                  return _DeclinedRequestCard(request: request);
                }
                return _NewTimeSuggestedCard(
                  request: request,
                  onAccept: () => _acceptSuggestion(request),
                  onRequestAnotherTime: () => _requestAnotherTime(request),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Bildiriminiz yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bir usta size yeni bir randevu saati önerdiğinde burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// A mechanic's decline notification — same card language (avatar circle,
/// name, message) as _NewTimeSuggestedCard below, but purely informational:
/// there's nothing to accept or request again for a declined request, so
/// no action row.
class _DeclinedRequestCard extends StatelessWidget {
  const _DeclinedRequestCard({required this.request});

  final AppointmentRequest request;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      borderRadius: 20,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy_rounded, color: Colors.red, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request.mechanicName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Usta randevu talebinizi reddetti.',
                  style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A mechanic's proposed-time notification card. Fully tappable actions —
/// no navigation, just the two responses the request state machine
/// actually supports (AppointmentRequestStatus.providerProposed ->
/// confirmed or back to pendingProvider).
class _NewTimeSuggestedCard extends StatelessWidget {
  const _NewTimeSuggestedCard({
    required this.request,
    required this.onAccept,
    required this.onRequestAnotherTime,
  });

  final AppointmentRequest request;
  final VoidCallback onAccept;
  final VoidCallback onRequestAnotherTime;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xl),
      borderRadius: 20,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + name + message grouped as a single header block —
                // name and message sit in one tightly-spaced Column, read
                // as one visual unit, with the icon aligned beside them.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            request.mechanicName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Size yeni bir randevu saati önerdi.',
                            style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Original request vs. the mechanic's new proposal.
                const Text(
                  'Talep Ettiğiniz',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('📅 ${formatFullDate(request.date)}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(width: 16),
                    Text('🕒 ${request.preferredWindowLabel}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                const Text(
                  'Ustanın Yeni Önerisi',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.turquoise),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('📅 ${formatFullDate(request.date)}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(width: 16),
                    Text('🕒 ${request.proposedTime}', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Unread dot on the trailing edge — top-padded to stay vertically
          // centered against the avatar+name row now that the outer Row is
          // top-aligned (needed so the avatar/name align with each other
          // rather than the much taller content column).
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
            ),
          ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.turquoise,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onAccept,
                    child: const Text('Kabul Et'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.turquoise,
                      side: const BorderSide(color: AppColors.turquoise),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onRequestAnotherTime,
                    child: const Text('Farklı Saat İste'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
