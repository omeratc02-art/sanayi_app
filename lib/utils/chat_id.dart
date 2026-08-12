/// Deterministic per-mechanic Firestore chat id — every "message this
/// mechanic" entry point used to hardcode the same literal chatId
/// ('ahmet-yilmaz-yag-degisimi'), so every mechanic shared one thread.
/// This turns a mechanic's display name into that same lowercase-ASCII
/// slug style instead, so each mechanic gets their own separate
/// chats/{chatId} document.
String mechanicChatId(String mechanicName) {
  const turkishToAscii = {
    'ı': 'i', 'İ': 'i',
    'ş': 's', 'Ş': 's',
    'ğ': 'g', 'Ğ': 'g',
    'ö': 'o', 'Ö': 'o',
    'ü': 'u', 'Ü': 'u',
    'ç': 'c', 'Ç': 'c',
  };

  var result = mechanicName;
  turkishToAscii.forEach((from, to) => result = result.replaceAll(from, to));
  result = result.toLowerCase();
  result = result.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  result = result.replaceAll(RegExp(r'^-+|-+$'), '');
  return result.isEmpty ? 'mechanic' : result;
}
