// =============================================================================
//  Kommentare — der erste auf Riverpod migrierte Provider der App
// =============================================================================
//  Der Rest der App laeuft noch auf dem provider-Paket; beide koexistieren.
//  Einzige Regel dabei: ein State gehoert immer nur EINER der beiden Welten.
//
//  Gegenueber der frueheren ChangeNotifier-Klasse faellt einiges ersatzlos weg:
//
//    frueher (ChangeNotifier)           jetzt
//    ---------------------------------  -----------------------------------
//    List _comments + Getter            der State des Providers selbst
//    bool _isLoading + setLoading()     steckt schon im AsyncValue
//    setComments()                      Riverpod haelt das Ergebnis selbst
//    _fetchData() im Widget             laeuft an, sobald jemand watcht
//    (Fehler fielen unter den Tisch)    AsyncValue.error, im UI erzwungen
//
//  Zum Fehlerfall mit Augenmass: Netzwerk-Exceptions (kein Empfang o.ae.)
//  landen ab jetzt sichtbar in AsyncValue.error statt als verschluckter Fehler
//  eines nicht-awaiteten Futures. Ein HTTP 500 bleibt aber weiterhin
//  unsichtbar, weil PostApiService.getComments() dann selbst [] zurueckgibt
//  (post_api_service.dart:98) — das Sheet zeigt "Be the first to pulse!"
//  obwohl der Server kaputt ist. Das zu fixen gehoert in den ApiService,
//  nicht hierher, und ist bewusst NICHT Teil dieser Migration.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ref_cache_for.dart';
import 'post_api_service.dart';

/// Die Kommentare EINES Posts.
///
/// `.family` heisst: das hier ist kein einzelner Provider, sondern eine
/// Schablone. `commentsProvider(42)` und `commentsProvider(99)` sind zwei
/// voneinander unabhaengige Zustaende mit eigenem Lade- und Fehlerstatus.
///
/// Das ist der Unterschied zur alten Klasse: die hatte EINE globale
/// Kommentarliste, die beim Oeffnen des naechsten Sheets ueberschrieben wurde.
///
/// Der Rueckgabetyp ist `AsyncValue<List<Map<String, dynamic>>>` — Riverpod
/// verpackt das Future automatisch in laden / Fehler / Daten. Das Widget
/// bekommt also nie eine halbfertige Liste zu sehen.
///
/// Zum Aufraeumen, weil das eine Falle ist: `.autoDispose` steht hier
/// ABSICHTLICH dran. Auto-Dispose-by-default gilt in Riverpod 3 nur fuer die
/// Codegen-API (`@riverpod`-Annotation); die klassischen Konstruktoren, die
/// wir hier benutzen, haben weiterhin `isAutoDispose = false` fest verdrahtet
/// (siehe providers/future_provider.dart im riverpod-Paket). Ohne das
/// `.autoDispose` behaelt die App jede je geoeffnete Kommentarliste bis zum
/// App-Ende im Speicher, und neue Kommentare anderer Leute sieht man nie.
///
/// [Ref.cacheFor] ist der Mittelweg: nach dem Schliessen des Sheets bleibt
/// der Zustand noch 45 Sekunden liegen. Wer zurueckspringt ("was stand da
/// nochmal"), sieht die Kommentare sofort statt eines Spinners; wer spaeter
/// wiederkommt, bekommt frische Daten. Der Wert ist bewusst grosszuegiger als
/// die gefuehlte "ausversehen geschlossen"-Sekunde — der haeufige Fall ist
/// zwei Posts weiterscrollen und zurueck, und das dauert laenger.
///
/// Ein Notifier statt FutureProvider, weil wir die Liste jetzt auch lokal
///AENDERN muessen (gemeldeten Kommentar ausblenden). Ein FutureProvider kann
///  nur laden, ein Notifier hat zusaetzlich eigene Methoden

class CommentsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  CommentsNotifier(this.postId);

  final int postId;

  // Lokal ausgeblendete Kommentare. Ueberlebt invalidate (Riverpod ruft dann
  // nur build() neu auf demselben Objekt auf), stirbt erst mit autoDispose.
  // Schuetzt davor, dass ein Neuladen den Kommentar zurueckholt, bevor der
  // Report im Hintergrund beim Server angekommen ist.
  final Set<int> _hiddenIds = {};

  @override
  Future<List<Map<String, dynamic>>> build() async {
    ref.cacheFor(const Duration(seconds: 45));
    final comments = await PostApiService.getComments(postId);
    return comments.where((c) => !_hiddenIds.contains(c['id'])).toList();
  }

  // Gemeldeten Kommentar lokal rausnehmen, OHNE neu zu laden.
  void hide(int commentId) {
    _hiddenIds.add(commentId);
    final current = state.value;
    if (current == null) return; // laedt noch / Fehler: build() filtert dann
    // NEUE Liste: Riverpod merkt nur ein neues Objekt (wie notifyListeners).
    state = AsyncData(current.where((c) => c['id'] != commentId).toList());
  }
}

  final commentsProvider = AsyncNotifierProvider.autoDispose
      .family<CommentsNotifier, List<Map<String, dynamic>>, int>(
        CommentsNotifier.new,
      );

