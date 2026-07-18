import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'app_colors.dart';
import 'api_client.dart';
import 'location_picker.dart';
import 'profile.dart';
import 'theme_provider.dart';
import 'user_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false; // blockt Doppel-Taps waehrend Logout/Delete laufen

  // Aktueller Heimatort ({id, name} oder null), kommt aus GET /users/.
  Map<String, dynamic>? _location;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    // fetchUser() ist geguarded (_hasFetched) — meist schon seit dem Login
    // geladen, kein zusaetzlicher Request noetig.
    final provider = context.read<ProfileProvider>();
    await provider.fetchUser();
    if (!mounted) return;
    setState(() {
      _location = provider.userdata['location'] as Map<String, dynamic>?;
      _locationLoading = false;
    });
  }

  // ── Standort ──────────────────────────────────────────────────────────────
  Future<void> _handlePickLocation() async {
    final loc = await showLocationPicker(context);
    if (loc == null || !mounted) return;

    setState(() => _busy = true);
    final ok = await UserApiService.setLocation(loc['id'] as int);
    if (!mounted) return;
    setState(() {
      // Erst nach Server-OK anzeigen — sonst zeigt die Zeile einen Ort,
      // den das Backend nie gespeichert hat.
      if (ok) _location = loc;
      _busy = false;
    });
    if (!ok) _showSnack('Ort konnte nicht gespeichert werden.');
  }

  Future<void> _handleClearLocation() async {
    final confirmed = await _confirm(
      title: 'Standort entfernen?',
      message: 'Ohne Standort kannst du den lokalen Feed nicht nutzen, '
          'bis du wieder einen Ort waehlst.',
      confirmLabel: 'Entfernen',
      destructive: false,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    final ok = await UserApiService.setLocation(null);
    if (!mounted) return;
    setState(() {
      if (ok) _location = null;
      _busy = false;
    });
    if (!ok) _showSnack('Entfernen fehlgeschlagen. Bitte erneut versuchen.');
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _handleLogout() async {
    final confirmed = await _confirm(
      title: 'Abmelden?',
      message: 'Du wirst von diesem Geraet abgemeldet.',
      confirmLabel: 'Abmelden',
      destructive: false,
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    // logout() loescht die Token und feuert den forceLogoutStream.
    // main.dart wiped daraufhin die lokale DB und springt zum Login.
    // TODO: sobald der /logout-Endpoint steht, vorher serverseitig invalidieren.
    await ApiClient.logout();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  // ── Account loeschen ────────────────────────────────────────────────────────
  Future<void> _handleDelete() async {
    final confirmed = await _confirm(
      title: 'Account loeschen?',
      message:
          'Dein Account, alle Posts, Votes und Kommentare werden dauerhaft '
          'geloescht. Das laesst sich nicht rueckgaengig machen.',
      confirmLabel: 'Endgueltig loeschen',
      destructive: true,
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    final ok = await UserApiService.deleteUser();
    if (!mounted) return;

    if (ok) {
      // Server hat den Account geloescht -> lokal genauso aufraeumen wie beim
      // Logout: Token weg, DB-Wipe + Ruecksprung zum Login via Stream.
      await ApiClient.logout();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      setState(() => _busy = false);
      _showSnack('Loeschen fehlgeschlagen. Bitte spaeter erneut versuchen.');
    }
  }

  // ── Generischer Bestaetigungs-Dialog ────────────────────────────────────────
  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required bool destructive,
  }) {
    final accent = destructive ? Colors.red.shade700 : AppColors.primary;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Abbrechen',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.onSurface),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                // ── Header ───────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Icon(Icons.arrow_back,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Settings',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Darstellung ──────────────────────────────────────────
                _SectionLabel('DARSTELLUNG'),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: 'Dunkles Erscheinungsbild',
                      trailing: Switch(
                        value: theme.isDark,
                        activeColor: AppColors.primary,
                        onChanged: (v) => theme.toggle(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Profil ───────────────────────────────────────────────
                _SectionLabel('PROFIL'),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      title: 'Standort',
                      subtitle: _locationLoading
                          ? 'Wird geladen …'
                          : (_location?['name'] as String? ??
                              'Kein Ort gesetzt'),
                      trailing: _location == null
                          ? Icon(Icons.chevron_right,
                              color: AppColors.onSurfaceVariant, size: 22)
                          : IconButton(
                              icon: Icon(Icons.close,
                                  color: AppColors.onSurfaceVariant, size: 20),
                              tooltip: 'Standort entfernen',
                              onPressed: _busy ? null : _handleClearLocation,
                            ),
                      onTap:
                          _busy || _locationLoading ? null : _handlePickLocation,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Rechtliches ──────────────────────────────────────────
                _SectionLabel('RECHTLICHES'),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.shield_outlined,
                      title: 'Datenschutz (DSGVO)',
                      subtitle: 'Wie wir mit deinen Daten umgehen',
                      trailing: Icon(Icons.chevron_right,
                          color: AppColors.onSurfaceVariant, size: 22),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const _DsgvoScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Account ──────────────────────────────────────────────
                _SectionLabel('ACCOUNT'),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.logout,
                      title: 'Abmelden',
                      onTap: _busy ? null : _handleLogout,
                    ),
                    const _TileDivider(),
                    _SettingsTile(
                      icon: Icons.delete_outline,
                      title: 'Account loeschen',
                      destructive: true,
                      onTap: _busy ? null : _handleDelete,
                    ),
                  ],
                ),
              ],
            ),

            // Lade-Overlay waehrend Logout/Delete
            if (_busy)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Abschnitts-Ueberschrift ───────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
}

// ── Karte, die Tiles gruppiert ────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.07)),
        ),
        child: Column(children: children),
      );
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: 60,
        color: AppColors.primary.withValues(alpha: 0.06),
      );
}

// ── Einzelne Zeile ────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = destructive ? Colors.red.shade700 : AppColors.onSurface;
    final Color iconColor =
        destructive ? Colors.red.shade700 : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ── DSGVO / Datenschutz-Info ──────────────────────────────────────────────────
class _DsgvoScreen extends StatelessWidget {
  const _DsgvoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(Icons.arrow_back,
                      color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Datenschutz',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Platzhalter – hier kommt der finale Datenschutz-Text rein.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.7,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}