import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message.dart';

/// Reads/writes chat messages at `chats/{chatId}/messages`. The UI never
/// talks to Firestore directly — everything goes through here.
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _messagesRef(String chatId) {
    return _firestore.collection('chats').doc(chatId).collection('messages');
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _messagesRef(chatId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    // Only the customer side passes this today — it lets the chat's own
    // chats/{chatId} doc carry a real display name, so the conversation
    // list (see watchChats) doesn't have to guess one from the chatId
    // slug. Optional so existing mechanic-side callers are unaffected.
    String? mechanicName,
  }) {
    final message = ChatMessage(
      id: '',
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
      isRead: false,
    );
    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('chats').doc(chatId),
      {
        if (mechanicName != null) 'mechanicName': mechanicName,
        'lastMessageAt': FieldValue.serverTimestamp(),
        // Lets the mechanic-side Notifications screen tell whether a chat
        // is awaiting a reply, without watching every chat's full messages
        // subcollection — see MechanicNotificationsScreen.
        'lastMessageText': text,
        'lastMessageSenderId': senderId,
        // Only CustomerConversationPage passes mechanicName — that's an
        // existing, reliable signal for which side actually sent this
        // message, unlike senderId, which can be the same Firebase UID on
        // both sides in the dev/test flow (no per-role sign-out exists).
        'lastMessageSenderRole': mechanicName != null ? 'customer' : 'mechanic',
      },
      SetOptions(merge: true),
    );
    batch.set(_messagesRef(chatId).doc(), message.toFirestore());
    return batch.commit();
  }

  /// One row per existing chats/{chatId} doc — used by the customer's
  /// conversation list (each mechanic's thread shows up separately instead
  /// of one hardcoded conversation) and by the mechanic's Notifications
  /// screen (which chats are awaiting a reply).
  Stream<List<ChatSummary>> watchChats() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) {
                final data = doc.data();
                final lastMessageAt = data['lastMessageAt'];
                return ChatSummary(
                  chatId: doc.id,
                  mechanicName: data['mechanicName'] as String? ?? doc.id,
                  lastMessageText: data['lastMessageText'] as String? ?? '',
                  lastMessageSenderId: data['lastMessageSenderId'] as String? ?? '',
                  lastMessageSenderRole: data['lastMessageSenderRole'] as String? ?? '',
                  lastMessageAt: lastMessageAt is Timestamp ? lastMessageAt.toDate() : null,
                );
              })
              .toList(),
        );
  }
}
