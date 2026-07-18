


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';
import '../../local_data/database.dart';
import '../../messenger/messenger_controller.dart';
import '../../net_image.dart';
// Noetig fuer die Extension-Methoden auf dem Service (sendDirectMessage,
// sendGroupMessage, isConnected, reconnect) — die leben in Part-Dateien
// dieser Library und sind sonst nicht im Scope.
import 'package:ranked/messenger/messenger_api_service.dart';

/// Share-Sheet: Kontakte als Avatar-Grid, dazu eine Link-Kopieren-Action.
/// Nach dem Senden zeigt ein bounce-animiertes Overlay im Sheet die
/// Bestaetigung (statt einer Mini-SnackBar) und schliesst sich danach von
/// selbst. Verschickt einen beliebigen In-App-Link (`ranked://post/1`,
/// `ranked://group/1234`, …) als normale Textnachricht.
class ShareSheet extends StatefulWidget {
  final AppDatabase db;
  final MessengerController controller;
  final String link;

  const ShareSheet({
    required this.db,
    required this.controller,
    required this.link,
  });

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confirmController;
  String? _sentToUsername;
  bool _linkCopied = false;

  @override
  void initState() {
    super.initState();
    _confirmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    HapticFeedback.selectionClick();
    setState(() => _linkCopied = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _linkCopied = false);
  }

  Future<void> _sendTo(OpenChat contact) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = widget.controller.service;
    if (service == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Messenger nicht bereit — bitte kurz warten und erneut '
            'versuchen.',
          ),
        ),
      );
      return;
    }
    // Verbindung kann still tot sein (Standby, Netzwechsel) — dann ginge
    // die Nachricht kommentarlos verloren (sink.add auf null). Deshalb
    // vorher sicherstellen.
    if (!service.isConnected) {
      await service.reconnect();
    }
    if (!mounted) return;
    // getAllContacts liefert DMs UND Gruppen — Gruppen brauchen den
    // Sender-Keys-Pfad.
    if (contact.isGroupChat) {
      service.sendGroupMessage(contact.id, widget.link);
    } else {
      service.sendDirectMessage(contact.id, widget.link);
    }
    HapticFeedback.mediumImpact();
    setState(() => _sentToUsername = contact.username);
    _confirmController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1300));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Teilen',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _buildCopyLinkAction(),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
                // Avatar Grid (Kontakte)
                Expanded(
                  child: FutureBuilder<List<OpenChat>>(
                    future: widget.db.getAllContacts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState !=
                          ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final contacts = snapshot.data ?? [];
                      if (contacts.isEmpty) {
                        return Center(
                          child: Text(
                            'Noch keine Chats zum Teilen.',
                            style: TextStyle(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      return GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) =>
                            _buildContactTile(contacts[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
            _buildConfirmOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildCopyLinkAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _copyLink,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _linkCopied
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _linkCopied
                      ? Icons.check_rounded
                      : Icons.link_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _linkCopied ? 'Link kopiert' : 'Link kopieren',
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(OpenChat contact) {
    final hasPic = contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _sendTo(contact),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ClipOval(
              child: hasPic
                  ? Image(
                      // Container ist 62x62 -> 62 logische px reichen.
                      image: netImage(
                        context,
                        contact.avatarUrl!,
                        logicalWidth: 62,
                      ),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          _contactFallback(contact.username),
                    )
                  : _contactFallback(contact.username),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@${contact.username}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactFallback(String username) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // Bestaetigungs-Overlay nach dem Senden: blitzt gross auf statt einer
  // Mini-SnackBar — Bounce-Scale + Fade, passend zum Like-Burst-Feeling.
  Widget _buildConfirmOverlay() {
    final username = _sentToUsername;
    if (username == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: AppColors.surface.withValues(alpha: 0.96),
          child: Center(
            child: AnimatedBuilder(
              animation: _confirmController,
              builder: (context, child) {
                final value = _confirmController.value;
                final bounce = Curves.elasticOut.transform(
                  value.clamp(0.0, 1.0),
                );
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + bounce * 0.4,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primaryContainer,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'An $username gesendet!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}