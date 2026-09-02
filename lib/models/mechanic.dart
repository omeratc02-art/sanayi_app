import '../utils/working_hours.dart';

class Mechanic {
  final String name;
  final String specialty;

  /// Broad taxonomy labels (e.g. 'Motor', 'Fren Sistemi') matching
  /// [MockData.categories] — used only as the seed value for a new real
  /// account's [hizmetler] at registration time (see MechanicLoginPage).
  /// Real, Firestore-backed browsing filters on [hizmetler] directly, never
  /// on this field.
  final List<String> categories;

  final double rating;
  final int reviewCount;

  /// Null for every real, Firestore-backed mechanic — there is no real
  /// geolocation data yet (a separate future task). Only MockData's catalog
  /// entries carry a real value here.
  final double? distanceValue;

  /// Null means "not entered yet" — render [priceFromLabel]/[priceRangeLabel]
  /// rather than a fabricated number.
  final int? priceMin;
  final int? priceMax;

  final bool isVerified;
  final int repeatCustomerRate;

  /// Free-text, e.g. "Pzt - Cmt: 08:00 - 19:00". Null/empty means "not
  /// entered yet" — see [workingHoursLabel] and [isOpen].
  final String? workingHours;

  final String phone;
  final String address;

  /// 'tamir' | 'ekspertiz' | 'sigorta' — mirrors the Firestore field
  /// `hizmetTürü` (Dart identifiers can't contain 'ü', so this Dart-side
  /// name drops it; the Firestore field name itself keeps the Turkish
  /// spelling, see [fromFirestore]). Null only for MockData's catalog
  /// entries, which predate this field and are never queried by it.
  final String? hizmetTuru;

  /// Structured sub-services this business offers (e.g. ['Motor', 'Fren
  /// Sistemi']) — what real category-filtered Firestore queries match
  /// against.
  final List<String> hizmetler;

  const Mechanic({
    required this.name,
    this.specialty = '',
    this.categories = const [],
    required this.rating,
    required this.reviewCount,
    this.distanceValue,
    this.priceMin,
    this.priceMax,
    this.workingHours,
    required this.phone,
    required this.address,
    this.isVerified = false,
    this.repeatCustomerRate = 0,
    this.hizmetTuru,
    this.hizmetler = const [],
  });

  factory Mechanic.fromFirestore(Map<String, dynamic> data) {
    final rating = data['rating'];
    final priceMin = data['priceMin'];
    final priceMax = data['priceMax'];
    final repeatRate = data['repeatCustomerRate'];
    return Mechanic(
      name: data['name'] as String? ?? '',
      specialty: data['specialty'] as String? ?? '',
      rating: rating is num ? rating.toDouble() : 0,
      reviewCount: data['reviewCount'] as int? ?? 0,
      priceMin: priceMin is num ? priceMin.toInt() : null,
      priceMax: priceMax is num ? priceMax.toInt() : null,
      workingHours: data['workingHours'] as String?,
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? false,
      repeatCustomerRate: repeatRate is num ? repeatRate.toInt() : 0,
      hizmetTuru: data['hizmetTürü'] as String?,
      hizmetler: (data['hizmetler'] as List<dynamic>?)?.whereType<String>().toList() ?? const [],
    );
  }

  /// Null when there's no real distance to show — omit distance UI entirely
  /// rather than falling back to a placeholder.
  String? get distanceLabel => distanceValue == null ? null : '${distanceValue!.toStringAsFixed(1)} km';

  String get specialtyLabel => specialty.isEmpty ? 'Uzmanlık alanı belirtilmemiş' : specialty;

  String get priceFromLabel => priceMin == null ? 'Fiyat bilgisi girilmemiş' : '₺$priceMin';

  String get priceRangeLabel =>
      (priceMin == null || priceMax == null) ? 'Fiyat bilgisi girilmemiş' : '₺$priceMin - ₺$priceMax';

  String get workingHoursLabel =>
      (workingHours == null || workingHours!.isEmpty) ? 'Çalışma saatleri belirtilmemiş' : workingHours!;

  /// Derived from [workingHours] + the current time rather than stored —
  /// null means unknown (no working hours entered), which callers should
  /// render as a hidden/omitted indicator, never as a default true/false.
  bool? get isOpen => isOpenNow(workingHours);

  /// Composite trust score (0-100) shown on the Service Listing screen —
  /// deliberately based only on verification status, customer rating, and
  /// repeat-customer rate, not price, distance, or anything else.
  int get trustScore {
    final ratingScore = (rating / 5) * 60;
    final repeatScore = (repeatCustomerRate / 100) * 30;
    final verifiedScore = isVerified ? 10 : 0;
    return (ratingScore + repeatScore + verifiedScore).round().clamp(0, 100);
  }
}
