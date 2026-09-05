import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import {
  fetchCompletedAppointments,
  computeRepeatCustomerRates,
  RepeatCustomerRateResult,
} from "./repeatCustomerRate";

admin.initializeApp();

const MECHANIC_ACCOUNTS_COLLECTION = "mechanicAccounts";

/**
 * mechanicAccounts is keyed by Firebase Auth UID, not businessId (see
 * lib/utils/identity.dart's resolveMyBusinessId and firestore.rules' own
 * exists(mechanicAccounts/{uid}) checks on the Flutter/rules side) —
 * businessId only exists as a field inside each document. So writing the
 * computed rate back means finding the matching document(s) by that field
 * first, not writing directly by businessId.
 */
async function writeRepeatCustomerRate(
  firestore: admin.firestore.Firestore,
  result: RepeatCustomerRateResult
): Promise<void> {
  const accountsSnapshot = await firestore
    .collection(MECHANIC_ACCOUNTS_COLLECTION)
    .where("businessId", "==", result.businessId)
    .get();

  if (accountsSnapshot.empty) {
    logger.warn(
      `No mechanicAccounts document found for businessId "${result.businessId}" — skipping repeatCustomerRate write.`
    );
    return;
  }

  // businessId is expected to be unique per mechanicAccounts document (one
  // account per registered business — see MechanicLoginPage registration),
  // but if more than one somehow matches, update all of them rather than
  // silently picking one arbitrarily.
  //
  // repeatCustomerCount (repeatCustomers, the raw distinct-customer count)
  // is written alongside the existing repeatCustomerRate field — the
  // Flutter app's UI has moved to showing the raw count (a "%0 Tekrar
  // Tercih" percentage unfairly read as a bad signal for a new business
  // with little data yet), but repeatCustomerRate itself is left in place
  // rather than removed, since nothing here requires reshaping what's
  // already stored.
  const batch = firestore.batch();
  for (const doc of accountsSnapshot.docs) {
    batch.update(doc.ref, {
      repeatCustomerRate: result.repeatCustomerRate,
      repeatCustomerCount: result.repeatCustomers,
    });
  }
  await batch.commit();
}

/**
 * Runs once daily. Businesses with zero verified-completed appointments
 * never appear in computeRepeatCustomerRates' results and are deliberately
 * left untouched here — same "don't show 0 as if it were a real measured
 * rate" reasoning already used for the Flutter app's empty-state UI, not
 * an oversight.
 */
export const updateRepeatCustomerRates = onSchedule(
  {
    schedule: "0 3 * * *",
    timeZone: "Europe/Istanbul",
  },
  async () => {
    const firestore = admin.firestore();

    const appointments = await fetchCompletedAppointments(firestore);
    const results = computeRepeatCustomerRates(appointments);
    logger.info(`Computed repeatCustomerRate for ${results.length} business(es).`);

    const outcomes = await Promise.allSettled(
      results.map((result) => writeRepeatCustomerRate(firestore, result))
    );
    const failures = outcomes.filter((outcome) => outcome.status === "rejected");
    if (failures.length > 0) {
      logger.error(`${failures.length} of ${results.length} repeatCustomerRate write(s) failed.`, failures);
    }

    logger.info("repeatCustomerRate update completed.");
  }
);