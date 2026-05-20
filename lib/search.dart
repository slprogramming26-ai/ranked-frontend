import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/user_api_service.dart';
import 'app_colors.dart';
import 'profile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const _minQueryLength = 2;
  static const _debounceDuration = Duration(milliseconds: 300);

  final SearchController _searchController = SearchController();
  Timer? _debounce;

  final Map<String, List<Map<String, dynamic>>> _cache = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }



  void _openProfile(int userId) {
    _searchController.closeView(null);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Profile(targetUserId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              SearchAnchor(
                searchController: _searchController,
                isFullScreen: false,
                viewBackgroundColor: AppColors.surface,
                viewElevation: 2,
                viewHintText: 'Search users',
                viewLeading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => _searchController.closeView(null),
                ),
                builder: (context, controller) => _SearchBarStub(
                  onTap: controller.openView,
                ),
                // Hier passiert jetzt die Magie – kurz und knackig:
                suggestionsBuilder: (context, controller) {
                  return _handleSearch(controller.text.trim(), controller);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Iterable<Widget> _renderResults(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return const [_HintTile(icon: Icons.person_off_outlined, text: 'No users found')];
    }

    return results.map((user) {
      final id = user['id'] as int;
      return _UserResultTile(
        key: ValueKey(id),
        username: (user['username'] as String?) ?? '',
        avatarUrl: user['profile_picture_url'] as String?,
        vibe1: user['vibe_factor_1'] as String?,
        vibe2: user['vibe_factor_2'] as String?,
        onTap: () => _openProfile(id),
      );
    });
  }

  Future<Iterable<Widget>> _handleSearch(String text, SearchController controller) async {
    // 1. Zu kurz? Sofort Hinweis zurückgeben
    if (text.length < _minQueryLength) {
      return const [_HintTile(icon: Icons.search, text: 'Type at least 2 characters')];
    }

    // 2. Haben wir das schon mal gesucht? Cache nutzen!
    if (_cache.containsKey(text)) {
      return _renderResults(_cache[text]!);
    }

    // 3. Debounce: Warte kurz, ob der Nutzer weitertippt
    await Future.delayed(_debounceDuration);
    if (controller.text.trim() != text) return const [_LoadingTile()];

    // 4. API abfragen
    try {
      final results = await UserApiService.getUserByUsername(text);
      _cache[text] = results;

      // Falls der Nutzer während des API-Requests weitergetippt hat: Abbrechen!
      if (controller.text.trim() != text) return const [_LoadingTile()];

      return _renderResults(results);
    } catch (_) {
      return const [_HintTile(icon: Icons.error_outline, text: 'Something went wrong.')];
    }
  }

}

class _SearchBarStub extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchBarStub({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withOpacity(0.6),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.primary.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Text(
              'Search users',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
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
    final subtitle =
        [vibe1, vibe2].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHighest,
              ),
              child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(username),
                    )
                  : _avatarFallback(username),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@$username',
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
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) => Container(
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
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