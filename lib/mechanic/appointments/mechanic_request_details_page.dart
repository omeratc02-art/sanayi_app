import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/booking/section_label.dart';
import '../../widgets/common/premium_surface.dart';
import 'mechanic_conversation_page.dart';

/// The mechanic's primary workspace for a single request. Not yet wired
/// into any navigation — a future step will push this from the Pending
/// Requests list and/or from a notification (see MechanicNotificationsScreen's
/// TODOs). Q&A and messaging are deliberately left out for now; the Photos
/// section shows placeholder thumbnails only, no viewer.
class MechanicRequestDetailsPage extends StatelessWidget {
  const MechanicRequestDetailsPage({super.key});

  // Mock data — consistent with the Ahmet Yılmaz request already shown on
  // the Home screen's Pending Requests list.
  static const _vehicleName = 'Renault Clio';
  static const _service = 'Yağ Değişimi';
  static const _preferredDate = '22 Temmuz, Çarşamba';
  static const _preferredTime = '10:00 – 12:00';
  static const _status = 'Beklemede';
  static const _customerName = 'Ahmet Yılmaz';
  static const _vehiclePlate = '34 ABC 123';
  static const _vehicleModel = 'Renault Clio';
  static const _customerNote = 'Aracımda ayrıca hafif bir fren sesi var, kontrol edebilir misiniz?';
  static const _photoCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Talep Detayı')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const _RequestSummaryCard(
            vehicleName: _vehicleName,
            service: _service,
            preferredDate: _preferredDate,
            preferredTime: _preferredTime,
            status: _status,
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(text: 'Müşteri Bilgileri'),
          const SizedBox(height: AppSpacing.md),
          const _CustomerInfoCard(
            customerName: _customerName,
            vehiclePlate: _vehiclePlate,
            vehicleModel: _vehicleModel,
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(text: 'Müşteri Notu'),
          const SizedBox(height: AppSpacing.md),
          const _NoteCard(note: _customerNote),
          const SizedBox(height: AppSpacing.xxl),
          const SectionLabel(text: 'Fotoğraflar'),
          const SizedBox(height: AppSpacing.md),
          const _PhotosCard(count: _photoCount),
        ],
      ),
      bottomNavigationBar: _RequestActionBar(
        onAccept: () {},
        onSuggestAnotherTime: () {},
      ),
    );
  }
}

/// Hero section — the first thing a mechanic sees for this request.
class _RequestSummaryCard extends StatelessWidget {
  const _RequestSummaryCard({
    required this.vehicleName,
    required this.service,
    required this.preferredDate,
    required this.preferredTime,
    required this.status,
  });

  final String vehicleName;
  final String service;
  final String preferredDate;
  final String preferredTime;
  final String status;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_rounded, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vehicleName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ServiceBadge(label: service),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  preferredDate,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  preferredTime,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Durum: $status',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small rounded chip for the requested service — the page's one turquoise
/// accent, matching the same badge already used on the Home screen's
/// Pending Requests cards.
class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.turquoise,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class _CustomerInfoCard extends StatelessWidget {
  const _CustomerInfoCard({
    required this.customerName,
    required this.vehiclePlate,
    required this.vehicleModel,
  });

  final String customerName;
  final String vehiclePlate;
  final String vehicleModel;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(icon: Icons.person_outline, label: 'Müşteri', value: customerName),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.pin_outlined, label: 'Plaka', value: vehiclePlate),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.directions_car_outlined, label: 'Araç Modeli', value: vehicleModel),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Text(
        note,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.45),
      ),
    );
  }
}

/// Placeholder photo thumbnails only — no photo viewer yet.
class _PhotosCard extends StatelessWidget {
  const _PhotosCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm + 2),
            Expanded(child: _PhotoPlaceholder()),
          ],
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.divider.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_outlined, size: 22, color: AppColors.textSecondary),
      ),
    );
  }
}

class _RequestActionBar extends StatelessWidget {
  const _RequestActionBar({required this.onAccept, required this.onSuggestAnotherTime});

  final VoidCallback onAccept;
  final VoidCallback onSuggestAnotherTime;

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
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('Talebi Kabul Et'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: onSuggestAnotherTime,
                  child: const Text('Başka Saat Öner'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MechanicConversationPage(chatId: 'ahmet-yilmaz-yag-degisimi'),
                    ),
                  ),
                  child: const Text('Mesajlaş'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
