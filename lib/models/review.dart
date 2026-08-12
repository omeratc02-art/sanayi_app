class Review {
  final String authorName;
  final int rating;
  final DateTime date;
  final String comment;
  final bool hasPhoto;
  final int helpfulCount;

  const Review({
    required this.authorName,
    required this.rating,
    required this.date,
    required this.comment,
    this.hasPhoto = false,
    this.helpfulCount = 0,
  });
}
