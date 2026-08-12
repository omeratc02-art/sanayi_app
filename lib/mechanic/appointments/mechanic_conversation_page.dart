import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import 'data/chat_message.dart';
import 'data/chat_repository.dart';
import 'mechanic_request_details_page.dart';

/// Conversation screen for a single request's customer question — reached
/// only from a "sent you a question" notification (see
/// MechanicNotificationsScreen). Distinct from MechanicRequestDetailsPage:
/// this is where the mechanic reads/replies to a question, not where they
/// manage the request itself (that's one "Talebi Görüntüle" tap away).
///
/// Messages are real, Firestore-backed data (see [ChatRepository])
/// streamed live via StreamBuilder — nothing here is mock/local state.
class MechanicConversationPage extends StatefulWidget {
  const MechanicConversationPage({super.key, required this.chatId});

  final String chatId;

  @override
  State<MechanicConversationPage> createState() => _MechanicConversationPageState();
}

class _MechanicConversationPageState extends State<MechanicConversationPage> {
  static const _customerName = 'Ahmet Yılmaz';
  static const _vehicle = 'Renault Clio · 34 ABC 123';
  static const _service = 'Yağ Değişimi';

  // TODO: There's no request<->chat linking yet (see
  // MechanicNotificationsScreen's TODOs) — callers still pass the same
  // hardcoded demo chatId until that exists. Falls back to the original
  // shared demo id for the dev/test flow (no signed-in Firebase user).
  String get _mechanicSenderId => FirebaseAuth.instance.currentUser?.uid ?? 'mechanic-demo';

  final _repository = ChatRepository();
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();

  // TODO: No real second participant yet — wire this up to a genuine
  // "customer is typing" signal (e.g. a Firestore presence field) once a
  // real customer client exists. Never set true today, so the indicator
  // stays hidden rather than showing a fake state.
  // ignore: prefer_final_fields — kept non-final deliberately (see TODO above).
  bool _isCustomerTyping = false;
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

  static String _formatMessageTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
    if (difference.inHours < 24) return '${difference.inHours} saat önce';
    return '${difference.inDays} gün önce';
  }

  Future<void> _handleSend() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    _replyController.clear();
    try {
      await _repository.sendMessage(
        chatId: widget.chatId,
        senderId: _mechanicSenderId,
        text: text,
      );
    } catch (error, stackTrace) {
      debugPrint('SEND MESSAGE ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Mesajlar'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MechanicRequestDetailsPage()),
            ),
            child: const Text(
              'Talebi Görüntüle',
              style: TextStyle(color: AppColors.turquoise, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _CustomerSummaryCard(
              customerName: _customerName,
              vehicle: _vehicle,
              service: _service,
            ),
          ),
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
                    return message.senderId == _mechanicSenderId
                        ? _OutgoingMessageBubble(text: message.text, time: time)
                        : _ChatBubble(text: message.text, time: time);
                  },
                );
              },
            ),
          ),
          if (_isCustomerTyping) const _TypingIndicator(),
          _ReplyBar(controller: _replyController, onSend: _handleSend),
        ],
      ),
    );
  }
}


/// Customer / vehicle / service summary — a flat card (not an elevated
/// "floating" surface) with a profile avatar and a turquoise accent bar
/// along the left edge. Name is the visual focus; vehicle/service are
/// icon-led secondary lines, no more "Label:" prefixes.
class _CustomerSummaryCard extends StatelessWidget {
  const _CustomerSummaryCard({
    required this.customerName,
    required this.vehicle,
    required this.service,
  });

  final String customerName;
  final String vehicle;
  final String service;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.turquoise.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppColors.turquoise, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 22, color: AppColors.turquoise),
                          const SizedBox(width: 8),
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoLine(icon: Icons.directions_car_outlined, text: vehicle),
                      const SizedBox(height: 4),
                      _InfoLine(icon: Icons.build_outlined, text: service),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SizedBox(width: 4, child: ColoredBox(color: AppColors.turquoise)),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.turquoise),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
        ),
      ],
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

/// Subtle "customer is typing" row shown above the reply bar — mock only,
/// driven by [_MechanicConversationPageState._scheduleMockIncomingReply].
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

/// A single customer message — left-aligned, flat light-gray bubble.
/// Outgoing (mechanic) replies would use the app's turquoise accent
/// instead, once sending is implemented.
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

/// A single outgoing (mechanic) reply — right-aligned, turquoise fill,
/// white text. Same border radius, padding, typography, and inline
/// bottom-right timestamp treatment as [_ChatBubble]; only the alignment
/// and color are mirrored so the reply reads as "sent" rather than
/// "received."
class _OutgoingMessageBubble extends StatelessWidget {
  const _OutgoingMessageBubble({required this.text, required this.time});

  final String text;
  final String time;

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
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time, style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85))),
                      const SizedBox(width: 5),
                      Icon(Icons.done_all_rounded, size: 14, color: Colors.white.withValues(alpha: 0.85)),
                    ],
                  ),
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
                    hintText: 'Yanıtınızı yazın...',
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
                    // Physical-keyboard Enter appends a newline to a
                    // multiline field by default; Shift+Enter should keep
                    // that newline, while plain Enter should submit
                    // instead. onSubmitted alone doesn't fire for
                    // multiline fields on desktop/web, so detect a
                    // trailing newline here and treat it as "send" unless
                    // Shift is held. The correction is deferred to a
                    // post-frame callback so it applies after the field's
                    // own pending update from the same key press, instead
                    // of racing it.
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
