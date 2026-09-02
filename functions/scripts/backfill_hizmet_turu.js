// One-time backfill: sets `hizmetTürü: 'tamir'` on every mechanicAccounts
// document that doesn't have it yet.
//
// This is a manual, one-off migration — NOT a deployed Cloud Function, and
// NOT wired into the app's own query logic (which assumes hizmetTürü always
// exists once this has been run). Existing accounts predate the
// Ekspertiz/Sigorta split, so every one of them is a repair shop; that's why
// 'tamir' is a safe explicit backfill value here, not a permanent
// missing-field fallback baked into product code.
//
// Deliberately does NOT touch hizmetler, priceMin, priceMax, or
// workingHours — there's no reliable source to infer those from for
// existing accounts, so they stay absent until a mechanic fills them in
// themselves.
//
// Run manually, once, from the functions/ directory:
//   node scripts/backfill_hizmet_turu.js
//
// Uses the same local firebase-tools credentials `firebase deploy`/`firebase
// apps:*` already use on this machine — no separate service-account key
// needed. Requires `firebase login` to have been run at least once.

const fs = require('fs');
const os = require('os');
const path = require('path');
const admin = require('firebase-admin');

const PROJECT_ID = 'sanayi-omer-tr';

function loadFirebaseToolsRefreshToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const refreshToken = config.tokens && config.tokens.refresh_token;
  if (!refreshToken) {
    throw new Error(
      `No refresh token found in ${configPath}. Run "firebase login" first, then re-run this script.`
    );
  }
  return refreshToken;
}

function writeTemporaryAdcFile(refreshToken) {
  const adc = {
    type: 'authorized_user',
    client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
    refresh_token: refreshToken,
  };
  const tmpPath = path.join(os.tmpdir(), `sanayi-app-backfill-adc-${process.pid}.json`);
  fs.writeFileSync(tmpPath, JSON.stringify(adc));
  return tmpPath;
}

async function main() {
  const refreshToken = loadFirebaseToolsRefreshToken();
  const adcPath = writeTemporaryAdcFile(refreshToken);
  process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;

  try {
    admin.initializeApp({ projectId: PROJECT_ID });
    const db = admin.firestore();

    const snapshot = await db.collection('mechanicAccounts').get();
    const missing = snapshot.docs.filter((doc) => !('hizmetTürü' in doc.data()));

    if (missing.length === 0) {
      console.log('Nothing to backfill — every mechanicAccounts document already has hizmetTürü.');
      return;
    }

    console.log(`Backfilling hizmetTürü: 'tamir' on ${missing.length} document(s):`);
    for (const doc of missing) {
      console.log(`  - ${doc.id} (${doc.data().name ?? 'no name'})`);
    }

    const batch = db.batch();
    for (const doc of missing) {
      batch.update(doc.ref, { hizmetTürü: 'tamir' });
    }
    await batch.commit();

    console.log('Done.');
  } finally {
    fs.unlinkSync(adcPath);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
