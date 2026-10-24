import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Provider fuer Netzwerkbilder mit Disk-Cache + RAM-Downsizing.
///
/// - CachedNetworkImageProvider: laedt erst aus dem Disk-Cache, sonst aus
///   dem Netz (und legt das Original dann auf die Platte).
/// - ResizeImage drumherum: dekodiert nur bis zur Zielbreite in den RAM.
///   Hoehe skaliert proportional mit; kleine Bilder werden NICHT
///   hochskaliert.
///
/// [logicalWidth] ist die Anzeige-Breite in logischen Pixeln (also das, was
/// im Widget-Code steht, z.B. 44 fuer einen 44er-Avatar). Multipliziert mit
/// der Pixeldichte des Geraets ergibt das die physischen Pixel, die das
/// Display maximal darstellen kann — mehr zu dekodieren waere reine
/// RAM-Verschwendung.
ImageProvider netImage(
  BuildContext context,
  String url, {
  required double logicalWidth,
}) {
  final targetWidth =
      (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();
  return ResizeImage(CachedNetworkImageProvider(url), width: targetWidth);
}
