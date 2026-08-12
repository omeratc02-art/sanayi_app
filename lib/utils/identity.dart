import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  final doc = await FirebaseFirestore.instance.collection('mechanicAccounts').doc(uid).get();
  return doc.data()?['businessId'] as String?;
}

/// The current customer's identity for tagging Firestore writes and
/// message sender ids — the signed-in Firebase UID, or the shared
/// 'customer-demo' fallback for guest/dev sessions (no signed-in user).
String resolveCustomerId() => FirebaseAuth.instance.currentUser?.uid ?? 'customer-demo';
