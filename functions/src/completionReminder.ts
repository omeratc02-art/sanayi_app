import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const CUSTOMERS_COLLECTION = "customers";

export const AWAITING_VERIFICATION_STATUS = "usta_onayladi_bekleniyor";

/**
 * Pure decision: does this randevular update represent the specific
 * transition the completion-confirmation reminder cares about — moving TO
 * 'usta_onayladi_bekleniyor' — rather than merely touching a document that
 * already sat in that state (an unrelated field edit on an
 * already-awaiting-verification document, e.g. a later customer-note
 * correction, must not re-fire a second reminder). Mirrors the same
 * before/after diff reasoning the Flutter completion-flow tests already
 * assert against (see test/appointment_completion_flow_test.dart), just on
 * the write-trigger side rather than the read side.
 *
 * Deliberately takes plain data, not a Firestore event, so this is directly
 * unit-testable without any Firestore/emulator dependency — same reasoning
 * as computeRepeatCustomerRates in repeatCustomerRate.ts.
 */
export function isNewlyAwaitingVerification(
  before: FirebaseFirestore.DocumentData | undefined,
  after: FirebaseFirestore.DocumentData | undefined
): boolean {
  if (!after) return false; // document deleted — nothing to remind about
  if (after["tamamlanmaDurumu"] !== AWAITING_VERIFICATION_STATUS) return false;
  return before?.["tamamlanmaDurumu"] !== AWAITING_VERIFICATION_STATUS;
}

export interface CompletionReminderNotification {
  title: string;
  body: string;
}

/**
 * The exact Turkish copy for this one, single reminder — no repeat/re-send
 * mechanism exists in this app by design (see the earlier design
 * investigation's own recommendation to defer that). Kept as a pure
 * function, separate from the Firestore/FCM glue below, purely so the copy
 * itself is directly testable without needing to fake a Messaging client.
 */
export function buildCompletionReminderNotification(): CompletionReminderNotification {
  return {
    title: "Randevunuz tamamlandı",
    body: "Onayınızı bekliyoruz — randevunuzu kontrol edin.",
  };
}

/**
 * Looks up [customerId]'s real fcmToken (see customers/{uid} — written by
 * the Flutter app's PushNotificationService) and sends the completion
 * reminder push. A real no-op, not a failure, when there's no matching
 * customers/{customerId} document or no token on it yet — most customers
 * won't have opted into notifications at all, and that's an expected,
 * routine state.
 *
 * On a stale token (the app was uninstalled, or the token otherwise
 * rotated out from under us — messaging/registration-token-not-registered),
 * clears fcmToken from the document rather than leaving a permanently-dead
 * token that would silently fail on every future completion for this same
 * customer.
 */
export async function sendCompletionReminder(
  firestore: admin.firestore.Firestore,
  messaging: admin.messaging.Messaging,
  customerId: string
): Promise<void> {
  if (!customerId) return;

  const customerDoc = await firestore.collection(CUSTOMERS_COLLECTION).doc(customerId).get();
  const token = customerDoc.data()?.["fcmToken"] as string | undefined;
  if (!token) return;

  const notification = buildCompletionReminderNotification();
  try {
    await messaging.send({ token, notification });
  } catch (error) {
    const code = (error as { code?: string }).code;
    if (code === "messaging/registration-token-not-registered") {
      logger.info(`Stale fcmToken for customer ${customerId} — clearing it.`);
      await customerDoc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
      return;
    }
    logger.error(`Failed to send completion reminder to customer ${customerId}.`, error);
  }
}
