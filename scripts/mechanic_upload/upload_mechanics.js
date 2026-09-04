// One-time admin script: bulk-uploads real mechanic business records into
// the `mechanicAccounts` Firestore collection for project sanayi-omer-tr.
// NOT part of the Flutter app — run manually from this folder:
//   npm install
//   node upload_mechanics.js
//
// Field names (name/phone/address/hizmetTürü/hizmetler/businessId) match
// exactly what the app itself reads — see lib/models/mechanic.dart's
// Mechanic.fromFirestore and lib/data/mechanic_directory_repository.dart —
// so these records display and query correctly the moment this runs, with
// no follow-up data fix needed.
'use strict';

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'sanayi-omer-tr',
});

const db = admin.firestore();

const mechanics = [
  { name: "Gaziantep Tekno Ford Özel Servis", phone: "0542 405 27 17", type: "tamir", services: [], address: "Mavikent Mah. 135021 Nolu Sk. Sanayi Sitesi 47/A, Şahinbey/Gaziantep", hours: "Pazartesi-Pazar 24 saat açık", emergency: null, gmail: "" },
  { name: "Yalçınkaya Oto Servis", phone: "0534 241 95 21", type: "tamir", services: [], address: "Küsget Sanayi Sitesi, 60011. Cd. No:115 B Blok 3, Şehitkamil/Gaziantep", hours: "Pzt-Cuma 24 saat, Cmt 07:00-21:30, Pzr 12:00-18:00", emergency: null, gmail: "" },
  { name: "Deniz Oto Tamir", phone: "0545 512 75 59", type: "tamir", services: [], address: "Küsget Sanayi, 60011. Cd. No:119 B Blok 3, Şehitkamil/Gaziantep", hours: "Pzt-Cuma 08:00-19:00, Cmt 09:00-17:00, Pzr Kapalı", emergency: null, gmail: "" },
  { name: "Hakan Oto Tamir & Şanzıman", phone: "0543 952 27 18", type: "tamir", services: [], address: "Küsget Sanayi, 60011. Cd. 1/D Sitesi 60053, Şehitkamil/Gaziantep", hours: "Pazartesi-Pazar 24 saat açık", emergency: null, gmail: "" },
  { name: "Boran Oto Tamir Bakım Servis", phone: "0535 593 89 32", type: "tamir", services: [], address: "Sanayi Mah. Araban Yolu Cd. Palmiye Sanayi Sitesi 53/E, Şehitkamil/Gaziantep", hours: "Pazartesi-Pazar 24 saat açık", emergency: null, gmail: "" },
  { name: "Yılmaz & Bağcı Oto Tamir", phone: "0551 663 02 14", type: "tamir", services: [], address: "Küsget Sanayi Sitesi 60003, Nolu Cd., Şehitkamil/Gaziantep", hours: "Pazartesi-Pazar 24 saat açık", emergency: null, gmail: "" },
  { name: "Rüzgar Oto Tamir (Ahmet Usta)", phone: "", type: "tamir", services: [], address: "Aydınlar Oto Sanayi Sitesi D Blok No:24, Şehitkamil/Gaziantep", hours: "Pzt-Cuma 09:00-17:30, Cmt 09:00-14:00, Pzr Kapalı", emergency: null, gmail: "" },
  { name: "Kaya Oto Tamir ve Elektrik", phone: "", type: "tamir", services: [], address: "Sanayi Sitesi, Şehitkamil/Gaziantep", hours: "", emergency: null, gmail: "" },
  { name: "Ottoman Oto Expertiz Gaziantep", phone: "0532 503 32 06", type: "ekspertiz", services: [], address: "Aydınlar Mah. Şehit Ömer Halis Demir Blv. No:26, Şehitkamil/Gaziantep", hours: "Pazartesi-Pazar 24 saat açık", emergency: null, gmail: "" },
  { name: "Pilot Garage Gaziantep İpekyolu", phone: "0540 579 00 27", type: "ekspertiz", services: [], address: "Eydibaba, Sani Konukoğlu Blv. No:47/C, Şehitkamil/Gaziantep", hours: "Pzt-Cuma 08:00-18:30, Cmt 08:00-18:00, Pzr 10:00-16:00", emergency: null, gmail: "" },
  { name: "Rapor Garage Gaziantep", phone: "0554 114 71 62", type: "ekspertiz", services: [], address: "Mavikent, 135025 Nolu Cd. No:11/A, Şahinbey/Gaziantep", hours: "Pzt-Cuma 08:30-18:00, Cmt 08:30-17:00, Pzr Kapalı", emergency: null, gmail: "" },
  { name: "Avrupa Oto Ekspertiz Gaziantep", phone: "0539 799 98 98", type: "ekspertiz", services: [], address: "Karacaahmet Mah. 38087 Cd. No:5, Şehitkamil/Gaziantep", hours: "Pazartesi-Pazar 08:00-19:00 (Pzr 08:00-17:00)", emergency: null, gmail: "" },
];

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
  let successCount = 0;
  let failureCount = 0;

  for (const entry of mechanics) {
    try {
      const id = await uploadMechanic(entry);
      successCount += 1;
      console.log(`OK   ${entry.name}  ->  mechanicAccounts/${id}`);
    } catch (error) {
      failureCount += 1;
      console.error(`FAIL ${entry.name}  ->  ${error.message}`);
    }
  }

  console.log('');
  console.log(`Done: ${successCount}/${mechanics.length} uploaded, ${failureCount} failed.`);

  if (failureCount > 0) {
    process.exitCode = 1;
  }
}

main();
