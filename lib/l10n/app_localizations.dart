import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// App-Name im Task-Switcher
  ///
  /// In de, this message translates to:
  /// **'ranked'**
  String get appTitle;

  /// Melde-Grund: Spam
  ///
  /// In de, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// Melde-Grund: Belästigung
  ///
  /// In de, this message translates to:
  /// **'Belästigung oder Mobbing'**
  String get reportReasonHarassment;

  /// Melde-Grund: unangemessener Inhalt
  ///
  /// In de, this message translates to:
  /// **'Unangemessener Inhalt'**
  String get reportReasonInappropriate;

  /// Melde-Grund: Falschinformation
  ///
  /// In de, this message translates to:
  /// **'Falschinformation'**
  String get reportReasonMisinformation;

  /// Melde-Grund: Sonstiges
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get reportReasonOther;

  /// Titel des Melde-Sheets für einen Post
  ///
  /// In de, this message translates to:
  /// **'Post melden'**
  String get reportTitlePost;

  /// Titel des Melde-Sheets für eine Story
  ///
  /// In de, this message translates to:
  /// **'Story melden'**
  String get reportTitleStory;

  /// Titel des Melde-Sheets für einen Kommentar
  ///
  /// In de, this message translates to:
  /// **'Kommentar melden'**
  String get reportTitleComment;

  /// Titel des Melde-Sheets für ein Profil
  ///
  /// In de, this message translates to:
  /// **'Profil melden'**
  String get reportTitleUser;

  /// Snackbar nach erfolgreichem Melden eines Posts
  ///
  /// In de, this message translates to:
  /// **'Danke! Der Post wird dir nicht mehr angezeigt.'**
  String get reportSuccessPost;

  /// Snackbar nach erfolgreichem Melden einer Story
  ///
  /// In de, this message translates to:
  /// **'Danke! Die Story wird dir nicht mehr angezeigt.'**
  String get reportSuccessStory;

  /// Snackbar nach erfolgreichem Melden eines Kommentars
  ///
  /// In de, this message translates to:
  /// **'Danke! Der Kommentar wird dir nicht mehr angezeigt.'**
  String get reportSuccessComment;

  /// Snackbar nach erfolgreichem Melden eines Profils
  ///
  /// In de, this message translates to:
  /// **'Danke! Wir schauen uns das an.'**
  String get reportSuccessUser;

  /// Snackbar bei 409: Post schon gemeldet
  ///
  /// In de, this message translates to:
  /// **'Du hast diesen Post bereits gemeldet.'**
  String get reportAlreadyPost;

  /// Snackbar bei 409: Story schon gemeldet
  ///
  /// In de, this message translates to:
  /// **'Du hast diese Story bereits gemeldet.'**
  String get reportAlreadyStory;

  /// Snackbar bei 409: Kommentar schon gemeldet
  ///
  /// In de, this message translates to:
  /// **'Du hast diesen Kommentar bereits gemeldet.'**
  String get reportAlreadyComment;

  /// Snackbar bei 409: Profil schon gemeldet
  ///
  /// In de, this message translates to:
  /// **'Du hast dieses Profil bereits gemeldet.'**
  String get reportAlreadyUser;

  /// Platzhalter im Details-Feld des Melde-Sheets
  ///
  /// In de, this message translates to:
  /// **'Was ist passiert? (optional)'**
  String get reportDetailsHint;

  /// Button im Melde-Sheet
  ///
  /// In de, this message translates to:
  /// **'Senden'**
  String get reportSend;

  /// Snackbar bei Netzwerk-/Serverfehler beim Melden
  ///
  /// In de, this message translates to:
  /// **'Melden fehlgeschlagen. Versuch es später erneut.'**
  String get reportFailed;

  /// Titel des Bestätigungs-Dialogs beim Löschen des eigenen Kommentars
  ///
  /// In de, this message translates to:
  /// **'Kommentar löschen?'**
  String get commentDeleteTitle;

  /// Text des Bestätigungs-Dialogs beim Löschen des eigenen Kommentars
  ///
  /// In de, this message translates to:
  /// **'Der Kommentar wird endgültig entfernt.'**
  String get commentDeleteMessage;

  /// Bestätigen-Button im Kommentar-Löschen-Dialog
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get commentDeleteConfirm;

  /// Snackbar, wenn das Löschen des eigenen Kommentars scheitert
  ///
  /// In de, this message translates to:
  /// **'Löschen fehlgeschlagen. Versuch es später erneut.'**
  String get commentDeleteFailed;

  /// Eintrag im ⋮-Menü eines fremden Profils
  ///
  /// In de, this message translates to:
  /// **'Melden'**
  String get profileMenuReport;

  /// Snackbar nach erfolgreichem Blockieren
  ///
  /// In de, this message translates to:
  /// **'{name} wurde blockiert.'**
  String profileBlocked(String name);

  /// Snackbar, wenn das Blockieren fehlschlägt
  ///
  /// In de, this message translates to:
  /// **'Blockieren fehlgeschlagen. Versuch es erneut.'**
  String get profileBlockFailed;

  /// Snackbar, wenn das Loeschen des eigenen Posts scheitert
  ///
  /// In de, this message translates to:
  /// **'Löschen fehlgeschlagen. Versuch es später erneut.'**
  String get postDeleteFailed;

  /// SnackBar in der Chatliste, wenn Gruppenerstellung fehlschlägt
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Erstellen der Gruppe.'**
  String get messengerGroupCreateFailed;

  /// SnackBar in der Chatliste, wenn Gruppenbeitritt per Code fehlschlägt
  ///
  /// In de, this message translates to:
  /// **'Beitritt fehlgeschlagen. Ist der Code noch gültig?'**
  String get messengerJoinFailed;

  /// Dialog-Titel und Aktions-Label zum Gruppenbeitritt
  ///
  /// In de, this message translates to:
  /// **'Gruppe beitreten'**
  String get messengerJoinGroupTitle;

  /// Untertitel der Aktion Gruppe beitreten im Neue-Konversation-Sheet
  ///
  /// In de, this message translates to:
  /// **'Mit Einladungs-Code einsteigen'**
  String get messengerJoinGroupSubtitle;

  /// Hint im Beitritts-Dialog und Titel des Einladungs-Code-Dialogs
  ///
  /// In de, this message translates to:
  /// **'Einladungs-Code'**
  String get messengerInviteCodeHint;

  /// Abbrechen-Button in Dialogen im Messenger
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get messengerCancel;

  /// Beitreten-Button (Dialog und Einladungs-Card)
  ///
  /// In de, this message translates to:
  /// **'Beitreten'**
  String get messengerJoin;

  /// Titel des Aktions-Sheets und Tooltip des Stift-Buttons
  ///
  /// In de, this message translates to:
  /// **'Neue Konversation'**
  String get messengerNewConversation;

  /// Aktion und Titel der User-Suche für neuen Chat
  ///
  /// In de, this message translates to:
  /// **'Chat starten'**
  String get messengerStartChat;

  /// Untertitel der Aktion Chat starten
  ///
  /// In de, this message translates to:
  /// **'User per Name suchen'**
  String get messengerStartChatSubtitle;

  /// Aktion im Neue-Konversation-Sheet
  ///
  /// In de, this message translates to:
  /// **'Gruppe erstellen'**
  String get messengerCreateGroup;

  /// Untertitel der Aktion Gruppe erstellen
  ///
  /// In de, this message translates to:
  /// **'Neue Gruppe anlegen'**
  String get messengerCreateGroupSubtitle;

  /// AppBar-Titel der Chatliste
  ///
  /// In de, this message translates to:
  /// **'Kontakte'**
  String get messengerContactsTitle;

  /// Titel der Anfragen-Zeile in der Chatliste und der Anfragen-Seite
  ///
  /// In de, this message translates to:
  /// **'Anfragen'**
  String get messengerRequests;

  /// Untertitel einer Gruppe in der Chatliste
  ///
  /// In de, this message translates to:
  /// **'Gruppenchat'**
  String get messengerGroupChat;

  /// Untertitel eines DM-Chats in der Chatliste
  ///
  /// In de, this message translates to:
  /// **'Direktnachricht'**
  String get messengerDirectMessage;

  /// Leer-Zustand der Chatliste, Titel
  ///
  /// In de, this message translates to:
  /// **'Keine Konversationen'**
  String get messengerEmptyTitle;

  /// Leer-Zustand der Chatliste, Hinweis
  ///
  /// In de, this message translates to:
  /// **'Tipp auf das Stift-Symbol,\num einen Chat oder eine Gruppe zu starten.'**
  String get messengerEmptyHint;

  /// Hint im Suchfeld der User-Suche
  ///
  /// In de, this message translates to:
  /// **'Username suchen'**
  String get messengerSearchUsernameHint;

  /// Hinweis in der User-Suche
  ///
  /// In de, this message translates to:
  /// **'Mindestens 2 Zeichen eingeben'**
  String get messengerMinChars;

  /// Fehlerhinweis in der User-Suche
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen.'**
  String get messengerSomethingWrong;

  /// Leer-Zustand der User-Suche
  ///
  /// In de, this message translates to:
  /// **'Keine User gefunden'**
  String get messengerNoUsersFound;

  /// Untertitel einer Chat-Anfrage
  ///
  /// In de, this message translates to:
  /// **'Möchte dir schreiben'**
  String get chatRequestsWantsToWrite;

  /// Leer-Zustand der Anfragen-Seite, Titel
  ///
  /// In de, this message translates to:
  /// **'Alles erledigt'**
  String get chatRequestsEmptyTitle;

  /// Leer-Zustand der Anfragen-Seite, Hinweis
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Chat-Anfragen.'**
  String get chatRequestsEmptyHint;

  /// Badge im Chat-Header und im Info-Sheet
  ///
  /// In de, this message translates to:
  /// **'Ende-zu-Ende verschlüsselt'**
  String get chatEncrypted;

  /// Vorschau-Card eines geteilten Posts, der nicht geladen werden kann
  ///
  /// In de, this message translates to:
  /// **'Post nicht verfügbar'**
  String get chatPostUnavailable;

  /// Fallback-Username in der Post-Vorschau
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get chatUnknownUser;

  /// Titel der Einladungs-Card im Chat
  ///
  /// In de, this message translates to:
  /// **'Gruppeneinladung'**
  String get chatGroupInvite;

  /// Code-Anzeige in der Einladungs-Card
  ///
  /// In de, this message translates to:
  /// **'Code {code}'**
  String chatInviteCode(int code);

  /// Button-Text der Einladungs-Card nach erfolgreichem Beitritt
  ///
  /// In de, this message translates to:
  /// **'Beigetreten'**
  String get chatJoined;

  /// Hint im Chat-Eingabefeld
  ///
  /// In de, this message translates to:
  /// **'Nachricht…'**
  String get chatMessageHint;

  /// Hinweis in der Anfrage-Leiste
  ///
  /// In de, this message translates to:
  /// **'Nimm die Anfrage an, um antworten zu können.'**
  String get chatAcceptToReply;

  /// Ablehnen-Button
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get chatDecline;

  /// Annehmen-Button der Anfrage-Leiste
  ///
  /// In de, this message translates to:
  /// **'Annehmen'**
  String get chatAccept;

  /// Titel des Ablehnen-Dialogs
  ///
  /// In de, this message translates to:
  /// **'Anfrage ablehnen?'**
  String get chatDeclineDialogTitle;

  /// Text des Ablehnen-Dialogs
  ///
  /// In de, this message translates to:
  /// **'Der Chat wird aus deiner Liste entfernt. Ohne Blockieren kann {username} dir aber erneut eine Anfrage schicken.'**
  String chatDeclineDialogBody(String username);

  /// Button im Ablehnen-Dialog
  ///
  /// In de, this message translates to:
  /// **'Ablehnen & blockieren'**
  String get chatDeclineAndBlock;

  /// Snackbar nach Ablehnen einer Chat-Anfrage (ohne Blockieren)
  ///
  /// In de, this message translates to:
  /// **'Anfrage abgelehnt.'**
  String get chatDeclined;

  /// Snackbar nach Ablehnen & Blockieren einer Chat-Anfrage
  ///
  /// In de, this message translates to:
  /// **'Anfrage abgelehnt und {name} blockiert.'**
  String chatDeclinedAndBlocked(String name);

  /// Snackbar: Anfrage lokal abgelehnt, aber das Blockieren am Server ging schief
  ///
  /// In de, this message translates to:
  /// **'Anfrage abgelehnt, Blockieren fehlgeschlagen.'**
  String get chatDeclinedBlockFailed;

  /// Leerer Chat, Titel
  ///
  /// In de, this message translates to:
  /// **'Sag Hallo! 👋'**
  String get chatEmptyTitle;

  /// Leerer Chat, Hinweis
  ///
  /// In de, this message translates to:
  /// **'Noch keine Nachrichten.\nSchreib die erste und brich das Eis.'**
  String get chatEmptyHint;

  /// Titel des Blockieren-Bestätigungsdialogs
  ///
  /// In de, this message translates to:
  /// **'{name} blockieren?'**
  String chatInfoBlockTitle(String name);

  /// Text des Blockieren-Bestätigungsdialogs
  ///
  /// In de, this message translates to:
  /// **'Ihr könnt einander keine Nachrichten mehr schreiben. Du kannst die Blockierung später wieder aufheben.'**
  String get chatInfoBlockMessage;

  /// Blockieren-Aktion und Bestätigungs-Button im Info-Sheet
  ///
  /// In de, this message translates to:
  /// **'Blockieren'**
  String get chatInfoBlock;

  /// Aktion im DM-Info-Sheet
  ///
  /// In de, this message translates to:
  /// **'Profil öffnen'**
  String get chatInfoOpenProfile;

  /// Titel des Gruppe-verlassen-Dialogs
  ///
  /// In de, this message translates to:
  /// **'{name} verlassen?'**
  String chatInfoLeaveTitle(String name);

  /// Text des Gruppe-verlassen-Dialogs
  ///
  /// In de, this message translates to:
  /// **'Du bekommst keine neuen Nachrichten mehr aus dieser Gruppe. Mit einer Einladung kannst du jederzeit wieder beitreten.'**
  String get chatInfoLeaveMessage;

  /// Bestätigungs-Button im Gruppe-verlassen-Dialog
  ///
  /// In de, this message translates to:
  /// **'Verlassen'**
  String get chatInfoLeave;

  /// Überschrift der Mitgliederliste im Gruppen-Info-Sheet
  ///
  /// In de, this message translates to:
  /// **'Mitglieder'**
  String get chatInfoMembers;

  /// Aktion im Gruppen-Info-Sheet
  ///
  /// In de, this message translates to:
  /// **'Einladen'**
  String get chatInfoInvite;

  /// Aktion im Gruppen-Info-Sheet
  ///
  /// In de, this message translates to:
  /// **'Gruppe verlassen'**
  String get chatInfoLeaveGroup;

  /// Fehlerhinweis der Mitgliederliste
  ///
  /// In de, this message translates to:
  /// **'Mitglieder konnten nicht geladen werden.'**
  String get chatInfoMembersLoadFailed;

  /// Badge am eigenen Eintrag in der Mitgliederliste
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get chatInfoYou;

  /// Hinweis im Einladungs-Code-Dialog
  ///
  /// In de, this message translates to:
  /// **'Nur für begrenzte Zeit gültig. Wer den Code eingibt, tritt der Gruppe bei.'**
  String get chatInfoInviteCodeNote;

  /// Button im Einladungs-Code-Dialog
  ///
  /// In de, this message translates to:
  /// **'Im Chat teilen'**
  String get chatInfoShareInChat;

  /// Button im Einladungs-Code-Dialog
  ///
  /// In de, this message translates to:
  /// **'Code kopieren'**
  String get chatInfoCopyCode;

  /// Großer Titel auf Welcome-Seite (Onboarding Schritt 1)
  ///
  /// In de, this message translates to:
  /// **'Willkommen im\nPulse'**
  String get onboardingWelcomeTitle;

  /// Untertitel auf Welcome-Seite
  ///
  /// In de, this message translates to:
  /// **'Der erste redaktionelle Social Feed, in dem deine Energie zählt.'**
  String get onboardingWelcomeSubtitle;

  /// Bento-Karte Titel 1: Post your life
  ///
  /// In de, this message translates to:
  /// **'Teile dein Leben'**
  String get onboardingWelcomePostTitle;

  /// Bento-Karte Untertitel 1
  ///
  /// In de, this message translates to:
  /// **'Teile deinen täglichen Pulse. Echt und ungefiltert.'**
  String get onboardingWelcomePostSub;

  /// Bento-Karte Titel 2
  ///
  /// In de, this message translates to:
  /// **'Get Ranked'**
  String get onboardingWelcomeRankTitle;

  /// Bento-Karte Untertitel 2
  ///
  /// In de, this message translates to:
  /// **'Die Community bewertet deine Kreativität.'**
  String get onboardingWelcomeRankSub;

  /// Bento-Karte Titel 3
  ///
  /// In de, this message translates to:
  /// **'Verdienen und gestalten'**
  String get onboardingWelcomeEarnTitle;

  /// Bento-Karte Untertitel 3
  ///
  /// In de, this message translates to:
  /// **'Bewerte andere und verdiene Coins. Schalte exklusive Avatar-Items und \"Freundebuch\"-Skins frei.'**
  String get onboardingWelcomeEarnSub;

  /// Titel auf Vibe-Seite (Schritt 2)
  ///
  /// In de, this message translates to:
  /// **'Was ist dein Vibe?'**
  String get onboardingVibeTitle;

  /// Untertitel auf Vibe-Seite
  ///
  /// In de, this message translates to:
  /// **'Wähle bis zu 2 Pulse-Faktoren, die deinen Alltag ausmachen – oder gar keinen. Teile nur, was du teilen willst.'**
  String get onboardingVibeSubtitle;

  /// Titel auf About-Me-Seite (Schritt 3)
  ///
  /// In de, this message translates to:
  /// **'Dein digitaler Pulse'**
  String get onboardingAboutMeTitle;

  /// Untertitel auf About-Me-Seite
  ///
  /// In de, this message translates to:
  /// **'Lass andere deine Energie spüren. Das ist dein persönlicher Freundebuch-Eintrag.'**
  String get onboardingAboutMeSubtitle;

  /// Label über dem Bio-Textarea
  ///
  /// In de, this message translates to:
  /// **'DEINE STORY'**
  String get onboardingAboutMeStoryLabel;

  /// Placeholder-Text im Bio-Textarea
  ///
  /// In de, this message translates to:
  /// **'Erzähl von dir, deinen Zielen oder was dich besonders macht ...'**
  String get onboardingAboutMeBioHint;

  /// Titel auf Age-Seite (Schritt 4)
  ///
  /// In de, this message translates to:
  /// **'Ein letzter Check'**
  String get onboardingAgeTitle;

  /// Untertitel auf Age-Seite
  ///
  /// In de, this message translates to:
  /// **'Wie alt bist du? Wir fragen das nur einmal – dein Alter wird nie gespeichert.'**
  String get onboardingAgeSubtitle;

  /// Warnung wenn User unter 16 ist
  ///
  /// In de, this message translates to:
  /// **'Ranked ist ab 16. Wir freuen uns, dich in ein paar Jahren wiederzusehen!'**
  String get onboardingAgeWarning;

  /// Anfang des Titels auf Credentials-Seite (Schritt 5) - "Pulse" wird pink gefärbt und separat hinzugefügt
  ///
  /// In de, this message translates to:
  /// **'Werde Teil vom'**
  String get onboardingCredentialsTitle;

  /// Untertitel auf Credentials-Seite
  ///
  /// In de, this message translates to:
  /// **'Letzter Schritt – wähle deine Login-Daten und dein Profil geht live.'**
  String get onboardingCredentialsSubtitle;

  /// Platzhalter im Email-Feld (Credentials)
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse'**
  String get onboardingCredentialsEmailHint;

  /// Platzhalter im Username-Feld
  ///
  /// In de, this message translates to:
  /// **'Username'**
  String get onboardingCredentialsUsernameHint;

  /// Platzhalter im Password-Feld
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get onboardingCredentialsPasswordHint;

  /// Rechtlicher Text am Ende der Credentials-Seite
  ///
  /// In de, this message translates to:
  /// **'Mit der Registrierung stimmst du unseren Community-Richtlinien zu'**
  String get onboardingCredentialsLegal;

  /// Button-Text zum nächsten Schritt
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get onboardingNextButton;

  /// Button-Text zum Konto erstellen (finaler Schritt)
  ///
  /// In de, this message translates to:
  /// **'Account erstellen'**
  String get onboardingCreateButton;

  /// Fortschrittsanzeige im Header
  ///
  /// In de, this message translates to:
  /// **'Schritt {current} von {total}'**
  String onboardingStepProgress(int current, int total);

  /// Titel im Loading-Overlay während Kontoerstellung
  ///
  /// In de, this message translates to:
  /// **'Dein Account wird eingerichtet'**
  String get onboardingLoadingSetup;

  /// Lade-Nachricht 1
  ///
  /// In de, this message translates to:
  /// **'Account wird erstellt ...'**
  String get onboardingLoadingCreating;

  /// Lade-Nachricht 2
  ///
  /// In de, this message translates to:
  /// **'Du wirst angemeldet ...'**
  String get onboardingLoadingSigning;

  /// Lade-Nachricht 3
  ///
  /// In de, this message translates to:
  /// **'Deine Chats werden gesichert ...'**
  String get onboardingLoadingSecuring;

  /// Lade-Nachricht 4
  ///
  /// In de, this message translates to:
  /// **'Dein Foto wird hochgeladen ...'**
  String get onboardingLoadingUploading;

  /// Lade-Nachricht 5
  ///
  /// In de, this message translates to:
  /// **'Fast geschafft ...'**
  String get onboardingLoadingAlmost;

  /// Fehler-Snackbar wenn Bild-Verarbeitung fehlschlägt
  ///
  /// In de, this message translates to:
  /// **'Dein Profilbild konnte nicht verarbeitet werden — du kannst es später im Profil nachtragen.'**
  String get onboardingImageProcessError;

  /// Fehler-Meldung wenn Auto-Login nach Registrierung fehlschlägt
  ///
  /// In de, this message translates to:
  /// **'Dein Konto wurde erstellt, aber der automatische Login hat nicht geklappt. Bitte melde dich auf der Login-Seite an.'**
  String get onboardingLoginFailedAuto;

  /// Begrüßung auf Login-Seite
  ///
  /// In de, this message translates to:
  /// **'Willkommen zurück'**
  String get loginWelcome;

  /// Untertitel auf Login-Seite
  ///
  /// In de, this message translates to:
  /// **'Der Pulse wartet auf dich.'**
  String get loginSubtitle;

  /// Label für Email-Feld auf Login-Seite
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse'**
  String get loginEmailLabel;

  /// Label für Password-Feld auf Login-Seite
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get loginPasswordLabel;

  /// Link zum Passwort zurücksetzen
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen?'**
  String get loginForgotPassword;

  /// Hauptbutton auf Login-Seite
  ///
  /// In de, this message translates to:
  /// **'Zum Feed einloggen'**
  String get loginButton;

  /// Divider-Text für soziale Logins
  ///
  /// In de, this message translates to:
  /// **'ODER WEITER MIT'**
  String get loginDivider;

  /// Google Login Button
  ///
  /// In de, this message translates to:
  /// **'Google'**
  String get loginGoogle;

  /// Apple Login Button
  ///
  /// In de, this message translates to:
  /// **'Apple'**
  String get loginApple;

  /// Text für Sign-Up-Link am Ende von Login-Seite
  ///
  /// In de, this message translates to:
  /// **'Neu bei Ranked?'**
  String get loginNoAccount;

  /// Link zu Onboarding auf Login-Seite
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get loginSignUp;

  /// Fehler-Meldung bei fehlgeschlagenem Login
  ///
  /// In de, this message translates to:
  /// **'Ungültige E-Mail oder Passwort'**
  String get loginInvalidCredentials;

  /// Fehler-Meldung wenn User Key-Setup abbricht
  ///
  /// In de, this message translates to:
  /// **'Anmeldung abgebrochen.'**
  String get loginAborted;

  /// Fehler-Meldung bei Netzwerk/Server-Fehler beim Login
  ///
  /// In de, this message translates to:
  /// **'Verbindung zum Server fehlgeschlagen. Bitte versuche es nochmal.'**
  String get loginServerError;

  /// Titel der Kommentar-Section im Bottom-Sheet
  ///
  /// In de, this message translates to:
  /// **'Kommentare'**
  String get postCommentSectionTitle;

  /// Fehlermeldung, wenn Kommentare nicht geladen werden können
  ///
  /// In de, this message translates to:
  /// **'Kommentare konnten nicht geladen werden'**
  String get postCommentsLoadError;

  /// Nachricht, wenn noch keine Kommentare vorhanden sind
  ///
  /// In de, this message translates to:
  /// **'Sei der Erste, um zu pulsieren!'**
  String get postBeFirstToPulse;

  /// Platzhalter im Kommentar-Eingabefeld
  ///
  /// In de, this message translates to:
  /// **'Schreib einen Kommentar …'**
  String get postCommentHint;

  /// Button-Text zum Bearbeiten des eigenen Posts
  ///
  /// In de, this message translates to:
  /// **'Post bearbeiten'**
  String get postEditButton;

  /// Button-Text zum Löschen des eigenen Posts
  ///
  /// In de, this message translates to:
  /// **'Post löschen'**
  String get postDeleteButton;

  /// Button-Text zum Melden eines fremden Posts
  ///
  /// In de, this message translates to:
  /// **'Post melden'**
  String get postReportButton;

  /// Fehlermeldung, wenn der Messenger nicht verbunden ist
  ///
  /// In de, this message translates to:
  /// **'Messenger nicht bereit — bitte kurz warten und erneut versuchen.'**
  String get shareMessengerNotReady;

  /// Titel des Share-Sheets
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get shareSheetTitle;

  /// Nachricht, wenn der Benutzer noch keine Chats hat
  ///
  /// In de, this message translates to:
  /// **'Noch keine Chats zum Teilen.'**
  String get shareNoChats;

  /// Button zum Kopieren des Post-Links
  ///
  /// In de, this message translates to:
  /// **'Link kopieren'**
  String get shareCopyLink;

  /// Bestätigung, dass der Link kopiert wurde
  ///
  /// In de, this message translates to:
  /// **'Link kopiert'**
  String get shareLinkCopied;

  /// Bestätigung nach dem Versenden eines Posts
  ///
  /// In de, this message translates to:
  /// **'An {username} gesendet!'**
  String shareSentTo(String username);

  /// Fehlermeldung, wenn der Ort nicht gespeichert werden kann
  ///
  /// In de, this message translates to:
  /// **'Ort konnte nicht gespeichert werden'**
  String get feedLocationSaveError;

  /// Label für den globalen Feed
  ///
  /// In de, this message translates to:
  /// **'Für dich'**
  String get feedForYou;

  /// Label für den lokalen Feed
  ///
  /// In de, this message translates to:
  /// **'Lokal'**
  String get feedLocal;

  /// Überschrift im Empty-State, wenn der Benutzer keinen Ort hat
  ///
  /// In de, this message translates to:
  /// **'Kein Ort gesetzt'**
  String get feedNoLocationTitle;

  /// Überschrift im Empty-State, wenn keine Posts vorhanden sind
  ///
  /// In de, this message translates to:
  /// **'Noch nichts los hier'**
  String get feedNoPostsTitle;

  /// Hinweis im Empty-State, wenn der Benutzer keinen Ort gesetzt hat
  ///
  /// In de, this message translates to:
  /// **'Wähle deinen Ort, um Posts aus deiner Umgebung zu sehen.'**
  String get feedChooseLocationHint;

  /// Hinweis im Empty-State, wenn keine Posts am Ort vorhanden sind
  ///
  /// In de, this message translates to:
  /// **'An deinem Ort wurde noch nichts gepostet — sei die/der Erste!'**
  String get feedNoPostsHint;

  /// Button zum Auswählen eines Ortes
  ///
  /// In de, this message translates to:
  /// **'Ort wählen'**
  String get feedChooseLocation;

  /// Label für den Button zum Erstellen einer Story
  ///
  /// In de, this message translates to:
  /// **'Dein Pulse'**
  String get storyRowYourPulse;

  /// Titel der Create-Post-Screen
  ///
  /// In de, this message translates to:
  /// **'Post erstellen'**
  String get createPostTitle;

  /// Titel des Location-Picker-Sheets
  ///
  /// In de, this message translates to:
  /// **'Ort wählen'**
  String get locationPickerTitle;

  /// Platzhalter im Location-Search-Feld
  ///
  /// In de, this message translates to:
  /// **'Stadt suchen …'**
  String get locationSearchHint;

  /// Hinweis am Anfang des Location-Pickers
  ///
  /// In de, this message translates to:
  /// **'Tippe, um deine Stadt zu suchen'**
  String get locationSearchStartHint;

  /// Nachricht, wenn bei der Ortssuche keine Ergebnisse gefunden werden
  ///
  /// In de, this message translates to:
  /// **'Keinen Ort gefunden — probier eine andere Schreibweise'**
  String get locationNotFound;

  /// Titel des Ranking Opt-In Screens
  ///
  /// In de, this message translates to:
  /// **'MACH MIT BEIM\nRANKING'**
  String get rankingOptinTitle;

  /// Beschreibungstext des Ranking Opt-In Screens
  ///
  /// In de, this message translates to:
  /// **'Aktiviere das Ranking und lass dich täglich von der Community bewerten — Productivity, Creativity & Engagement.'**
  String get rankingOptinDescription;

  /// Button zum Aktivieren des Rankings
  ///
  /// In de, this message translates to:
  /// **'AKTIVIEREN'**
  String get rankingOptinButton;

  /// Header für persönliche Ranking-Statistiken
  ///
  /// In de, this message translates to:
  /// **'DEINE STATS'**
  String get rankingStatsHeader;

  /// Label für heute erhaltene Punkte in Bento Card
  ///
  /// In de, this message translates to:
  /// **'PUNKTE HEUTE'**
  String get rankingPointsToday;

  /// Label für Streak-Zähler in Bento Card
  ///
  /// In de, this message translates to:
  /// **'DEIN STREAK'**
  String get rankingStreakLabel;

  /// Label über dem Nutzernamen beim Swipen
  ///
  /// In de, this message translates to:
  /// **'DU BEWERTEST'**
  String get rankingEvaluatingLabel;

  /// Badge-Text in der Leaderboard-Zeile des Nutzers
  ///
  /// In de, this message translates to:
  /// **'DU'**
  String get rankingYourBadge;

  /// Headline wenn der Nutzer heute noch keine Punkte hat
  ///
  /// In de, this message translates to:
  /// **'Noch keine Punkte heute'**
  String get rankingNoPointsHeadline;

  /// Subline wenn der Nutzer heute noch keine Punkte hat
  ///
  /// In de, this message translates to:
  /// **'Poste, um bewertet zu werden'**
  String get rankingNoPointsSubline;

  /// Headline wenn der Nutzer Platz 1 hat
  ///
  /// In de, this message translates to:
  /// **'Du führst heute!'**
  String get rankingLeadingHeadline;

  /// Subline wenn der Nutzer Platz 1 hat
  ///
  /// In de, this message translates to:
  /// **'Verteidge deinen Platz'**
  String get rankingLeadingSubline;

  /// Headline wenn der Nutzer einen anderen Platz hat
  ///
  /// In de, this message translates to:
  /// **'Platz #{rank}'**
  String rankingMyRank(int rank);

  /// Empty state wenn noch keine Leaderboard-Einträge vorhanden sind
  ///
  /// In de, this message translates to:
  /// **'Noch keine Rankings heute'**
  String get rankingEmptyLeaderboard;

  /// Button label wenn der Nutzer bereits heute gerankt hat
  ///
  /// In de, this message translates to:
  /// **'HEUTE SCHON GEWERTET'**
  String get rankingAlreadyRankedButton;

  /// Button zum Starten einer Ranking-Session
  ///
  /// In de, this message translates to:
  /// **'FINDE DEINEN RANKING-PARTNER'**
  String get rankingGetPartnerButton;

  /// Empty state wenn keine Teilnehmer zum Bewerten vorhanden sind
  ///
  /// In de, this message translates to:
  /// **'Aktuell keine Teilnehmer zum Bewerten verfügbar.'**
  String get rankingNoParticipants;

  /// Label für Like-Swipe Aktion
  ///
  /// In de, this message translates to:
  /// **'LIKE'**
  String get rankingSwipeLike;

  /// Label für Nope-Swipe Aktion
  ///
  /// In de, this message translates to:
  /// **'NOPE'**
  String get rankingSwipeNope;

  /// Label auf dem Result Screen nach dem Swipen
  ///
  /// In de, this message translates to:
  /// **'PUNKTE VERGEBEN'**
  String get rankingResultLabel;

  /// Button zum Schließen des Result Screens
  ///
  /// In de, this message translates to:
  /// **'FERTIG'**
  String get rankingResultDone;

  /// Error Headline wenn der Nutzer bereits heute gewertet hat
  ///
  /// In de, this message translates to:
  /// **'BEREITS\nGEWERTET'**
  String get rankingAlreadyVotedHeadline;

  /// Error Headline für allgemeine Fehler
  ///
  /// In de, this message translates to:
  /// **'FEHLER'**
  String get rankingErrorHeadline;

  /// Error Message wenn der Nutzer bereits heute gewertet hat
  ///
  /// In de, this message translates to:
  /// **'Du hast heute schon abgestimmt.\nMorgen bist du wieder dran!'**
  String get rankingAlreadyVotedMessage;

  /// Standard Error Message für Fehler beim Ranking
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen. Versuch es später nochmal.'**
  String get rankingErrorMessage;

  /// Button zum Zurückgehen vom Error Screen
  ///
  /// In de, this message translates to:
  /// **'ZURÜCK'**
  String get rankingBackButton;

  /// Empty state in activity section of profile
  ///
  /// In de, this message translates to:
  /// **'Noch keine Aktivität — sobald dich jemand bewertet, steht es hier.'**
  String get profileNoActivity;

  /// Activity item title for rating
  ///
  /// In de, this message translates to:
  /// **'Du wurdest bewertet'**
  String get profileActivityRated;

  /// Default activity item title
  ///
  /// In de, this message translates to:
  /// **'Neue Aktivität'**
  String get profileActivityDefault;

  /// Activity subtitle showing points earned
  ///
  /// In de, this message translates to:
  /// **'+{points} Punkte von der Community erhalten'**
  String profileActivityRatedSubtitle(int points);

  /// Message when user reaches max league
  ///
  /// In de, this message translates to:
  /// **'Höchste Liga erreicht'**
  String get profileLeagueMaxReached;

  /// League progress message with XP remaining
  ///
  /// In de, this message translates to:
  /// **'Noch {xp} XP bis {next}'**
  String profileLeagueProgress(int xp, String next);

  /// Follow button text
  ///
  /// In de, this message translates to:
  /// **'Folgen'**
  String get profileFollow;

  /// Following button text
  ///
  /// In de, this message translates to:
  /// **'Gefolgt'**
  String get profileFollowing;

  /// Settings screen title
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// Appearance section label in settings
  ///
  /// In de, this message translates to:
  /// **'DARSTELLUNG'**
  String get settingsSectionAppearance;

  /// Dark mode setting title
  ///
  /// In de, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// Dark mode setting subtitle
  ///
  /// In de, this message translates to:
  /// **'Dunkles Erscheinungsbild'**
  String get settingsDarkModeSubtitle;

  /// Profile section label in settings
  ///
  /// In de, this message translates to:
  /// **'PROFIL'**
  String get settingsSectionProfile;

  /// Location setting title
  ///
  /// In de, this message translates to:
  /// **'Standort'**
  String get settingsLocation;

  /// Location loading state
  ///
  /// In de, this message translates to:
  /// **'Wird geladen …'**
  String get settingsLocationLoading;

  /// Location not set message
  ///
  /// In de, this message translates to:
  /// **'Kein Ort gesetzt'**
  String get settingsLocationNotSet;

  /// Tooltip for remove location button
  ///
  /// In de, this message translates to:
  /// **'Standort entfernen'**
  String get settingsRemoveLocation;

  /// Error message when saving location fails
  ///
  /// In de, this message translates to:
  /// **'Ort konnte nicht gespeichert werden.'**
  String get settingsLocationFailed;

  /// Confirmation dialog title for removing location
  ///
  /// In de, this message translates to:
  /// **'Standort entfernen?'**
  String get settingsClearLocationTitle;

  /// Confirmation dialog message for removing location
  ///
  /// In de, this message translates to:
  /// **'Ohne Standort kannst du den lokalen Feed nicht nutzen, bis du wieder einen Ort waehlst.'**
  String get settingsClearLocationMessage;

  /// Confirmation button for removing location
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get settingsClearLocationButton;

  /// Error message when removing location fails
  ///
  /// In de, this message translates to:
  /// **'Entfernen fehlgeschlagen. Bitte erneut versuchen.'**
  String get settingsClearLocationError;

  /// Privacy section label in settings (blocked accounts etc.)
  ///
  /// In de, this message translates to:
  /// **'PRIVATSPHÄRE'**
  String get settingsSectionPrivacy;

  /// Settings tile that opens the blocked accounts list
  ///
  /// In de, this message translates to:
  /// **'Blockierte Konten'**
  String get settingsBlockedAccounts;

  /// Subtitle of the blocked accounts tile
  ///
  /// In de, this message translates to:
  /// **'Blockierungen ansehen und aufheben'**
  String get settingsBlockedAccountsSubtitle;

  /// Header of the blocked accounts screen
  ///
  /// In de, this message translates to:
  /// **'Blockierte Konten'**
  String get blockedTitle;

  /// Empty state of the blocked accounts list
  ///
  /// In de, this message translates to:
  /// **'Du hast niemanden blockiert.'**
  String get blockedEmpty;

  /// Error state when GET /users/blocked fails
  ///
  /// In de, this message translates to:
  /// **'Die Liste konnte nicht geladen werden.'**
  String get blockedLoadFailed;

  /// Retry button in the error state
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get blockedRetry;

  /// Subtitle per row; date is already formatted
  ///
  /// In de, this message translates to:
  /// **'Blockiert am {date}'**
  String blockedSince(String date);

  /// Button per row to unblock a user
  ///
  /// In de, this message translates to:
  /// **'Aufheben'**
  String get blockedUnblock;

  /// Title of the unblock confirm dialog
  ///
  /// In de, this message translates to:
  /// **'{name} nicht mehr blockieren?'**
  String blockedUnblockTitle(String name);

  /// Message of the unblock confirm dialog
  ///
  /// In de, this message translates to:
  /// **'{name} kann dir dann wieder schreiben und deine Inhalte sehen.'**
  String blockedUnblockMessage(String name);

  /// Snackbar after a successful unblock
  ///
  /// In de, this message translates to:
  /// **'{name} ist nicht mehr blockiert.'**
  String blockedUnblocked(String name);

  /// Snackbar when unblocking fails
  ///
  /// In de, this message translates to:
  /// **'Aufheben fehlgeschlagen. Versuch es erneut.'**
  String get blockedUnblockFailed;

  /// Legal section label in settings
  ///
  /// In de, this message translates to:
  /// **'RECHTLICHES'**
  String get settingsSectionLegal;

  /// Privacy/GDPR setting title
  ///
  /// In de, this message translates to:
  /// **'Datenschutz (DSGVO)'**
  String get settingsPrivacy;

  /// Privacy setting subtitle
  ///
  /// In de, this message translates to:
  /// **'Wie wir mit deinen Daten umgehen'**
  String get settingsPrivacySubtitle;

  /// Account section label in settings
  ///
  /// In de, this message translates to:
  /// **'KONTO'**
  String get settingsSectionAccount;

  /// Logout button text
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get settingsLogout;

  /// Delete account button text
  ///
  /// In de, this message translates to:
  /// **'Account löschen'**
  String get settingsDeleteAccount;

  /// Logout confirmation dialog title
  ///
  /// In de, this message translates to:
  /// **'Abmelden?'**
  String get settingsLogoutTitle;

  /// Logout confirmation dialog message
  ///
  /// In de, this message translates to:
  /// **'Du wirst von diesem Gerät abgemeldet.'**
  String get settingsLogoutMessage;

  /// Delete account confirmation dialog title
  ///
  /// In de, this message translates to:
  /// **'Account löschen?'**
  String get settingsDeleteAccountTitle;

  /// Delete account confirmation dialog message
  ///
  /// In de, this message translates to:
  /// **'Dein Account, alle Posts, Votes und Kommentare werden dauerhaft gelöscht. Das lässt sich nicht rückgängig machen.'**
  String get settingsDeleteAccountMessage;

  /// Delete account confirmation button
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get settingsDeleteAccountButton;

  /// Error message when account deletion fails
  ///
  /// In de, this message translates to:
  /// **'Löschen fehlgeschlagen. Bitte später erneut versuchen.'**
  String get settingsDeleteFailed;

  /// Generic cancel button in settings dialogs
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get settingsCancelButton;

  /// GDPR/Privacy screen title
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get settingsDsgvoTitle;

  /// Confirmation dialog title for clearing search history
  ///
  /// In de, this message translates to:
  /// **'Suchverlauf löschen?'**
  String get searchClearHistoryTitle;

  /// Confirmation dialog message for clearing search history
  ///
  /// In de, this message translates to:
  /// **'Dies entfernt alle kürzlichen Suchen von diesem Gerät.'**
  String get searchClearHistoryMessage;

  /// Cancel button in search dialogs
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get searchCancelButton;

  /// Clear button in search history
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get searchClearButton;

  /// Search input placeholder
  ///
  /// In de, this message translates to:
  /// **'Nutzer suchen'**
  String get searchPlaceholder;

  /// Message when no users match search
  ///
  /// In de, this message translates to:
  /// **'Keine Nutzer gefunden'**
  String get searchNoUsersFound;

  /// Hint when query is too short
  ///
  /// In de, this message translates to:
  /// **'Mindestens 2 Zeichen eintippen'**
  String get searchMinCharacters;

  /// Recent searches header
  ///
  /// In de, this message translates to:
  /// **'Kürzlich'**
  String get searchHistoryRecent;

  /// Empty state title for search history
  ///
  /// In de, this message translates to:
  /// **'Keine kürzlichen Suchen'**
  String get searchHistoryEmpty;

  /// Empty state message for search history
  ///
  /// In de, this message translates to:
  /// **'Erkunde die App – deine letzten Suchen\nwerden hier angezeigt.'**
  String get searchHistoryEmptyMessage;

  /// Dialog title for restoring chats from backup
  ///
  /// In de, this message translates to:
  /// **'Chats wiederherstellen'**
  String get keyRestoreTitle;

  /// Dialog message for restoring chats
  ///
  /// In de, this message translates to:
  /// **'Deine Chats wurden mit einem anderen Passwort gesichert. Gib dein vorheriges Passwort ein, um sie wiederherzustellen.'**
  String get keyRestoreMessage;

  /// Label for password input in restore dialog
  ///
  /// In de, this message translates to:
  /// **'Vorheriges Passwort'**
  String get keyRestorePasswordLabel;

  /// Error message for incorrect backup password
  ///
  /// In de, this message translates to:
  /// **'Das Passwort passt nicht. Versuch es nochmal.'**
  String get keyRestoreWrongPassword;

  /// Button to restore chats
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get keyRestoreButton;

  /// Cancel button in key restore dialogs
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get keyRestoreCancelButton;

  /// Emergency option to reset chats without password
  ///
  /// In de, this message translates to:
  /// **'Passwort vergessen? Chats zurücksetzen'**
  String get keyRestoreForgotPassword;

  /// Dialog title for emergency chat reset
  ///
  /// In de, this message translates to:
  /// **'Chats zurücksetzen?'**
  String get keyRestoreResetTitle;

  /// Warning message for emergency chat reset
  ///
  /// In de, this message translates to:
  /// **'Das lässt sich nicht rückgängig machen. Bitte lies kurz, was passiert:'**
  String get keyRestoreResetMessage;

  /// First consequence of chat reset
  ///
  /// In de, this message translates to:
  /// **'Deine bisherigen Nachrichten sind auf allen Geräten nicht mehr lesbar.'**
  String get keyRestoreResetConsequence1;

  /// Second consequence of chat reset
  ///
  /// In de, this message translates to:
  /// **'Andere angemeldete Geräte werden abgemeldet.'**
  String get keyRestoreResetConsequence2;

  /// Third consequence/positive note of chat reset
  ///
  /// In de, this message translates to:
  /// **'Neue Chats funktionieren ganz normal.'**
  String get keyRestoreResetConsequence3;

  /// Button to execute emergency chat reset
  ///
  /// In de, this message translates to:
  /// **'Chats zurücksetzen'**
  String get keyRestoreResetButton;

  /// Dialog title for recovering lost post draft
  ///
  /// In de, this message translates to:
  /// **'Entwurf wiederherstellen?'**
  String get appDraftRestoreTitle;

  /// Dialog message for recovering lost post draft
  ///
  /// In de, this message translates to:
  /// **'Du hast einen unfertigen Post.'**
  String get appDraftRestoreMessage;

  /// Button to discard post draft
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get appDraftDiscardButton;

  /// Button to restore post draft
  ///
  /// In de, this message translates to:
  /// **'Wiederherstellen'**
  String get appDraftRestoreButton;

  /// Snackbar when story deletion fails
  ///
  /// In de, this message translates to:
  /// **'Story konnte nicht gelöscht werden'**
  String get storyDeleteFailedSnackbar;

  /// Header text in viewer for own story
  ///
  /// In de, this message translates to:
  /// **'Deine Story'**
  String get storyYourStory;

  /// Title in delete sheet of story viewer
  ///
  /// In de, this message translates to:
  /// **'Story löschen'**
  String get storyDeleteTitle;

  /// Cancel button in delete sheet
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get storyDeleteCancel;

  /// Error when formatting image to 9:16 aspect ratio
  ///
  /// In de, this message translates to:
  /// **'Bild konnte nicht verarbeitet werden'**
  String get storyProcessingError;

  /// Error when uploading story
  ///
  /// In de, this message translates to:
  /// **'Story-Upload fehlgeschlagen'**
  String get storyUploadError;

  /// Header in create screen
  ///
  /// In de, this message translates to:
  /// **'Neue Story'**
  String get storyCreateTitle;

  /// Hero text in create screen
  ///
  /// In de, this message translates to:
  /// **'Teile deinen Moment'**
  String get storyShareMoment;

  /// Description text in create screen
  ///
  /// In de, this message translates to:
  /// **'Erstelle in Sekunden eine Story für deine Follower.'**
  String get storyCreateDescription;

  /// Badge text above button row
  ///
  /// In de, this message translates to:
  /// **'24H sichtbar'**
  String get storyVisibleTime;

  /// Label of gallery source card
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get storySourceGallery;

  /// Subtitle of gallery source card
  ///
  /// In de, this message translates to:
  /// **'Bild wählen'**
  String get storySourceGallerySubtitle;

  /// Label of camera source card
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get storySourceCamera;

  /// Subtitle of camera source card
  ///
  /// In de, this message translates to:
  /// **'Live aufnehmen'**
  String get storySourceCameraSubtitle;

  /// Button text while uploading
  ///
  /// In de, this message translates to:
  /// **'Wird geteilt...'**
  String get storyUploadingButton;

  /// Button text for sharing story
  ///
  /// In de, this message translates to:
  /// **'Story teilen'**
  String get storyShareButton;

  /// Title of the suspended screen
  ///
  /// In de, this message translates to:
  /// **'Konto gesperrt'**
  String get suspendedTitle;

  /// Temporary suspension; date is already formatted (date + time)
  ///
  /// In de, this message translates to:
  /// **'Dein Konto ist bis {date} gesperrt.'**
  String suspendedUntil(String date);

  /// Permanent suspension (banned_until year 9999)
  ///
  /// In de, this message translates to:
  /// **'Dein Konto ist dauerhaft gesperrt.'**
  String get suspendedPermanent;

  /// Small label above the ban reason
  ///
  /// In de, this message translates to:
  /// **'GRUND'**
  String get suspendedReasonLabel;

  /// Hint below a temporary suspension
  ///
  /// In de, this message translates to:
  /// **'Danach kannst du dich wieder ganz normal anmelden.'**
  String get suspendedHint;

  /// Button on the suspended screen
  ///
  /// In de, this message translates to:
  /// **'Zurück zum Login'**
  String get suspendedBack;

  /// Moderation section label in settings, only visible for moderators/admins
  ///
  /// In de, this message translates to:
  /// **'MODERATION'**
  String get settingsSectionModeration;

  /// Settings tile that opens the moderation area
  ///
  /// In de, this message translates to:
  /// **'Moderation'**
  String get settingsModeration;

  /// Subtitle of the moderation tile
  ///
  /// In de, this message translates to:
  /// **'Meldungen prüfen'**
  String get settingsModerationSubtitle;

  /// Title of the moderation home screen
  ///
  /// In de, this message translates to:
  /// **'Moderation'**
  String get moderationTitle;

  /// Tab in the moderation area: report queue
  ///
  /// In de, this message translates to:
  /// **'Meldungen'**
  String get moderationTabReports;

  /// Tab in the moderation area: audit log (admins only)
  ///
  /// In de, this message translates to:
  /// **'Protokoll'**
  String get moderationTabAudit;

  /// Report queue filter chip: pending reports
  ///
  /// In de, this message translates to:
  /// **'Offen'**
  String get moderationFilterPending;

  /// Report queue filter chip: dismissed reports
  ///
  /// In de, this message translates to:
  /// **'Abgelehnt'**
  String get moderationFilterDismissed;

  /// Report queue filter chip: reports where action was taken
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get moderationFilterActionTaken;

  /// Empty state of the pending report queue
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Meldungen. Alles sauber!'**
  String get moderationEmptyPending;

  /// Empty state of the dismissed report list
  ///
  /// In de, this message translates to:
  /// **'Noch keine abgelehnten Meldungen.'**
  String get moderationEmptyDismissed;

  /// Empty state of the action-taken report list
  ///
  /// In de, this message translates to:
  /// **'Noch keine erledigten Meldungen.'**
  String get moderationEmptyActionTaken;

  /// Error state of the report queue
  ///
  /// In de, this message translates to:
  /// **'Die Meldungen konnten nicht geladen werden.'**
  String get moderationLoadFailed;

  /// Retry button in the report queue (first load and load more)
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get moderationRetry;

  /// How many reports a queue entry has
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Meldung} other{{count} Meldungen}}'**
  String moderationReportCount(int count);

  /// When the newest report came in (queue card header)
  ///
  /// In de, this message translates to:
  /// **'zuletzt {date}'**
  String moderationLastReported(String date);

  /// Badge on a queue card: the reported user is currently banned
  ///
  /// In de, this message translates to:
  /// **'Gesperrt'**
  String get moderationBanned;

  /// Badge on a queue card: the reported user is banned forever
  ///
  /// In de, this message translates to:
  /// **'Dauerhaft gesperrt'**
  String get moderationBannedPermanent;

  /// Queue card: the user deleted the content, the text shown is the copy from the time of the report
  ///
  /// In de, this message translates to:
  /// **'Vom User gelöscht – Stand beim Melden'**
  String get moderationContentDeleted;

  /// Queue card: the server sent no preview
  ///
  /// In de, this message translates to:
  /// **'Keine Vorschau verfügbar'**
  String get moderationNoPreview;

  /// Queue card: expands the free-text notes the reporters wrote
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Anmerkung anzeigen} other{{count} Anmerkungen anzeigen}}'**
  String moderationShowDetails(int count);

  /// Queue card: collapses the reporters' notes again
  ///
  /// In de, this message translates to:
  /// **'Anmerkungen ausblenden'**
  String get moderationHideDetails;

  /// Queue card button: the reports were unfounded (status dismissed)
  ///
  /// In de, this message translates to:
  /// **'Kein Verstoß'**
  String get moderationDismiss;

  /// Queue card button: opens the sheet with the possible actions (remove, ban, unban, mark as done)
  ///
  /// In de, this message translates to:
  /// **'Eingreifen'**
  String get moderationTakeAction;

  /// Title of the action sheet opened by 'Take action' on a queue card
  ///
  /// In de, this message translates to:
  /// **'Was möchtest du tun?'**
  String get moderationActionSheetTitle;

  /// Action sheet: explanation under 'Remove post/comment/story'
  ///
  /// In de, this message translates to:
  /// **'Für alle ausgeblendet. Die Meldungen gelten damit als erledigt.'**
  String get moderationActionRemoveHint;

  /// Action sheet: explanation under 'Remove profile picture'
  ///
  /// In de, this message translates to:
  /// **'Name und Bio bleiben. Die Meldungen bleiben offen.'**
  String get moderationActionRemovePictureHint;

  /// Action sheet: explanation under 'Ban {username}'
  ///
  /// In de, this message translates to:
  /// **'Die Person wird abgemeldet und kann sich bis zum Ende der Sperre nicht anmelden. Die Meldungen bleiben offen.'**
  String get moderationActionBanHint;

  /// Action sheet: explanation under 'Just mark as done' (status action_taken)
  ///
  /// In de, this message translates to:
  /// **'Z. B. wenn es schon anders geklärt ist. Die Karte wandert zu „Erledigt“.'**
  String get moderationActionMarkDoneHint;

  /// Action sheet: hint when the reported user has the same or a higher role
  ///
  /// In de, this message translates to:
  /// **'Gleicher oder höherer Rang als du. Du kannst die Meldungen nur als erledigt markieren.'**
  String get moderationActionRestricted;

  /// Action sheet option: mark the reports as handled without removing or banning (status action_taken)
  ///
  /// In de, this message translates to:
  /// **'Nur als erledigt markieren'**
  String get moderationMarkDone;

  /// Snackbar when dismissing / marking a report as done failed
  ///
  /// In de, this message translates to:
  /// **'Konnte nicht gespeichert werden. Versuch es nochmal.'**
  String get moderationResolveFailed;

  /// Title of the moderator removal sheet for a post
  ///
  /// In de, this message translates to:
  /// **'Beitrag entfernen'**
  String get moderationRemoveTitlePost;

  /// Title of the moderator removal sheet for a comment
  ///
  /// In de, this message translates to:
  /// **'Kommentar entfernen'**
  String get moderationRemoveTitleComment;

  /// Title of the moderator removal sheet for a story
  ///
  /// In de, this message translates to:
  /// **'Story entfernen'**
  String get moderationRemoveTitleStory;

  /// Title of the moderator removal sheet for a profile picture (reported user)
  ///
  /// In de, this message translates to:
  /// **'Profilbild entfernen'**
  String get moderationRemoveTitleProfilePicture;

  /// Section label above the reason chips in the removal sheet
  ///
  /// In de, this message translates to:
  /// **'Grund'**
  String get moderationRemoveReasonLabel;

  /// Hint of the optional details field in the removal sheet; the affected user sees this text (GET /users/moderation) and it goes into the audit log
  ///
  /// In de, this message translates to:
  /// **'Begründung für die Person (optional)'**
  String get moderationRemoveDetailsHint;

  /// Info line above the remove button; content is archived for 180 days, not deleted
  ///
  /// In de, this message translates to:
  /// **'Für alle sofort ausgeblendet. Ein Admin kann es 180 Tage lang wiederherstellen.'**
  String get moderationRemoveHint;

  /// Confirm button of the removal sheet
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get moderationRemoveConfirm;

  /// Placeholder until the audit log is built
  ///
  /// In de, this message translates to:
  /// **'Hier erscheint bald das Protokoll aller Moderations-Aktionen.'**
  String get moderationAuditPlaceholder;

  /// Title of the ban sheet
  ///
  /// In de, this message translates to:
  /// **'{username} sperren'**
  String moderationBanTitle(String username);

  /// Section label above the duration chips in the ban sheet
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get moderationBanDurationLabel;

  /// Duration chip in the ban sheet
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tage}}'**
  String moderationBanDays(int count);

  /// Duration chip for a permanent ban (admins only)
  ///
  /// In de, this message translates to:
  /// **'Dauerhaft'**
  String get moderationBanPermanent;

  /// Section label above the required reason field in the ban sheet
  ///
  /// In de, this message translates to:
  /// **'Begründung'**
  String get moderationBanReasonLabel;

  /// Hint of the required reason field; the banned user sees it on the suspended screen
  ///
  /// In de, this message translates to:
  /// **'Die Person sieht diesen Text beim Login'**
  String get moderationBanReasonHint;

  /// Info line above the ban button when the user is not banned yet
  ///
  /// In de, this message translates to:
  /// **'Die Person wird sofort abgemeldet.'**
  String get moderationBanHintNew;

  /// Info line above the ban button when the user is already banned
  ///
  /// In de, this message translates to:
  /// **'Ersetzt die laufende Sperre.'**
  String get moderationBanHintReplace;

  /// Confirm button of the ban sheet
  ///
  /// In de, this message translates to:
  /// **'Sperren'**
  String get moderationBanConfirm;

  /// Button on a report card to lift the reported user's ban
  ///
  /// In de, this message translates to:
  /// **'Entsperren'**
  String get moderationUnban;

  /// Snackbar after banning a user from the report queue
  ///
  /// In de, this message translates to:
  /// **'{username} wurde gesperrt'**
  String moderationUserBanned(String username);

  /// Snackbar when the backend answers 403 to a moderation action (rank rule or moderator limit)
  ///
  /// In de, this message translates to:
  /// **'Dafür fehlt dir die Berechtigung'**
  String get moderationForbidden;

  /// Snackbar when a moderation action (remove, ban, unban) failed
  ///
  /// In de, this message translates to:
  /// **'Aktion fehlgeschlagen. Bitte versuche es erneut.'**
  String get moderationActionFailed;

  /// Title of the confirm dialog before lifting a ban
  ///
  /// In de, this message translates to:
  /// **'{username} entsperren?'**
  String moderationUnbanTitle(String username);

  /// Message of the confirm dialog before lifting a ban
  ///
  /// In de, this message translates to:
  /// **'Die Person kann sich sofort wieder anmelden.'**
  String get moderationUnbanMessage;

  /// Snackbar after lifting a ban from the report queue
  ///
  /// In de, this message translates to:
  /// **'{username} wurde entsperrt'**
  String moderationUserUnbanned(String username);

  /// Snackbar after a moderator removed a post, comment or story
  ///
  /// In de, this message translates to:
  /// **'Inhalt entfernt'**
  String get moderationContentRemoved;

  /// Snackbar after a moderator removed a profile picture; the user reports stay open because they may concern name or bio
  ///
  /// In de, this message translates to:
  /// **'Profilbild entfernt. Die Meldungen bleiben offen.'**
  String get moderationPictureRemoved;

  /// Title of the screen listing moderation actions against the current user (GET /users/moderation)
  ///
  /// In de, this message translates to:
  /// **'Kontostatus'**
  String get accountStatusTitle;

  /// Empty state of the account status screen
  ///
  /// In de, this message translates to:
  /// **'Gegen dich liegen keine Maßnahmen vor.'**
  String get accountStatusEmpty;

  /// Error state / snackbar when loading the account status failed
  ///
  /// In de, this message translates to:
  /// **'Dein Kontostatus konnte nicht geladen werden.'**
  String get accountStatusLoadFailed;

  /// Account status card title: a moderator removed one of your posts
  ///
  /// In de, this message translates to:
  /// **'Beitrag entfernt'**
  String get accountStatusRemovedPost;

  /// Account status card title: a moderator removed one of your comments
  ///
  /// In de, this message translates to:
  /// **'Kommentar entfernt'**
  String get accountStatusRemovedComment;

  /// Account status card title: a moderator removed one of your stories
  ///
  /// In de, this message translates to:
  /// **'Story entfernt'**
  String get accountStatusRemovedStory;

  /// Account status card title: a moderator removed your profile picture
  ///
  /// In de, this message translates to:
  /// **'Profilbild entfernt'**
  String get accountStatusRemovedPicture;

  /// Account status card title for a temporary ban
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Konto für 1 Tag gesperrt} other{Konto für {count} Tage gesperrt}}'**
  String accountStatusBanned(int count);

  /// Account status card title for a permanent ban
  ///
  /// In de, this message translates to:
  /// **'Konto dauerhaft gesperrt'**
  String get accountStatusBannedPermanent;

  /// Badge on an account status card: an admin restored the removed content
  ///
  /// In de, this message translates to:
  /// **'Wiederhergestellt'**
  String get accountStatusRestored;

  /// Account status card: label above the reason (category or ban text)
  ///
  /// In de, this message translates to:
  /// **'Grund'**
  String get accountStatusReasonLabel;

  /// Account status card: label above the optional explanation the moderator wrote
  ///
  /// In de, this message translates to:
  /// **'Hinweis der Moderation'**
  String get accountStatusNoteLabel;

  /// Account status card: label above the text copy of the removed content
  ///
  /// In de, this message translates to:
  /// **'Dein Inhalt'**
  String get accountStatusSnapshotLabel;

  /// Subtitle of the account status tile in settings
  ///
  /// In de, this message translates to:
  /// **'Entfernte Inhalte und Sperren'**
  String get settingsAccountStatusSubtitle;

  /// Activity item title: a moderator removed some of your content
  ///
  /// In de, this message translates to:
  /// **'Inhalt entfernt'**
  String get profileActivityContentRemoved;

  /// Activity item title: an admin restored previously removed content
  ///
  /// In de, this message translates to:
  /// **'Inhalt wiederhergestellt'**
  String get profileActivityContentRestored;

  /// Activity item subtitle for moderation events; tapping opens the account status screen
  ///
  /// In de, this message translates to:
  /// **'Tippe für Details'**
  String get profileActivityModerationSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
