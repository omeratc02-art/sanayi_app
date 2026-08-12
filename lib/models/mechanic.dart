class Mechanic {
  final String name;
  final String specialty;
  final List<String> categories;
  final double rating;
  final int reviewCount;
  final double distanceValue;
  final int priceMin;
  final int priceMax;
  final bool isOpen;
  final bool isVerified;
  final int repeatCustomerRate;
  final int onTimeRate;
  final String workingHours;
  final String phone;
  final String address;

  const Mechanic({
    required this.name,
    required this.specialty,
    required this.categories,
    required this.rating,
    required this.reviewCount,
    required this.distanceValue,
    required this.priceMin,
    required this.priceMax,
    required this.workingHours,
    required this.phone,
    required this.address,
    this.isOpen = true,
    this.isVerified = false,
    this.repeatCustomerRate = 0,
    this.onTimeRate = 0,
  });

  String get distanceLabel => '${distanceValue.toStringAsFixed(1)} km';

  String get priceFromLabel => '₺$priceMin';

  String get priceRangeLabel => '₺$priceMin - ₺$priceMax';

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
