// One-off migration: adds `claimedByUid: null` to the 13 mechanicAccounts
// documents created by upload_mechanics.js. The field's mere presence
// (even though its value is null) is what marks a document as
// "script-uploaded and claimable" — see mechanic_login_page.dart's
// business-picker, which queries
// mechanicAccounts.where('claimedByUid', isEqualTo: null). A real
// registered mechanic's document never has this field at all, so it can
// never appear in that query, without needing to inspect anything else.
//
// The 13 doc ids below are exact and known from this session's own prior
// work (they're the same 13 fix_business_ids.js migrated earlier) —
// listed explicitly rather than inferred from any heuristic, so there's no
// risk of this script guessing wrong and marking an unrelated document.
// Each is still read and its durum field cross-checked against the
// script's own known write ('onaylandi') before any write happens; any
// mismatch aborts with no writes at all, same read-and-confirm-before-write
// pattern as fix_business_ids.js.
//
// Run with: node add_claimed_by_uid.js
'use strict';

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'sanayi-omer-tr',
});

const db = admin.firestore();

const SCRIPT_UPLOADED_DOC_IDS = [
  'LNQtqhVdZXI0lQ1tMYim', // Gaziantep Tekno Ford Özel Servis
  'F0E7jXvTD8Yc1gKGdAEO', // Yalçınkaya Oto Servis
  'Ap2gIFot8EEqYoQsUvmi', // Deniz Oto Tamir
  'A3XetKfmCxO4KxmkDQLf', // Hakan Oto Tamir & Şanzıman
  'OeSJgDYifAaZlhurH1o3', // Boran Oto Tamir Bakım Servis
  'VMVODXLoGFYXdy35NITh', // Yılmaz & Bağcı Oto Tamir
  'qPEa396jW5itahv29Qi9', // Rüzgar Oto Tamir (Ahmet Usta)
  'IBLU4V24JO1DLG6qEXXk', // Kaya Oto Tamir ve Elektrik
  'wHp4wfoWEUqFnw5qm9B8', // Ottoman Oto Expertiz Gaziantep
  'buhJFDgNAmM2eAG7XPC1', // Pilot Garage Gaziantep İpekyolu
  'GkxyzxUxxMoqM9nn86Bw', // Rapor Garage Gaziantep
  'kDrGaJ6i2HdGXT8GkgIu', // Avrupa Oto Ekspertiz Gaziantep
  'RJirXS8YViN5Vyo9k62I', // TOYOPEL Rıfat Usta
];

async function main() {
  const reads = await Promise.all(SCRIPT_UPLOADED_DOC_IDS.map((id) => db.collection('mechanicAccounts').doc(id).get()));

  const problems = [];
  const plan = [];
  for (let i = 0; i < reads.length; i++) {
    const doc = reads[i];
    const id = SCRIPT_UPLOADED_DOC_IDS[i];
    if (!doc.exists) {
      problems.push(`${id}: document does not exist`);
      continue;
    }
    const data = doc.data();
    if (data.durum !== 'onaylandi') {
      problems.push(`${id} ("${data.name}"): durum is "${data.durum}", expected "onaylandi" — not touching it`);
      continue;
    }
    if (Object.prototype.hasOwnProperty.call(data, 'claimedByUid')) {
      problems.push(`${id} ("${data.name}"): already has a claimedByUid field (value: ${data.claimedByUid}) — skipping, not overwriting`);
      continue;
    }
    plan.push({ id, name: data.name });
  }

  if (problems.length > 0) {
    console.log('Found issue(s) — reporting only, no writes made for the affected doc(s):');
    for (const p of problems) console.log(`  ISSUE  ${p}`);
    console.log('');
  }

  if (plan.length === 0) {
    console.log('Nothing to write.');
    return;
  }

  console.log(`About to add claimedByUid: null to ${plan.length} document(s):`);
  for (const p of plan) console.log(`  ${p.id}  "${p.name}"`);
  console.log('');

  const batch = db.batch();
  for (const p of plan) {
    batch.update(db.collection('mechanicAccounts').doc(p.id), { claimedByUid: null });
  }
  await batch.commit();

  console.log(`Done: ${plan.length} document(s) updated.`);
}

main();
