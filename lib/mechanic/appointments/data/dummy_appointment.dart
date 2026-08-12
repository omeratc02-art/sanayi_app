import 'package:flutter/material.dart';

/// Status of an upcoming appointment, with its display label and badge
/// color baked in so callers never have to duplicate that mapping.
enum AppointmentStatus { confirmed, pending, cancelled, completed }

extension AppointmentStatusPresentation on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.confirmed => 'Onaylandı',
    AppointmentStatus.pending => 'Beklemede',
    AppointmentStatus.cancelled => 'İptal Edildi',
    AppointmentStatus.completed => 'Tamamlandı',
  };

  Color get color => switch (this) {
    AppointmentStatus.confirmed => Colors.green.shade700,
    AppointmentStatus.pending => Colors.orange.shade700,
    AppointmentStatus.cancelled => Colors.red.shade700,
    AppointmentStatus.completed => Colors.blue.shade700,
  };
}

/// Stand-in for an upcoming appointment until a real Firestore-backed
/// repository exists — mirrors the shape [AppointmentCard] needs so that
/// swapping this out for real data later is just a new data source, not a
/// layout change (see ChatRepository for the pattern this would follow).
class DummyAppointment {
  const DummyAppointment({
    required this.status,
    required this.daysUntil,
    required this.date,
    required this.time,
    required this.service,
    required this.mechanicName,
    required this.mechanicRating,
    required this.mechanicReviewCount,
    required this.vehicle,
    required this.shopName,
    required this.location,
  });

  final AppointmentStatus status;
  final int daysUntil;
  final String date;
  final String time;
  final String service;
  final String mechanicName;
  final double mechanicRating;
  final int mechanicReviewCount;
  final String vehicle;
  final String shopName;
  final String location;
}

const dummyUpcomingAppointments = [
  DummyAppointment(
    status: AppointmentStatus.confirmed,
    daysUntil: 9,
    date: '12 Ağustos 2026',
    time: '14:30',
    service: 'Periyodik Bakım (10.000 km)',
    mechanicName: 'Mehmet Usta',
    mechanicRating: 4.9,
    mechanicReviewCount: 328,
    vehicle: '2017 Peugeot 208',
    shopName: 'Şahin Otomotiv',
    location: 'Gaziantep / Şahinbey',
  ),
  DummyAppointment(
    status: AppointmentStatus.pending,
    daysUntil: 3,
    date: '6 Ağustos 2026',
    time: '10:00',
    service: 'Fren Balata Değişimi',
    mechanicName: 'Ahmet Yıldız',
    mechanicRating: 4.7,
    mechanicReviewCount: 156,
    vehicle: '2020 Renault Clio',
    shopName: 'Yıldız Oto Servis',
    location: 'Gaziantep / Şehitkamil',
  ),
  DummyAppointment(
    status: AppointmentStatus.confirmed,
    daysUntil: 14,
    date: '17 Ağustos 2026',
    time: '11:15',
    service: 'Lastik Değişimi',
    mechanicName: 'Emre Kaya',
    mechanicRating: 4.8,
    mechanicReviewCount: 212,
    vehicle: '2019 Fiat Egea',
    shopName: 'Kaya Lastik & Bakım',
    location: 'Gaziantep / Şahinbey',
  ),
];
