const List<String> _weekdayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

const List<String> _weekdayFull = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

const List<String> _monthFull = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String weekdayShort(DateTime date) => _weekdayShort[date.weekday - 1];

String weekdayFull(DateTime date) => _weekdayFull[date.weekday - 1];

String monthFull(DateTime date) => _monthFull[date.month - 1];

String formatFullDate(DateTime date) => '${date.day} ${monthFull(date)}, ${weekdayFull(date)}';

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
