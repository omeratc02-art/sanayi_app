import * as admin from "firebase-admin";

/**
 * The old guest-booking fallback (see resolveCustomerId in the Flutter
 * app's lib/utils/identity.dart, before guest mode was removed) wrote this
 * exact literal string as müşteri_kimliği for every unauthenticated
 * customer. Counting it would treat every guest booking as "the same"
 * repeat customer across every business. New documents can no longer
 * produce this value now that booking requires sign-in, but older
 * documents may still carry it — excluded defensively.
 */
const GUEST_CUSTOMER_ID = "customer-demo";

const RANDEVULAR_COLLECTION = "randevular";
const VERIFIED_COMPLETED_STATUS = "dogrulanmis_tamamlandi";

export interface CompletedAppointment {
  businessId: string;
  customerId: string;
}

export interface RepeatCustomerRateResult {
  businessId: string;
  totalCustomers: number;
  repeatCustomers: number;
  /** 0-100 integer percentage. */
  repeatCustomerRate: number;
}

/**
 * Fetches every verified-completed appointment's (businessId, customerId)
 * pair from randevular. Field names match Appointment.fromFirestore/
 * toFirestore in the Flutter app exactly (lib/mechanic/appointments/data/
 * appointment.dart) — işletme_kimliği (business), müşteri_kimliği
 * (customer), tamamlanmaDurumu == 'dogrulanmis_tamamlandi' (the only status
 * a customer can legitimately reach, via markCustomerVerified — see
 * firestore.rules' matching customer-verification branch).
 *
 * Takes the Firestore instance as a parameter (rather than calling
 * admin.firestore() directly) so a test can pass an emulator/fake instance
 * without this function needing to change.
 */
export async function fetchCompletedAppointments(
  firestore: admin.firestore.Firestore
): Promise<CompletedAppointment[]> {
  const snapshot = await firestore
    .collection(RANDEVULAR_COLLECTION)
    .where("tamamlanmaDurumu", "==", VERIFIED_COMPLETED_STATUS)
    .get();

  return snapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      businessId: (data["işletme_kimliği"] as string | undefined) ?? "",
      customerId: (data["müşteri_kimliği"] as string | undefined) ?? "",
    };
  });
}

/**
 * Pure aggregation: given every verified-completed appointment's
 * (businessId, customerId) pair, computes each business's repeat-customer
 * rate — the percentage of that business's distinct customers who
 * completed more than one verified appointment with them.
 *
 * Deliberately takes plain data, not a Firestore query result, so this can
 * be unit tested without any Firestore/emulator dependency at all.
 */
export function computeRepeatCustomerRates(
  appointments: CompletedAppointment[]
): RepeatCustomerRateResult[] {
  // businessId -> customerId -> verified-completed visit count
  const byBusiness = new Map<string, Map<string, number>>();

  for (const { businessId, customerId } of appointments) {
    if (!businessId || !customerId) continue;
    if (customerId === GUEST_CUSTOMER_ID) continue;

    let customers = byBusiness.get(businessId);
    if (!customers) {
      customers = new Map<string, number>();
      byBusiness.set(businessId, customers);
    }
    customers.set(customerId, (customers.get(customerId) ?? 0) + 1);
  }

  const results: RepeatCustomerRateResult[] = [];
  for (const [businessId, customers] of byBusiness) {
    const totalCustomers = customers.size;
    let repeatCustomers = 0;
    for (const visitCount of customers.values()) {
      if (visitCount > 1) repeatCustomers++;
    }
    const repeatCustomerRate =
      totalCustomers === 0 ? 0 : Math.round((repeatCustomers / totalCustomers) * 100);

    results.push({ businessId, totalCustomers, repeatCustomers, repeatCustomerRate });
  }

  return results;
}