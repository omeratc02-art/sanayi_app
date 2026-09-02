/// Short relative-time label (e.g. "Şimdi", "5 dk", "3 sa", "2 g") for a
/// past [dateTime], falling back to a "gg.aa.yyyy" date once it's a week or
/// older. Shared by CustomerConversationListPage's conversation rows and
/// NotificationsPage's message-type cards, so both read the same format.
String formatRelativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  if (difference.inMinutes < 1) return 'Şimdi';
  if (difference.inMinutes < 60) return '${difference.inMinutes} dk';
  if (difference.inHours < 24) return '${difference.inHours} sa';
  if (difference.inDays < 7) return '${difference.inDays} g';
  return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
}
