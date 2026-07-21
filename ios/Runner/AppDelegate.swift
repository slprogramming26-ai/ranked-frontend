import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    excludeDriftDbFromBackup()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    // Beim allerersten Start existiert die DB zum Launch-Zeitpunkt noch nicht.
    // iCloud-Backups laufen nur, waehrend die App im Hintergrund ist - hier
    // erneut setzen deckt diesen Fall ab.
    excludeDriftDbFromBackup()
    super.applicationDidEnterBackground(application)
  }

  // Die Drift-DB (Documents/ranked.sqlite) enthaelt entschluesselte
  // Chat-Nachrichten und darf nicht ins iCloud-Backup.
  private func excludeDriftDbFromBackup() {
    guard let documents = FileManager.default.urls(
      for: .documentDirectory, in: .userDomainMask
    ).first else { return }

    for name in ["ranked.sqlite", "ranked.sqlite-wal", "ranked.sqlite-shm", "ranked.sqlite-journal"] {
      var url = documents.appendingPathComponent(name)
      guard FileManager.default.fileExists(atPath: url.path) else { continue }
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try? url.setResourceValues(values)
    }
  }
}