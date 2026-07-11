import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_colors.dart';

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
    final isMine = stories.first['is_mine'] == true;
    final hasPic = picUrl != null && picUrl.isNotEmpty && picUrl != 'null';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                        ? Image.network(
                            picUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => _fallback(username),
                          )
                        : _fallback(username),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMine ? 'Du' : username,
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

  Widget _fallback(String username) {
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