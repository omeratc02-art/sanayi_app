import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firebase_instances.dart';
import 'chat_message.dart';

/// Reads/writes chat messages at `chats/{chatId}/messages`. The UI never
/// talks to Firestore directly — everything goes through here.
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? firestoreInstance;

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
    // Only set for a genuine customer send (same mechanicName != null signal
    // used below) — this is always the caller's own signed-in Auth profile,
    // never looked up for another user, since that's not possible client-side.
    // Empty/whitespace-only names (guests, accounts predating this field)
    // are left unset rather than writing a blank string.
    final customerDisplayName = mechanicName != null ? firebaseAuthInstance.currentUser?.displayName?.trim() : null;

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
        if (customerDisplayName != null && customerDisplayName.isNotEmpty)
          'customerDisplayName': customerDisplayName,
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
                  customerDisplayName: data['customerDisplayName'] as String?,
                );
              })
              .toList(),
        );
  }

  /// Marks every unread message in [chatId] not sent by [currentSenderId]
  /// as read — the single write path for ChatMessage.isRead. Called by
  /// both CustomerConversationPage and MechanicConversationPage when the
  /// signed-in user actually views a conversation; every unread-count
  /// reader (the Mesajlar-tab badge, NotificationsPage's message cards,
  /// the bell badge) reads the same field this sets, so there is nowhere
  /// else isRead is ever written.
  Future<void> markMessagesRead({required String chatId, required String currentSenderId}) async {
    final snapshot = await _messagesRef(chatId).where('isRead', isEqualTo: false).get();
    final unreadFromOther = snapshot.docs.where((doc) => doc.data()['senderId'] != currentSenderId).toList();
    if (unreadFromOther.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unreadFromOther) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Real-time list of chats that currently have at least one unread
  /// message from the other party, for [currentSenderId] — the single
  /// data source behind the Mesajlar-tab badge, NotificationsPage's
  /// message-type cards, and the bell badge total, so the three can never
  /// disagree. Hand-rolled combine-latest (this project has no rxdart
  /// dependency): subscribes to [watchChats] for the chat list, then fans
  /// out one [watchMessages] subscription per chat — the same per-chat
  /// unread check _ConversationRow already does — re-emitting the
  /// filtered result whenever any of them changes, and tearing down
  /// subscriptions for chats that disappear.
  Stream<List<ChatSummary>> watchUnreadChats(String currentSenderId) {
    late final StreamController<List<ChatSummary>> controller;
    StreamSubscription<List<ChatSummary>>? chatsSubscription;
    final messageSubscriptions = <String, StreamSubscription<List<ChatMessage>>>{};
    final latestChatById = <String, ChatSummary>{};
    final unreadChatIds = <String>{};

    void emit() {
      final result = unreadChatIds
          .where(latestChatById.containsKey)
          .map((id) => latestChatById[id]!)
          .toList()
        ..sort((a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(a.lastMessageAt ?? DateTime(0)));
      controller.add(result);
    }

    controller = StreamController<List<ChatSummary>>.broadcast(
      onListen: () {
        chatsSubscription = watchChats().listen((chats) {
          final currentChatIds = chats.map((chat) => chat.chatId).toSet();
          latestChatById
            ..clear()
            ..addEntries(chats.map((chat) => MapEntry(chat.chatId, chat)));

          for (final staleChatId in messageSubscriptions.keys.toList()) {
            if (currentChatIds.contains(staleChatId)) continue;
            messageSubscriptions.remove(staleChatId)?.cancel();
            unreadChatIds.remove(staleChatId);
          }

          for (final chat in chats) {
            if (messageSubscriptions.containsKey(chat.chatId)) continue;
            messageSubscriptions[chat.chatId] = watchMessages(chat.chatId).listen((messages) {
              final hasUnread = messages.any((m) => !m.isRead && m.senderId != currentSenderId);
              if (hasUnread) {
                unreadChatIds.add(chat.chatId);
              } else {
                unreadChatIds.remove(chat.chatId);
              }
              emit();
            });
          }
          emit();
        });
      },
      onCancel: () {
        chatsSubscription?.cancel();
        for (final subscription in messageSubscriptions.values) {
          subscription.cancel();
        }
        messageSubscriptions.clear();
      },
    );

    return controller.stream;
  }
}
