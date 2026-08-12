import 'package:flutter/material.dart';

import '../../data/appointment_request_store.dart';
import '../../data/booking_history.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/booking/date_strip.dart';
import '../../widgets/booking/section_label.dart';

/// Premium "appointment request" flow reached from every "Randevu Al"
/// button in the app. The customer isn't booking a fixed slot — they're
/// requesting one: a preferred date plus a preferred arrival window (or "no
/// preference"), with an optional note. The service provider proposes the
/// exact arrival time afterward; see [AppointmentRequestStore] and the
/// "Randevularım" tab where that response and the accept/request-another
/// actions live.
class AppointmentRequestPage extends StatefulWidget {
  const AppointmentRequestPage({super.key, required this.mechanic, required this.serviceLabel});

  final Mechanic mechanic;
  final String serviceLabel;

  @override
  State<AppointmentRequestPage> createState() => _AppointmentRequestPageState();
}

class _AppointmentRequestPageState extends State<AppointmentRequestPage> {
  static const _firstAvailableLabel = 'İlk Müsait Saat';

  final _notesController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late final List<DateTime> _dates;
  late DateTime _selectedDate;
  String? _selectedWindow;
  bool _kvkkAccepted = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    _dates = List.generate(14, (i) => startOfToday.add(Duration(days: i)));
    _selectedDate = _dates.first;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedWindow = null;
    });
  }

  void _handleSubmit() {
    BookingHistory.markCompleted(widget.mechanic.name);

    AppointmentRequestStore.instance.submit(
      mechanicName: widget.mechanic.name,
      date: _selectedDate,
      preferredWindowLabel: _selectedWindow!,
      serviceLabel: widget.serviceLabel,
    );

    showDialog<void>(
      context: context,
      builder: (_) => _RequestSubmittedDialog(
        mechanicName: widget.mechanic.name,
        dateLabel: formatFullDate(_selectedDate),
        windowLabel: _selectedWindow!,
      ),
    ).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Randevu Talep Zaman Aralığını Seç')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.turquoise),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                        children: [
                          const TextSpan(
                            text: 'Seçtiğiniz zaman aralığı servis sağlayıcıya talep olarak iletilir.',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const TextSpan(
                            text: ' Talebiniz onaylandığında size bildirim gönderilecektir.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _RequestSummaryCard(mechanic: widget.mechanic, serviceLabel: widget.serviceLabel),
            const SizedBox(height: 24),
            const SectionLabel(text: 'Tercih Ettiğiniz Tarih'),
            const SizedBox(height: 10),
            DateStrip(dates: _dates, selected: _selectedDate, onSelected: _selectDate),
            const SizedBox(height: 6),
            Text(
              formatFullDate(_selectedDate),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            const SectionLabel(text: 'Tercih Ettiğiniz Saat Aralığı'),
            const SizedBox(height: 10),
            _TimeWindowChips(
              selected: _selectedWindow,
              onSelected: (window) => setState(() => _selectedWindow = window),
            ),
            const SizedBox(height: 10),
            _FirstAvailableOption(
              isSelected: _selectedWindow == _firstAvailableLabel,
              onTap: () => setState(() => _selectedWindow = _firstAvailableLabel),
            ),
            const SizedBox(height: 14),
            const _InfoBanner(
              message: 'Tercih ettiğiniz saat aralığı servis sağlayıcıya iletilecektir. Servis sağlayıcı, '
                  'iş yoğunluğuna göre kesin varış saatini onaylayacaktır.',
            ),
            const SizedBox(height: 22),
            const SectionLabel(text: 'İletişim Bilgileri'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon Numarası'),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 22),
            const SectionLabel(text: 'Notlar (opsiyonel)'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Servis sağlayıcıya iletmek istediğiniz bir not var mı?',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SubmitBar(onSubmit: _selectedWindow == null ? null : _handleSubmit),
    );
  }
}

/// Read-only recap of what's being requested — the service already chosen
/// upstream, which provider it's for, and the provider's estimated price —
/// so the customer can confirm at a glance before picking a time.
class _RequestSummaryCard extends StatelessWidget {
  const _RequestSummaryCard({required this.mechanic, required this.serviceLabel});

  final Mechanic mechanic;
  final String serviceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(icon: Icons.build_outlined, label: 'Seçili Hizmet', value: serviceLabel),
          const SizedBox(height: 12),
          _SummaryRow(icon: Icons.storefront_outlined, label: 'Servis Sağlayıcı', value: mechanic.name),
          const SizedBox(height: 12),
          _SummaryRow(icon: Icons.payments_outlined, label: 'Tahmini Ücret', value: mechanic.priceRangeLabel),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The "no preference" option — visually distinct from the fixed-window
/// chips above it since it carries its own explanatory copy rather than
/// just a label.
class _FirstAvailableOption extends StatelessWidget {
  const _FirstAvailableOption({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bolt_rounded, size: 20, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İlk Müsait Saat',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Tercih ettiğim bir saat yok. Servis sağlayıcının en erken uygun olduğu zamanda '
                    'beni bilgilendirin.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}


/// Preferred time-range picker built on [Wrap] + [ChoiceChip] — single-select
/// against [selected], mirroring the same chip pattern [ReviewsPage] already
/// uses for its sort filters (no checkmark, turquoise fill when selected).
class _TimeWindowChips extends StatelessWidget {
  const _TimeWindowChips({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  static const _labels = ['08:00 – 10:00', '10:00 – 12:00', '13:00 – 15:00', '15:00 – 17:00'];
  static const _chipWidth = 132.0;
  static const _chipHeight = 46.0;
  static const _borderColor = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _buildChip(_labels[i]),
        ],
      ],
    );
  }

  Widget _buildChip(String label) {
    final isSelected = selected == label;
    return SizedBox(
      width: _chipWidth,
      height: _chipHeight,
      child: ChoiceChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onSelected(label),
        selectedColor: AppColors.turquoise,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isSelected ? AppColors.turquoise : _borderColor, width: 1),
        ),
        elevation: isSelected ? 3 : 0,
        pressElevation: 4,
        shadowColor: AppColors.turquoise.withValues(alpha: 0.35),
        selectedShadowColor: AppColors.turquoise.withValues(alpha: 0.35),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.onSubmit});

  final VoidCallback? onSubmit;

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
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onSubmit,
              child: const Text('Randevu Talebini Gönder'),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestSubmittedDialog extends StatelessWidget {
  const _RequestSubmittedDialog({required this.mechanicName, required this.dateLabel, required this.windowLabel});

  final String mechanicName;
  final String dateLabel;
  final String windowLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Randevu Talebiniz Alındı!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              '$mechanicName, tercih ettiğiniz saati inceleyip kesin varış saatini kısa süre içinde '
              'onaylayacak.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _DialogSummaryRow(icon: Icons.event, label: dateLabel),
                  const SizedBox(height: 8),
                  _DialogSummaryRow(icon: Icons.schedule, label: windowLabel),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogSummaryRow extends StatelessWidget {
  const _DialogSummaryRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
