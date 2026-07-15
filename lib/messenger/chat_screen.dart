import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_info_sheet.dart';
import 'conversation.dart';
import '../app_colors.dart';
import '../net_image.dart';
import '../post/post_api_service.dart';

/// Erkennt einen geteilten Post-Link der Form `ranked://post/<id>`.
///
/// Der Messenger speichert und verschickt den Link als ganz normalen Text –
/// erst beim Rendern der Bubble prüfen wir, ob es ein Post-Link ist, und
/// zeigen dann statt des nackten Textes eine Mini-Vorschau. Liefert die
/// Post-ID zurück oder `null`, wenn der Text kein (sauberer) Post-Link ist.
///
/// Bewusst streng verankert (`^…$`, nur Ziffern): So kann niemand über die
/// Tastatur etwas anderes einschmuggeln (z. B. `ranked://post/5 evil.com`).
int? _tryParsePostId(String text) {
  final match = RegExp(r'^ranked://post/(\d+)$').firstMatch(text.trim());
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

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
  // Einmal in initState geholt und festgehalten: watch() im build wuerde bei
  // jedem Rebuild eine NEUE Drift-Query starten (alte Subscription weg, volle
  // SQL-Abfrage neu). So bleibt eine Subscription fuer die Lebensdauer des
  // Screens bestehen und feuert nur bei echten DB-Aenderungen.
  late final Stream<List<ChatMessage>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = widget.conversation.watch();
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
    final conversation = widget.conversation;
    final title = conversation.title;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        // Der ganze Header ist tappbar (WhatsApp-Stil) und öffnet das
        // Chat-Info-Sheet (Mini-Profil bzw. Gruppen-Info).
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showChatInfoSheet(context, conversation),
          child: Row(
            children: [
              _Avatar(name: title, avatarUrl: conversation.avatarUrl),
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
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messages,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) return const _EmptyConversation();

                // Datums-Trenner + Nachrichten zu einer flachen Liste mischen
                // (rein aus createdAt abgeleitet, keine Datenänderung).
                final items = _buildItems(messages);

                // reverse: true dreht die Laufrichtung: Index 0 klebt UNTEN,
                // und die Ansicht startet dort — man landet beim Öffnen also
                // automatisch bei der neuesten Nachricht, und neue Nachrichten
                // bleiben "angeheftet". Damit unten auch wirklich das neueste
                // Item liegt, wird der Index gespiegelt (items ist chronologisch).
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[items.length - 1 - i];
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

    // Ist der Text ein geteilter Post-Link? Dann statt der Text-Bubble die
    // Mini-Vorschau rendern (lädt den Post per getPostById nach).
    final postId = _tryParsePostId(text);
    if (postId != null) {
      return Padding(
        padding: EdgeInsets.only(top: groupedWithPrevious ? 2 : 8),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width * 0.76),
            child: _PostPreviewCard(postId: postId, time: time, isMe: isMe),
          ),
        ),
      );
    }

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
//  Mini-Post-Vorschau (geteilter Post im Chat)
// -----------------------------------------------------------------------------

/// Lädt einen geteilten Post einmalig per [PostApiService.getPostById] nach und
/// zeigt eine kompakte Vorschau (Thumbnail, Titel, Autor). Bewusst ein
/// StatefulWidget: so wird das Future in [initState] festgehalten und nicht bei
/// jedem Rebuild (Scrollen, neue Nachricht) neu geladen.
class _PostPreviewCard extends StatefulWidget {
  final int postId;
  final String time;
  final bool isMe;

  const _PostPreviewCard({
    required this.postId,
    required this.time,
    required this.isMe,
  });

  @override
  State<_PostPreviewCard> createState() => _PostPreviewCardState();
}

class _PostPreviewCardState extends State<_PostPreviewCard> {
  late final Future<Map<String, dynamic>?> _postFuture;

  @override
  void initState() {
    super.initState();
    _postFuture = PostApiService.getPostById(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        // Gleiche Logik wie bei der Text-Bubble: eigene Nachricht = primary,
        // fremde = neutrale Container-Farbe.
        color: widget.isMe
            ? AppColors.primary
            : AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(widget.isMe ? 20 : 6),
          bottomRight: Radius.circular(widget.isMe ? 6 : 20),
        ),
      ),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _wrap(SizedBox(
              height: 60,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    // Auf der roten eigenen Bubble wäre der Standard-Spinner
                    // (primary) unsichtbar.
                    color: widget.isMe ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ));
          }

          final data = snapshot.data;
          // Post gelöscht, kein Zugriff oder Netzfehler → neutrale Card,
          // niemals die rohe URL oder ein Crash.
          if (data == null || data['post'] == null) {
            return _wrap(_buildUnavailable());
          }

          return _wrap(_buildPreview(data['post'] as Map<String, dynamic>));
        },
      ),
    );
  }

  /// Umschlag: Inhalt + Zeitstempel darunter, einheitliches Padding.
  Widget _wrap(Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.time,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailable() {
    final muted = widget.isMe
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.onSurfaceVariant;
    return Row(
      children: [
        Icon(Icons.hide_source_rounded, size: 20, color: muted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Post nicht verfügbar',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(Map<String, dynamic> post) {
    final title = (post['title'] ?? '').toString();
    final owner = post['owner'] as Map<String, dynamic>?;
    final username = owner?['username']?.toString() ?? 'Unbekannt';
    final imageUrl = post['image_url']?.toString();

    // Auf der roten eigenen Bubble wäre primary-auf-primary unsichtbar –
    // dort übernimmt Weiß die Akzent-Rolle.
    final accent = widget.isMe ? Colors.white : AppColors.primary;
    final textColor = widget.isMe ? Colors.white : AppColors.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // TODO: Post-Detail öffnen (nächster Schritt).
      },
      child: SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image(
                    // Vorschau ist in einer SizedBox mit Breite 240.
                    image: netImage(context, imageUrl, logicalWidth: 240),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: AppColors.surfaceContainerLow,
                      child: Icon(Icons.image_not_supported_outlined,
                          color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.article_outlined, size: 13, color: accent),
                      const SizedBox(width: 4),
                      Text(
                        '@$username',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
  final String? avatarUrl;
  const _Avatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerHighest,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: url != null && url.isNotEmpty
          ? Image(
              image: netImage(context, url, logicalWidth: 38),
              fit: BoxFit.cover,
              width: 38,
              height: 38,
              // Bild kaputt/offline -> zurück zur Initiale statt Fehler-Icon.
              errorBuilder: (_, _, _) => _initial(),
            )
          : _initial(),
    );
  }

  Widget _initial() {
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Text(
      letter,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Eingabeleiste
// -----------------------------------------------------------------------------

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
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
            // Der Controller ist selbst ein ValueListenable — so rebuildet bei
            // jedem Tastendruck NUR dieser Button, nicht der ganze Screen.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty;
                return GestureDetector(
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
                );
              },
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
            child: Icon(
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