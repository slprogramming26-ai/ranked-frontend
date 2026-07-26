import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Entfernt Metadaten (GPS, Kameramodell, Aufnahmezeit) aus Bildern, bevor
/// sie hochgeladen werden.
///
/// Warum das ein eigener Schritt sein muss: Unsere Kompression allein wirft
/// die Metadaten NICHT weg. `Image.from`/`Image.fromResized` klonen die
/// EXIF-Daten mit, und der `JpegEncoder` schreibt sie wieder ins JPEG, sobald
/// sie nicht leer sind. Ein Galerie-Foto kommt also inklusive Wohnadresse
/// beim Server an, obwohl wir es neu enkodiert haben.

/// Dekodiert Bilddaten, ohne bei Muell zu werfen.
///
/// `img.decodeImage` probiert der Reihe nach alle Decoder durch, und die
/// pruefen ihre Header nicht sauber: bei abgeschnittenen oder fremden Bytes
/// liest z.B. der PSD-Decoder ueber das Ende hinaus und wirft `RangeError`
/// statt `null` zurueckzugeben. Realistisch wird das, wenn Android uns
/// waehrend der Kamera abschiesst und eine halb geschriebene Datei
/// zurueckbleibt.
img.Image? decodeImageSafely(Uint8List bytes) {
  try {
    return img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
}

/// Backt die EXIF-Drehung in die Pixel und wirft danach alle Metadaten weg.
///
/// Zur Reihenfolge: Das Orientation-Tag IST EXIF. Wer zuerst loescht, bei
/// dem liegen Hochkant-Fotos anschliessend quer. Beim JPEG-Pfad kommt uns
/// das Paket zuvor — sein Decoder backt die Drehung schon beim
/// `decodeImage` ein und raeumt das Tag weg (`_jpeg_quantize_io.dart`).
/// `bakeOrientation` ist dort also nur noch ein Netz: es kostet eine Kopie,
/// deckt aber die Formate ab, bei denen das nicht passiert, und faengt uns
/// auf, falls sich das Paket-Verhalten mal aendert.
///
/// Das ICC-Farbprofil bleibt absichtlich drin: es verraet nichts ueber den
/// Nutzer, sorgt aber dafuer, dass Weitwinkel-/P3-Fotos nicht ausgewaschen
/// oder uebersaettigt ankommen.
img.Image stripMetadata(img.Image src) {
  // Gibt immer eine Kopie zurueck, das Original bleibt unangetastet.
  final baked = img.bakeOrientation(src);

  // Leeres ExifData => der Encoder ueberspringt den EXIF-Block komplett.
  baked.exif = img.ExifData();
  // PNG-Textchunks (Kommentare, "Software: ...").
  baked.textData = null;

  return baked;
}

/// Dekodiert die Bytes, entfernt die Metadaten, skaliert auf maximal
/// [maxSize] Kantenlaenge (Seitenverhaeltnis bleibt) und kodiert als JPG.
///
/// Gibt `null` zurueck, wenn die Bytes kein lesbares Bild sind.
Uint8List? sanitizeImageBytes(
  Uint8List bytes, {
  int maxSize = 1080,
  int quality = 85,
}) {
  final decoded = decodeImageSafely(bytes);
  if (decoded == null) return null;

  final clean = stripMetadata(decoded);

  final resized = (clean.width > maxSize || clean.height > maxSize)
      ? img.copyResize(
          clean,
          width: clean.width >= clean.height ? maxSize : null,
          height: clean.height > clean.width ? maxSize : null,
        )
      : clean;

  return img.encodeJpg(resized, quality: quality);
}

/// Parameter fuer [sanitizeImageFile] — `compute` nimmt nur ein Argument.
typedef SanitizeRequest = ({String path, int maxSize, int quality});

/// Liest die Datei unter `path`, saeubert + komprimiert sie und schreibt das
/// Ergebnis als neue Datei daneben. Gibt den neuen Pfad zurueck, oder `null`,
/// wenn das Bild nicht dekodiert werden konnte.
///
/// Top-Level und ohne State, damit sie direkt in `compute` laufen kann:
/// ```dart
/// final path = await compute(
///   sanitizeImageFile,
///   (path: original, maxSize: 1080, quality: 85),
/// );
/// ```
Future<String?> sanitizeImageFile(SanitizeRequest req) async {
  final bytes = await File(req.path).readAsBytes();
  final cleaned = sanitizeImageBytes(
    bytes,
    maxSize: req.maxSize,
    quality: req.quality,
  );
  if (cleaned == null) return null;

  final newPath = '${req.path}.clean.jpg';
  await File(newPath).writeAsBytes(cleaned);
  return newPath;
}
