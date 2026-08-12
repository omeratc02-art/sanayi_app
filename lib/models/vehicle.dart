class Vehicle {
  final String name;
  final int year;

  const Vehicle({required this.name, required this.year});

  String get label => '$name ($year)';
}
