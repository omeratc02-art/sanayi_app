import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/turkish_date.dart';
import '../../widgets/booking/booking_confirm_bar.dart';
import '../../widgets/booking/booking_success_dialog.dart';
import '../../widgets/booking/date_strip.dart';
import '../../widgets/booking/mechanic_summary_card.dart';
import '../../widgets/booking/section_label.dart';
import '../../widgets/booking/service_type_selector.dart';
import '../../widgets/booking/time_slot_grid.dart';
import '../../widgets/booking/vehicle_info_form.dart';

class AppointmentBookingPage extends StatefulWidget {
  const AppointmentBookingPage({super.key, required this.mechanic});

  final Mechanic mechanic;

  @override
  State<AppointmentBookingPage> createState() => _AppointmentBookingPageState();
}

class _AppointmentBookingPageState extends State<AppointmentBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _plateController = TextEditingController();
  final _notesController = TextEditingController();

  late final List<DateTime> _dates;
  late DateTime _selectedDate;
  String? _selectedTime;
  String? _selectedService;

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
    _brandController.dispose();
    _plateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTime = null;
    });
  }

  void _handleConfirm() {
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (_selectedTime == null || _selectedService == null || !isFormValid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Lütfen tüm gerekli alanları doldurun.')));
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => BookingSuccessDialog(
        mechanicName: widget.mechanic.name,
        dateLabel: formatFullDate(_selectedDate),
        timeLabel: _selectedTime!,
        serviceLabel: _selectedService!,
        vehicleLabel: '${_brandController.text.trim()} · ${_plateController.text.trim()}',
      ),
    ).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = MockData.timeSlotsFor(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Randevu Al')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MechanicSummaryCard(mechanic: widget.mechanic),
              const SizedBox(height: 24),
              const SectionLabel(text: 'Tarih Seçin'),
              const SizedBox(height: 10),
              DateStrip(dates: _dates, selected: _selectedDate, onSelected: _selectDate),
              const SizedBox(height: 6),
              Text(
                formatFullDate(_selectedDate),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              const SectionLabel(text: 'Saat Seçin'),
              const SizedBox(height: 10),
              TimeSlotGrid(
                slots: timeSlots,
                selected: _selectedTime,
                onSelected: (time) => setState(() => _selectedTime = time),
              ),
              const SizedBox(height: 22),
              const SectionLabel(text: 'Hizmet Türü'),
              const SizedBox(height: 10),
              ServiceTypeSelector(
                selected: _selectedService,
                onSelected: (service) => setState(() => _selectedService = service),
              ),
              const SizedBox(height: 22),
              const SectionLabel(text: 'Araç Bilgileri'),
              const SizedBox(height: 10),
              VehicleInfoForm(brandController: _brandController, plateController: _plateController),
              const SizedBox(height: 22),
              const SectionLabel(text: 'Notlar (opsiyonel)'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Ustaya iletmek istediğiniz bir not var mı?',
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BookingConfirmBar(
        priceRangeLabel: widget.mechanic.priceRangeLabel,
        onConfirm: _handleConfirm,
      ),
    );
  }
}
