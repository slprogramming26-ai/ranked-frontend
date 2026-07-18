import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../app_colors.dart';
import '../../local_data/database.dart';
import '../../net_image.dart';
import '../../messenger/messenger_controller.dart';
import '../../user_api_service.dart';
import '../post_provider.dart';
import '../comment_provider.dart';
import '../post_api_service.dart';
import 'comment.dart';
import 'feed_image.dart';
import 'share_sheet.dart';

class TextPost extends StatefulWidget {
  TextPost({
    super.key,
    required this.title,
    required this.content,
    required this.owner_username,
    required this.created_at,
    required this.likes,
    required this.post_id,
    this.imageUrl,
    this.profilePictureUrl,
    this.flag,
    this.locationName,
    required this.timeDifference,
    this.isMine = false,
    this.isLiked = false,
  });

  final String title;
  final String content;
  final String owner_username;
  final DateTime created_at;
  final int likes;
  final int post_id;
  final String? imageUrl;
  final String? profilePictureUrl;
  final String timeDifference;
  final String? flag;
  // Ort des Posts (beim Erstellen eingefroren); null bei Posts ohne Ort.
  final String? locationName;
  final bool isMine;
  final bool isLiked;

  @override
  State<TextPost> createState() => _TextPostState();
}

class _TextPostState extends State<TextPost>
    with SingleTickerProviderStateMixin {
  // Der Controller muss hier bleiben, damit deine Logik funktioniert
  late TextEditingController commentController;

  // Steuert die "Burst"-Animation beim Doppeltipp auf den Post.
  late AnimationController _burstController;

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }


  @override
  void dispose() {
    commentController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  // Liken mit optimistischem Update: Erst lokal anzeigen, dann ans Backend.
  // Schlägt der Request fehl, machen wir das Update rückgängig.
  Future<void> _like() async {
    final provider = Provider.of<PostProvider>(context, listen: false);
    provider.setLike(widget.post_id, true);
    final success = await PostApiService.createVote(widget.post_id, 1);
    if (!success) provider.setLike(widget.post_id, false);
  }

  Future<void> _unlike() async {
    final provider = Provider.of<PostProvider>(context, listen: false);
    provider.setLike(widget.post_id, false);
    final success = await PostApiService.createVote(widget.post_id, 0);
    if (!success) provider.setLike(widget.post_id, true);
  }

  // Einfacher Tap auf den Button: je nach Status liken oder entliken.
  void _toggleLike() {
    if (widget.isLiked) {
      _unlike();
    } else {
      _like();
    }
  }

  // Doppeltipp auf den Post: Animation immer abspielen (wie bei Instagram),
  // aber nur liken, wenn noch nicht geliked.
  void _handleDoubleTapLike() {
    _burstController.forward(from: 0);
    if (!widget.isLiked) _like();
  }


  Future<void> _fetchData(BuildContext context) async {
    final provider = Provider.of<CommentProvider>(context, listen: false);
    provider.setLoading(true);
    final comments = await PostApiService.getComments(widget.post_id);
    provider.setComments(comments);
  }

  void showCommentSection(BuildContext context) async {
    _fetchData(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: AppColors.surface, // Nutzt die neue Background-Farbe
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Comments",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),

              // Kommentar-Liste
              Expanded(
                child: Consumer<CommentProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    if (provider.comments.isEmpty) {
                      return Center(
                        child: Text(
                          "Be the first to pulse!",
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 20),
                      children: provider.comments.map((commentData) {
                        return Comment(
                          commentId: commentData['id'],
                          comment: commentData['comment'],
                          username: commentData['username'] ?? "Anonymous",
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              // Eingabebereich
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Write a comment...",
                          hintStyle: TextStyle(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryContainer],
                        ),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          if (commentController.text.trim().isEmpty) return;
                          final success = await PostApiService.postComment(
                            widget.post_id,
                            commentController.text,
                          );
                          if (success) {
                            commentController.clear();
                            _fetchData(context);
                          }
                        },
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hier kommt das restliche UI aus meiner vorherigen Antwort rein (Container, Card, Hype Button etc.)
    // WICHTIG: Beim Kommentar-Button einfach showCommentSection(context) aufrufen!
    return _buildPostCard(context); // Wrapper für das Design von eben
  }

  // Das ist der visuelle Teil von eben, nur sauber verpackt:
  Widget _buildPostCard(BuildContext context) {
    return GestureDetector(
      // Doppeltipp irgendwo auf der Karte liked den Post.
      onDoubleTap: _handleDoubleTapLike,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.02),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // Stack, damit die Burst-Animation über dem Inhalt zentriert liegt.
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildBody(),
                _buildFooter(context),
              ],
            ),
            _buildLikeBurst(),
          ],
        ),
      ),
    );
  }

  // Der aufblitzende Blitz beim Doppeltipp. IgnorePointer, damit er keine
  // Taps abfängt; spielt nur, während der Controller läuft.
  Widget _buildLikeBurst() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _burstController,
        builder: (context, child) {
          final double v = _burstController.value;
          if (v == 0) return const SizedBox.shrink();
          // Zuerst schnell rein-faden, dann langsam raus.
          final double opacity = v < 0.3 ? v / 0.3 : (1 - (v - 0.3) / 0.7);
          final double scale = 0.5 + v * 0.9;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Icon(
          Icons.bolt,
          size: 110,
          color: Colors.white.withValues(alpha: 0.9),
          shadows: [
            Shadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: widget.profilePictureUrl != null
                  ? Image(
                      // 44er-Avatar → 44 logische px Dekodier-Breite.
                      image: netImage(
                        context,
                        widget.profilePictureUrl.toString(),
                        logicalWidth: 44,
                      ),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _avatarFallback(widget.owner_username),
                      // Weich einblenden statt aufpoppen; aus dem Cache
                      // (wasSync) sofort zeigen, sonst blendet jedes
                      // Zurueckscrollen erneut.
                      frameBuilder: (_, child, frame, wasSync) => wasSync
                          ? child
                          : AnimatedOpacity(
                              opacity: frame != null ? 1 : 0,
                              duration: const Duration(milliseconds: 250),
                              child: child,
                            ),
                    )
                  : _avatarFallback(widget.owner_username),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceContainerLow, width: 2),
              ),
              child: const Text(
                "#1",
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              widget.owner_username,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
          if (widget.isMine) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Du",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      // Nur vorhandene Teile mit • verbinden — kein haengender Punkt mehr,
      // und der Ort reiht sich dezent ein statt als eigenes Element.
      subtitle: Text(
        [
          widget.timeDifference,
          if (widget.flag != null && widget.flag!.isNotEmpty) widget.flag!,
          if (widget.locationName != null) '📍 ${widget.locationName}',
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_horiz),
        onPressed: () {
          showMiniMenu(context, widget.post_id.toString());
        },
      ),
    );
  }

  void showMiniMenu(BuildContext context, String post_id) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.1), // Sanfterer Backdrop
      builder: (_) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0), // 2xl Style
            ),
            backgroundColor: Colors.white,
            elevation: 10,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // Dialog passt sich dem Inhalt an
                children: [
                  if (widget.isMine) ...[
                    // Eigener Post: Edit + Delete.
                    _buildRankedButton(
                      icon: Icons.edit_outlined,
                      text: 'Edit Post',
                      color: AppColors.onSurface,
                      onTap: () {
                        // Deine Edit-Logik
                        Navigator.pop(context);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Divider(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        thickness: 1,
                      ),
                    ),
                    _buildRankedButton(
                      icon: Icons.delete_outline_rounded,
                      text: 'Delete Post',
                      color: AppColors.primary,
                      isBold: true,
                      onTap: () async {
                        final success = await PostApiService.deletePost(widget.post_id);
                        Navigator.pop(context);
                      },
                    ),
                  ] else ...[
                    // Fremder Post: melden statt loeschen.
                    _buildRankedButton(
                      icon: Icons.flag_outlined,
                      text: 'Report Post',
                      color: AppColors.primary,
                      isBold: true,
                      onTap: () {
                        Navigator.pop(context); // Mini-Menue schliessen
                        showReportSheet(context); // Grund-Sheet oeffnen
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankedButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
    bool isBold = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: AppColors.surfaceContainerLow,
        splashColor: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              SizedBox(width: 14),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  fontFamily: 'Plus Jakarta Sans', // Falls im Projekt vorhanden
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Grund-Sheet: zeigt die festen Melde-Gruende. Tap auf einen Grund
  // schliesst das Sheet und schickt den Report ab.
  void showReportSheet(BuildContext context) {
    const reasons = [
      'Spam',
      'Belästigung oder Mobbing',
      'Unangemessener Inhalt',
      'Falschinformation',
      'Sonstiges',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle-Bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Post melden",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              ...reasons.map(
                (reason) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext); // Sheet zu
                      _sendReport(reason);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Etwas Luft nach unten (Gestenleiste / Safe Area).
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }

  // Schickt den Report ans Backend und gibt Feedback per Snackbar.
  Future<void> _sendReport(String reason) async {
    // Messenger vor dem await greifen — danach koennte der context weg sein.
    final messenger = ScaffoldMessenger.of(context);
    final status = await UserApiService.report(widget.post_id, "post", reason);

    final String message;
    if (status == 201) {
      message = "Danke! Wir schauen uns das an.";
    } else if (status == 409) {
      message = "Du hast diesen Post bereits gemeldet.";
    } else {
      message = "Melden fehlgeschlagen. Versuch es später erneut.";
    }

    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _avatarFallback(String name) => Container(
    color: AppColors.surfaceContainerHighest,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    ),
  );

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            widget.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (widget.imageUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: FeedImage(url: widget.imageUrl!),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            widget.content,
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _buildHypeButton(context),
          const SizedBox(width: 15),
          IconButton(
            onPressed: () => showCommentSection(context),
            icon: Icon(
              Icons.chat_bubble_outline,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showShareSheet(context),
            icon: Icon(
              Icons.share_outlined,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Instagram-Style Share-Sheet: laedt die bestehenden Chats/Kontakte aus der
  // lokalen DB (getAllContacts) und zeigt sie zum Weiterleiten des Posts an.
  // Der Post wird als In-App-Link "ranked://post/<id>" verschickt. Optik und
  // Bestaetigung uebernimmt ShareSheet (Avatar-Grid + Bounce-Overlay).
  void _showShareSheet(BuildContext context) {
    final db = context.read<AppDatabase>();
    final controller = context.read<MessengerController>();
    final postLink = 'ranked://post/${widget.post_id}';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => ShareSheet(
        db: db,
        controller: controller,
        link: postLink,
      ),
    );
  }

  Widget _buildHypeButton(BuildContext context) {
    final bool liked = widget.isLiked;
    return GestureDetector(
      // Ein Tap toggelt: geliked -> entliken, sonst liken.
      onTap: _toggleLike,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // Geliked = voller Gradient, sonst dezenter Outline-Look.
          gradient: liked
              ? LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                )
              : null,
          color: liked
              ? null
              : AppColors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(30),
          border: liked
              ? null
              : Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: liked
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.bolt,
              color: liked ? Colors.white : AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              widget.likes.toString(),
              style: TextStyle(
                color: liked ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}