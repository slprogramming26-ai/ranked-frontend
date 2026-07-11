import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ranked/user_api_service.dart';
import 'app_colors.dart';
import 'ranking/ranking_api_service.dart';
import 'settings_screen.dart';


class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic> _userdata = {};
  // Echte Ranking-Events (GET /ranking/activity), neueste zuerst.
  List<Map<String, dynamic>> _activity = [];
  bool _isLoading = false;
  bool _hasFetched = false; // verhindert doppeltes Laden

  Map<String, dynamic> get userdata  => _userdata;
  List<Map<String, dynamic>> get activity => _activity;
  bool get isLoading  => _isLoading;
  bool get hasFetched => _hasFetched;

  Future<void> fetchUser() async {
    if (_hasFetched) return; // schon geladen? nichts tun
    _isLoading = true;
    notifyListeners();

    // Beide Requests gleichzeitig abschicken statt nacheinander —
    // Future.wait ist fertig, sobald BEIDE Antworten da sind.
    final results = await Future.wait([
      UserApiService.getCurrentUser(),
      RankingApiService.getActivity(),
    ]);
    _userdata   = results[0] as Map<String, dynamic>;
    _activity   = (results[1] as List).cast<Map<String, dynamic>>();
    _isLoading  = false;
    _hasFetched = true;
    notifyListeners();
  }
}


class Profile extends StatefulWidget {
  final int? targetUserId; // null = eigenes Profil
  const Profile({super.key, this.targetUserId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  static const Map<String, IconData> _vibeIcons = {
    'Gaming':       Icons.sports_esports,
    'Fitness':      Icons.fitness_center,
    'Productivity': Icons.bolt,
    'Coding':       Icons.computer,
    'Sports':       Icons.sports_soccer,
    'Creativity':   Icons.palette,
    'Reading':      Icons.book,
    'Music':        Icons.music_note,
  };

  // Zustand für fremdes Profil
  Map<String, dynamic> _foreignData = {};
  bool _foreignLoading = false;
  bool _isFollowing = false;
  bool _followLoading = false;

  bool get _isOwn => widget.targetUserId == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isOwn) {
        Provider.of<ProfileProvider>(context, listen: false).fetchUser();
      } else {
        _fetchForeignUser();
      }
    });
  }

  Future<void> _fetchForeignUser() async {
    setState(() => _foreignLoading = true);
    final data = await UserApiService.getUser(widget.targetUserId!);
    if (mounted) {
      setState(() {
        _foreignData = data;
        _isFollowing = data['is_followed'] as bool? ?? false;
        _foreignLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _followLoading = true);
    final success = await UserApiService.createFollow(
      widget.targetUserId!,
      _isFollowing ? 0 : 1,
    );
    if (mounted) {
      setState(() {
        _followLoading = false;
        if (success) _isFollowing = !_isFollowing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOwn) {
      return Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || !provider.hasFetched) {
            return _loadingScaffold();
          }
          return _buildScaffold(provider.userdata, provider.activity);
        },
      );
    }

    if (_foreignLoading || _foreignData.isEmpty) {
      return _loadingScaffold();
    }
    // Fremdes Profil: /ranking/activity liefert nur die EIGENEN Events,
    // deshalb gibt es hier keine Activity-Sektion.
    return _buildScaffold(_foreignData, const []);
  }

  Widget _loadingScaffold() => Scaffold(
    backgroundColor: AppColors.surface,
    body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );

  Widget _buildScaffold(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> activity,
  ) {
    final String username   = data['username']          ?? '';
    final String biography  = data['biography']         ?? '';
    final String? avatarUrl = data['profile_picture_url'];
    final String? vibe1     = data['vibe_factor_1'];
    final String? vibe2     = data['vibe_factor_2'];
    final int? followerCount = data['follower_count'];
    // Gamification (GetUserOut): kann null sein (z.B. Daten aus /users/search),
    // dann verschwinden Ring, XP-Balken & Liga-Zelle einfach.
    final int xp = (data['xp'] as num?)?.toInt() ?? 0;
    final Map<String, dynamic>? league =
        data['league'] as Map<String, dynamic>?;
    final int tier = (league?['tier'] as num?)?.toInt() ?? 0;
    final Color tierColor =
        _tierColors[tier.clamp(0, _tierColors.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 72,
              bottom: 32,
            ),
            child: Column(
              children: [
                // ── Profile hero ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Avatar mit Liga-Ring (Farbe = tier)
                      Container(
                        width: 128,
                        height: 128,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: league != null
                              ? LinearGradient(
                                  colors: [
                                    tierColor,
                                    tierColor.withOpacity(0.35),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: league == null
                              ? AppColors.surfaceContainerHigh
                              : null,
                          border: league == null
                              ? Border.all(
                                  color: AppColors.primary.withOpacity(0.05),
                                  width: 4,
                                )
                              : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: avatarUrl != null
                                ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarFallback(username),
                            )
                                : _avatarFallback(username),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        username,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '@$username',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        biography,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.onSurface,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Vibe chips
                      if (vibe1 != null || vibe2 != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (vibe1 != null) _vibeChip(vibe1),
                            if (vibe1 != null && vibe2 != null)
                              const SizedBox(width: 12),
                            if (vibe2 != null) _vibeChip(vibe2),
                          ],
                        ),

                      const SizedBox(height: 28),

                      // ── Liga-Fortschritt (XP-Balken) ──────────────
                      if (league != null) ...[
                        _LeagueProgress(league: league, color: tierColor),
                        const SizedBox(height: 28),
                      ],

                      // Stats row
                      Container(
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: AppColors.primary.withOpacity(0.07),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          children: [
                            _statCell(
                              league?['league']?.toString() ?? '—',
                              'LIGA',
                            ),
                            _statDivider(),
                            _statCell(_fmtXp(xp), 'XP'),
                            _statDivider(),
                            _statCell('${followerCount ?? 0}', 'FOLLOWERS'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isOwn
                      ? null
                      : _FollowButton(
                          isFollowing: _isFollowing,
                          isLoading: _followLoading,
                          onTap: _toggleFollow,
                        ),
                ),

                const SizedBox(height: 40),

                // Recent Activity — echte Events, nur im eigenen Profil
                if (_isOwn)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RECENT ACTIVITY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (activity.isEmpty)
                          Text(
                            'Noch keine Aktivität — sobald dich jemand bewertet, steht es hier.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          )
                        else
                          ...activity.map((a) => _ActivityItem(
                            icon:     _activityIcon(a),
                            title:    _activityTitle(a),
                            subtitle: _activitySubtitle(a),
                            time:     _relativeTime(
                              DateTime.tryParse(
                                  a['created_at']?.toString() ?? ''),
                            ),
                          )),
                      ],
                    ),
                  ),

                const SizedBox(height: 60),
              ],
            ),
          ),

          _TopBar(
            username: username,
            avatarUrl: avatarUrl,
            isOwn: _isOwn,
            onSettings: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Liga-Helper ────────────────────────────────────────────────────────────
  // Eine Farbe pro tier (Index aus dem league-Objekt, 0 = Bronze).
  // Reihenfolge muss zu LEAGUES im Backend (xp_config.py) passen.
  static const List<Color> _tierColors = [
    Color(0xFFCD7F32), // 0 Bronze
    Color(0xFF8E9AA6), // 1 Silber
    Color(0xFFE6A817), // 2 Gold
    Color(0xFF2EB8B0), // 3 Platin
    Color(0xFF3FA9F5), // 4 Diamant
    Color(0xFF9B59D0), // 5 Meister
    Color(0xFFE0413E), // 6 Legende
  ];

  // 12800 -> "12.8k", 950 -> "950"
  String _fmtXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return '$xp';
  }

  // ── Activity-Mapping ───────────────────────────────────────────────────────
  // Übersetzt ein Backend-Event {type, payload, created_at} in Icon + Texte.
  // Unbekannte types (später "placement"/"streak"/"badge") fallen auf einen
  // neutralen Default zurück, statt zu crashen — Forward-Kompatibilität.

  IconData _activityIcon(Map<String, dynamic> a) {
    switch (a['type']) {
      case 'rated':
        return Icons.bolt_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _activityTitle(Map<String, dynamic> a) {
    switch (a['type']) {
      case 'rated':
        return 'Du wurdest bewertet';
      default:
        return 'Neue Aktivität';
    }
  }

  String _activitySubtitle(Map<String, dynamic> a) {
    final payload = (a['payload'] as num?)?.toInt() ?? 0;
    switch (a['type']) {
      case 'rated':
        return '+$payload Punkte von der Community erhalten';
      default:
        return '';
    }
  }

  // "vor 5 Min." / "vor 3 Std." / "vor 2 Tg." / ab einer Woche das Datum.
  // Der Server schickt UTC-Zeitstempel; die Differenz ist davon unabhängig
  // (beide Seiten werden auf denselben absoluten Zeitpunkt bezogen), nur fürs
  // Datum am Ende brauchen wir toLocal().
  String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'jetzt';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tg.';
    return DateFormat('dd.MM.yyyy').format(dt.toLocal());
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  Widget _vibeChip(String vibe) {
    final icon = _vibeIcons[vibe] ?? Icons.star_outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            vibe,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _statDivider() => Container(
    width: 1,
    height: 36,
    color: AppColors.primary.withOpacity(0.07),
  );
}

// ── Liga-Fortschritt ──────────────────────────────────────────────────────────
// Karte mit Liga-Name, XP-Balken und "Noch X XP bis <nächste Liga>".
// Alle Werte kommen fertig berechnet vom Server (get_league) — hier wird
// nichts selbst hergeleitet, nur angezeigt.
class _LeagueProgress extends StatelessWidget {
  final Map<String, dynamic> league;
  final Color color;
  const _LeagueProgress({required this.league, required this.color});

  @override
  Widget build(BuildContext context) {
    final name = league['league']?.toString() ?? '';
    final next = league['next_league']?.toString();
    final xpInto = (league['xp_into_league'] as num?)?.toInt() ?? 0;
    final span = (league['league_span'] as num?)?.toInt() ?? 0;
    final xpForNext = (league['xp_for_next'] as num?)?.toInt() ?? 0;

    // Höchste Liga liefert league_span == 0 -> Balken voll statt durch 0 teilen.
    final double progress =
        span == 0 ? 1.0 : (xpInto / span).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                name.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                next == null ? 'MAX' : '$xpInto / $span XP',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next == null
                ? 'Höchste Liga erreicht'
                : 'Noch $xpForNext XP bis $next',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top App Bar ───────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final bool isOwn;
  final VoidCallback? onSettings;
  const _TopBar({
    required this.username,
    this.avatarUrl,
    required this.isOwn,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface.withOpacity(0.85),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 24,
        right: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Links: Mini-Avatar (eigen) oder Zurück-Button (fremd)
          if (isOwn)
            Container(
              width: 32,
              height: 32,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: avatarUrl != null
                  ? Image.network(avatarUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback())
                  : _fallback(),
            )
          else
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.arrow_back, color: AppColors.primary, size: 24),
            ),

          // @username
          Text(
            '@$username',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.onSurface,
            ),
          ),

          // Rechts: Settings (eigen) oder Platzhalter (fremd)
          if (isOwn)
            GestureDetector(
              onTap: onSettings,
              child: Icon(Icons.settings_outlined,
                  color: AppColors.primary, size: 24),
            )
          else
            const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    color: AppColors.surfaceContainerHighest,
    child: Center(
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

// ── Primary Button ────────────────────────────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _pressed ? AppColors.primaryDark : AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.surfaceContainerLow,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Follow Button ─────────────────────────────────────────────────────────────
class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onTap;
  const _FollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isFollowing ? AppColors.surfaceContainerHigh : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          border: isFollowing
              ? Border.all(color: AppColors.primary.withOpacity(0.3))
              : null,
          boxShadow: isFollowing
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isFollowing
                      ? AppColors.onSurface
                      : AppColors.surfaceContainerLow,
                ),
              ),
      ),
    );
  }
}




// ── Activity Item ─────────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}