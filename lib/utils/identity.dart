import 'firebase_instances.dart';

/// Centralizes two identity-resolution expressions that were previously
/// copy-pasted across multiple screens — the mechanic businessId lookup
/// (mechanic_notifications_screen.dart and mechanic_appointments_screen.dart
/// each had their own identical private _loadMyBusinessId), and the
/// customer sender-id fallback (appointment_request_store.dart and
/// customer_conversation_page.dart). Pure extraction — every existing call
/// site's behavior is unchanged; no new Firestore access pattern, no new
/// collection, no new document structure.

/// The signed-in mechanic's own stable business id
/// (mechanicAccounts/{uid}.businessId — the same id used as that business's
/// chats/{chatId} document id, see mechanicChatId). Null when there's no
/// signed-in user, or when the account predates this field.
Future<String?> resolveMyBusinessId() async {
  final uid = firebaseAuthInstance.currentUser?.uid;
  if (uid == null) return null;
  final doc = await firestoreInstance.collection('mechanicAccounts').doc(uid).get();
  return doc.data()?['businessId'] as String?;
}

/// The current customer's identity for tagging Firestore writes and
/// message sender ids — the signed-in Firebase UID. Booking now requires
/// sign-in (see LoginPage — guest mode was removed there), so the
/// 'customer-demo' fallback below should never actually be reached from
/// the booking flow anymore; it's kept only as a defensive guard against
/// a null currentUser (e.g. a mid-session sign-out), not a supported,
/// designed path from that flow. customer_conversation_page.dart's chat
/// entry point is separate, still guest-accessible, and out of scope for
/// this change — this fallback can still legitimately fire from there.
String resolveCustomerId() => firebaseAuthInstance.currentUser?.uid ?? 'customer-demo';
