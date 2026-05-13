import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ranked/api_service.dart';


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

    final data  = await ApiService.getUser();
    _userdata   = data;
    _isLoading  = false;
    _hasFetched = true;
    notifyListeners();
  }
}


class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {

  // ── Color tokens ───────────────────────────────────────────────────────────
  static const Color primary                 = Color(0xFFB41B00);
  static const Color onBackground            = Color(0xFF4D2124);
  static const Color onSurface               = Color(0xFF4D2124);
  static const Color onSurfaceVariant        = Color(0xFF834C4F);
  static const Color surface                 = Color(0xFFFFF4F3);
  static const Color surfaceContainerLow     = Color(0xFFFFEDEC);
  static const Color surfaceContainerHigh    = Color(0xFFFFDADA);
  static const Color surfaceContainerHighest = Color(0xFFFFD2D3);

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
    // postFrameCallback: context ist in initState noch nicht sicher nutzbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consumer rebuilt automatisch bei notifyListeners() — kein setState nötig
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {

        if (provider.isLoading || !provider.hasFetched) {
          return const Scaffold(
            backgroundColor: surface,
            body: Center(child: CircularProgressIndicator(color: primary)),
          );
        }

        final data          = provider.userdata;
        final String username   = data['username']          ?? '';
        final String biography  = data['biography']         ?? '';
        final String? avatarUrl = data['profile_picture_url'];
        final String? vibe1     = data['vibe_factor_1'];
        final String? vibe2     = data['vibe_factor_2'];

        return Scaffold(
          backgroundColor: surface,
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
                              color: surfaceContainerHigh,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primary.withOpacity(0.05),
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
                              color: onBackground,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '@$username',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            biography,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: onSurface,
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
                                  color: primary.withOpacity(0.07),
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
                                _statCell('982', 'FOLLOWERS'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _PrimaryButton(label: 'Rank Pulse', onTap: () {}),
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
                                  color: onSurfaceVariant,
                                ),
                              ),
                              const Icon(Icons.sort, color: primary, size: 20),
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

              _TopBar(username: username, avatarUrl: avatarUrl),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _avatarFallback(String name) => Container(
    color: surfaceContainerHighest,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: primary,
        ),
      ),
    ),
  );

  Widget _vibeChip(String vibe) {
    final icon = _vibeIcons[vibe] ?? Icons.star_outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withOpacity(0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primary),
          const SizedBox(width: 6),
          Text(
            vibe,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: onSurfaceVariant,
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
            color: onBackground,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _statDivider() => Container(
    width: 1,
    height: 36,
    color: primary.withOpacity(0.07),
  );
}

// ── Top App Bar ───────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  const _TopBar({required this.username, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF4F3).withOpacity(0.85),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 24,
        right: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mini avatar
          Container(
            width: 32,
            height: 32,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: avatarUrl != null
                ? Image.network(avatarUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback())
                : _fallback(),
          ),

          // @username
          Text(
            '@$username',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: const Color(0xFF4D2124),
            ),
          ),

          // Settings icon
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.settings_outlined,
                color: Color(0xFFB41B00), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    color: const Color(0xFFFFD2D3),
    child: Center(
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFFB41B00),
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
            color: _pressed ? const Color(0xFF9E1700) : const Color(0xFFB41B00),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB41B00).withOpacity(0.15),
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
              color: const Color(0xFFFFEFEC),
            ),
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
              color: const Color(0xFFFFD2D3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFB41B00), size: 22),
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
                          color: const Color(0xFF4D2124),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF834C4F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF834C4F),
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