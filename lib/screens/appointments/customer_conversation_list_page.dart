import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../mechanic/appointments/data/chat_message.dart';
import '../../mechanic/appointments/data/chat_repository.dart';
import '../../models/mechanic.dart';
import '../../theme/app_theme.dart';
import 'customer_conversation_page.dart';

/// Conversation list — the real destination for the bottom nav's "Mesajlar"
/// tab. Lists one row per mechanic the customer has an existing
/// conversation with (each mechanic gets a separate chats/{chatId}
/// document — see mechanicChatId/ChatRepository.watchChats) and opens the
/// existing, unmodified CustomerConversationPage on tap. Creating new
/// conversations from here is out of scope — rows only ever come from
/// conversations that already exist.
///
/// The search field and "Tümü"/"Okunmamış"/"Randevular" filter chips are
/// visual only for this pass (no filtering logic wired yet) — this step is
/// a styling pass on the list itself, not new list behavior.
class CustomerConversationListPage extends StatefulWidget {
  const CustomerConversationListPage({super.key});

  @override
  State<CustomerConversationListPage> createState() => _CustomerConversationListPageState();
}

class _CustomerConversationListPageState extends State<CustomerConversationListPage> {
  static const _filters = ['Tümü', 'Okunmamış', 'Randevular'];

  var _selectedFilter = 0;

  /// The chat list only stores a mechanicName string (see ChatSummary) —
  /// no mechanic id/verified flag, and adding one is out of scope for a
  /// UI-only pass. Cross-referencing the existing mock mechanic directory
  /// by name (already used to seed these same conversations from
  /// AppointmentRequestCard/ServiceCenterCard) recovers verification
  /// status without touching the data model.
  static Mechanic? _findMechanicByName(String name) {
    for (final mechanic in MockData.allMechanics) {
      if (mechanic.name == name) return mechanic;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mesajlar')),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
              child: _SearchField(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
              child: Row(
                children: [
                  for (var i = 0; i < _filters.length; i++) ...[
                    _FilterChip(
                      label: _filters[i],
                      selected: _selectedFilter == i,
                      onTap: () => setState(() => _selectedFilter = i),
                    ),
                    if (i < _filters.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ChatSummary>>(
                stream: ChatRepository().watchChats(),
                builder: (context, snapshot) {
                  final chats = snapshot.data ?? const <ChatSummary>[];
                  if (chats.isEmpty) return const _EmptyState();

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
                    itemCount: chats.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, index) => _ConversationRow(
                      chatId: chats[index].chatId,
                      mechanicName: chats[index].mechanicName,
                      mechanic: _findMechanicByName(chats[index].mechanicName),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded, very-light-gray search field — visual only, no filtering
/// wired up in this pass.
class _SearchField extends StatelessWidget {
  const _SearchField();

  static const _fillColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Ara',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: _fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Small pill filter chip — turquoise fill when selected, light gray
/// otherwise (never red, matching the app's turquoise/light-blue identity).
class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _neutralColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.turquoise : _neutralColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown when the customer has no conversations yet — same icon+text
/// treatment as AppointmentsTab's own empty state, for consistency with
/// how this app already handles "nothing here yet" elsewhere.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Henüz bir mesajınız yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bir ustaya mesaj gönderdiğinizde burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// One conversation card: avatar, mechanic name (+ verified badge/label
/// when applicable), last-message preview, last-message time, and an
/// unread-count badge — all driven by the same live Firestore stream
/// CustomerConversationPage itself reads from, so this never shows stale
/// or invented data. The unread count uses ChatMessage.isRead, a field the
/// existing ChatRepository/ChatMessage already write on every message
/// (just not previously surfaced anywhere in the UI).
class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.chatId, required this.mechanicName, required this.mechanic});

  final String chatId;
  final String mechanicName;
  final Mechanic? mechanic;

  // Matches CustomerConversationPage's own sender id for "me".
  static const _customerSenderId = 'customer-demo';

  static String _formatTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk';
    if (difference.inHours < 24) return '${difference.inHours} sa';
    if (difference.inDays < 7) return '${difference.inDays} g';
    return '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = mechanic?.isVerified ?? false;

    return StreamBuilder<List<ChatMessage>>(
      stream: ChatRepository().watchMessages(chatId),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? const <ChatMessage>[];
        final lastMessage = messages.isEmpty ? null : messages.last;
        final unreadCount = messages.where((m) => !m.isRead && m.senderId != _customerSenderId).length;

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomerConversationPage(chatId: chatId, mechanicName: mechanicName),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.car_repair, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                mechanicName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 15, color: AppColors.primary),
                            ],
                          ],
                        ),
                        if (isVerified) ...[
                          const SizedBox(height: 2),
                          const Text(
                            'Doğrulanmış Usta',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          lastMessage?.text ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lastMessage == null ? '' : _formatTime(lastMessage.createdAt),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.turquoise, shape: BoxShape.circle),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
