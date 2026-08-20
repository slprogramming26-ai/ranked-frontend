import 'package:flutter/material.dart';

/// Sagt Widgets Bescheid, wenn sich eine Route ueber sie legt oder wieder
/// verschwindet. Global, weil MaterialApp und der Feed dieselbe Instanz
/// brauchen — eigene Datei, damit posts_feed.dart nicht main.dart importieren
/// muss (main.dart importiert ja schon posts_feed.dart).
///
/// ModalRoute<void>, NICHT PageRoute: RouteObserver meldet nur, wenn alte UND
/// neue Route zum Typ passen. Das Kommentar-Sheet ist eine PopupRoute und
/// wuerde bei PageRoute komplett durchrutschen.
final routeObserver = RouteObserver<ModalRoute<void>>();