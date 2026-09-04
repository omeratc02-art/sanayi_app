// One-off migration: corrects businessId (and its işletme_kimliği mirror)
// on the mechanicAccounts documents that were created by an earlier
// version of upload_mechanics.js, which wrote the raw Firestore document
// id as businessId instead of mechanicChatId(name) — the convention every
// customer-facing lookup in the app actually expects (see that file's
// header comment for the full story).
//
// Read-and-confirm-before-write: every check below runs fully, against
// live Firestore, for every candidate document, BEFORE any write happens.
// If any conflict is found anywhere, the script aborts with a report and
// writes nothing at all — never a partial migration.
//
// Run with: node fix_business_ids.js
'use strict';

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const { mechanicChatId } = require('./mechanic_chat_id.js');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'sanayi-omer-tr',
});

const db = admin.firestore();

async function main() {
  const snapshot = await db.collection('mechanicAccounts').get();

  // The bug's exact signature: businessId === the document's own id. Real
  // registrations (mechanicAccounts/{Auth UID}) always have businessId ==
  // mechanicChatId(name), which only coincides with the doc id by chance
  // for an astronomically unlikely name — this is a precise filter, not a
  // heuristic, and confirmed against live data during the earlier
  // investigation (all 13 script-uploaded docs matched, nothing else did).
  const candidates = snapshot.docs
    .map((doc) => ({ id: doc.id, data: doc.data() }))
    .filter((entry) => entry.data.businessId === entry.id);

  if (candidates.length === 0) {
    console.log('No documents match the bug signature (businessId === doc id). Nothing to migrate.');
    return;
  }

  console.log(`Found ${candidates.length} document(s) matching the bug signature:`);
  for (const c of candidates) console.log(`  ${c.id}  "${c.data.name}"`);
  console.log('');

  // businessId values already in use by every OTHER document (not one of
  // the candidates) — a candidate's new slug must not collide with any of
  // these either, not just with live chat/appointment activity.
  const otherBusinessIds = new Set(
    snapshot.docs
      .filter((doc) => !candidates.some((c) => c.id === doc.id))
      .map((doc) => doc.data().businessId)
      .filter(Boolean),
  );

  const plan = [];
  const conflicts = [];

  for (const candidate of candidates) {
    const newSlug = mechanicChatId(candidate.data.name);

    if (otherBusinessIds.has(newSlug)) {
      conflicts.push(`${candidate.id} ("${candidate.data.name}"): new slug "${newSlug}" already used by another mechanicAccounts document`);
      continue;
    }

    const chatDoc = await db.collection('chats').doc(newSlug).get();
    if (chatDoc.exists) {
      conflicts.push(`${candidate.id} ("${candidate.data.name}"): chats/${newSlug} already exists`);
      continue;
    }

    const randevular = await db.collection('randevular').where('işletme_kimliği', '==', newSlug).get();
    if (!randevular.empty) {
      conflicts.push(
        `${candidate.id} ("${candidate.data.name}"): ${randevular.size} randevular document(s) already reference işletme_kimliği=${newSlug}`,
      );
      continue;
    }

    plan.push({ id: candidate.id, name: candidate.data.name, oldValue: candidate.data.businessId, newValue: newSlug });
  }

  if (conflicts.length > 0) {
    console.log('ABORTING — conflicts found, no writes have been made:');
    for (const c of conflicts) console.log(`  CONFLICT  ${c}`);
    console.log('');
    console.log('Resolve the conflict(s) above and rerun. No documents were changed.');
    process.exitCode = 1;
    return;
  }

  console.log('No conflicts found for any candidate. Writing updates...');
  console.log('');

  for (const item of plan) {
    await db.collection('mechanicAccounts').doc(item.id).update({
      businessId: item.newValue,
      işletme_kimliği: item.newValue,
    });
    console.log(`OK  ${item.name}`);
    console.log(`    businessId:      ${item.oldValue}  ->  ${item.newValue}`);
    console.log(`    işletme_kimliği: ${item.oldValue}  ->  ${item.newValue}`);
  }

  console.log('');
  console.log(`Done: ${plan.length} document(s) migrated.`);
}

main();
