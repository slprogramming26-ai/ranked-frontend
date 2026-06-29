import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'conversation.dart';
import '../app_colors.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({
    super.key,
    required this.conversation
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Nur fürs Aktivieren/Deaktivieren des Send-Buttons – keine Logik.
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose(); // wichtig, sonst Leak
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    widget.conversation.send(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.conversation.title;
    final canSend = _textController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _Avatar(name: title),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ende-zu-Ende verschlüsselt',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.conversation.watch(),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) return const _EmptyConversation();

                // Datums-Trenner + Nachrichten zu einer flachen Liste mischen
                // (rein aus createdAt abgeleitet, keine Datenänderung).
                final items = _buildItems(messages);

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    if (item is _DateSeparator) {
                      return _DateChip(label: item.label);
                    }
                    final entry = item as _MessageItem;
                    final msg = entry.message;
                    final isMe = msg.senderId == widget.conversation.myUserId;
                    return _MessageBubble(
                      text: msg.message,
                      time: _formatTime(msg.createdAt),
                      isMe: isMe,
                      groupedWithPrevious: entry.groupedWithPrevious,
                    );
                  },
                );
              },
            ),
          ),
          _Composer(
            controller: _textController,
            canSend: canSend,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Aufbereitung (reine Darstellung)
  // ---------------------------------------------------------------------------

  List<Object> _buildItems(List<ChatMessage> messages) {
    final items = <Object>[];
    DateTime? lastDay;
    int? lastSender;
    for (final msg in messages) {
      final local = msg.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final newDay = lastDay == null || day != lastDay;
      if (newDay) {
        items.add(_DateSeparator(_formatDay(day)));
        lastDay = day;
        lastSender = null;
      }
      items.add(_MessageItem(
        message: msg,
        groupedWithPrevious: !newDay && lastSender == msg.senderId,
      ));
      lastSender = msg.senderId;
    }
    return items;
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Gestern';
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
    ];
    return '${day.day}. ${months[day.month - 1]} ${day.year}';
  }
}

// -----------------------------------------------------------------------------
//  Hilfs-Typen für die flache Liste
// -----------------------------------------------------------------------------

class _DateSeparator {
  final String label;
  const _DateSeparator(this.label);
}

class _MessageItem {
  final ChatMessage message;
  final bool groupedWithPrevious;
  const _MessageItem({required this.message, required this.groupedWithPrevious});
}

// -----------------------------------------------------------------------------
//  Nachrichten-Blase
// -----------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final String text;
  final String time;
  final bool isMe;
  final bool groupedWithPrevious;

  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.groupedWithPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(top: groupedWithPrevious ? 2 : 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: width * 0.76),
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 8),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.primary
                : AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.75)
                      : AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Datums-Chip
// -----------------------------------------------------------------------------

class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Avatar in der AppBar (Initiale aus dem Titel)
// -----------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerHighest,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Eingabeleiste
// -----------------------------------------------------------------------------

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 50),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nachricht…',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: canSend ? onSend : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canSend
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.35),
                  boxShadow: canSend
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Leerer Chat
// -----------------------------------------------------------------------------

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Sag Hallo! 👋',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Noch keine Nachrichten.\nSchreib die erste und brich das Eis.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}