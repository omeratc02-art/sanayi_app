import 'package:cloud_firestore/cloud_firestore.dart';

/// A single chat message, stored in Firestore at
/// `chats/{chatId}/messages/{id}`. See [ChatRepository] for all reads/writes
/// — nothing in the UI talks to Firestore directly.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  factory ChatMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final timestamp = data['createdAt'];
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}

/// Lightweight per-conversation summary read from the `chats/{chatId}`
/// document itself (not its messages subcollection) — just enough to
/// render one row in a conversation list, or (via [lastMessageSenderId])
/// tell whether a chat is awaiting a reply, without pulling every message.
/// See [ChatRepository.watchChats].
class ChatSummary {
  const ChatSummary({
    required this.chatId,
    required this.mechanicName,
    required this.lastMessageText,
    required this.lastMessageSenderId,
    required this.lastMessageSenderRole,
    required this.lastMessageAt,
  });

  final String chatId;
  final String mechanicName;
  final String lastMessageText;
  final String lastMessageSenderId;

  /// 'customer' or 'mechanic' — who actually authored the latest message,
  /// tagged at write time by which conversation screen sent it (see
  /// ChatRepository.sendMessage). Deliberately independent of any Firebase
  /// Auth UID: in the dev/test flow both sides can be driven by the same
  /// signed-in account (no per-role sign-out exists), so comparing
  /// lastMessageSenderId to "whoever is currently signed in" cannot
  /// reliably tell a customer message from a mechanic one. Empty for chats
  /// whose latest message predates this field.
  final String lastMessageSenderRole;
  final DateTime? lastMessageAt;
}
