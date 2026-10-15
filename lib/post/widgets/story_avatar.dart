import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';
import '../../net_image.dart';
import '../../l10n/l10n.dart';

/// Ein Story-Ring im Feed. Zeigt das Profilbild des Owners, einen Gradient-Ring
/// (signalisiert: hat aktive Stories) und den Usernamen. [stories] sind alle
/// (noch gültigen) Stories dieses einen Users.
class ShowStoryAvatar extends StatelessWidget {
  final List<Map<String, dynamic>> stories;
  final VoidCallback onTap;

  const ShowStoryAvatar({
    super.key,
    required this.stories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final owner = stories.first['owner'] as Map<String, dynamic>?;
    final username = owner?['username']?.toString() ?? 'User';
    final picUrl = owner?['profile_picture_url']?.toString();

    return _StoryTile(
      label: username,
      onTap: onTap,
      avatar: _AvatarSquare(picUrl: picUrl, username: username, ring: true),
    );
  }
}

/// Die eigene Kachel ganz vorne in der Story-Reihe: dein Avatar + kleines
/// Plus an der Ecke (wie Insta/WhatsApp — ein Gesicht laedt mehr ein als
/// eine leere Plus-Kachel). Hast du aktive Stories, bekommt der Avatar den
/// Ring und spielt sie ab; das Plus fuehrt immer zum Erstellen.
class MyStoryAvatar extends StatelessWidget {
  final String? picUrl;
  final String username;
  final bool hasStories;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  const MyStoryAvatar({
    super.key,
    required this.picUrl,
    required this.username,
    required this.hasStories,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return _StoryTile(
      label: context.l10n.storyRowYourPulse,
      // Ohne Stories gibt es nichts abzuspielen -> ganze Kachel = Erstellen.
      onTap: hasStories ? onOpen : onAdd,
      avatar: Stack(
        clipBehavior: Clip.none,
        children: [
          _AvatarSquare(picUrl: picUrl, username: username, ring: hasStories),
          Positioned(
            right: -4,
            bottom: -4,
            // Eigener Tap-Bereich: bei aktiven Stories soll das Plus trotzdem
            // erstellen statt abspielen. Padding vergroessert die Trefferflaeche.
            child: GestureDetector(
              onTap: onAdd,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    // Eckig-rund wie die Ringe und das "+" in der Nav-Bar.
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Gemeinsamer Rahmen fuer alle Kacheln der Reihe (Breite, Abstand, Label),
// damit die eigene Kachel exakt auf Linie mit den anderen sitzt.
class _StoryTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Widget avatar;

  const _StoryTile({
    required this.label,
    required this.onTap,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: avatar,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 64er Avatar-Quadrat. ring = Gradient-Rahmen ("hat aktive Stories");
// ohne Ring bleibt der Platz gleich gross, damit alles auf einer Linie liegt.
class _AvatarSquare extends StatelessWidget {
  final String? picUrl;
  final String username;
  final bool ring;

  const _AvatarSquare({
    required this.picUrl,
    required this.username,
    required this.ring,
  });

  @override
  Widget build(BuildContext context) {
    final url = picUrl;
    final hasPic = url != null && url.isNotEmpty && url != 'null';

    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        gradient: ring
            ? LinearGradient(
                colors: [AppColors.primary, AppColors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: hasPic
              ? Image(
                  // 64er-Ring minus Padding — 64 logische px
                  // reichen als Dekodier-Breite locker.
                  image: netImage(context, url, logicalWidth: 64),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, _, _) => _fallback(),
                  // Weich einblenden statt aufpoppen; aus dem
                  // Cache (wasSync) sofort zeigen.
                  frameBuilder: (_, child, frame, wasSync) => wasSync
                      ? child
                      : AnimatedOpacity(
                          opacity: frame != null ? 1 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: child,
                        ),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    final letter = username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Container(
      color: AppColors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Platzhalter-Ring während Stories noch laden.
class StoryAvatarSkeleton extends StatelessWidget {
  const StoryAvatarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 36,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
