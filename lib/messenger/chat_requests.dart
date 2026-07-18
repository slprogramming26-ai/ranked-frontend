// =============================================================================
//  Chat-Anfragen (Instagram-Stil)
// =============================================================================
//  Liste aller pending-Chats — also Chats, die ein Fremder per Erstnachricht
//  eroeffnet hat. Haengt am selben Drift-Stream wie die Chatliste: nimmt man
//  eine Anfrage an (oder lehnt ab), verschwindet sie hier live von selbst.
//  Anfragen entstehen nur ueber DMs (Gruppen betritt man aktiv per Code),
//  deshalb baut der Tap immer eine DmConversation.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_colors.dart';
import '../local_data/database.dart';
import '../net_image.dart';
import 'chat_screen.dart';
import 'conversation.dart';
import 'messenger_controller.dart';

class ChatRequestsPage extends StatelessWidget {
  const ChatRequestsPage({super.key});

  void _openRequest(BuildContext context, OpenChat c) {
    final controller = context.read<MessengerController>();
    final db = context.read<AppDatabase>();
    final service = controller.service;
    final myUserId = controller.userId;
    // Wie in der Chatliste: noch nicht initialisiert -> Tap ignorieren.
    if (service == null || myUserId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: DmConversation(
            peerId: c.id,
            myUserId: myUserId,
            db: db,
            service: service,
            displayName: c.username,
            avatarUrl: c.avatarUrl,
          ),
          isRequest: true,
        ),
      ),
    );
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Anfragen',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
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
            final requests = snapshot.data!
                .where((c) => c.isPending && !c.isGroupChat)
                .toList();
            if (requests.isEmpty) return const _EmptyRequests();
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              physics: const BouncingScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = requests[index];
                return _RequestTile(
                  key: ValueKey(c.id),
                  contact: c,
                  onTap: () => _openRequest(context, c),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final OpenChat contact;
  final VoidCallback onTap;

  const _RequestTile({super.key, required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = contact.username;
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
                        image: netImage(
                          context,
                          contact.avatarUrl!,
                          logicalWidth: 48,
                        ),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallback(name),
                      )
                    : _fallback(name),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@$name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Möchte dir schreiben',
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

  Widget _fallback(String name) => Container(
    color: AppColors.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    ),
  );
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

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
              Icons.mark_email_read_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Alles erledigt',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keine offenen Chat-Anfragen.',
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
