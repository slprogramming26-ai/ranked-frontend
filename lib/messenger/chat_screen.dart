import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'chat_info_sheet.dart';
import 'conversation.dart';
import 'messenger_api_service.dart';
import '../app_colors.dart';
import '../local_data/database.dart';
import '../net_image.dart';
import '../post/post_api_service.dart';
import '../user_api_service.dart';

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

/// Erkennt eine Gruppen-Einladung der Form `ranked://group/<code>`.
/// Gleiche Idee (und gleiche strenge Verankerung) wie [_tryParsePostId].
int? _tryParseGroupCode(String text) {
  final match = RegExp(r'^ranked://group/(\d+)$').firstMatch(text.trim());
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  // true = der Chat ist eine noch offene Anfrage (Erstkontakt von einem
  // Fremden): statt des Eingabefelds erscheint unten Annehmen/Ablehnen.
  final bool isRequest;

  const ChatScreen({
    super.key,
    required this.conversation,
    this.isRequest = false,
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

  // Lokale Kopie des Request-Zustands: nach "Annehmen" muss nur DIESER
  // Screen umschalten (Composer statt Leiste), kein Neu-Navigieren noetig.
  late bool _isRequest;

  @override
  void initState() {
    super.initState();
    _messages = widget.conversation.watch();
    _isRequest = widget.isRequest;
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
          if (_isRequest)
            _RequestBar(
              onAccept: _acceptRequest,
              onDecline: _declineRequest,
            )
          else
            _Composer(
              controller: _textController,
              onSend: _send,
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Chat-Anfrage annehmen / ablehnen
  // ---------------------------------------------------------------------------

  // Annehmen = nur das pending-Flag in der Chatliste loeschen. Der Drift-
  // Stream der Chatliste zieht den Chat dann automatisch aus "Anfragen"
  // in die normale Liste.
  Future<void> _acceptRequest() async {
    final dm = widget.conversation as DmConversation;
    await (dm.db.update(dm.db.openChats)
          ..where((t) => t.id.equals(dm.peerId) & t.isGroupChat.equals(false)))
        .write(const OpenChatsCompanion(isPending: Value(false)));
    if (mounted) setState(() => _isRequest = false);
  }

  // Ablehnen loescht die Chatlisten-Zeile (die Nachrichten-Historie bleibt,
  // sie ist reiner Cache). Ohne Blockieren kann dieselbe Person die Anfrage
  // mit ihrer naechsten Nachricht neu erzeugen — deshalb bietet der Dialog
  // das Blockieren gleich mit an.
  Future<void> _declineRequest() async {
    final dm = widget.conversation as DmConversation;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final action = await showDialog<String>(
      context: context,
      builder: (_) => _DeclineDialog(username: dm.title),
    );
    if (action == null || !mounted) return;

    if (action == 'block') {
      await UserApiService.blockUser(dm.peerId);
    }
    await (dm.db.delete(dm.db.openChats)
          ..where((t) => t.id.equals(dm.peerId) & t.isGroupChat.equals(false)))
        .go();
    nav.pop(); // zurueck zur Anfragen-Liste
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.onSurface,
        content: Text(
          action == 'block'
              ? 'Anfrage abgelehnt und ${dm.title} blockiert.'
              : 'Anfrage abgelehnt.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
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

    // Oder eine Gruppen-Einladung? Dann Card mit Beitreten-Button.
    final groupCode = _tryParseGroupCode(text);
    if (groupCode != null) {
      return Padding(
        padding: EdgeInsets.only(top: groupedWithPrevious ? 2 : 8),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width * 0.76),
            child: _GroupInviteCard(code: groupCode, time: time, isMe: isMe),
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
//  Gruppen-Einladung (geteilter Invite-Code im Chat)
// -----------------------------------------------------------------------------

enum _JoinState { idle, loading, joined }

/// Einladungs-Card für `ranked://group/<code>`-Nachrichten: zeigt den Code und
/// einen Beitreten-Button. Der Button macht genau das, was auch der
/// Code-Dialog in der Chatliste macht (joinGroupByCode + OpenChat anlegen) —
/// nur ohne Tipparbeit. Abgelaufene Codes meldet der Server mit einem Fehler,
/// dann bleibt die Card benutzbar und eine SnackBar erklärt das Problem.
class _GroupInviteCard extends StatefulWidget {
  final int code;
  final String time;
  final bool isMe;

  const _GroupInviteCard({
    required this.code,
    required this.time,
    required this.isMe,
  });

  @override
  State<_GroupInviteCard> createState() => _GroupInviteCardState();
}

class _GroupInviteCardState extends State<_GroupInviteCard> {
  _JoinState _state = _JoinState.idle;

  Future<void> _join() async {
    // Messenger/DB VOR dem ersten await sichern (Screen könnte weg sein).
    final messenger = ScaffoldMessenger.of(context);
    final db = context.read<AppDatabase>();
    setState(() => _state = _JoinState.loading);

    // Welche Gruppe hinter dem Code steckt, verrät erst die Server-Antwort.
    final groupId = await MessengerApiService.joinGroupByCode(widget.code);
    if (!mounted) return;

    if (groupId == null) {
      setState(() => _state = _JoinState.idle);
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          content: Text(
            'Beitritt fehlgeschlagen. Ist der Code noch gültig?',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
      return;
    }

    // Wie beim Code-Dialog: Chatlisten-Eintrag nur anlegen, wenn er fehlt
    // (man kann derselben Gruppe nicht zweimal in der Liste stehen).
    final existing =
        await (db.select(db.openChats)
              ..where((t) => t.id.equals(groupId) & t.isGroupChat.equals(true)))
            .getSingleOrNull();
    if (existing == null) {
      await db
          .into(db.openChats)
          .insert(
            OpenChatsCompanion.insert(
              id: groupId,
              isGroupChat: true,
              username: Value('Gruppe $groupId'),
            ),
          );
    }
    if (!mounted) return;
    setState(() => _state = _JoinState.joined);
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.onSurface,
        content: Text(
          'Gruppe beigetreten! Du findest sie in deiner Chatliste.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Farblogik wie bei der Post-Vorschau: auf der eigenen (roten) Bubble
    // übernimmt Weiß die Akzent-Rolle, sonst primary.
    final accent = widget.isMe ? Colors.white : AppColors.primary;
    final textColor = widget.isMe ? Colors.white : AppColors.onSurface;
    final muted = widget.isMe
        ? Colors.white.withValues(alpha: 0.75)
        : AppColors.onSurfaceVariant;
    // Button invertiert die Bubble-Farben, damit er sich abhebt.
    final buttonBg = widget.isMe ? Colors.white : AppColors.primary;
    final buttonFg = widget.isMe ? AppColors.primary : Colors.white;

    return Container(
      decoration: BoxDecoration(
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.groups_rounded, size: 22, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Gruppeneinladung',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Code ${widget.code}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: widget.isMe ? null : FilledButton(
                onPressed: _state == _JoinState.idle ? _join : null,
                style: FilledButton.styleFrom(
                  backgroundColor: buttonBg,
                  foregroundColor: buttonFg,
                  // "Beigetreten" soll nicht wie ein Fehler aussehen — nur
                  // leicht abgeschwächt.
                  disabledBackgroundColor: buttonBg.withValues(alpha: 0.55),
                  disabledForegroundColor: buttonFg.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _state == _JoinState.loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: buttonFg,
                        ),
                      )
                    : Text(
                        _state == _JoinState.joined
                            ? 'Beigetreten'
                            : 'Beitreten',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                widget.time,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: muted,
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
//  Anfrage-Leiste (ersetzt den Composer, solange der Chat pending ist)
// -----------------------------------------------------------------------------

class _RequestBar extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestBar({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nimm die Anfrage an, um antworten zu können.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Ablehnen',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Annehmen',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nachfrage beim Ablehnen. Gibt per Navigator.pop zurueck:
/// 'decline' = nur ablehnen, 'block' = ablehnen UND blockieren, null = abbrechen.
class _DeclineDialog extends StatelessWidget {
  final String username;
  const _DeclineDialog({required this.username});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Anfrage ablehnen?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Der Chat wird aus deiner Liste entfernt. Ohne Blockieren kann '
              '$username dir aber erneut eine Anfrage schicken.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, 'decline'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Ablehnen',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, 'block'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Ablehnen & blockieren',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Abbrechen',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
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