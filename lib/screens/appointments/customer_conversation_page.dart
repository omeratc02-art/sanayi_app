import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/mock_data.dart';
import '../../mechanic/appointments/data/chat_message.dart';
import '../../mechanic/appointments/data/chat_repository.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import '../../utils/identity.dart';

/// Customer-side conversation screen — the counterpart to
/// MechanicConversationPage. Reads/writes the exact same Firestore
/// `chats/{chatId}/messages` thread via the shared [ChatRepository] and
/// [ChatMessage] model, so both sides see each other's messages live.
class CustomerConversationPage extends StatefulWidget {
  const CustomerConversationPage({super.key, required this.chatId, required this.mechanicName});

  final String chatId;

  /// Written onto the chats/{chatId} doc on every send, so the
  /// conversation list can show a real name instead of the chatId slug —
  /// see ChatRepository.sendMessage/watchChats. Also now shown directly in
  /// the app bar header (see _CustomerConversationPageState.build).
  final String mechanicName;

  @override
  State<CustomerConversationPage> createState() => _CustomerConversationPageState();
}

class _CustomerConversationPageState extends State<CustomerConversationPage> {
  // Falls back to the original shared demo id for guest sessions (no
  // signed-in Firebase user) — signed-in customers now get their own real
  // uid instead of sharing this one literal with every other guest.
  String get _customerSenderId => resolveCustomerId();

  final _repository = ChatRepository();
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  // TODO: No real second participant signal yet — wire this up to a genuine
  // "mechanic is typing" signal (e.g. a Firestore presence field) once one
  // exists. Never set true today, so the indicator stays hidden rather than
  // showing a fake state (mirrors MechanicConversationPage's same TODO).
  // ignore: prefer_final_fields
  bool _isMechanicTyping = false;
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  // Absolute clock time (e.g. "14:32") rather than a relative "X dk önce"
  // description — clearer at a glance for which exact message said what,
  // and matches how every other timestamp in a chat bubble UI reads.
  static String _formatMessageTime(DateTime createdAt) =>
      '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

  /// Nothing in the chat data itself (chatId/mechanicName) carries a
  /// verified flag or avatar — cross-referencing the existing mock
  /// mechanic directory by name (the same directory these conversations
  /// were already seeded from in AppointmentRequestCard/ServiceCenterCard)
  /// recovers it without any data-model change.
  static Mechanic? _findMechanicByName(String name) {
    for (final mechanic in MockData.allMechanics) {
      if (mechanic.name == name) return mechanic;
    }
    return null;
  }

  Future<void> _handleSend() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    _replyController.clear();
    try {
      await _repository.sendMessage(
        chatId: widget.chatId,
        senderId: _customerSenderId,
        text: text,
        mechanicName: widget.mechanicName,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = _findMechanicByName(widget.mechanicName)?.isVerified ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.car_repair, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.mechanicName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                      if (isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 15, color: AppColors.primary),
                      ],
                    ],
                  ),
                  if (isVerified)
                    const Text(
                      'Doğrulanmış Usta',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          const _TodayLabel(),
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _repository.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                // Newest first — matches the ListView's reverse:true ordering
                // (the repository stream itself is oldest-first).
                final messages = snapshot.data?.reversed.toList() ?? const <ChatMessage>[];

                if (messages.length != _lastMessageCount) {
                  _lastMessageCount = messages.length;
                  _scrollToLatest();
                }

                return ListView.separated(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final time = _formatMessageTime(message.createdAt);
                    return message.senderId == _customerSenderId
                        ? _OutgoingMessageBubble(text: message.text, time: time, isRead: message.isRead)
                        : _ChatBubble(text: message.text, time: time);
                  },
                );
              },
            ),
          ),
          if (_isMechanicTyping) const _TypingIndicator(),
          _ReplyBar(controller: _replyController, onSend: _handleSend),
        ],
      ),
    );
  }
}

class _TodayLabel extends StatelessWidget {
  const _TodayLabel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'Bugün',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

/// Subtle "mechanic is typing" row shown above the reply bar — mirrors
/// MechanicConversationPage's _TypingIndicator (mock/dormant only, see the
/// TODO on _isMechanicTyping above).
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Yazıyor...',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final t = (_controller.value - (i * 0.2)) % 1.0;
                  final opacity = (0.3 + 0.7 * (1 - (t - 0.5).abs() * 2)).clamp(0.3, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(color: AppColors.textSecondary, shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A single mechanic message — left-aligned, flat light-gray bubble. Mirror
/// of MechanicConversationPage's incoming-bubble treatment.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.time});

  final String text;
  final String time;

  static const _bubbleColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _bubbleColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.4),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(time, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single outgoing (customer) message — right-aligned, turquoise fill,
/// white text. Mirror of MechanicConversationPage's outgoing-bubble
/// treatment. [isRead] is ChatMessage.isRead as-is from Firestore — no
/// message here is ever marked read by any existing code path today, so
/// this will honestly show the single "Gönderildi" check until something
/// actually sets isRead true; it never fabricates a "Görüldü" state.
class _OutgoingMessageBubble extends StatelessWidget {
  const _OutgoingMessageBubble({required this.text, required this.time, required this.isRead});

  final String text;
  final String time;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.turquoise,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(fontSize: 13.5, color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time, style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(width: 4),
                    Icon(
                      isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: isRead ? 1 : 0.85),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => onSend(),
                  onChanged: (value) {
                    // See MechanicConversationPage's _ReplyBar for why this
                    // exists: physical-keyboard Enter needs to submit
                    // instead of inserting a newline, except when Shift is
                    // held, and onSubmitted alone doesn't fire for
                    // multiline fields on desktop/web.
                    if (!value.endsWith('\n') || HardwareKeyboard.instance.isShiftPressed) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final current = controller.text;
                      if (current.endsWith('\n')) {
                        controller.text = current.substring(0, current.length - 1);
                        controller.selection = TextSelection.collapsed(offset: controller.text.length);
                      }
                      onSend();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
                child: IconButton(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
