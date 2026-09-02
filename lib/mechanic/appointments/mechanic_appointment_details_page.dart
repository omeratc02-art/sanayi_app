import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/premium_surface.dart';
import 'data/appointment.dart';
import 'data/appointment_repository.dart';
import 'mechanic_conversation_page.dart';

/// Read-only detail screen for an already-accepted, same-day appointment —
/// opened from the calendar's appointment blocks (see _AppointmentBlock in
/// appointment_calendar_view.dart). This is a separate page from
/// MechanicRequestDetailsPage on purpose: that page is for *pending*
/// requests still awaiting an accept/decline decision (used by
/// MechanicHomeScreen's "Bekleyen Talepler" list) and keeps its
/// accept/suggest-another-time actions; this page has no such decision to
/// make — the appointment is already confirmed. Its only action is marking
/// the completed job (see _CompletionActionBar), shown only while
/// tamamlanmaDurumu is still "beklemede". Laid out as two cards
/// (appointment, customer) plus that conditional bottom bar. Every field
/// comes from the [appointment] passed in — no hardcoded sample data.
class MechanicAppointmentDetailsPage extends StatelessWidget {
  const MechanicAppointmentDetailsPage({super.key, required this.appointment});

  final Appointment appointment;

  static const _cardRadius = 18.0;

  static const _weekdayNames = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  static const _monthNames = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String _formatDate(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1]} ${_weekdayNames[date.weekday - 1]}';

  static String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static String _formatTimeRange(DateTime start, int durationMinutes) =>
      '${_formatTime(start)}–${_formatTime(start.add(Duration(minutes: durationMinutes)))}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Randevu Detayı')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _AppointmentCard(
            vehicleModel: appointment.vehicleModel,
            licensePlate: appointment.licensePlate,
            service: appointment.serviceType,
            appointmentDate: _formatDate(appointment.start),
            appointmentTime: _formatTimeRange(appointment.start, appointment.estimatedDuration.inMinutes),
            estimatedDuration: '${appointment.estimatedDuration.inMinutes} dk',
          ),
          const SizedBox(height: AppSpacing.md),
          _CustomerCard(
            appointment: appointment,
            customerName: appointment.customerName,
            phoneNumber: appointment.customerPhone,
            distance: appointment.distance,
            note: appointment.customerNote,
            businessId: appointment.businessId,
            vehicleInfo: '${appointment.vehicleModel} · ${appointment.licensePlate}',
            service: appointment.serviceType,
          ),
        ],
      ),
      bottomNavigationBar: appointment.tamamlanmaDurumu == 'beklemede'
          ? _CompletionActionBar(appointment: appointment)
          : null,
    );
  }
}

/// Bottom action bar with the mechanic's one available action on this page
/// — hides itself locally once the write succeeds (rather than popping the
/// page), since tamamlanmaDurumu is no longer "beklemede" at that point.
class _CompletionActionBar extends StatefulWidget {
  const _CompletionActionBar({required this.appointment});

  final Appointment appointment;

  @override
  State<_CompletionActionBar> createState() => _CompletionActionBarState();
}

class _CompletionActionBarState extends State<_CompletionActionBar> {
  var _isSubmitting = false;
  var _isCompleted = false;

  Future<void> _markCompleted() async {
    setState(() => _isSubmitting = true);
    try {
      await AppointmentRepository().markMechanicCompleted(widget.appointment.appointmentId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşaretleme başarısız: $error')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _isCompleted = true;
    });
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('İş Tamamlandı Olarak İşaretlendi'),
        content: const Text('Müşterinin onayı bekleniyor. Müşteri onayladığında iş tamamlanmış sayılacaktır.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _markCompleted,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('İşi Tamamladım'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card 1 — vehicle identity up top (name, plate, service badge), then the
/// rest of the appointment facts as a balanced two-column grid instead of
/// one long vertical stack.
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.vehicleModel,
    required this.licensePlate,
    required this.service,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.estimatedDuration,
  });

  final String vehicleModel;
  final String licensePlate;
  final String service;
  final String appointmentDate;
  final String appointmentTime;
  final String estimatedDuration;

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: MechanicAppointmentDetailsPage._cardRadius,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_rounded, size: 22, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vehicleModel,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            licensePlate,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _ServiceBadge(label: service),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconTextRow(icon: Icons.event, text: appointmentDate),
                    const SizedBox(height: 10),
                    _IconTextRow(icon: Icons.schedule, text: appointmentTime),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(icon: Icons.hourglass_top_rounded, label: 'Tahmini Süre', value: estimatedDuration),
                    const SizedBox(height: 10),
                    _InfoRow(icon: Icons.build_outlined, label: 'Hizmet', value: service),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card 2 — customer identity, distance, and their note in one card. The
/// note sits in its own light-grey rounded container rather than behind a
/// divider, and the two actions below are a clear primary/secondary pair.
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.appointment,
    required this.customerName,
    required this.phoneNumber,
    required this.distance,
    required this.note,
    required this.businessId,
    required this.vehicleInfo,
    required this.service,
  });

  /// The same real Appointment this whole page was opened for — passed
  /// straight through to MechanicConversationPage so its own "Talebi
  /// Görüntüle" button can open MechanicRequestDetailsPage with real data
  /// instead of needing to guess one from businessId/chatId alone.
  final Appointment appointment;

  final String customerName;
  final String phoneNumber;
  final String distance;
  final String note;

  /// Same slug used everywhere else (chats/{businessId}, appointments'
  /// businessId field, mechanicAccounts.businessId) — passed in from the
  /// real appointment this page was opened for, so "Mesaj Gönder" below
  /// opens that appointment's actual conversation instead of a fixed id.
  final String businessId;

  /// Real appointment fields, passed straight through to
  /// MechanicConversationPage's summary card — see that widget's
  /// customerName/vehicleInfo/serviceLabel doc comment.
  final String vehicleInfo;
  final String service;

  static const _buttonHeight = 48.0;
  static const _noteBackground = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: MechanicAppointmentDetailsPage._cardRadius,
      border: Border.all(color: AppColors.divider, width: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Müşteri Bilgileri',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          _IconTextRow(icon: Icons.person_outline, text: customerName),
          const SizedBox(height: 8),
          _IconTextRow(icon: Icons.phone_outlined, text: phoneNumber),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Mesafe', value: distance),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Müşteri Notu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: _noteBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              note,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: _buttonHeight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.turquoise,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: phoneNumber.replaceAll(' ', ''))),
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Ara'),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: _buttonHeight,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MechanicConversationPage(
                          chatId: businessId,
                          customerName: customerName,
                          vehicleInfo: vehicleInfo,
                          serviceLabel: service,
                          appointment: appointment,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Mesaj Gönder'),
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

/// Icon + plain text row (no bold label prefix) — for fields that read
/// naturally on their own, like a date or a name.
class _IconTextRow extends StatelessWidget {
  const _IconTextRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
          ),
        ),
      ],
    );
  }
}

/// Icon + "Label: value" row — same treatment as the rest of the mechanic
/// module (see MechanicRequestDetailsPage._InfoRow).
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

/// Small rounded chip for the service — same treatment as _ServiceBadge
/// elsewhere in the mechanic module.
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
