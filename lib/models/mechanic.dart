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
  });

  String get distanceLabel => '${distanceValue.toStringAsFixed(1)} km';

  String get priceFromLabel => '₺$priceMin';

  String get priceRangeLabel => '₺$priceMin - ₺$priceMax';
}
