import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/mechanic.dart';
import '../models/time_slot.dart';

class MockData {
  MockData._();

  static const categories = [
    ServiceCategory(label: 'Motor', icon: Icons.settings),
    ServiceCategory(label: 'Fren', icon: Icons.album),
    ServiceCategory(label: 'Lastik', icon: Icons.tire_repair),
    ServiceCategory(label: 'Akü', icon: Icons.battery_charging_full),
    ServiceCategory(label: 'Yağ Değişimi', icon: Icons.oil_barrel),
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
      categories: ['Lastik'],
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
      categories: ['Akü'],
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
      categories: ['Motor', 'Fren'],
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
      categories: ['Fren'],
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
      isOpen: false,
      isVerified: true,
      repeatCustomerRate: 90,
      workingHours: 'Pzt - Cmt: 08:00 - 18:00, Pazar Kapalı',
      phone: '0212 345 67 89',
      address: 'Selçuklu Mah. Yağcılar Sok. No:3, Konya',
    ),
    Mechanic(
      name: 'Doğan Lastik Center',
      specialty: 'Lastik & Rot Balans',
      categories: ['Lastik'],
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
      categories: ['Akü'],
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
      categories: ['Lastik'],
      rating: 4.3,
      reviewCount: 39,
      distanceValue: 1.9,
      priceMin: 220,
      priceMax: 400,
      isOpen: false,
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

  static List<TimeSlot> timeSlotsFor(DateTime date) {
    final now = DateTime.now();
    final slots = <TimeSlot>[];
    for (var hour = 9; hour <= 18; hour++) {
      for (final minute in [0, 30]) {
        if (hour == 18 && minute == 30) continue;
        final slotTime = DateTime(date.year, date.month, date.day, hour, minute);
        final isPast = slotTime.isBefore(now);
        final isDeterministicallyBusy = (date.day + hour + minute) % 7 == 0;
        slots.add(
          TimeSlot(
            label: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
            isAvailable: !isPast && !isDeterministicallyBusy,
          ),
        );
      }
    }
    return slots;
  }
}
