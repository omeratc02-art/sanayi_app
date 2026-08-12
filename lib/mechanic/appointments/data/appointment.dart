import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Status of an appointment across its lifecycle, from an accepted request
/// through to completion. Distinct from the customer-facing AppointmentStatus
/// in dummy_appointment.dart, which belongs to an unrelated screen and must
/// not be affected by changes here.
enum AppointmentStatus { pending, accepted, inProgress, completed, cancelled, declined }

extension AppointmentStatusPresentation on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.pending => 'Beklemede',
    AppointmentStatus.accepted => 'Onaylandı',
    AppointmentStatus.inProgress => 'Devam Ediyor',
    AppointmentStatus.completed => 'Tamamlandı',
    AppointmentStatus.cancelled => 'İptal Edildi',
    AppointmentStatus.declined => 'Reddedildi',
  };

  Color get color => switch (this) {
    AppointmentStatus.pending => Colors.orange.shade700,
    AppointmentStatus.accepted => Colors.green.shade700,
    AppointmentStatus.inProgress => Colors.blue.shade700,
    AppointmentStatus.completed => Colors.blue.shade700,
    AppointmentStatus.cancelled => Colors.red.shade700,
    AppointmentStatus.declined => Colors.red.shade700,
  };
}

/// A complete appointment record — created by accepting a pending request
/// (see MechanicAppointmentsScreen._acceptRequest) or, eventually, loaded
/// directly from a real backend. Dummy data only for now; mirrors the shape
/// a real Firestore-backed repository would provide.
class Appointment {
  const Appointment({
    required this.appointmentId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.licensePlate,
    required this.serviceType,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.estimatedDuration,
    required this.customerNote,
    required this.status,
    required this.createdAt,
    required this.distance,
    this.businessId = '',
  });

  final String appointmentId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String vehicleBrand;
  final String vehicleModel;
  final String licensePlate;
  final String serviceType;

  /// Calendar date only (year/month/day) — time-of-day lives in
  /// [appointmentTime].
  final DateTime appointmentDate;
  final TimeOfDay appointmentTime;
  final Duration estimatedDuration;
  final String customerNote;
  final AppointmentStatus status;
  final DateTime createdAt;

  /// Not part of the required field set — kept because
  /// MechanicAppointmentDetailsPage's customer card already displays how
  /// far the customer is, and the existing UI must not change.
  final String distance;

  /// The stable per-business id (mechanicChatId(name), same as chats and
  /// mechanicAccounts.businessId) this appointment belongs to. Defaults to
  /// '' so the existing dummy schedule below (never written to or read
  /// from Firestore) doesn't need one — only real customer requests and
  /// the mechanic screen's own businessId-filtered query rely on it.
  final String businessId;

  /// [appointmentDate] and [appointmentTime] combined into one instant —
  /// used for calendar positioning and time formatting.
  DateTime get start => DateTime(
    appointmentDate.year,
    appointmentDate.month,
    appointmentDate.day,
    appointmentTime.hour,
    appointmentTime.minute,
  );

  /// Reads back a document written by AppointmentRepository.saveAppointment
  /// — mirrors that method's field mapping exactly (Timestamp -> DateTime,
  /// "HH:mm" string -> TimeOfDay, minutes -> Duration, enum name -> enum).
  factory Appointment.fromFirestore(Map<String, dynamic> data) {
    final appointmentDate = data['appointmentDate'];
    final createdAt = data['createdAt'];
    final timeParts = (data['appointmentTime'] as String? ?? '00:00').split(':');
    return Appointment(
      appointmentId: data['appointmentId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      vehicleBrand: data['vehicleBrand'] as String? ?? '',
      vehicleModel: data['vehicleModel'] as String? ?? '',
      licensePlate: data['licensePlate'] as String? ?? '',
      serviceType: data['serviceType'] as String? ?? '',
      appointmentDate: appointmentDate is Timestamp ? appointmentDate.toDate() : DateTime.now(),
      appointmentTime: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      estimatedDuration: Duration(minutes: data['estimatedDurationMinutes'] as int? ?? 0),
      customerNote: data['customerNote'] as String? ?? '',
      status: AppointmentStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => AppointmentStatus.accepted,
      ),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      distance: data['distance'] as String? ?? '',
      businessId: data['businessId'] as String? ?? '',
    );
  }
}

/// Dummy schedule spanning several days around "today" so the calendar has
/// something to show regardless of which date is selected.
List<Appointment> buildDummyAppointments() {
  final today = DateTime.now();
  DateTime dateOnly(int dayOffset) {
    final day = today.add(Duration(days: dayOffset));
    return DateTime(day.year, day.month, day.day);
  }

  return [
    Appointment(
      appointmentId: 'APT-2001',
      customerId: 'CUST-1001',
      customerName: 'Ahmet Yılmaz',
      customerPhone: '0532 111 22 33',
      vehicleBrand: 'Renault',
      vehicleModel: 'Clio',
      licensePlate: '34 ABC 123',
      serviceType: 'Yağ Değişimi',
      appointmentDate: dateOnly(0),
      appointmentTime: const TimeOfDay(hour: 9, minute: 0),
      estimatedDuration: const Duration(minutes: 60),
      customerNote: 'Aracımda ayrıca hafif bir fren sesi var, kontrol edebilir misiniz?',
      status: AppointmentStatus.accepted,
      createdAt: today.subtract(const Duration(days: 2)),
      distance: '3.2 km',
    ),
    Appointment(
      appointmentId: 'APT-2002',
      customerId: 'CUST-2001',
      customerName: 'Mehmet Demir',
      customerPhone: '0532 123 45 67',
      vehicleBrand: 'Toyota',
      vehicleModel: 'Corolla',
      licensePlate: '35 DEF 789',
      serviceType: 'Akü Değişimi',
      appointmentDate: dateOnly(0),
      appointmentTime: const TimeOfDay(hour: 11, minute: 30),
      estimatedDuration: const Duration(minutes: 45),
      customerNote: 'Sabahları araç bazen zor çalışıyor, kontrol edilmesini istiyorum.',
      status: AppointmentStatus.pending,
      createdAt: today.subtract(const Duration(days: 1)),
      distance: '2.1 km',
    ),
    Appointment(
      appointmentId: 'APT-2003',
      customerId: 'CUST-2002',
      customerName: 'Mehmet Usta',
      customerPhone: '0533 222 33 44',
      vehicleBrand: 'Peugeot',
      vehicleModel: '208',
      licensePlate: '27 GHI 456',
      serviceType: 'Periyodik Bakım (10.000 km)',
      appointmentDate: dateOnly(1),
      appointmentTime: const TimeOfDay(hour: 10, minute: 0),
      estimatedDuration: const Duration(minutes: 90),
      customerNote: 'Uzun yol öncesi genel kontrol istiyorum.',
      status: AppointmentStatus.accepted,
      createdAt: today.subtract(const Duration(days: 3)),
      distance: '4.5 km',
    ),
    Appointment(
      appointmentId: 'APT-2004',
      customerId: 'CUST-2003',
      customerName: 'Ahmet Yıldız',
      customerPhone: '0534 333 44 55',
      vehicleBrand: 'Renault',
      vehicleModel: 'Clio',
      licensePlate: '34 ABC 123',
      serviceType: 'Fren Balata Değişimi',
      appointmentDate: dateOnly(2),
      appointmentTime: const TimeOfDay(hour: 14, minute: 0),
      estimatedDuration: const Duration(minutes: 60),
      customerNote: 'Fren yaparken hafif titreme hissediyorum.',
      status: AppointmentStatus.cancelled,
      createdAt: today.subtract(const Duration(days: 4)),
      distance: '5.8 km',
    ),
    Appointment(
      appointmentId: 'APT-2005',
      customerId: 'CUST-2004',
      customerName: 'Emre Kaya',
      customerPhone: '0535 444 55 66',
      vehicleBrand: 'Fiat',
      vehicleModel: 'Egea',
      licensePlate: '06 XYZ 456',
      serviceType: 'Lastik Değişimi',
      appointmentDate: dateOnly(3),
      appointmentTime: const TimeOfDay(hour: 9, minute: 30),
      estimatedDuration: const Duration(minutes: 30),
      customerNote: 'Kış lastiklerine geçiş yapılacak.',
      status: AppointmentStatus.pending,
      createdAt: today.subtract(const Duration(days: 1)),
      distance: '1.7 km',
    ),
    Appointment(
      appointmentId: 'APT-2006',
      customerId: 'CUST-1002',
      customerName: 'Elif Kaya',
      customerPhone: '0536 555 66 77',
      vehicleBrand: 'Fiat',
      vehicleModel: 'Egea',
      licensePlate: '06 XYZ 456',
      serviceType: 'Fren Bakımı',
      appointmentDate: dateOnly(3),
      appointmentTime: const TimeOfDay(hour: 13, minute: 0),
      estimatedDuration: const Duration(minutes: 60),
      customerNote: 'Öğleden sonra müsaitim, sabah saatleri bana uygun değil.',
      status: AppointmentStatus.completed,
      createdAt: today.subtract(const Duration(days: 5)),
      distance: '5.8 km',
    ),
    Appointment(
      appointmentId: 'APT-2007',
      customerId: 'CUST-1001',
      customerName: 'Ahmet Yılmaz',
      customerPhone: '0532 111 22 33',
      vehicleBrand: 'Renault',
      vehicleModel: 'Clio',
      licensePlate: '34 ABC 123',
      serviceType: 'Klima Bakımı',
      appointmentDate: dateOnly(5),
      appointmentTime: const TimeOfDay(hour: 15, minute: 30),
      estimatedDuration: const Duration(minutes: 45),
      customerNote: 'Klimadan garip bir koku geliyor.',
      status: AppointmentStatus.accepted,
      createdAt: today.subtract(const Duration(days: 2)),
      distance: '3.2 km',
    ),
  ];
}
