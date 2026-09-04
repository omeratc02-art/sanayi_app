// Admin script: uploads real mechanic business records into the
// `mechanicAccounts` Firestore collection for project sanayi-omer-tr.
// NOT part of the Flutter app — reusable, not one-time: run again whenever
// mechanics_to_add.json gets a new entry appended.
//   npm install
//   node upload_mechanics.js
//
// The mechanic list itself lives in mechanics_to_add.json, not here — to
// add a mechanic found in the field, append an entry there (same shape as
// the existing ones: name/phone/type/services/address/hours/emergency/gmail)
// and rerun. Every run re-checks the whole file against Firestore and only
// creates documents for entries not already present (see findDuplicate
// below), so it's always safe to rerun after adding one new entry — it
// will not duplicate or overwrite any of the existing records.
//
// Field names written to Firestore (name/phone/address/hizmetTürü/
// hizmetler/businessId) match exactly what the app itself reads — see
// lib/models/mechanic.dart's Mechanic.fromFirestore and
// lib/data/mechanic_directory_repository.dart — so these records display
// and query correctly the moment this runs, with no follow-up data fix
// needed.
'use strict';

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'sanayi-omer-tr',
});

const db = admin.firestore();

const mechanics = JSON.parse(fs.readFileSync(path.join(__dirname, 'mechanics_to_add.json'), 'utf8'));

// Turkish phone numbers get typed in several equivalent forms across
// entries (leading 0, leading +90, spaced or not) — comparing raw strings
// would miss a real duplicate typed differently the second time. Reducing
// to the bare 10-digit subscriber number (no country/trunk prefix) makes
// the comparison format-independent. Blank stays blank: an empty phone
// must never be treated as a match against another empty phone — several
// of the existing 12 records have no phone on file, and none of them are
// duplicates of each other.
function normalizePhone(phone) {
  const digits = (phone || '').replace(/\D/g, '');
  if (!digits) return '';
  if (digits.length === 12 && digits.startsWith('90')) return digits.slice(2);
  if (digits.length === 11 && digits.startsWith('0')) return digits.slice(1);
  return digits;
}

async function fetchExistingKeys() {
  const snapshot = await db.collection('mechanicAccounts').get();
  const phones = new Set();
  const businessIds = new Set();
  // Exact business name, but only for existing docs that have no phone on
  // file — this is what phone/businessId dedup alone misses: two of the
  // original 12 records (Rüzgar Oto Tamir, Kaya Oto Tamir ve Elektrik)
  // were entered with no phone number, so a normalized-phone comparison
  // can never recognize them and a rerun would otherwise re-create them as
  // duplicates every time (confirmed the hard way against live Firestore,
  // then cleaned up manually). Scoped to only the no-phone case so two
  // different phoned businesses that happen to share a name string are
  // never wrongly treated as the same one.
  const namesWithoutPhone = new Set();
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const normalizedPhone = normalizePhone(data.phone);
    if (normalizedPhone) {
      phones.add(normalizedPhone);
    } else if (data.name) {
      namesWithoutPhone.add(data.name);
    }
    if (data.businessId) businessIds.add(data.businessId);
  }
  return { phones, businessIds, namesWithoutPhone };
}

// Null means "not a duplicate, safe to upload". A non-null string names
// which field matched, for the skip log line.
function findDuplicateReason(entry, existingPhones, existingBusinessIds, existingNamesWithoutPhone) {
  if (entry.businessId && existingBusinessIds.has(entry.businessId)) return 'businessId';
  const normalizedPhone = normalizePhone(entry.phone);
  if (normalizedPhone && existingPhones.has(normalizedPhone)) return 'phone';
  if (!normalizedPhone && entry.name && existingNamesWithoutPhone.has(entry.name)) return 'name (no phone on file)';
  return null;
}

async function uploadMechanic(entry) {
  // A pre-generated ref, not add() + a follow-up update — lets businessId
  // (and its işletme_kimliği duplicate) be written in the same single set()
  // as everything else, instead of a second write per document.
  const ref = db.collection('mechanicAccounts').doc();
  await ref.set({
    businessId: ref.id,
    işletme_kimliği: ref.id,
    name: entry.name,
    phone: entry.phone,
    hizmetTürü: entry.type,
    hizmetler: entry.services,
    address: entry.address,
    workingHours: entry.hours,
    acilDurumHizmeti: entry.emergency,
    gmail: entry.gmail,
    durum: 'onaylandi',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return ref.id;
}

async function main() {
  const {
    phones: existingPhones,
    businessIds: existingBusinessIds,
    namesWithoutPhone: existingNamesWithoutPhone,
  } = await fetchExistingKeys();

  let successCount = 0;
  let skippedCount = 0;
  let failureCount = 0;

  for (const entry of mechanics) {
    const duplicateReason = findDuplicateReason(entry, existingPhones, existingBusinessIds, existingNamesWithoutPhone);
    if (duplicateReason) {
      skippedCount += 1;
      console.log(`SKIP ${entry.name}  ->  already exists (matched on ${duplicateReason})`);
      continue;
    }

    try {
      const id = await uploadMechanic(entry);
      successCount += 1;
      console.log(`OK   ${entry.name}  ->  mechanicAccounts/${id}`);
      // So a second entry later in this same file matching this one (same
      // phone, or same name when both are phone-less) is also caught as a
      // duplicate, not just ones already in Firestore before this run
      // started.
      const normalizedPhone = normalizePhone(entry.phone);
      if (normalizedPhone) {
        existingPhones.add(normalizedPhone);
      } else if (entry.name) {
        existingNamesWithoutPhone.add(entry.name);
      }
    } catch (error) {
      failureCount += 1;
      console.error(`FAIL ${entry.name}  ->  ${error.message}`);
    }
  }

  console.log('');
  console.log(
    `Done: ${successCount} uploaded, ${skippedCount} already existed (skipped), ${failureCount} failed, ${mechanics.length} total in mechanics_to_add.json.`,
  );

  if (failureCount > 0) {
    process.exitCode = 1;
  }
}

main();
