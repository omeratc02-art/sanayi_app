/// Parses a free-text Turkish working-hours string (e.g. "Pzt - Cmt: 08:00 -
/// 19:00", "Her gün: 09:00 - 20:00", "Pzt - Cmt: 08:00 - 18:00, Pazar
/// Kapalı") against [now] to decide whether the business is open right now.
///
/// Returns null when [workingHours] is empty or doesn't contain a
/// recognizable time range — callers should render this as "unknown" rather
/// than falling back to true/false.
bool? isOpenNow(String? workingHours, [DateTime? now]) {
  if (workingHours == null || workingHours.trim().isEmpty) return null;
  final text = workingHours.toLowerCase();

  final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})').firstMatch(text);
  if (timeMatch == null) return null;
  final startMinutes = int.parse(timeMatch.group(1)!) * 60 + int.parse(timeMatch.group(2)!);
  final endMinutes = int.parse(timeMatch.group(3)!) * 60 + int.parse(timeMatch.group(4)!);

  final current = now ?? DateTime.now();
  final todayIndex = current.weekday - 1; // 0=Pzt(Mon) .. 6=Paz(Sun)
  final nowMinutes = current.hour * 60 + current.minute;

  // Explicit closed-day override (e.g. "Pazar Kapalı") always wins.
  for (final closedMatch in RegExp(r'(pzt|sal|çar|car|per|cum|cmt|paz)\s*kapalı').allMatches(text)) {
    if (_dayIndex(closedMatch.group(1)!) == todayIndex) return false;
  }

  bool matchesToday;
  if (text.contains('her gün') || text.contains('her gun')) {
    matchesToday = true;
  } else {
    final dayRangeMatch = RegExp(r'(pzt|sal|çar|car|per|cum|cmt|paz)\s*-\s*(pzt|sal|çar|car|per|cum|cmt|paz)')
        .firstMatch(text);
    if (dayRangeMatch == null) {
      // No recognizable day info alongside a real time range — assume it
      // applies every day rather than treating the whole string as unusable.
      matchesToday = true;
    } else {
      final startDay = _dayIndex(dayRangeMatch.group(1)!);
      final endDay = _dayIndex(dayRangeMatch.group(2)!);
      matchesToday = startDay <= endDay
          ? todayIndex >= startDay && todayIndex <= endDay
          : todayIndex >= startDay || todayIndex <= endDay; // wraps, e.g. Cmt - Sal
    }
  }

  if (!matchesToday) return false;
  return nowMinutes >= startMinutes && nowMinutes < endMinutes;
}

const _dayOrder = ['pzt', 'sal', 'çar', 'per', 'cum', 'cmt', 'paz'];

int _dayIndex(String token) {
  final normalized = token == 'car' ? 'çar' : token;
  return _dayOrder.indexOf(normalized);
}
