import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'user_api_service.dart';

/// Oeffnet den Location-Picker als Bottom-Sheet und liefert den gewaehlten
/// Ort als `{id, name}`-Map zurueck — oder `null`, wenn der User das Sheet
/// ohne Auswahl schliesst. Wird von Sign-up, Settings und dem
/// Lokal-Feed-Empty-State gemeinsam benutzt.
Future<Map<String, dynamic>?> showLocationPicker(BuildContext context) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    // Ohne isScrollControlled ist ein Bottom-Sheet auf halbe Bildschirmhoehe
    // gedeckelt — mit offener Tastatur bliebe kaum Platz fuer die Liste.
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const LocationPicker(),
  );
}

class LocationPicker extends StatefulWidget {
  const LocationPicker({super.key});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  // Zaehlt die Suchanfragen hoch. Antworten koennen sich ueberholen
  // ("Ber" kommt nach "Berlin" zurueck) — nur die Antwort auf die neueste
  // Anfrage darf die Liste setzen.
  int _searchSeq = 0;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      // Feld geleert: laufende Suche verwerfen und zurueck zum Start-Hint.
      _searchSeq++;
      setState(() {
        _results = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }
    // Debounce: erst suchen, wenn der User ~300ms nicht weitertippt —
    // sonst feuert jeder Tastendruck einen Request.
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query) async {
    final seq = ++_searchSeq;
    setState(() => _isLoading = true);
    final results = await UserApiService.getLocations(query);
    // Waehrend des await kann eine neuere Suche gestartet oder das Sheet
    // geschlossen worden sein.
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _results = results;
      _isLoading = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // viewInsets = Tastaturhoehe; das Padding schiebt das Sheet darueber.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ort wählen',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
            _buildSearchField(),
            const SizedBox(height: 8),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: _onQueryChanged,
        autofocus: true,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: AppColors.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Stadt suchen …',
          hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          filled: true,
          fillColor: AppColors.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasSearched) {
      return _buildHint(
        Icons.travel_explore_rounded,
        'Tippe, um deine Stadt zu suchen',
      );
    }
    if (_results.isEmpty) {
      return _buildHint(
        Icons.location_off_rounded,
        'Keinen Ort gefunden — probier eine andere Schreibweise',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
      // Tastatur beim Scrollen in der Liste einklappen, damit man mehr
      // Ergebnisse sieht.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final loc = _results[index];
        return ListTile(
          leading: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          title: Text(
            loc['name'] as String? ?? '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          onTap: () => Navigator.pop(context, loc),
        );
      },
    );
  }

  Widget _buildHint(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
