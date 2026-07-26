import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ranked/image_sanitizer.dart';

/// Testet `lib/image_sanitizer.dart` gegen ein Foto mit GPS.
///
/// Warum ueberhaupt ein Unit-Test, wo der Upload doch live geprueft wurde:
/// Ein sauberes Bild in S3 beweist NICHT, dass unser Client die Metadaten
/// entfernt hat. Das Backend enkodiert mit Pillow neu und wirft EXIF dabei
/// sowieso weg. Der Livetest kann also nicht unterscheiden, ob der Client
/// oder der Server gestrippt hat. Hier laeuft nur unser Code - was hier
/// sauber rauskommt, hat der Client sauber gemacht.
///
/// Das Fixture stammt aus `tool/make_exif_fixture.py` (dort steht auch, was
/// genau drinsteckt und warum).
void main() {
  late Uint8List dirtyBytes;

  setUpAll(() {
    dirtyBytes = File('test/fixtures/exif_portrait.jpg').readAsBytesSync();
  });

  group('Fixture', () {
    // Ein Test, der ein sauberes Bild sauber findet, beweist nichts. Deshalb
    // hier zuerst der Nachweis, dass die Testdatei wirklich verseucht ist.
    test('enthaelt die Metadaten, die der Test entfernt sehen will', () {
      expect(_header(dirtyBytes), containsBytes(_exifHeader));
      expect(_header(dirtyBytes), containsBytes(_ascii('Apple')));

      final decoded = img.decodeImage(dirtyBytes)!;
      expect(decoded.exif.isEmpty, isFalse);
      expect(decoded.exif.gpsIfd.isEmpty, isFalse);
    });

    test('kommt schon gedreht aus dem Decoder', () {
      // Nicht selbstverstaendlich und beim Schreiben dieses Tests zuerst
      // falsch angenommen: In der Datei liegen die Pixel QUER (900 x 600)
      // mit Orientation 6. Der JPEG-Decoder des image-Pakets backt die
      // Drehung aber selbst ein und loescht das Tag dabei
      // (`_jpeg_quantize_io.dart`: "except for Orientation which we're
      // baking"). Hier steht also nur, was der Decoder tut - unser eigenes
      // bakeOrientation wird weiter unten bei stripMetadata geprueft.
      final decoded = img.decodeImage(dirtyBytes)!;

      expect(decoded.width, 600);
      expect(decoded.height, 900);
      expect(decoded.exif.imageIfd.orientation, isNull);
    });
  });

  group('sanitizeImageBytes', () {
    test('entfernt EXIF, GPS und Hersteller-Spuren', () {
      final clean = sanitizeImageBytes(dirtyBytes)!;

      // Auf Byte-Ebene, nicht nur ueber die EXIF-API: GPS kann auch als
      // XMP-XML in einem zweiten APP1-Block liegen, davon sieht ein
      // `exif.isEmpty` nichts.
      final header = _header(clean);
      expect(header, isNot(containsBytes(_exifHeader)));
      expect(header, isNot(containsBytes(_ascii('Apple'))));
      expect(header, isNot(containsBytes(_ascii('iPhone'))));
      expect(header, isNot(containsBytes(_ascii('GPS'))));
      expect(header, isNot(containsBytes(_ascii('ranked-fixture'))));
      expect(header, isNot(containsBytes(_ascii('2026:07:25'))));

      final decoded = img.decodeImage(clean)!;
      expect(decoded.exif.isEmpty, isTrue);
      expect(decoded.exif.gpsIfd.isEmpty, isTrue);
    });

    test('liefert das Hochkant-Foto hochkant ab', () {
      // Die Eigenschaft, auf die es beim Upload ankommt, egal wer sie
      // herstellt: Das Bild muss physisch richtig herum rauskommen. Ein
      // Orientation-Tag wuerde nichts mehr retten - das Backend wirft es
      // beim Re-Encode mit Pillow weg und kann die Drehung nicht nachholen.
      final decoded = img.decodeImage(sanitizeImageBytes(dirtyBytes)!)!;

      expect(decoded.width, 600);
      expect(decoded.height, 900);
      expect(decoded.height, greaterThan(decoded.width), reason: 'hochkant');
    });

    test('skaliert auf maxSize und behaelt das Seitenverhaeltnis', () {
      final decoded =
          img.decodeImage(sanitizeImageBytes(dirtyBytes, maxSize: 300)!)!;

      // Nach dem Backen ist die lange Kante die Hoehe.
      expect(decoded.height, 300);
      expect(decoded.width, 200); // 600/900 * 300
    });

    test('laesst kleine Bilder in Ruhe', () {
      final small = img.encodeJpg(img.Image(width: 40, height: 25));
      final decoded = img.decodeImage(sanitizeImageBytes(small)!)!;

      expect(decoded.width, 40);
      expect(decoded.height, 25);
    });

    test('gibt null zurueck, wenn die Bytes kein Bild sind', () {
      // Wichtig fuer die Call-Sites: die brechen bei null den Upload ab,
      // statt wie frueher die Originaldatei zu schicken - also genau die
      // mit dem GPS drin.
      expect(sanitizeImageBytes(Uint8List.fromList([1, 2, 3, 4])), isNull);
      expect(sanitizeImageBytes(Uint8List(0)), isNull);
    });
  });

  group('stripMetadata', () {
    test('backt eine gesetzte Orientation in die Pixel', () {
      // Hier haengt unser eigenes bakeOrientation dran. Beim JPEG-Pfad
      // laeuft es leer, weil der Decoder schon gedreht hat - dieses Bild
      // baut den Fall nach, in dem das Tag noch dran ist (andere Formate,
      // oder falls das Paket sein Verhalten mal aendert).
      final quer = img.Image(width: 40, height: 20)
        ..exif.imageIfd.orientation = 6; // "hochkant anzeigen"

      final gebacken = stripMetadata(quer);

      expect(gebacken.width, 20);
      expect(gebacken.height, 40);
      expect(gebacken.exif.isEmpty, isTrue);
    });

    test('laesst das uebergebene Bild unangetastet', () {
      // Arbeitet auf einer Kopie. Sonst wuerde ein Aufrufer, der das Bild
      // danach noch anzeigt, ploetzlich eines ohne EXIF sehen.
      final original = img.decodeImage(dirtyBytes)!;

      stripMetadata(original);

      expect(original.exif.isEmpty, isFalse);
      expect(original.exif.gpsIfd.isEmpty, isFalse);
      expect(original.width, 600);
    });

    test('wirft PNG-Textchunks weg', () {
      final png = img.Image(width: 10, height: 10)
        ..textData = {'Software': 'Kamera-App', 'Comment': 'zuhause'};

      expect(stripMetadata(png).textData, isNull);
    });
  });

  group('sanitizeImageFile', () {
    test('schreibt eine gesaeuberte Datei daneben', () async {
      final temp = Directory.systemTemp.createTempSync('sanitize_test');
      addTearDown(() => temp.deleteSync(recursive: true));

      final source = File('${temp.path}/foto.jpg')
        ..writeAsBytesSync(dirtyBytes);

      final path = await sanitizeImageFile(
        (path: source.path, maxSize: 1080, quality: 85),
      );

      expect(path, isNotNull);
      expect(File(path!).existsSync(), isTrue);
      // Original bleibt liegen - die Call-Sites raeumen selbst auf.
      expect(source.existsSync(), isTrue);

      expect(
        _header(File(path).readAsBytesSync()),
        isNot(containsBytes(_exifHeader)),
      );
    });

    test('gibt null zurueck, wenn die Datei kein Bild ist', () async {
      final temp = Directory.systemTemp.createTempSync('sanitize_test');
      addTearDown(() => temp.deleteSync(recursive: true));

      final broken = File('${temp.path}/kaputt.jpg')
        ..writeAsStringSync('das ist kein JPEG');

      expect(
        await sanitizeImageFile(
          (path: broken.path, maxSize: 1080, quality: 85),
        ),
        isNull,
      );
    });
  });
}

// --- Helfer -----------------------------------------------------------

final _exifHeader = Uint8List.fromList([0x45, 0x78, 0x69, 0x66, 0, 0]);

Uint8List _ascii(String text) => Uint8List.fromList(text.codeUnits);

/// Schneidet alles ab dem Bildinhalt weg und laesst nur die JPEG-Kopfdaten
/// stehen (alles vor dem SOS-Marker `FF DA`).
///
/// Noetig, damit die Byte-Suche nicht flaky wird: In 30 KB komprimierten
/// Pixeln taucht irgendwann zufaellig die Folge "GPS" auf, und dann schlaegt
/// ein Test fehl, obwohl gar nichts drinsteht. Metadaten stehen ohnehin
/// immer im Kopf.
Uint8List _header(Uint8List jpeg) {
  for (var i = 2; i < jpeg.length - 1; i++) {
    if (jpeg[i] == 0xFF && jpeg[i + 1] == 0xDA) {
      return Uint8List.sublistView(jpeg, 0, i);
    }
  }
  return jpeg;
}

/// `contains` sucht nur einzelne Elemente, keine Teilfolgen.
Matcher containsBytes(Uint8List needle) => predicate<Uint8List>(
      (haystack) {
        outer:
        for (var i = 0; i <= haystack.length - needle.length; i++) {
          for (var j = 0; j < needle.length; j++) {
            if (haystack[i + j] != needle[j]) continue outer;
          }
          return true;
        }
        return false;
      },
      'enthaelt die Bytefolge ${String.fromCharCodes(needle)}',
    );
