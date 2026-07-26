"""Prueft ein hochgeladenes Bild auf Metadaten-Reste (GPS, Kamera, Zeit).

Gegenstueck zu `lib/image_sanitizer.dart`: dort werden die Metadaten vor dem
Upload entfernt, hier wird nachgesehen, ob das auch wirklich passiert ist.
Nach jeder Aenderung am Upload-Pfad einmal laufen lassen.

Aufruf:
    python tool/check_metadata.py <pfad-oder-url> [<pfad-oder-url> ...]

    # Supabase-URL geht direkt (die Buckets sind public-read):
    python tool/check_metadata.py "https://<projekt>.supabase.co/storage/v1/object/public/post_images/posts/<uuid>.jpg"

    # Immer auch das ORIGINAL mitgeben - ein Test, der nur "SAUBER" sagen
    # kann, beweist nichts. Das Original MUSS "RESTE VORHANDEN" melden:
    python tool/check_metadata.py "https://..." "C:/.../IMG_1234.jpg"

Braucht Pillow:  pip install Pillow

Worauf zu achten ist:
  * Segmente: nur APP0 (JFIF) und APP2 (ICC-Farbprofil) sind ok. Das ICC-Profil
    lassen wir bewusst drin, damit die Farben stimmen - es verraet nichts.
  * Masse: bei einem Hochkant-Foto muss "hochkant" dastehen. Steht da "quer",
    hat `bakeOrientation` nicht gegriffen und das Bild liegt dauerhaft auf der
    Seite - das Backend wirft das Orientation-Tag beim Re-Encode naemlich weg.
"""

import io
import sys
import urllib.request

from PIL import ExifTags, Image

# Was die einzelnen APP-Segmente ueblicherweise transportieren.
SEGMENTS = {
    0xE0: "APP0  (JFIF - harmlos)",
    0xE1: "APP1  (EXIF oder XMP  <-- hier steckt GPS)",
    0xE2: "APP2  (ICC-Farbprofil - harmlos, behalten wir absichtlich)",
    0xEC: "APP12 (Ducky/Kamera-Info)",
    0xED: "APP13 (Photoshop/IPTC - kann Autor/Ort enthalten)",
    0xEE: "APP14 (Adobe)",
    0xFE: "COM   (Kommentar)",
}

# Byte-Muster, die auf Metadaten hindeuten. Noetig, weil GPS auch als XMP-XML
# in einem zweiten APP1-Block liegen kann - davon sieht `getexif()` nichts.
NEEDLES = [
    (b"Exif\x00\x00", "EXIF-Header"),
    (b"http://ns.adobe.com/xap", "XMP (Adobe-Metadaten)"),
    (b"Photoshop", "Photoshop/IPTC-Block"),
    (b"GPS", "GPS-Kennung"),
    (b"Apple", "Hersteller: Apple"),
    (b"samsung", "Hersteller: Samsung"),
    (b"Samsung", "Hersteller: Samsung"),
    (b"Google", "Hersteller: Google"),
    (b"Xiaomi", "Hersteller: Xiaomi"),
]

HARMLESS = ("JFIF", "ICC")


def load(target: str) -> bytes:
    if target.startswith(("http://", "https://")):
        with urllib.request.urlopen(target) as response:
            return response.read()
    with open(target, "rb") as handle:
        return handle.read()


def list_segments(data: bytes) -> list[str]:
    """Laeuft die JPEG-Marker ab, bis die Bilddaten anfangen (SOS)."""
    if not data.startswith(b"\xff\xd8"):
        return ["(kein JPEG - Segment-Check uebersprungen)"]

    found = []
    i = 2
    while i < len(data) - 3:
        if data[i] != 0xFF:
            break
        marker = data[i + 1]
        if marker == 0xDA:  # Start of Scan -> ab hier nur noch Pixel
            break
        length = int.from_bytes(data[i + 2:i + 4], "big")
        if marker in SEGMENTS:
            found.append(f"{SEGMENTS[marker]}  [{length} Bytes]")
        i += 2 + length
    return found


def check(target: str) -> bool:
    """Gibt True zurueck, wenn die Datei sauber ist."""
    data = load(target)
    print(f"\n{'=' * 70}\n{target}\n{'=' * 70}")
    print(f"Groesse: {len(data) / 1024:.1f} KB")

    image = Image.open(io.BytesIO(data))
    lage = "hochkant" if image.height > image.width else "quer"
    print(f"Masse:   {image.width} x {image.height}  ({lage})")

    print("\n-- JPEG-Segmente --")
    segments = list_segments(data)
    print("  " + "\n  ".join(segments) if segments else "  (keine)")

    print("\n-- Pillow EXIF --")
    exif = image.getexif()
    if not exif:
        print("  (leer)")
    else:
        for tag, value in exif.items():
            print(f"  {ExifTags.TAGS.get(tag, tag)}: {str(value)[:70]}")
        gps = exif.get_ifd(ExifTags.IFD.GPSInfo)
        if gps:
            print("  !! GPS !!")
            for tag, value in gps.items():
                print(f"     {ExifTags.GPSTAGS.get(tag, tag)}: {value}")

    print("\n-- Byte-Suche --")
    hits = list(dict.fromkeys(
        label for needle, label in NEEDLES if needle in data
    ))
    if hits:
        for hit in hits:
            print(f"  TREFFER: {hit}")
    else:
        print("  (nichts gefunden)")

    suspicious = [s for s in segments if not any(h in s for h in HARMLESS)]
    clean = not suspicious and not exif and not hits
    print(f"\n=> {'SAUBER' if clean else 'RESTE VORHANDEN'}")
    return clean


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    # Exit-Code 1, sobald eine der Dateien Reste hat - damit man das Skript
    # auch in einen CI-Schritt haengen koennte.
    results = [check(arg) for arg in sys.argv[1:]]
    sys.exit(0 if all(results) else 1)
