import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Haelt einen autoDispose-Provider nach dem letzten Zuhoerer noch eine Weile
/// am Leben, statt ihn sofort wegzuwerfen.
///
/// Das Problem, das die Extension loest: `autoDispose` wirft den Zustand in
/// dem Moment weg, in dem das letzte Widget aufhoert zu watchen. Wer ein
/// Bottom-Sheet schliesst und zwei Sekunden spaeter wieder oeffnet, sieht
/// deshalb erneut den Spinner, obwohl sich am Server garantiert nichts
/// geaendert hat. Ohne autoDispose bleibt der Zustand dagegen bis zum
/// App-Ende liegen und wird schleichend alt. [cacheFor] ist der Mittelweg.
///
/// Der Timer laeuft ab dem Moment, in dem der letzte Zuhoerer geht — nicht
/// ab Erstellung des Providers. Das ist der Unterschied zur kuerzeren
/// Variante, die man haeufig sieht:
///
/// ```dart
/// // NICHT das hier:
/// final link = ref.keepAlive();
/// Timer(duration, link.close);   // laeuft schon, waehrend das Sheet offen ist
/// ```
///
/// Die wirft den Cache nach [duration] weg, auch wenn das Sheet die ganze
/// Zeit offen war. Sichtbar kaputt ist das nicht (solange jemand watcht,
/// disposed Riverpod ohnehin nicht), aber das Verhalten waere Zufall statt
/// Absicht — und beim naechsten Oeffnen haette man dann doch wieder den
/// Spinner, obwohl gerade erst geladen wurde.
extension CacheForExtension on Ref {
  /// Verzoegert das Aufraeumen um [duration], gerechnet ab dem letzten
  /// Zuhoerer.
  ///
  /// Wirkt NUR auf Providern mit `.autoDispose`. Bei einem normalen
  /// (keepAlive-) Provider ist der Aufruf wirkungslos, weil dort sowieso nie
  /// aufgeraeumt wird — [keepAlive] hat dann nichts zu verhindern.
  void cacheFor(Duration duration) {
    // Solange der Link offen ist, raeumt Riverpod nicht auf.
    final link = keepAlive();
    Timer? timer;

    // Feuert, wenn der LETZTE Zuhoerer weg ist (Sheet zu). Ab jetzt tickt die
    // Schonfrist; laeuft sie ab, gibt link.close() den Provider zum
    // Aufraeumen frei.
    onCancel(() {
      timer?.cancel();
      timer = Timer(duration, link.close);
    });

    // Rechtzeitig wieder jemand da (Sheet wieder auf) -> Countdown abbrechen,
    // der Zustand bleibt. Beim naechsten Schliessen faengt onCancel von vorn an.
    onResume(() {
      timer?.cancel();
    });

    // Wird der Provider aus einem anderen Grund entsorgt (z.B. ref.invalidate
    // oder das Wegwerfen des ganzen ProviderScope beim Logout), darf kein
    // Timer weiterlaufen und spaeter auf ein totes Element zeigen.
    onDispose(() {
      timer?.cancel();
    });
  }
}
