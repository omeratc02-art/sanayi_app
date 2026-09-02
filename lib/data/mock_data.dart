import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/mechanic.dart';
import '../models/review.dart';
import '../models/time_slot.dart';
import '../models/vehicle.dart';

class MockData {
  MockData._();

  // Ordered by real customer demand rather than alphabetically or by icon —
  // periodic maintenance and oil/filter changes are the two most frequently
  // requested services and are deliberately adjacent, followed by brake and
  // engine work (the next-highest-demand categories).
  static const categories = [
    ServiceCategory(label: 'Periyodik Bakım', subtitle: 'Genel kontrol', icon: Icons.event_repeat),
    ServiceCategory(label: 'Yağ Değişimi', subtitle: 'Yağ & filtre', icon: Icons.oil_barrel),
    ServiceCategory(label: 'Fren Sistemi', subtitle: 'Balata & disk', icon: Icons.album),
    ServiceCategory(label: 'Motor', subtitle: 'Motor arızası', icon: Icons.settings),
    ServiceCategory(label: 'Akü & Elektrik', subtitle: 'Şarj sistemi', icon: Icons.battery_charging_full),
    ServiceCategory(label: 'Lastik & Jant', subtitle: 'Değişim & balans', icon: Icons.tire_repair),
    ServiceCategory(label: 'Şanzıman ve Debriyaj', subtitle: 'Vites & aktarma', icon: Icons.sync_alt),
    ServiceCategory(label: 'Tüm Hizmetler', subtitle: 'Tüm kategorileri gör', icon: Icons.more_horiz),
  ];

  // The complete Araç Tamiri sub-service taxonomy — every real category,
  // with no separate "teaser" subset left behind a tap-through. Shown
  // directly on VehicleRepairCategoryPage (via CategoryGrid) and reused
  // as-is for the shared Ekspertiz/Sigorta "Tüm Kategoriler" pages
  // (EkspertizPage/SigortaPage), parameterized with their own taxonomies
  // instead of this one.
  static const allServiceCategories = [
    ServiceCategory(label: 'Periyodik Bakım', subtitle: 'Genel kontrol', icon: Icons.event_repeat),
    ServiceCategory(label: 'Yağ Değişimi', subtitle: 'Yağ & filtre', icon: Icons.oil_barrel),
    ServiceCategory(label: 'Fren Sistemi', subtitle: 'Balata & disk', icon: Icons.album),
    ServiceCategory(label: 'Motor', subtitle: 'Motor arızası', icon: Icons.settings),
    ServiceCategory(label: 'Akü & Elektrik', subtitle: 'Şarj sistemi', icon: Icons.battery_charging_full),
    ServiceCategory(label: 'Lastik & Jant', subtitle: 'Değişim & balans', icon: Icons.tire_repair),
    ServiceCategory(label: 'Şanzıman ve Debriyaj', subtitle: 'Vites & aktarma', icon: Icons.sync_alt),
    ServiceCategory(label: 'Klima', subtitle: 'Klima bakımı', icon: Icons.ac_unit),
    ServiceCategory(label: 'Süspansiyon & Direksiyon', subtitle: 'Amortisör & denge', icon: Icons.height),
    ServiceCategory(label: 'Kaporta & Boya', subtitle: 'Gövde & boya', icon: Icons.format_paint),
    ServiceCategory(label: 'Cam & Aydınlatma', subtitle: 'Cam & far', icon: Icons.lightbulb_outline),
    ServiceCategory(label: 'Egzoz Sistemi', subtitle: 'Egzoz sistemi', icon: Icons.air),
  ];

  // Sub-service taxonomy for the Ekspertiz/Sigorta category grids — real
  // navigation labels, not mock business data, matching [categories]'s own
  // role: what real mechanicAccounts.hizmetler entries get filtered against.
  static const ekspertizCategories = [
    ServiceCategory(
      label: 'Araç Alım Ekspertizi',
      subtitle: 'İkinci el alım kontrolü',
      icon: Icons.assignment_turned_in_outlined,
    ),
    ServiceCategory(label: 'Hasar Tespiti', subtitle: 'Kaza & hasar analizi', icon: Icons.report_problem_outlined),
    ServiceCategory(
      label: 'Boya-Kaporta Kontrolü',
      subtitle: 'Boya & gövde muayenesi',
      icon: Icons.format_paint_outlined,
    ),
    ServiceCategory(
      label: 'Motor & Şanzıman Kontrolü',
      subtitle: 'Mekanik durum tespiti',
      icon: Icons.settings_outlined,
    ),
    ServiceCategory(label: 'Genel Ekspertiz Raporu', subtitle: 'Kapsamlı araç raporu', icon: Icons.description_outlined),
  ];

  static const sigortaCategories = [
    ServiceCategory(label: 'Trafik Sigortası', subtitle: 'Zorunlu trafik poliçesi', icon: Icons.local_police_outlined),
    ServiceCategory(label: 'Kasko', subtitle: 'Araç hasar güvencesi', icon: Icons.shield_outlined),
    ServiceCategory(label: 'Ferdi Kaza', subtitle: 'Kişisel kaza sigortası', icon: Icons.personal_injury_outlined),
    ServiceCategory(label: 'Yol Yardım Paketi', subtitle: '7/24 yol desteği', icon: Icons.support_agent_outlined),
  ];

  static const popularMechanics = [
    Mechanic(
      name: 'Karabaş Oto Servis',
      specialty: 'Genel Bakım',
      categories: ['Motor', 'Yağ Değişimi'],
      rating: 4.8,
      reviewCount: 214,
      distanceValue: 1.2,
      priceMin: 350,
      priceMax: 650,
      isVerified: true,
      repeatCustomerRate: 88,
      workingHours: 'Pzt - Cmt: 08:00 - 19:00',
      phone: '0212 345 12 34',
      address: 'Sanayi Sitesi 2. Blok No:8, Konya',
    ),
    Mechanic(
      name: 'Usta Motorlu Servis',
      specialty: 'Motor & Şanzıman',
      categories: ['Motor'],
      rating: 4.6,
      reviewCount: 138,
      distanceValue: 2.4,
      priceMin: 500,
      priceMax: 900,
      isVerified: true,
      repeatCustomerRate: 79,
      workingHours: 'Pzt - Cmt: 08:30 - 18:30',
      phone: '0212 556 22 10',
      address: 'Organize Sanayi Bölgesi 5. Cadde No:21, Konya',
    ),
    Mechanic(
      name: 'Hızlı Lastikçi',
      specialty: 'Lastik & Balans',
      categories: ['Lastik & Jant'],
      rating: 4.7,
      reviewCount: 96,
      distanceValue: 0.8,
      priceMin: 200,
      priceMax: 380,
      isVerified: true,
      repeatCustomerRate: 84,
      workingHours: 'Her gün: 09:00 - 20:00',
      phone: '0212 667 45 09',
      address: 'Fatih Mah. Lastikçiler Sok. No:5, Konya',
    ),
    Mechanic(
      name: 'Öztürk Elektrik',
      specialty: 'Akü & Elektrik',
      categories: ['Akü & Elektrik'],
      rating: 4.5,
      reviewCount: 71,
      distanceValue: 3.1,
      priceMin: 150,
      priceMax: 320,
      isVerified: true,
      repeatCustomerRate: 71,
      workingHours: 'Pzt - Cmt: 09:00 - 18:00',
      phone: '0212 778 90 12',
      address: 'Yenişehir Mah. Elektrikçiler Cad. No:34, Konya',
    ),
  ];

  static const topRatedMechanics = [
    Mechanic(
      name: 'Güven Oto Bakım',
      specialty: 'Genel Bakım & Onarım',
      categories: ['Motor', 'Fren Sistemi'],
      rating: 4.9,
      reviewCount: 312,
      distanceValue: 1.5,
      priceMin: 400,
      priceMax: 750,
      isVerified: true,
      repeatCustomerRate: 91,
      workingHours: 'Pzt - Cmt: 08:00 - 19:00',
      phone: '0212 234 56 78',
      address: 'Merkez Mah. Sanayi Cad. No:14, Konya',
    ),
    Mechanic(
      name: 'Master Fren Sistemleri',
      specialty: 'Fren & Süspansiyon',
      categories: ['Fren Sistemi'],
      rating: 4.9,
      reviewCount: 187,
      distanceValue: 2.0,
      priceMin: 300,
      priceMax: 550,
      isVerified: true,
      repeatCustomerRate: 87,
      workingHours: 'Pzt - Cmt: 08:30 - 18:30',
      phone: '0212 890 11 22',
      address: 'Karatay Sanayi Sitesi C Blok No:9, Konya',
    ),
    Mechanic(
      name: 'Yılmaz Yağ & Filtre',
      specialty: 'Yağ Değişimi',
      categories: ['Yağ Değişimi'],
      rating: 4.8,
      reviewCount: 245,
      distanceValue: 0.6,
      priceMin: 250,
      priceMax: 420,
      isVerified: true,
      repeatCustomerRate: 90,
      workingHours: 'Pzt - Cmt: 08:00 - 18:00, Pazar Kapalı',
      phone: '0212 345 67 89',
      address: 'Selçuklu Mah. Yağcılar Sok. No:3, Konya',
    ),
    Mechanic(
      name: 'Doğan Lastik Center',
      specialty: 'Lastik & Rot Balans',
      categories: ['Lastik & Jant'],
      rating: 4.7,
      reviewCount: 159,
      distanceValue: 4.2,
      priceMin: 180,
      priceMax: 360,
      isVerified: true,
      repeatCustomerRate: 82,
      workingHours: 'Her gün: 08:00 - 20:00',
      phone: '0212 456 78 90',
      address: 'Meram Sanayi Sitesi No:41, Konya',
    ),
  ];

  static const otherMechanics = [
    Mechanic(
      name: 'Aksoy Akü Merkezi',
      specialty: 'Akü Değişimi & Şarj',
      categories: ['Akü & Elektrik'],
      rating: 4.6,
      reviewCount: 58,
      distanceValue: 2.8,
      priceMin: 180,
      priceMax: 300,
      isVerified: true,
      repeatCustomerRate: 76,
      workingHours: 'Pzt - Cmt: 09:00 - 19:00',
      phone: '0212 123 45 67',
      address: 'Beyhekim Mah. Akücüler Sok. No:11, Konya',
    ),
    Mechanic(
      name: 'Çelik Motor Tamir',
      specialty: 'Motor Revizyon',
      categories: ['Motor'],
      rating: 4.4,
      reviewCount: 44,
      distanceValue: 5.0,
      priceMin: 600,
      priceMax: 1100,
      repeatCustomerRate: 68,
      workingHours: 'Pzt - Cmt: 09:00 - 18:00',
      phone: '0212 999 88 77',
      address: 'Organize Sanayi Bölgesi 12. Cadde No:2, Konya',
    ),
    Mechanic(
      name: 'Best Lastik Oto',
      specialty: 'Lastik & Jant',
      categories: ['Lastik & Jant'],
      rating: 4.3,
      reviewCount: 39,
      distanceValue: 1.9,
      priceMin: 220,
      priceMax: 400,
      repeatCustomerRate: 65,
      workingHours: 'Pzt - Cmt: 09:00 - 18:00',
      phone: '0212 111 22 33',
      address: 'Fetih Mah. Jantçılar Cad. No:7, Konya',
    ),
    Mechanic(
      name: 'Nur Yağlama Servisi',
      specialty: 'Yağ & Filtre Değişimi',
      categories: ['Yağ Değişimi'],
      rating: 4.6,
      reviewCount: 102,
      distanceValue: 3.5,
      priceMin: 230,
      priceMax: 390,
      isVerified: true,
      repeatCustomerRate: 80,
      workingHours: 'Her gün: 08:00 - 19:00',
      phone: '0212 222 33 44',
      address: 'Aziziye Mah. Yağlama Sok. No:19, Konya',
    ),
  ];

  static const allMechanics = [...popularMechanics, ...topRatedMechanics, ...otherMechanics];

  static const userVehicles = [
    Vehicle(name: 'Peugeot 208', year: 2017),
    Vehicle(name: 'Volkswagen Jetta', year: 2013),
  ];

  // Shared across every mechanic/service center — there's no per-business
  // review data in this mock dataset, matching how [allMechanics] itself is
  // reused as "nearby service centers" regardless of which service was
  // tapped to get there.
  static final sampleReviews = [
    Review(
      authorName: 'Ahmet Y.',
      rating: 5,
      date: DateTime(2026, 7, 2),
      comment: 'Çok memnun kaldım, işlemi zamanında ve özenle tamamladılar. Kesinlikle tavsiye ederim.',
      hasPhoto: true,
      helpfulCount: 24,
    ),
    Review(
      authorName: 'Elif K.',
      rating: 5,
      date: DateTime(2026, 6, 28),
      comment: 'Fiyatlar gayet makul, ustalar bilgili ve güler yüzlü. Randevu saatine tam uydular.',
      helpfulCount: 18,
    ),
    Review(
      authorName: 'Mehmet S.',
      rating: 4,
      date: DateTime(2026, 6, 20),
      comment: 'Genel olarak iyi bir deneyimdi, sadece bekleme süresi biraz uzun oldu.',
      helpfulCount: 9,
    ),
    Review(
      authorName: 'Zeynep A.',
      rating: 5,
      date: DateTime(2026, 6, 14),
      comment: 'Aracımı teslim ettiğim gibi geri aldım, hiçbir sorun yaşamadım. Teşekkürler!',
      hasPhoto: true,
      helpfulCount: 31,
    ),
    Review(
      authorName: 'Burak T.',
      rating: 3,
      date: DateTime(2026, 6, 5),
      comment: 'İşçilik iyiydi ama iletişim konusunda biraz daha titiz olabilirler.',
      helpfulCount: 5,
    ),
    Review(
      authorName: 'Selin D.',
      rating: 4,
      date: DateTime(2026, 5, 27),
      comment: 'Doğrulanmış usta rozetine güvenerek gittim, beklentimi karşıladılar.',
      helpfulCount: 12,
    ),
    Review(
      authorName: 'Can Ö.',
      rating: 2,
      date: DateTime(2026, 5, 19),
      comment: 'Randevu saatine göre biraz gecikme oldu, bunun dışında iş kalitesi fena değildi.',
      helpfulCount: 3,
    ),
    Review(
      authorName: 'Deniz R.',
      rating: 5,
      date: DateTime(2026, 5, 10),
      comment: 'Şeffaf fiyatlandırma ve düzgün bir hizmet aldım. Tekrar tercih edeceğim.',
      helpfulCount: 15,
    ),
  ];

  /// Preferred arrival time windows offered on the appointment request form —
  /// the customer picks one of these instead of an exact time; the provider
  /// proposes the exact arrival time afterward (see [AppointmentRequestStore]).
  static const _timeWindowLabels = [
    '08:00 – 10:00',
    '10:00 – 12:00',
    '13:00 – 15:00',
    '15:00 – 17:00',
    'İlk Müsait Saat',
  ];

  static List<TimeSlot> timeWindowsFor(DateTime date) {
    final now = DateTime.now();
    return _timeWindowLabels.map((label) {
      final endHourMatch = RegExp(r'(\d{2}):\d{2}$').firstMatch(label);
      if (endHourMatch == null) return TimeSlot(label: label, isAvailable: true);
      final windowEnd = DateTime(date.year, date.month, date.day, int.parse(endHourMatch.group(1)!));
      return TimeSlot(label: label, isAvailable: !windowEnd.isBefore(now));
    }).toList();
  }
}
