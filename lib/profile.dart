import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ranked/user_api_service.dart';
import 'app_colors.dart';
import 'settings_screen.dart';


class ProfileProvider extends ChangeNotifier {
  Map<String, dynamic> _userdata = {};
  bool _isLoading = false;
  bool _hasFetched = false; // verhindert doppeltes Laden

  Map<String, dynamic> get userdata  => _userdata;
  bool get isLoading  => _isLoading;
  bool get hasFetched => _hasFetched;

  Future<void> fetchUser() async {
    if (_hasFetched) return; // schon geladen? nichts tun
    _isLoading = true;
    notifyListeners();

    final data  = await UserApiService.getCurrentUser();
    _userdata   = data;
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

  final List<Map<String, dynamic>> _recentActivity = [
    {
      'icon':     Icons.auto_graph,
      'title':    "Ranked up in 'Visual Architecture'",
      'subtitle': "Movement into the top 1% globally for the 'Nexus' collection.",
      'time':     '2h ago',
    },
    {
      'icon':     Icons.add_circle_outline,
      'title':    "Created new Pulse 'Obsidian Flow'",
      'subtitle': 'A study on kinetic movement in digital environments.',
      'time':     '1d ago',
    },
    {
      'icon':     Icons.favorite_border,
      'title':    'Hype record broken',
      'subtitle': "'Digital Pulse' reached 4.2k total hype pulses from the community.",
      'time':     '3d ago',
    },
  ];

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
          return _buildScaffold(provider.userdata);
        },
      );
    }

    if (_foreignLoading || _foreignData.isEmpty) {
      return _loadingScaffold();
    }
    return _buildScaffold(_foreignData);
  }

  Widget _loadingScaffold() => Scaffold(
    backgroundColor: AppColors.surface,
    body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );

  Widget _buildScaffold(Map<String, dynamic> data) {
    final String username   = data['username']          ?? '';
    final String biography  = data['biography']         ?? '';
    final String? avatarUrl = data['profile_picture_url'];
    final String? vibe1     = data['vibe_factor_1'];
    final String? vibe2     = data['vibe_factor_2'];
    final int? followerCount = data['follower_count'];

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
                      // Avatar
                      Container(
                        width: 128,
                        height: 128,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.05),
                            width: 4,
                          ),
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
                            _statCell('#42', 'RANK'),
                            _statDivider(),
                            _statCell('12.8k', 'POINTS'),
                            _statDivider(),
                            _statCell('$followerCount', 'FOLLOWERS'),
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

                // Recent Activity
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Icon(Icons.sort, color: AppColors.primary, size: 20),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ..._recentActivity.map((item) => _ActivityItem(
                        icon:     item['icon']     as IconData,
                        title:    item['title']    as String,
                        subtitle: item['subtitle'] as String,
                        time:     item['time']     as String,
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