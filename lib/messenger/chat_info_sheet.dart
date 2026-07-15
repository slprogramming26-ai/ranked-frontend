// =============================================================================
//  Chat-Info-Sheet (Mini-Profil im WhatsApp-Stil)
// =============================================================================
//  Öffnet sich beim Tap auf den Header im ChatScreen.
//   * DM:     großes Profil + "Profil öffnen" + "Blockieren"
//   * Gruppe: Mitgliederliste (EIN Request — der Server joint Username/Avatar
//             schon mit) + "Gruppe verlassen"
// =============================================================================

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../net_image.dart';
import '../profile.dart';
import '../user_api_service.dart';
import 'conversation.dart';
import 'messenger_api_service.dart';

/// Einstiegspunkt: entscheidet anhand des Conversation-Typs, welches Sheet
/// gezeigt wird. Wird vom ChatScreen-Header aufgerufen.
Future<void> showChatInfoSheet(BuildContext context, Conversation conversation) {
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

class _DmInfoSheet extends StatelessWidget {
  final DmConversation conversation;
  const _DmInfoSheet({required this.conversation});

  Future<void> _openProfile(BuildContext context) async {
    // Navigator VOR dem pop holen: das Sheet liegt auf dem Root-Navigator,
    // pop schließt also nur das Sheet, danach pushen wir aufs selbe Navigator.
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(
        builder: (_) => Profile(targetUserId: conversation.peerId),
      ),
    );
  }

  Future<void> _confirmBlock(BuildContext context) async {
    // Messenger/Navigator VOR dem ersten await sichern — nach einem async-Gap
    // darf context nicht mehr benutzt werden (Sheet könnte weggewischt sein).
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        icon: Icons.block_rounded,
        title: '${conversation.title} blockieren?',
        message: 'Ihr könnt einander keine Nachrichten mehr schreiben. '
            'Du kannst die Blockierung später wieder aufheben.',
        confirmLabel: 'Blockieren',
      ),
    );
    if (confirmed != true) return;

    final ok = await UserApiService.blockUser(conversation.peerId);

    if (ok && nav.canPop()) nav.pop(); // Sheet zu
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.onSurface : AppColors.primary,
        content: Text(
          ok
              ? '${conversation.title} wurde blockiert.'
              : 'Blockieren fehlgeschlagen. Versuch es erneut.',
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
              name: conversation.title,
              avatarUrl: conversation.avatarUrl,
            ),
            const SizedBox(height: 12),
            Text(
              conversation.title,
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
              label: 'Profil öffnen',
              onTap: () => _openProfile(context),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.block_rounded,
              label: 'Blockieren',
              onTap: () => _confirmBlock(context),
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
  // Future in initState festhalten (wie bei _PostPreviewCard): sonst würde
  // jeder Rebuild die Mitglieder neu vom Server laden.
  late final Future<List<({int id, String username, String? avatarUrl})>>
  _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = MessengerApiService.fetchGroupMembers(
      widget.conversation.groupChatId,
    );
  }

  void _openMemberProfile(int userId) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute(builder: (_) => Profile(targetUserId: userId)),
    );
  }

  Future<void> _confirmLeave() async {
    // Wie im DM-Sheet: Messenger/Navigator vor dem ersten await sichern.
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        icon: Icons.logout_rounded,
        title: '${widget.conversation.title} verlassen?',
        message: 'Du bekommst keine neuen Nachrichten mehr aus dieser Gruppe. '
            'Mit einer Einladung kannst du jederzeit wieder beitreten.',
        confirmLabel: 'Verlassen',
      ),
    );
    if (confirmed != true) return;

    final ok = await MessengerApiService.leaveGroup(
      widget.conversation.groupChatId,
    );

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
          ok
              ? 'Du hast die Gruppe verlassen.'
              : 'Verlassen fehlgeschlagen. Versuch es erneut.',
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
              _BigAvatar(
                name: widget.conversation.title,
                avatarUrl: widget.conversation.avatarUrl,
                isGroup: true,
              ),
              const SizedBox(height: 12),
              Text(
                widget.conversation.title,
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
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Mitglieder',
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
                icon: Icons.logout_rounded,
                label: 'Gruppe verlassen',
                onTap: _confirmLeave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    return FutureBuilder<List<({int id, String username, String? avatarUrl})>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
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

        final members = [...?snapshot.data]
          ..sort((a, b) =>
              a.username.toLowerCase().compareTo(b.username.toLowerCase()));
        if (members.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Mitglieder konnten nicht geladen werden.',
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
              isMe: isMe,
              // Aufs eigene Profil führt schon der Profil-Tab.
              onTap: isMe ? null : () => _openMemberProfile(m.id),
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
  final bool isMe;
  final VoidCallback? onTap;

  const _MemberTile({
    required this.username,
    required this.avatarUrl,
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
            if (isMe)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Du',
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

// -----------------------------------------------------------------------------
//  Bausteine
// -----------------------------------------------------------------------------

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
          'Ende-zu-Ende verschlüsselt',
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
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
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
      ),
    );
  }
}

/// Bestätigungs-Dialog für folgenreiche Aktionen (Blockieren, Gruppe
/// verlassen). Gibt true/false über Navigator.pop zurück.
class _ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmLabel;

  const _ConfirmDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

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
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Abbrechen',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
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