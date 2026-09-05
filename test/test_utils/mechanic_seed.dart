import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds the fake `mechanicAccounts` collection with the same handful of
/// real-shaped businesses the search/booking/detail tests exercise —
/// SearchTab and ServiceListingPage now query Firestore directly (see
/// MechanicDirectoryRepository) instead of reading MockData, so tests that
/// expect a named business to show up need it seeded here.
Future<void> seedMechanicAccounts(FirebaseFirestore firestore) async {
  final collection = firestore.collection('mechanicAccounts');

  await collection.add({
    'name': 'Hızlı Lastikçi',
    'specialty': 'Lastik & Balans',
    'hizmetTürü': 'tamir',
    'hizmetler': ['Lastik & Jant'],
    'businessId': 'hizli-lastikci',
    'rating': 4.7,
    'reviewCount': 96,
    'priceMin': 200,
    'priceMax': 380,
    'isVerified': true,
    'repeatCustomerRate': 84,
    'repeatCustomerCount': 42,
    'workingHours': 'Her gün: 09:00 - 20:00',
    'phone': '0212 667 45 09',
    'address': 'Fatih Mah. Lastikçiler Sok. No:5, Konya',
  });

  await collection.add({
    'name': 'Master Fren Sistemleri',
    'specialty': 'Fren & Süspansiyon',
    'hizmetTürü': 'tamir',
    'hizmetler': ['Fren Sistemi'],
    'businessId': 'master-fren-sistemleri',
    'rating': 4.9,
    'reviewCount': 187,
    'priceMin': 300,
    'priceMax': 550,
    'isVerified': true,
    'repeatCustomerRate': 87,
    'repeatCustomerCount': 55,
    'workingHours': 'Pzt - Cmt: 08:30 - 18:30',
    'phone': '0212 890 11 22',
    'address': 'Karatay Sanayi Sitesi C Blok No:9, Konya',
  });

  await collection.add({
    'name': 'Öztürk Elektrik',
    'specialty': 'Akü & Elektrik',
    'hizmetTürü': 'tamir',
    'hizmetler': ['Akü & Elektrik'],
    'businessId': 'ozturk-elektrik',
    'rating': 4.5,
    'reviewCount': 71,
    'priceMin': 150,
    'priceMax': 320,
    'isVerified': true,
    'repeatCustomerRate': 71,
    'repeatCustomerCount': 28,
    'workingHours': 'Pzt - Cmt: 09:00 - 18:00',
    'phone': '0212 778 90 12',
    'address': 'Yenişehir Mah. Elektrikçiler Cad. No:34, Konya',
  });

  await collection.add({
    'name': 'Aksoy Akü Merkezi',
    'specialty': 'Akü Değişimi & Şarj',
    'hizmetTürü': 'tamir',
    'hizmetler': ['Akü & Elektrik'],
    'businessId': 'aksoy-aku-merkezi',
    'rating': 4.6,
    'reviewCount': 58,
    'priceMin': 180,
    'priceMax': 300,
    'isVerified': true,
    'repeatCustomerRate': 76,
    'repeatCustomerCount': 30,
    'workingHours': 'Pzt - Cmt: 09:00 - 19:00',
    'phone': '0212 123 45 67',
    'address': 'Beyhekim Mah. Akücüler Sok. No:11, Konya',
  });
}
