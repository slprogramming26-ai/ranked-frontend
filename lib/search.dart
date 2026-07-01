import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ranked/user_api_service.dart';
import 'app_colors.dart';
import 'profile.dart';
import 'local_data/database.dart';
import 'package:provider/provider.dart';

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

  Future<void> _confirmClearHistory(BuildContext context) async {
    final db = context.read<AppDatabase>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear search history?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'This will remove all recent searches from this device.',
          style: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Clear',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await db.clearSearchHistory();
    }
  }

  void _openProfile(
    int userId,
    String username, {
    String? avatarUrl,
    String? vibe1,
    String? vibe2,
  }) {
    final db = Provider.of<AppDatabase>(context, listen: false);

    unawaited(
      db.saveUserSearchHistory(
        userId,
        username,
        avatarUrl: avatarUrl,
        vibe1: vibe1,
        vibe2: vibe2,
      ),
    );
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
                  icon: Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => _searchController.closeView(null),
                ),
                builder: (context, controller) =>
                    _SearchBarStub(onTap: controller.openView),
                // Hier passiert jetzt die Magie – kurz und knackig:
                suggestionsBuilder: (context, controller) {
                  return _handleSearch(controller.text.trim(), controller);
                },
              ),
              const SizedBox(height: 28),
              Expanded(
                child: StreamBuilder<List<UserSearchHistoryData>>(
                  stream: context.read<AppDatabase>().watchRecentSearches(
                    limit: 10,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const _HistoryLoading();
                    }
                    final history = snapshot.data!;

                    if (history.isEmpty) {
                      return const _HistoryEmpty();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HistoryHeader(
                          count: history.length,
                          onClear: () => _confirmClearHistory(context),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            physics: const BouncingScrollPhysics(),
                            itemCount: history.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final entry = history[index];
                              return _HistoryTile(
                                key: ValueKey(entry.id),
                                username: entry.username,
                                avatarUrl: entry.avatarUrl,
                                vibe1: entry.vibe1,
                                vibe2: entry.vibe2,
                                clickedAt: entry.clickedAt,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Profile(
                                        targetUserId: entry.userId,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Iterable<Widget> _renderResults(List<Map<String, dynamic>> results) {
    if (results.isEmpty) {
      return const [
        _HintTile(icon: Icons.person_off_outlined, text: 'No users found'),
      ];
    }

    return results.map((user) {
      final id = user['id'] as int;
      return _UserResultTile(
        key: ValueKey(id),
        username: (user['username'] as String?) ?? '',
        avatarUrl: user['profile_picture_url'] as String?,
        vibe1: user['vibe_factor_1'] as String?,
        vibe2: user['vibe_factor_2'] as String?,
        onTap: () => _openProfile(
          id,
          (user['username'] as String?) ?? '',
          avatarUrl: user['profile_picture_url'] as String?,
          vibe1: user['vibe_factor_1'] as String?,
          vibe2: user['vibe_factor_2'] as String?,
        ),
      );
    });
  }

  Future<Iterable<Widget>> _handleSearch(
    String text,
    SearchController controller,
  ) async {
    // 1. Zu kurz? Sofort Hinweis zurückgeben
    if (text.length < _minQueryLength) {
      return const [
        _HintTile(icon: Icons.search, text: 'Type at least 2 characters'),
      ];
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
      return const [
        _HintTile(icon: Icons.error_outline, text: 'Something went wrong.'),
      ];
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
            Icon(Icons.search, color: AppColors.primary, size: 22),
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
    final subtitle = [
      vibe1,
      vibe2,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
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
              decoration: BoxDecoration(
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
            Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
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
    return Padding(
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

class _HistoryHeader extends StatelessWidget {
  final int count;
  final VoidCallback onClear;
  const _HistoryHeader({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Recent',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onClear,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: Text(
            'Clear',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String? vibe1;
  final String? vibe2;
  final DateTime clickedAt;
  final VoidCallback onTap;

  const _HistoryTile({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.vibe1,
    required this.vibe2,
    required this.clickedAt,
    required this.onTap,
  });

  String _formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [vibe1, vibe2]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');

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
                    ? Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _avatarFallback(),
                      )
                    : _avatarFallback(),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 12,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatRelative(clickedAt),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
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
                  Icons.arrow_outward_rounded,
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

  Widget _avatarFallback() => Container(
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

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.travel_explore_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No recent searches',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start exploring – your last searches\nwill show up here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 40, bottom: 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, __) => Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
