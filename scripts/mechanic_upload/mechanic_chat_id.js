// Node.js port of lib/utils/chat_id.dart's mechanicChatId — this script
// folder is plain Node.js and can't import Dart directly, so this file
// exists purely to keep the same slugification available here. It is a
// manual copy, not a shared source: if chat_id.dart's rules ever change,
// this must be updated to match, in the same order —
// 1) replace this fixed set of Turkish characters, 2) lowercase,
// 3) collapse every remaining non a-z0-9 run into a single hyphen,
// 4) trim leading/trailing hyphens, 5) 'mechanic' if that leaves nothing.
// Both upload_mechanics.js and fix_business_ids.js require this, so the
// value a newly-created mechanic gets and the value a migration recomputes
// can never drift apart from each other, even if they drift from Dart.
'use strict';

const TURKISH_TO_ASCII = {
  ı: 'i',
  İ: 'i',
  ş: 's',
  Ş: 's',
  ğ: 'g',
  Ğ: 'g',
  ö: 'o',
  Ö: 'o',
  ü: 'u',
  Ü: 'u',
  ç: 'c',
  Ç: 'c',
};

function mechanicChatId(mechanicName) {
  let result = mechanicName;
  for (const [from, to] of Object.entries(TURKISH_TO_ASCII)) {
    result = result.split(from).join(to);
  }
  result = result.toLowerCase();
  result = result.replace(/[^a-z0-9]+/g, '-');
  result = result.replace(/^-+|-+$/g, '');
  return result === '' ? 'mechanic' : result;
}

module.exports = { mechanicChatId };
