"""Erzeugt das Test-Foto fuer `test/image_sanitizer_test.dart`.

Der Unit-Test braucht ein JPEG, das nachweislich Metadaten enthaelt - sonst
kann er nicht zeigen, dass `sanitizeImageBytes` sie entfernt. Ein Test, der
ein sauberes Bild sauber findet, beweist nichts.

Die Datei liegt danach unter `test/fixtures/exif_portrait.jpg` und wird
mitcommittet. Dieses Skript muss also nur laufen, wenn man das Fixture
aendern oder neu erzeugen will.

Aufruf:
    python tool/make_exif_fixture.py

Braucht Pillow:  pip install Pillow

Was drin steckt und warum:
  * GPS (Berlin, Brandenburger Tor) - der eigentliche Grund fuer den ganzen
    Aufwand: ein Galerie-Foto verraet sonst die Wohnadresse.
  * Make/Model/DateTime - typische Kamera-Reste.
  * Orientation = 6 ("um 90 Grad gedreht anzeigen"). Die Pixel liegen QUER
    (900 x 600), angezeigt gehoert das Bild HOCHKANT. Damit prueft der Test
    die knifflige Stelle: `stripMetadata` muss die Drehung erst in die Pixel
    backen und DANN das EXIF wegwerfen. Wer zuerst loescht, bei dem liegt
    das Bild anschliessend dauerhaft auf der Seite.
"""

import pathlib

from PIL import ExifTags, Image
from PIL.TiffImagePlugin import IFDRational

# Pixel liegen quer, das Orientation-Tag sagt "hochkant anzeigen".
WIDTH, HEIGHT = 900, 600

TARGET = pathlib.Path(__file__).parent.parent / "test" / "fixtures" / "exif_portrait.jpg"


def build_pixels() -> Image.Image:
    """Farbverlauf statt Einfarbig - eine leere Flaeche komprimiert zu
    einem Winz-JPEG, an dem sich Resize/Encode kaum beobachten lassen."""
    image = Image.new("RGB", (WIDTH, HEIGHT))
    pixels = image.load()
    for x in range(WIDTH):
        for y in range(HEIGHT):
            pixels[x, y] = (x * 255 // WIDTH, y * 255 // HEIGHT, (x + y) % 256)
    return image


def build_exif() -> Image.Exif:
    exif = Image.Exif()
    exif[ExifTags.Base.Orientation] = 6  # 90 Grad im Uhrzeigersinn drehen
    exif[ExifTags.Base.Make] = "Apple"
    exif[ExifTags.Base.Model] = "iPhone 15 Pro"
    exif[ExifTags.Base.DateTime] = "2026:07:25 14:30:00"
    exif[ExifTags.Base.Software] = "ranked-fixture"

    # GPS liegt in einem eigenen Unter-Verzeichnis (IFD), nicht im Haupt-EXIF.
    # Grad/Minuten/Sekunden muessen IFDRational sein, rohe (zaehler, nenner)-
    # Tupel lehnt Pillow beim Schreiben ab.
    gps = exif.get_ifd(ExifTags.IFD.GPSInfo)
    gps[ExifTags.GPS.GPSLatitudeRef] = "N"
    gps[ExifTags.GPS.GPSLatitude] = (
        IFDRational(52), IFDRational(31), IFDRational(0),
    )
    gps[ExifTags.GPS.GPSLongitudeRef] = "E"
    gps[ExifTags.GPS.GPSLongitude] = (
        IFDRational(13), IFDRational(22), IFDRational(39),
    )

    return exif


if __name__ == "__main__":
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    build_pixels().save(TARGET, format="JPEG", quality=85, exif=build_exif())

    size_kb = TARGET.stat().st_size / 1024
    print(f"geschrieben: {TARGET}  ({size_kb:.1f} KB)")
    print("gegenpruefen mit:  python tool/check_metadata.py test/fixtures/exif_portrait.jpg")
    print("erwartet:          RESTE VORHANDEN  (das Fixture MUSS dreckig sein)")
