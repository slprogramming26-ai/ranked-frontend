import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:ranked/messenger/conversation.dart';
import 'package:ranked/local_data/database.dart';
import 'messenger_api_service.dart';
import 'messenger_controller.dart';
import '../profile.dart';
import 'chat_requests.dart';
import 'chat_screen.dart';
import '../app_colors.dart';
import '../net_image.dart';
import '../user_api_service.dart';

class MessengerHomescreen extends StatefulWidget {
  const MessengerHomescreen({super.key});

  @override
  State<MessengerHomescreen> createState() => _MessengerHomescreenState();
}

class _MessengerHomescreenState extends State<MessengerHomescreen> {
  // Service-Besitz, Lifecycle-Observer und Event-Abo liegen jetzt im
  // app-weiten MessengerController (messenger_controller.dart). Dieser
  // Screen LIEST nur noch — er erstellt und disposed nichts mehr; sonst
  // wuerde Zurueck-Navigieren die app-weite Verbindung killen.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeService(context);
    });
  }

  // Lazy-Fallback, solange Schritt 2 (init beim Login) noch fehlt: stellt
  // sicher, dass der Controller laeuft. Dank Idempotenz-Guard im Controller
  // ist der Aufruf ein No-Op, wenn der Service schon existiert.
  Future<void> initializeService(BuildContext context) async {
    final provider = context.read<ProfileProvider>();
    final db = context.read<AppDatabase>();
    final controller = context.read<MessengerController>();
    await provider.fetchUser();
    if (!mounted) return;
    final userId = provider.userdata["id"] as int;
    await controller.init(db, userId);
  }

  Future<void> _startPrivateChat(
    int userId, {
    String? username,
    String? avatarUrl,
  }) async {
    final db = context.read<AppDatabase>();
    final existing = await (db.select(db.openChats)
          ..where((t) => t.id.equals(userId) & t.isGroupChat.equals(false)))
        .getSingleOrNull();
    if (existing != null) {
      // Liegt der Chat noch als Anfrage vor, ist "selbst anschreiben" die
      // deutlichste Zustimmung -> direkt annehmen statt stumm abzubrechen.
      if (existing.isPending) {
        await (db.update(db.openChats)
              ..where((t) => t.localId.equals(existing.localId)))
            .write(const OpenChatsCompanion(isPending: Value(false)));
      }
      return;
    }

    await db.into(db.openChats).insert(
          OpenChatsCompanion.insert(
            id: userId,
            isGroupChat: false,
            username: Value(username ?? 'User $userId'),
            avatarUrl: Value(avatarUrl),
          ),
        );
  }

  Future<void> _openNewChatPicker() async {
    final picked = await Navigator.push<_PickedUser>(
      context,
      MaterialPageRoute(builder: (_) => const _NewChatSearchPage()),
    );
    if (picked == null || !mounted) return;
    await _startPrivateChat(
      picked.id,
      username: picked.username,
      avatarUrl: picked.avatarUrl,
    );
  }

  Future<void> _createNewGroup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
    final newGroupId = await MessengerApiService.createGroup();
    if (!mounted) return;
    Navigator.pop(context);
    if (newGroupId == null) {
      _snack('Fehler beim Erstellen der Gruppe.');
      return;
    }
    final db = context.read<AppDatabase>();
    await db.into(db.openChats).insert(
          OpenChatsCompanion.insert(
            id: newGroupId,
            isGroupChat: true,
            username: Value('Gruppe $newGroupId'),
          ),
        );
    _snack('Gruppe $newGroupId erfolgreich erstellt!');
  }

  Future<void> _joinGroupWithCode(int code) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
    // Welche Gruppe hinter dem Code steckt, wissen wir erst nach der Antwort.
    final groupId = await MessengerApiService.joinGroupByCode(code);
    if (!mounted) return;
    Navigator.pop(context);
    if (groupId == null) {
      _snack('Beitritt fehlgeschlagen. Ist der Code noch gültig?');
      return;
    }
    final db = context.read<AppDatabase>();
    final existing = await (db.select(db.openChats)
          ..where((t) => t.id.equals(groupId) & t.isGroupChat.equals(true)))
        .getSingleOrNull();
    if (existing == null) {
      await db.into(db.openChats).insert(
            OpenChatsCompanion.insert(
              id: groupId,
              isGroupChat: true,
              username: Value('Gruppe $groupId'),
            ),
          );
    }
    _snack('Gruppe $groupId beigetreten!');
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        backgroundColor: AppColors.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  Future<void> _showJoinGroupDialog() async {
    final controller = TextEditingController();
    final id = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Gruppe beitreten',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Einladungs-Code',
            hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: AppColors.surface.withValues(alpha: 0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Abbrechen',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null) Navigator.pop(ctx, parsed);
            },
            child: Text(
              'Beitreten',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (id != null) await _joinGroupWithCode(id);
  }

  Future<void> _showActionSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Neue Konversation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ActionTile(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Chat starten',
                subtitle: 'User per Name suchen',
                onTap: () => Navigator.pop(ctx, 'new_chat'),
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.group_add_rounded,
                label: 'Gruppe erstellen',
                subtitle: 'Neue Gruppe anlegen',
                onTap: () => Navigator.pop(ctx, 'create_group'),
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.meeting_room_rounded,
                label: 'Gruppe beitreten',
                subtitle: 'Mit Einladungs-Code einsteigen',
                onTap: () => Navigator.pop(ctx, 'join_group'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'new_chat':
        await _openNewChatPicker();
      case 'create_group':
        await _createNewGroup();
      case 'join_group':
        await _showJoinGroupDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Kontakte',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: IconButton(
                icon: Icon(Icons.edit_rounded, color: AppColors.primary),
                onPressed: _showActionSheet,
                tooltip: 'Neue Konversation',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<OpenChat>>(
          stream: db.watchAllContacts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final contacts = snapshot.data!;
            if (contacts.isEmpty) return const _EmptyChats();
            // Anfragen (Erstkontakt von Fremden) fliegen aus der normalen
            // Liste und sammeln sich hinter EINER Zeile oben — die nur
            // existiert, wenn es gerade Anfragen gibt.
            final requests = contacts.where((c) => c.isPending).toList();
            final chats = contacts.where((c) => !c.isPending).toList();
            final hasRequestsRow = requests.isNotEmpty;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              physics: const BouncingScrollPhysics(),
              itemCount: chats.length + (hasRequestsRow ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (hasRequestsRow && index == 0) {
                  return _RequestsRow(
                    count: requests.length,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatRequestsPage(),
                      ),
                    ),
                  );
                }
                final c = chats[hasRequestsRow ? index - 1 : index];
                return _ChatTile(
                  key: ValueKey('${c.isGroupChat}-${c.id}'),
                  contact: c,
                  onTap: () {
                    final controller = context.read<MessengerController>();
                    final service = controller.service;
                    final myUserId = controller.userId;
                    // Noch nicht initialisiert (init laeuft gerade) -> Tap
                    // ignorieren statt mit ! zu crashen.
                    if (service == null || myUserId == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversation: c.isGroupChat
                              ? GroupConversation(
                                  groupChatId: c.id,
                                  myUserId: myUserId,
                                  db: db,
                                  service: service,
                                  displayName: c.username,
                                  avatarUrl: c.avatarUrl,
                                )
                              : DmConversation(
                                  peerId: c.id,
                                  myUserId: myUserId,
                                  db: db,
                                  service: service,
                                  displayName: c.username,
                                  avatarUrl: c.avatarUrl,
                                ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}



// Sammel-Zeile fuer offene Chat-Anfragen. Wird nur gerendert, wenn es
// welche gibt — ihr Erscheinen (plus Count-Badge) ist das Signal.
class _RequestsRow extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _RequestsRow({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anfragen',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      count == 1
                          ? '1 Person möchte dir schreiben'
                          : '$count Personen möchten dir schreiben',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final OpenChat contact;
  final VoidCallback onTap;

  const _ChatTile({super.key, required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isGroup = contact.isGroupChat;
    final raw = contact.username;
    final displayName = isGroup ? raw : '@$raw';
    final subtitle = isGroup ? 'Gruppenchat' : 'Direktnachricht';

    return Material(
      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHighest,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child:
                    (contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty)
                    ? Image(
                        // Container ist 48x48 -> 48 logische px reichen.
                        image: netImage(
                          context,
                          contact.avatarUrl!,
                          logicalWidth: 48,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallback(raw, isGroup),
                      )
                    : _fallback(raw, isGroup),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isGroup
                              ? Icons.groups_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 12,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(String name, bool isGroup) => Container(
    color: AppColors.surfaceContainerHighest,
    alignment: Alignment.center,
    child: isGroup
        ? Icon(Icons.groups_rounded, color: AppColors.primary, size: 22)
        : Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
  );
}

// -----------------------------------------------------------------------------
//  Bottom-Sheet-Action
// -----------------------------------------------------------------------------

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_outward_rounded,
                color: AppColors.primary.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Empty-State
// -----------------------------------------------------------------------------

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

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
              Icons.forum_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Keine Konversationen',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tipp auf das Stift-Symbol,\num einen Chat oder eine Gruppe zu starten.',
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

// -----------------------------------------------------------------------------
//  Picker-Seite (ersetzt AlertDialog + nested SearchAnchor)
// -----------------------------------------------------------------------------

class _PickedUser {
  final int id;
  final String username;
  final String? avatarUrl;
  const _PickedUser({
    required this.id,
    required this.username,
    this.avatarUrl,
  });
}

class _NewChatSearchPage extends StatefulWidget {
  const _NewChatSearchPage();

  @override
  State<_NewChatSearchPage> createState() => _NewChatSearchPageState();
}

class _NewChatSearchPageState extends State<_NewChatSearchPage> {
  static const _minQueryLength = 2;
  static const _debounceDuration = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Map<String, List<Map<String, dynamic>>> _cache = {};
  Timer? _debounce;

  String _query = '';
  List<Map<String, dynamic>>? _results;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    final text = _controller.text.trim();
    if (text == _query) return;
    setState(() {
      _query = text;
      _error = false;
    });
    _debounce?.cancel();
    if (text.length < _minQueryLength) {
      setState(() => _results = null);
      return;
    }
    if (_cache.containsKey(text)) {
      setState(() => _results = _cache[text]);
      return;
    }
    _debounce = Timer(_debounceDuration, () => _runSearch(text));
  }

  Future<void> _runSearch(String text) async {
    setState(() => _loading = true);
    try {
      final res = await UserApiService.getUserByUsername(text);
      _cache[text] = res;
      if (!mounted || _controller.text.trim() != text) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _pick(Map<String, dynamic> user) {
    Navigator.pop(
      context,
      _PickedUser(
        id: user['id'] as int,
        username: (user['username'] as String?) ?? '',
        avatarUrl: user['profile_picture_url'] as String?,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat starten',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Username suchen',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () => _controller.clear(),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_query.length < _minQueryLength) {
      return const _HintTile(
        icon: Icons.keyboard_alt_outlined,
        text: 'Mindestens 2 Zeichen eingeben',
      );
    }
    if (_loading) return const _LoadingTile();
    if (_error) {
      return const _HintTile(
        icon: Icons.error_outline,
        text: 'Etwas ist schiefgelaufen.',
      );
    }
    final results = _results;
    if (results == null) return const _LoadingTile();
    if (results.isEmpty) {
      return const _HintTile(
        icon: Icons.person_off_outlined,
        text: 'Keine User gefunden',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final user = results[i];
        return _UserResultTile(
          key: ValueKey(user['id']),
          username: (user['username'] as String?) ?? '',
          avatarUrl: user['profile_picture_url'] as String?,
          vibe1: user['vibe_factor_1'] as String?,
          vibe2: user['vibe_factor_2'] as String?,
          onTap: () => _pick(user),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
//  Wiederverwendbare Helfer für den Picker
// -----------------------------------------------------------------------------

class _HintTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HintTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _UserResultTile extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String? vibe1;
  final String? vibe2;
  final VoidCallback onTap;

  const _UserResultTile({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.vibe1,
    required this.vibe2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      vibe1,
      vibe2,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return Material(
      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHighest,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
                child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? Image(
                        // Container ist 46x46 -> 46 logische px reichen.
                        image: netImage(
                          context,
                          avatarUrl!,
                          logicalWidth: 46,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallback(),
                      )
                    : _fallback(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() => Container(
    color: AppColors.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Text(
      username.isNotEmpty ? username[0].toUpperCase() : '?',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    ),
  );
}