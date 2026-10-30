// =============================================================================
//  Chat-Info-Sheet (Mini-Profil im WhatsApp-Stil)
// =============================================================================
//  Öffnet sich beim Tap auf den Header im ChatScreen.
//   * DM:     großes Profil + "Profil öffnen" + "Blockieren"
//   * Gruppe: Mitgliederliste (EIN Request — der Server joint Username/Avatar
//             schon mit) + "Gruppe verlassen"
// =============================================================================

import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../ui/app_colors.dart';
import '../ui/confirm_dialog.dart';
import '../local_data/database.dart';
import '../ui/net_image.dart';
import '../post/widgets/share_sheet.dart';
import '../profile/profile.dart';
import '../core/user_api_service.dart';
import 'conversation.dart';
import 'group_permissions.dart';
import 'group_picture.dart';
import 'messenger_api_service.dart';
import 'messenger_controller.dart';
import 'package:ranked/l10n/l10n.dart';

/// Einstiegspunkt: entscheidet anhand des Conversation-Typs, welches Sheet
/// gezeigt wird. Wird vom ChatScreen-Header aufgerufen.
Future<void> showChatInfoSheet(
  BuildContext context,
  Conversation conversation,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => conversation is GroupConversation
        ? _GroupInfoSheet(conversation: conversation)
        : _DmInfoSheet(conversation: conversation as DmConversation),
  );
}

// -----------------------------------------------------------------------------
//  DM-Variante
// -----------------------------------------------------------------------------

class _DmInfoSheet extends StatefulWidget {
  final DmConversation conversation;
  const _DmInfoSheet({required this.conversation});

  @override
  State<_DmInfoSheet> createState() => _DmInfoSheetState();
}

class _DmInfoSheetState extends State<_DmInfoSheet> {
  // Name + Bild live aus Drift, wie im Gruppen-Sheet (Begründung dort).
  late ChatHeader _header = (
    title: widget.conversation.title,
    avatarUrl: widget.conversation.avatarUrl,
  );
  late final StreamSubscription<ChatHeader> _headerSub;

  @override
  void initState() {
    super.initState();
    fetchBlock();
    _headerSub = widget.conversation.watchHeader().listen(
      (h) => setState(() => _header = h),
    );
  }

  @override
  void dispose() {
    _headerSub.cancel();
    super.dispose();
  }

  bool? isBlocked;

  Future<void> fetchBlock() async {
    final blocks = await UserApiService.getBlocks();
    if (!mounted) return; // Sheet evtl. schon weggewischt
    // Fehler (null) -> false, also wie bisher "Blockieren". Harmlos: ist er
    // doch schon blockiert, liefert der Server 409 = Erfolg.
    setState(() {
      isBlocked =
          blocks?.any((b) => b['id'] == widget.conversation.peerId) ?? false;
    });
  }

  Future<void> _openProfile(BuildContext context) async {
    // Navigator VOR dem pop holen: das Sheet liegt auf dem Root-Navigator,
    // pop schließt also nur das Sheet, danach pushen wir aufs selbe Navigator.
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => Profile(targetUserId: widget.conversation.peerId),
      ),
    );
  }

  Future<void> _confirmBlock(BuildContext context) async {
    // Messenger/Navigator VOR dem ersten await sichern — nach einem async-Gap
    // darf context nicht mehr benutzt werden (Sheet könnte weggewischt sein).
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: Icons.block_rounded,
        title: l10n.chatInfoBlockTitle(_header.title),
        message: l10n.chatInfoBlockMessage,
        confirmLabel: l10n.chatInfoBlock,
      ),
    );
    if (confirmed != true) return;

    final ok = await UserApiService.blockUser(widget.conversation.peerId);

    if (ok && nav.canPop()) nav.pop(); // Sheet zu
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.onSurface : AppColors.primary,
        content: Text(
          ok
              ? l10n.profileBlocked(_header.title)
              : l10n.profileBlockFailed,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Spiegelbild von _confirmBlock, Texte wie im BlockedAccountsScreen.
  Future<void> _confirmUnblock(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final l10n = context.l10n;
    final name = _header.title;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: Icons.lock_open_rounded,
        title: l10n.blockedUnblockTitle(name),
        message: l10n.blockedUnblockMessage(name),
        confirmLabel: l10n.blockedUnblock,
      ),
    );
    if (confirmed != true) return;

    final ok = await UserApiService.deleteBlock(widget.conversation.peerId);

    if (ok && nav.canPop()) nav.pop(); // Sheet zu
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.onSurface : AppColors.primary,
        content: Text(
          ok ? l10n.blockedUnblocked(name) : l10n.blockedUnblockFailed,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            const SizedBox(height: 16),
            _BigAvatar(
              name: _header.title,
              avatarUrl: _header.avatarUrl,
            ),
            const SizedBox(height: 12),
            Text(
              _header.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            const _EncryptedBadge(),
            const SizedBox(height: 20),
            _ActionTile(
              icon: Icons.person_rounded,
              label: context.l10n.chatInfoOpenProfile,
              onTap: () => _openProfile(context),
            ),
            const SizedBox(height: 8),
            // Waehrend des Ladens gesperrt (onTap null), sonst koennte man in
            // den ersten Millisekunden die falsche Aktion erwischen.
            _ActionTile(
              icon: isBlocked == true
                  ? Icons.lock_open_rounded
                  : Icons.block_rounded,
              label: isBlocked == true
                  ? context.l10n.chatInfoUnblock
                  : context.l10n.chatInfoBlock,
              loading: isBlocked == null,
              onTap: switch (isBlocked) {
                null => null,
                true => () => _confirmUnblock(context),
                false => () => _confirmBlock(context),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Gruppen-Variante
// -----------------------------------------------------------------------------

class _GroupInfoSheet extends StatefulWidget {
  final GroupConversation conversation;
  const _GroupInfoSheet({required this.conversation});

  @override
  State<_GroupInfoSheet> createState() => _GroupInfoSheetState();
}

class _GroupInfoSheetState extends State<_GroupInfoSheet> {
  // Future festhalten (wie bei _PostPreviewCard): sonst würde jeder Rebuild
  // die Mitglieder neu vom Server laden. Nicht final — nach jeder
  // Mitglieder-Aktion setzt _loadMembers ein neues Future.
  late Future<List<GroupMember>> _membersFuture;

  // Eigene Rolle, aus derselben Mitgliederliste gelesen (Rollen kommen nicht
  // per WebSocket). null = noch nicht geladen -> Bearbeiten-Elemente bleiben
  // so lange versteckt, statt kurz aufzublitzen und wieder zu verschwinden.
  GroupRole? _myRole;
  bool get _canManage => _myRole?.canManage ?? false;

  bool _uploadingPicture = false;

  // Name + Bild live aus Drift (wie der ChatScreen-Header). Per listen statt
  // StreamBuilder, weil nicht nur build den aktuellen Namen braucht, sondern
  // auch die Dialoge (Umbenennen, Löschen, Verlassen). Startwert =
  // Schnappschuss, bis Drift den ersten Wert liefert.
  late ChatHeader _header = (
    title: widget.conversation.title,
    avatarUrl: widget.conversation.avatarUrl,
  );
  late final StreamSubscription<ChatHeader> _headerSub;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _headerSub = widget.conversation.watchHeader().listen(
      (h) => setState(() => _header = h),
    );
  }

  @override
  void dispose() {
    // Ohne cancel liefe die Drift-Abfrage weiter und setState würde auf
    // einem toten State landen.
    _headerSub.cancel();
    super.dispose();
  }

  // Laedt die Mitgliederliste (neu) und liest dabei die eigene Rolle mit aus.
  // Laeuft in initState und nach jeder Mitglieder-Aktion: Rollen kommen nicht
  // per WebSocket, nach einer Aenderung weiss es nur der Server sicher.
  // Nach Aktionen als setState(_loadMembers) aufrufen, damit der
  // FutureBuilder das neue Future mitbekommt.
  void _loadMembers() {
    _membersFuture =
        MessengerApiService.fetchGroupMembers(
          widget.conversation.groupChatId,
        ).then((members) {
          final me = members.where((m) => m.id == widget.conversation.myUserId);
          if (mounted && me.isNotEmpty) setState(() => _myRole = me.first.role);
          return members;
        });
  }

  Future<void> _changeGroupPicture() async {
    if (_uploadingPicture) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final picked = await pickGroupPicture();
    if (picked == null || !mounted) return;

    setState(() => _uploadingPicture = true);

    // 1) EXIF/GPS raus (siehe group_picture.dart).
    final cleanFile = await sanitizeGroupPicture(picked);
    if (!mounted) return;
    if (cleanFile == null) {
      setState(() => _uploadingPicture = false);
      _showSnack(messenger, l10n.chatInfoPictureProcessFailed);
      return;
    }

    // 2) Hochladen.
    final groupId = widget.conversation.groupChatId;
    final result = await MessengerApiService.uploadGroupChatPicture(
      groupId,
      cleanFile,
    );
    final url = result.url;

    // 3) Lokal in Drift speichern -> Chatliste, ChatScreen-Header und dieses
    // Sheet (_header) ziehen über ihre Streams nach. Wie beim Umbenennen VOR
    // dem mounted-Check: das Bild ist auf dem Server, auch wenn das Sheet
    // inzwischen zu ist.
    if (url != null) {
      final db = widget.conversation.db;
      await (db.update(db.openChats)
            ..where((t) => t.id.equals(groupId) & t.isGroupChat.equals(true)))
          .write(OpenChatsCompanion(avatarUrl: Value(url)));
    }
    if (!mounted) return;

    setState(() => _uploadingPicture = false);
    if (url == null) {
      _showSnack(
        messenger,
        result.statusCode == 403
            ? l10n.chatInfoPictureOnlyCreator
            : l10n.chatInfoPictureUploadFailed,
      );
      return;
    }
    _showSnack(messenger, l10n.chatInfoPictureUpdated, error: false);
  }

  Future<void> _renameGroup() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initialName: _header.title),
    );
    if (newName == null || newName == _header.title || !mounted) return;

    final groupId = widget.conversation.groupChatId;
    final status = await MessengerApiService.renameGroup(groupId, newName);
    final ok = status >= 200 && status < 300;

    // Drift VOR dem mounted-Check: hat man das Sheet inzwischen weggewischt,
    // ist der Name auf dem Server trotzdem neu — die Chatliste soll ihn dann
    // auch zeigen und nicht bis zum naechsten Sync den alten.
    if (ok) {
      final db = widget.conversation.db;
      await (db.update(db.openChats)
            ..where((t) => t.id.equals(groupId) & t.isGroupChat.equals(true)))
          .write(OpenChatsCompanion(username: Value(newName)));
    }
    if (!mounted) return;

    if (ok) {
      // Kein setState nötig: der Drift-Write oben lässt _headerSub feuern.
      _showSnack(messenger, l10n.chatInfoRenamed(newName), error: false);
      return;
    }
    // 403 = wir sind (nicht mehr) Gruender/Admin, 404 = Gruppe weg. Wie bei
    // den Mitglieder-Aktionen neu laden -> Stift verschwindet ggf.
    if (status == 403 || status == 404) setState(_loadMembers);
    _showSnack(
      messenger,
      (status == 403 || status == 404)
          ? l10n.chatInfoMemberActionOutdated
          : l10n.chatInfoMemberActionFailed,
    );
  }

  void _showSnack(
    ScaffoldMessengerState messenger,
    String text, {
    bool error = true,
  }) {
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.primary : AppColors.onSurface,
        content: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _openMemberProfile(int userId) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => Profile(targetUserId: userId)));
  }

  // Tap auf ein Mitglied: Darf ich nichts mit ihm machen, geht's direkt zum
  // Profil (wie vorher). Sonst kommt ein kleines Aktions-Sheet.
  Future<void> _onMemberTap(GroupMember member) async {
    final myRole = _myRole;
    final actions = myRole == null
        ? const <MemberAction>{}
        : allowedMemberActions(
            myRole: myRole,
            myUserId: widget.conversation.myUserId,
            target: member,
          );
    if (actions.isEmpty) {
      _openMemberProfile(member.id);
      return;
    }

    final action = await showModalBottomSheet<MemberAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _MemberActionsSheet(
        member: member,
        actions: actions,
        onOpenProfile: () => _openMemberProfile(member.id),
      ),
    );
    if (action == null || !mounted) return;
    await _runMemberAction(action, member);
  }

  Future<void> _runMemberAction(MemberAction action, GroupMember member) async {
    // Wie überall im Sheet: Messenger/l10n vor dem ersten await sichern.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final groupId = widget.conversation.groupChatId;
    final name = member.username;

    // Rauswerfen und Übergeben kann man nicht mit einem Tap zurückdrehen
    // (nach dem Übergeben gar nicht mehr selbst) -> erst nachfragen.
    // Befördern/Degradieren gehen ohne Dialog, die sind leicht umkehrbar.
    final dialog = switch (action) {
      MemberAction.kick => ConfirmDialog(
        icon: Icons.person_remove_rounded,
        title: l10n.chatInfoKickTitle(name),
        message: l10n.chatInfoKickMessage,
        confirmLabel: l10n.chatInfoKickConfirm,
      ),
      MemberAction.transfer => ConfirmDialog(
        icon: Icons.workspace_premium_rounded,
        title: l10n.chatInfoTransferTitle(name),
        message: l10n.chatInfoTransferMessage(name),
        confirmLabel: l10n.chatInfoTransferConfirm,
      ),
      MemberAction.promote || MemberAction.demote => null,
    };
    if (dialog != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => dialog,
      );
      if (confirmed != true || !mounted) return;
    }

    final status = await switch (action) {
      MemberAction.promote => MessengerApiService.setMemberRole(
        groupId,
        member.id,
        GroupRole.admin,
      ),
      MemberAction.demote => MessengerApiService.setMemberRole(
        groupId,
        member.id,
        GroupRole.member,
      ),
      MemberAction.kick => MessengerApiService.kickMember(groupId, member.id),
      MemberAction.transfer => MessengerApiService.transferGroup(
        groupId,
        member.id,
      ),
    };
    if (!mounted) return;

    // IMMER neu laden, auch bei Fehlern: Rollen kommen nicht per WebSocket,
    // ein 403/404 heisst fast immer "deine Ansicht war veraltet" (jemand
    // anderes hat inzwischen was geaendert). Nach dem Uebergeben aendert
    // sich auch _myRole (wir sind dann Admin) -> Buttons passen sich an.
    setState(_loadMembers);

    final ok = status >= 200 && status < 300;
    final text = ok
        ? switch (action) {
            MemberAction.promote => l10n.chatInfoPromoted(name),
            MemberAction.demote => l10n.chatInfoDemoted(name),
            MemberAction.kick => l10n.chatInfoKicked(name),
            MemberAction.transfer => l10n.chatInfoTransferred(name),
          }
        : (status == 403 || status == 404)
        ? l10n.chatInfoMemberActionOutdated
        : l10n.chatInfoMemberActionFailed;
    _showSnack(messenger, text, error: !ok);
  }

  Future<void> _showInviteCode() async {
    // Wie überall im Sheet: Messenger vor dem ersten await sichern.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final code = await MessengerApiService.createGroupJoinCode(
      widget.conversation.groupChatId,
    );
    if (!mounted) return;

    if (code == null) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          content: Text(
            l10n.chatInfoInviteCodeFailed,
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

    // Der Dialog gibt true zurück, wenn der User "Im Chat teilen" gewählt hat
    // (Kopieren erledigt der Dialog selbst und gibt nichts zurück).
    final share = await showDialog<bool>(
      context: context,
      builder: (_) => _InviteCodeDialog(code: code),
    );
    if (share != true || !mounted) return;

    // Gleicher Link-Trick wie beim Post-Teilen: der Code geht als
    // "ranked://group/<code>"-Textnachricht raus, der ChatScreen rendert
    // daraus eine Einladungs-Card mit Beitreten-Button.
    final db = widget.conversation.db;
    final controller = context.read<MessengerController>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ShareSheet(
        db: db,
        controller: controller,
        link: 'ranked://group/$code',
      ),
    );
  }

  // Der Gruender darf nicht einfach gehen (Server: 403), sonst haette die
  // Gruppe niemanden mehr, der sie verwaltet. Statt eines Fehler-Snacks
  // erklaeren wir, was zu tun ist.
  Future<void> _showCreatorLeaveHint() async {
    final l10n = context.l10n;
    // Liste ist meist schon geladen; await wartet sonst kurz auf den Server.
    final members = await _membersFuture;
    if (!mounted) return;
    final alone = members.length <= 1;

    // Allein: Uebergeben geht nicht -> der Hinweis bietet direkt Loeschen an.
    // Der Text sagt schon, dass es endgueltig ist, daher kein zweiter Dialog.
    final deleteNow = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: Icons.workspace_premium_rounded,
        title: l10n.chatInfoCreatorLeaveTitle,
        message: alone
            ? l10n.chatInfoCreatorLeaveAloneMessage
            : l10n.chatInfoCreatorLeaveMessage,
        confirmLabel: alone ? l10n.chatInfoDeleteGroup : l10n.chatInfoGotIt,
        showCancel: alone,
      ),
    );
    if (alone && deleteNow == true && mounted) {
      await _deleteGroup(askFirst: false);
    }
  }

  Future<void> _deleteGroup({bool askFirst = true}) async {
    // Wie überall im Sheet: Messenger/Navigator vor dem ersten await sichern.
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final l10n = context.l10n;

    if (askFirst) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => ConfirmDialog(
          icon: Icons.delete_forever_rounded,
          title: l10n.chatInfoDeleteTitle(_header.title),
          message: l10n.chatInfoDeleteMessage,
          confirmLabel: l10n.chatInfoDeleteConfirm,
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final groupId = widget.conversation.groupChatId;
    final status = await MessengerApiService.deleteGroup(groupId);
    if (!mounted) return;

    // 404 = Gruppe gibt's eh nicht mehr -> lokal genauso aufraeumen.
    if (status == 200 || status == 404) {
      await widget.conversation.db.removeGroupLocally(groupId);
      nav.pop(); // Sheet zu
      if (nav.canPop()) nav.pop(); // ChatScreen zu -> zurück zur Chatliste
      _showSnack(messenger, l10n.chatInfoGroupDeleted, error: false);
      return;
    }

    // 403 = wir sind nicht (mehr) Gruender, Ansicht veraltet -> neu laden,
    // damit der Loeschen-Button verschwindet.
    if (status == 403) setState(_loadMembers);
    _showSnack(
      messenger,
      status == 403
          ? l10n.chatInfoMemberActionOutdated
          : l10n.chatInfoMemberActionFailed,
    );
  }

  Future<void> _confirmLeave() async {
    // Gruender? Dann gar nicht erst fragen/anfragen, gleich den Hinweis.
    if (_myRole == GroupRole.creator) {
      await _showCreatorLeaveHint();
      return;
    }

    // Wie im DM-Sheet: Messenger/Navigator vor dem ersten await sichern.
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: Icons.logout_rounded,
        title: l10n.chatInfoLeaveTitle(_header.title),
        message: l10n.chatInfoLeaveMessage,
        confirmLabel: l10n.chatInfoLeave,
      ),
    );
    if (confirmed != true) return;

    final status = await MessengerApiService.leaveGroup(
      widget.conversation.groupChatId,
    );
    if (!mounted) return;

    // 403 = wir sind (inzwischen) Gruender, die Ansicht war veraltet —
    // z. B. hat uns jemand die Gruppe uebergeben, waehrend das Sheet offen
    // war. Rollen neu laden und denselben Hinweis zeigen.
    if (status == 403) {
      setState(_loadMembers);
      await _showCreatorLeaveHint();
      return;
    }

    final ok = status == 200;

    if (ok) {
      // Chat aus der lokalen Liste nehmen — sonst bleibt eine Leiche in der
      // Chatliste. Die Discovery (/group_chat/my) legt ihn nicht neu an,
      // weil wir dort nicht mehr Mitglied sind.
      final db = widget.conversation.db;
      await (db.delete(db.openChats)..where(
            (t) =>
                t.id.equals(widget.conversation.groupChatId) &
                t.isGroupChat.equals(true),
          ))
          .go();
      nav.pop(); // Sheet zu
      if (nav.canPop()) nav.pop(); // ChatScreen zu -> zurück zur Chatliste
    }
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.onSurface : AppColors.primary,
        content: Text(
          ok ? l10n.chatInfoLeftGroup : l10n.chatInfoLeaveFailed,
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
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              const SizedBox(height: 16),
              // Tap -> neues Gruppenbild (nur Gruender/Admins). Kamera-Badge
              // zeigt, dass es geht; waehrend des Uploads liegt ein Spinner
              // ueber dem Avatar.
              GestureDetector(
                onTap: _canManage ? _changeGroupPicture : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _BigAvatar(
                      name: _header.title,
                      avatarUrl: _header.avatarUrl,
                      isGroup: true,
                    ),
                    if (_uploadingPicture)
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(28),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (_canManage)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Tap auf den Namen -> umbenennen (nur Gruender/Admins), der
              // Stift zeigt, dass es geht — wie die Kamera am Avatar.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _canManage ? _renameGroup : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _header.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (_canManage) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const _EncryptedBadge(),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.chatInfoMembers,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(child: _buildMemberList()),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.person_add_rounded,
                label: context.l10n.chatInfoInvite,
                onTap: _showInviteCode,
              ),
              const SizedBox(height: 8),
              _ActionTile(
                icon: Icons.logout_rounded,
                label: context.l10n.chatInfoLeaveGroup,
                onTap: _confirmLeave,
              ),
              if (_myRole == GroupRole.creator) ...[
                const SizedBox(height: 8),
                _ActionTile(
                  icon: Icons.delete_forever_rounded,
                  label: context.l10n.chatInfoDeleteGroup,
                  onTap: _deleteGroup,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    return FutureBuilder<List<GroupMember>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        // Spinner nur beim ersten Laden. Beim Neuladen behaelt der
        // FutureBuilder die alten Daten im Snapshot — die Liste bleibt
        // stehen und springt erst um, wenn die neue Antwort da ist.
        if (snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
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

        // Gruender oben, dann Admins, dann alle anderen — jeweils alphabetisch.
        // role.index passt dafuer, weil das Enum genau so sortiert ist.
        final members = [...?snapshot.data]
          ..sort((a, b) {
            final byRole = a.role.index.compareTo(b.role.index);
            if (byRole != 0) return byRole;
            return a.username.toLowerCase().compareTo(b.username.toLowerCase());
          });
        if (members.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              context.l10n.chatInfoMembersLoadFailed,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (_, i) {
            final m = members[i];
            final isMe = m.id == widget.conversation.myUserId;
            return _MemberTile(
              username: m.username,
              avatarUrl: m.avatarUrl,
              role: m.role,
              isMe: isMe,
              // Aufs eigene Profil führt schon der Profil-Tab.
              onTap: isMe ? null : () => _onMemberTap(m),
            );
          },
        );
      },
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final GroupRole role;
  final bool isMe;
  final VoidCallback? onTap;

  const _MemberTile({
    required this.username,
    required this.avatarUrl,
    required this.role,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(
          children: [
            _CircleAvatar(name: username, avatarUrl: avatarUrl, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  // Flexible statt Expanded: der Name nimmt nur so viel Platz
                  // wie noetig, das Badge klebt direkt dahinter.
                  Flexible(
                    child: Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  if (role != GroupRole.member) ...[
                    const SizedBox(width: 6),
                    _RoleBadge(role: role),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isMe)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  context.l10n.chatInfoYou,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }
}

// Aktions-Sheet beim Tap auf ein Mitglied: Kopf mit Avatar + Name, darunter
// "Profil öffnen" und die erlaubten Aktionen. Gibt die gewählte Aktion per
// Navigator.pop zurück (null = weggewischt); das Ausführen macht der Aufrufer.
class _MemberActionsSheet extends StatelessWidget {
  final GroupMember member;
  final Set<MemberAction> actions;
  final VoidCallback onOpenProfile;

  const _MemberActionsSheet({
    required this.member,
    required this.actions,
    required this.onOpenProfile,
  });

  // Feste Reihenfolge, unabhaengig davon, wie das Set gebaut wurde.
  // Rauswerfen bewusst ganz unten — die "gefaehrlichste" Aktion.
  static const _order = [
    MemberAction.promote,
    MemberAction.demote,
    MemberAction.transfer,
    MemberAction.kick,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            const SizedBox(height: 16),
            Row(
              children: [
                _CircleAvatar(
                  name: member.username,
                  avatarUrl: member.avatarUrl,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    member.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                if (member.role != GroupRole.member) ...[
                  const SizedBox(width: 8),
                  _RoleBadge(role: member.role),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _ActionTile(
              icon: Icons.person_rounded,
              label: l10n.chatInfoOpenProfile,
              onTap: () {
                Navigator.pop(context); // nur dieses Sheet zu ...
                onOpenProfile(); // ... den Rest macht _openMemberProfile
              },
            ),
            for (final action in _order.where(actions.contains)) ...[
              const SizedBox(height: 8),
              _ActionTile(
                icon: switch (action) {
                  MemberAction.promote => Icons.add_moderator_rounded,
                  MemberAction.demote => Icons.remove_moderator_rounded,
                  MemberAction.transfer => Icons.workspace_premium_rounded,
                  MemberAction.kick => Icons.person_remove_rounded,
                },
                label: switch (action) {
                  MemberAction.promote => l10n.chatInfoMakeAdmin,
                  MemberAction.demote => l10n.chatInfoRemoveAdmin,
                  MemberAction.transfer => l10n.chatInfoTransfer,
                  MemberAction.kick => l10n.chatInfoKick,
                },
                onTap: () => Navigator.pop(context, action),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Kleines Rollen-Badge hinter dem Namen. Gruender in Gold (Brand-Moment),
// Admin bewusst neutral, damit nur der Gruender heraussticht.
class _RoleBadge extends StatelessWidget {
  final GroupRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isCreator = role == GroupRole.creator;
    final fg = isCreator ? AppColors.tertiary : AppColors.secondary;
    final bg = isCreator
        ? AppColors.tertiaryContainer.withValues(alpha: 0.35)
        : AppColors.secondaryFixed;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCreator ? Icons.workspace_premium_rounded : Icons.shield_rounded,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 3),
          Text(
            isCreator
                ? context.l10n.chatInfoRoleCreator
                : context.l10n.chatInfoRoleAdmin,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
//  Bausteine
// -----------------------------------------------------------------------------

/// Gibt den neuen Namen schon getrimmt per pop zurück, null = abgebrochen.
/// Stateful nur wegen des TextEditingControllers (muss disposed werden).
class _RenameDialog extends StatefulWidget {
  final String initialName;
  const _RenameDialog({required this.initialName});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  // Alter Name vorausgefüllt + komplett markiert: Tippen ersetzt ihn,
  // für kleine Korrekturen kann man trotzdem reintippen.
  late final _controller = TextEditingController(text: widget.initialName)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialName.length,
    );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Leerer Name -> Server antwortet 400, also gar nicht erst abschicken.
  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        l10n.chatInfoRenameTitle,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: MessengerApiService.groupNameMaxLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        style: GoogleFonts.inter(color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: l10n.chatInfoRenameHint,
          hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
          counterText: '',
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
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.messengerCancel,
            style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: _save,
          child: Text(
            l10n.chatInfoRenameSave,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _EncryptedBadge extends StatelessWidget {
  const _EncryptedBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_rounded,
          size: 11,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Text(
          context.l10n.chatEncrypted,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Großer Kreis-Avatar (Bild, sonst Initiale bzw. Gruppen-Icon).
class _BigAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isGroup;

  const _BigAvatar({
    required this.name,
    required this.avatarUrl,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return _CircleAvatar(
      name: name,
      avatarUrl: avatarUrl,
      size: 84,
      isGroup: isGroup,
    );
  }
}

/// Gemeinsame Basis für alle Kreis-Avatare im Sheet: zeigt das Bild, bei
/// fehlender URL (oder Ladefehler) die Initiale bzw. das Gruppen-Icon.
class _CircleAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;
  final bool isGroup;

  const _CircleAvatar({
    required this.name,
    required this.avatarUrl,
    required this.size,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return Container(
      width: size,
      height: size,
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
              image: netImage(context, url, logicalWidth: size),
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    if (isGroup) {
      return Icon(
        Icons.groups_rounded,
        size: size * 0.45,
        color: AppColors.primary,
      );
    }
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Text(
      initial,
      style: GoogleFonts.plusJakartaSans(
        fontSize: size * 0.38,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    );
  }
}

/// Eine Aktions-Zeile im Sheet (Profil öffnen, Blockieren, Verlassen …).
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap; // null = gesperrt
  final bool loading; // nur zentrierter Spinner, Inhalt unsichtbar

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          // Opacity 0 statt weglassen: die Row bestimmt weiter die Hoehe,
          // die Kachel springt also nicht, wenn das Label erscheint.
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: loading ? 0 : 1,
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
              if (loading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zeigt einen frisch erzeugten Einladungs-Code groß an. Tap auf den Code
/// (oder den Button) kopiert ihn in die Zwischenablage.
class _InviteCodeDialog extends StatelessWidget {
  final int code;
  const _InviteCodeDialog({required this.code});

  void _copy(BuildContext context) {
    // Messenger VOR dem pop holen — danach hängt der Dialog-Context in der Luft.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    Clipboard.setData(ClipboardData(text: '$code'));
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.onSurface,
        content: Text(
          l10n.chatInfoCodeCopied,
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
                Icons.person_add_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.messengerInviteCodeHint,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _copy(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$code',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.l10n.chatInfoInviteCodeNote,
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
              child: FilledButton.icon(
                // Nur den Dialog mit "teilen gewünscht" schließen — das
                // ShareSheet öffnet der Aufrufer (_showInviteCode), weil der
                // Dialog-Context dafür nach dem pop nicht mehr taugt.
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  context.l10n.chatInfoShareInChat,
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
              child: TextButton.icon(
                onPressed: () => _copy(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: Text(
                  context.l10n.chatInfoCopyCode,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
