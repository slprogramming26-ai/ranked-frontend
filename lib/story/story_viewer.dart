import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import 'story.dart';

/// Vollbild-Story-Viewer im Instagram-Stil.
///
/// [owners] ist die nach User gruppierte Story-Liste (eine innere Liste pro
/// User), [initialOwner] der Index, bei dem gestartet wird. Navigation:
/// - Tap rechts -> nächste Story / nächster User
/// - Tap links -> vorherige Story / vorheriger User
/// - Halten -> pausieren
/// Eigene Stories können über das Menü gelöscht werden.
class StoryViewer extends StatefulWidget {
  final List<List<Map<String, dynamic>>> owners;
  final int initialOwner;

  const StoryViewer({
    super.key,
    required this.owners,
    required this.initialOwner,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 5);

  late int _ownerIndex;
  int _storyIndex = 0;
  late final AnimationController _progress;
  bool _started = false;

  List<Map<String, dynamic>> get _currentStories => widget.owners[_ownerIndex];
  Map<String, dynamic> get _currentStory => _currentStories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _ownerIndex = widget.initialOwner;
    _progress = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // precacheImage braucht MediaQuery -> erst hier (nach initState) starten.
    if (!_started) {
      _started = true;
      _loadCurrent();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  // Bild der aktuellen Story vorladen, Fortschritt erst danach starten,
  // damit die Zeit nicht läuft, während noch ein graues Bild zu sehen ist.
  void _loadCurrent() {
    _progress.stop();
    _progress.reset();
    final url = _currentStory['image_url']?.toString();
    if (url == null || url.isEmpty) {
      _progress.forward();
      return;
    }
    precacheImage(NetworkImage(url), context).whenComplete(() {
      if (mounted) _progress.forward();
    });
  }

  void _next() {
    if (_storyIndex < _currentStories.length - 1) {
      setState(() => _storyIndex++);
      _loadCurrent();
    } else if (_ownerIndex < widget.owners.length - 1) {
      setState(() {
        _ownerIndex++;
        _storyIndex = 0;
      });
      _loadCurrent();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previous() {
    if (_storyIndex > 0) {
      setState(() => _storyIndex--);
      _loadCurrent();
    } else if (_ownerIndex > 0) {
      setState(() {
        _ownerIndex--;
        _storyIndex = 0;
      });
      _loadCurrent();
    } else {
      // Schon ganz am Anfang: aktuelle Story einfach neu starten.
      _loadCurrent();
    }
  }

  Future<void> _deleteCurrent() async {
    _progress.stop();
    final storyId = _currentStory['id'] as int;
    final ok = await StoryApiService.deleteStory(storyId);
    if (!mounted) return;
    if (ok) {
      context.read<StoryProvider>().removeStory(storyId);
      Navigator.of(context).pop();
    } else {
      _progress.forward();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story konnte nicht gelöscht werden')),
      );
    }
  }

  String _timeAgo(String? createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return 'vor ${diff.inDays} T.';
  }

  @override
  Widget build(BuildContext context) {
    final owner = _currentStory['owner'] as Map<String, dynamic>?;
    final username = owner?['username']?.toString() ?? 'User';
    final picUrl = owner?['profile_picture_url']?.toString();
    final hasPic = picUrl != null && picUrl.isNotEmpty && picUrl != 'null';
    final isMine = _currentStory['is_mine'] == true;
    final imageUrl = _currentStory['image_url']?.toString();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final dx = details.globalPosition.dx;
          final third = MediaQuery.of(context).size.width / 3;
          if (dx < third) {
            _previous();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) => _progress.forward(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Story-Bild
            if (imageUrl != null && imageUrl.isNotEmpty)
              Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    );
                  },
                ),
              ),

            // Verlauf oben für Lesbarkeit der Leisten/Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Fortschritts-Leisten + Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildProgressBars(),
                    const SizedBox(height: 12),
                    _buildHeader(username, hasPic, picUrl, isMine),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBars() {
    return Row(
      children: List.generate(_currentStories.length, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 3,
                child: i < _storyIndex
                    // Bereits gesehen -> voll.
                    ? const ColoredBox(color: Colors.white)
                    : i > _storyIndex
                        // Noch nicht dran -> leer.
                        ? ColoredBox(color: Colors.white.withValues(alpha: 0.3))
                        // Aktuell -> animiert.
                        : AnimatedBuilder(
                            animation: _progress,
                            builder: (_, _) => LinearProgressIndicator(
                              value: _progress.value,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation(
                                Colors.white,
                              ),
                            ),
                          ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(
    String username,
    bool hasPic,
    String? picUrl,
    bool isMine,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surfaceContainerHighest,
          backgroundImage: hasPic ? NetworkImage(picUrl!) : null,
          child: hasPic
              ? null
              : Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  isMine ? 'Deine Story' : username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timeAgo(_currentStory['created_at']?.toString()),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (isMine)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _confirmDelete,
          ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  void _confirmDelete() {
    _progress.stop();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1413),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(
                'Story löschen',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteCurrent();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.white70),
              title: Text(
                'Abbrechen',
                style: GoogleFonts.plusJakartaSans(color: Colors.white70),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _progress.forward();
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Falls per Wisch geschlossen: Fortschritt wieder anwerfen.
      if (mounted && !_progress.isAnimating && _progress.value < 1.0) {
        _progress.forward();
      }
    });
  }
}