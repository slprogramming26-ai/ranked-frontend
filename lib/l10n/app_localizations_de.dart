// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ranked';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Belästigung oder Mobbing';

  @override
  String get reportReasonInappropriate => 'Unangemessener Inhalt';

  @override
  String get reportReasonMisinformation => 'Falschinformation';

  @override
  String get reportReasonOther => 'Sonstiges';

  @override
  String get reportTitlePost => 'Post melden';

  @override
  String get reportTitleStory => 'Story melden';

  @override
  String get reportTitleComment => 'Kommentar melden';

  @override
  String get reportTitleUser => 'Profil melden';

  @override
  String get reportSuccessPost =>
      'Danke! Der Post wird dir nicht mehr angezeigt.';

  @override
  String get reportSuccessStory =>
      'Danke! Die Story wird dir nicht mehr angezeigt.';

  @override
  String get reportSuccessComment =>
      'Danke! Der Kommentar wird dir nicht mehr angezeigt.';

  @override
  String get reportSuccessUser => 'Danke! Wir schauen uns das an.';

  @override
  String get reportAlreadyPost => 'Du hast diesen Post bereits gemeldet.';

  @override
  String get reportAlreadyStory => 'Du hast diese Story bereits gemeldet.';

  @override
  String get reportAlreadyComment =>
      'Du hast diesen Kommentar bereits gemeldet.';

  @override
  String get reportAlreadyUser => 'Du hast dieses Profil bereits gemeldet.';

  @override
  String get reportDetailsHint => 'Was ist passiert? (optional)';

  @override
  String get reportSend => 'Senden';

  @override
  String get reportFailed => 'Melden fehlgeschlagen. Versuch es später erneut.';

  @override
  String get commentDeleteTitle => 'Kommentar löschen?';

  @override
  String get commentDeleteMessage => 'Der Kommentar wird endgültig entfernt.';

  @override
  String get commentDeleteConfirm => 'Löschen';

  @override
  String get commentDeleteFailed =>
      'Löschen fehlgeschlagen. Versuch es später erneut.';

  @override
  String get profileMenuReport => 'Melden';

  @override
  String profileBlocked(String name) {
    return '$name wurde blockiert.';
  }

  @override
  String get profileBlockFailed =>
      'Blockieren fehlgeschlagen. Versuch es erneut.';

  @override
  String get postDeleteFailed =>
      'Löschen fehlgeschlagen. Versuch es später erneut.';

  @override
  String get messengerGroupCreateFailed => 'Fehler beim Erstellen der Gruppe.';

  @override
  String get messengerJoinFailed =>
      'Beitritt fehlgeschlagen. Ist der Code noch gültig?';

  @override
  String get messengerJoinGroupTitle => 'Gruppe beitreten';

  @override
  String get messengerJoinGroupSubtitle => 'Mit Einladungs-Code einsteigen';

  @override
  String get messengerInviteCodeHint => 'Einladungs-Code';

  @override
  String get messengerCancel => 'Abbrechen';

  @override
  String get messengerJoin => 'Beitreten';

  @override
  String get messengerNewConversation => 'Neue Konversation';

  @override
  String get messengerStartChat => 'Chat starten';

  @override
  String get messengerStartChatSubtitle => 'User per Name suchen';

  @override
  String get messengerCreateGroup => 'Gruppe erstellen';

  @override
  String get messengerCreateGroupSubtitle => 'Neue Gruppe anlegen';

  @override
  String get messengerContactsTitle => 'Kontakte';

  @override
  String get messengerRequests => 'Anfragen';

  @override
  String get messengerGroupChat => 'Gruppenchat';

  @override
  String get messengerDirectMessage => 'Direktnachricht';

  @override
  String get messengerEmptyTitle => 'Keine Konversationen';

  @override
  String get messengerEmptyHint =>
      'Tipp auf das Stift-Symbol,\num einen Chat oder eine Gruppe zu starten.';

  @override
  String get messengerSearchUsernameHint => 'Username suchen';

  @override
  String get messengerMinChars => 'Mindestens 2 Zeichen eingeben';

  @override
  String get messengerSomethingWrong => 'Etwas ist schiefgelaufen.';

  @override
  String get messengerNoUsersFound => 'Keine User gefunden';

  @override
  String get chatRequestsWantsToWrite => 'Möchte dir schreiben';

  @override
  String get chatRequestsEmptyTitle => 'Alles erledigt';

  @override
  String get chatRequestsEmptyHint => 'Keine offenen Chat-Anfragen.';

  @override
  String get chatEncrypted => 'Ende-zu-Ende verschlüsselt';

  @override
  String get chatPostUnavailable => 'Post nicht verfügbar';

  @override
  String get chatUnknownUser => 'Unbekannt';

  @override
  String get chatGroupInvite => 'Gruppeneinladung';

  @override
  String chatInviteCode(int code) {
    return 'Code $code';
  }

  @override
  String get chatJoined => 'Beigetreten';

  @override
  String get chatMessageHint => 'Nachricht…';

  @override
  String get chatAcceptToReply =>
      'Nimm die Anfrage an, um antworten zu können.';

  @override
  String get chatDecline => 'Ablehnen';

  @override
  String get chatAccept => 'Annehmen';

  @override
  String get chatDeclineDialogTitle => 'Anfrage ablehnen?';

  @override
  String chatDeclineDialogBody(String username) {
    return 'Der Chat wird aus deiner Liste entfernt. Ohne Blockieren kann $username dir aber erneut eine Anfrage schicken.';
  }

  @override
  String get chatDeclineAndBlock => 'Ablehnen & blockieren';

  @override
  String get chatDeclined => 'Anfrage abgelehnt.';

  @override
  String chatDeclinedAndBlocked(String name) {
    return 'Anfrage abgelehnt und $name blockiert.';
  }

  @override
  String get chatDeclinedBlockFailed =>
      'Anfrage abgelehnt, Blockieren fehlgeschlagen.';

  @override
  String get chatEmptyTitle => 'Sag Hallo! 👋';

  @override
  String get chatEmptyHint =>
      'Noch keine Nachrichten.\nSchreib die erste und brich das Eis.';

  @override
  String chatInfoBlockTitle(String name) {
    return '$name blockieren?';
  }

  @override
  String get chatInfoBlockMessage =>
      'Ihr könnt einander keine Nachrichten mehr schreiben. Du kannst die Blockierung später wieder aufheben.';

  @override
  String get chatInfoBlock => 'Blockieren';

  @override
  String get chatInfoOpenProfile => 'Profil öffnen';

  @override
  String chatInfoLeaveTitle(String name) {
    return '$name verlassen?';
  }

  @override
  String get chatInfoLeaveMessage =>
      'Du bekommst keine neuen Nachrichten mehr aus dieser Gruppe. Mit einer Einladung kannst du jederzeit wieder beitreten.';

  @override
  String get chatInfoLeave => 'Verlassen';

  @override
  String get chatInfoMembers => 'Mitglieder';

  @override
  String get chatInfoInvite => 'Einladen';

  @override
  String get chatInfoLeaveGroup => 'Gruppe verlassen';

  @override
  String get chatInfoMembersLoadFailed =>
      'Mitglieder konnten nicht geladen werden.';

  @override
  String get chatInfoYou => 'Du';

  @override
  String get chatInfoInviteCodeNote =>
      'Nur für begrenzte Zeit gültig. Wer den Code eingibt, tritt der Gruppe bei.';

  @override
  String get chatInfoShareInChat => 'Im Chat teilen';

  @override
  String get chatInfoCopyCode => 'Code kopieren';

  @override
  String get onboardingWelcomeTitle => 'Willkommen im\nPulse';

  @override
  String get onboardingWelcomeSubtitle =>
      'Der erste redaktionelle Social Feed, in dem deine Energie zählt.';

  @override
  String get onboardingWelcomePostTitle => 'Teile dein Leben';

  @override
  String get onboardingWelcomePostSub =>
      'Teile deinen täglichen Pulse. Echt und ungefiltert.';

  @override
  String get onboardingWelcomeRankTitle => 'Get Ranked';

  @override
  String get onboardingWelcomeRankSub =>
      'Die Community bewertet deine Kreativität.';

  @override
  String get onboardingWelcomeEarnTitle => 'Verdienen und gestalten';

  @override
  String get onboardingWelcomeEarnSub =>
      'Bewerte andere und verdiene Coins. Schalte exklusive Avatar-Items und \"Freundebuch\"-Skins frei.';

  @override
  String get onboardingVibeTitle => 'Was ist dein Vibe?';

  @override
  String get onboardingVibeSubtitle =>
      'Wähle bis zu 2 Pulse-Faktoren, die deinen Alltag ausmachen – oder gar keinen. Teile nur, was du teilen willst.';

  @override
  String get onboardingAboutMeTitle => 'Dein digitaler Pulse';

  @override
  String get onboardingAboutMeSubtitle =>
      'Lass andere deine Energie spüren. Das ist dein persönlicher Freundebuch-Eintrag.';

  @override
  String get onboardingAboutMeStoryLabel => 'DEINE STORY';

  @override
  String get onboardingAboutMeBioHint =>
      'Erzähl von dir, deinen Zielen oder was dich besonders macht ...';

  @override
  String get onboardingAgeTitle => 'Ein letzter Check';

  @override
  String get onboardingAgeSubtitle =>
      'Wie alt bist du? Wir fragen das nur einmal – dein Alter wird nie gespeichert.';

  @override
  String get onboardingAgeWarning =>
      'Ranked ist ab 16. Wir freuen uns, dich in ein paar Jahren wiederzusehen!';

  @override
  String get onboardingCredentialsTitle => 'Werde Teil vom';

  @override
  String get onboardingCredentialsSubtitle =>
      'Letzter Schritt – wähle deine Login-Daten und dein Profil geht live.';

  @override
  String get onboardingCredentialsEmailHint => 'E-Mail-Adresse';

  @override
  String get onboardingCredentialsUsernameHint => 'Username';

  @override
  String get onboardingCredentialsPasswordHint => 'Passwort';

  @override
  String get onboardingCredentialsLegal =>
      'Mit der Registrierung stimmst du unseren Community-Richtlinien zu';

  @override
  String get onboardingNextButton => 'Weiter';

  @override
  String get onboardingCreateButton => 'Account erstellen';

  @override
  String onboardingStepProgress(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get onboardingLoadingSetup => 'Dein Account wird eingerichtet';

  @override
  String get onboardingLoadingCreating => 'Account wird erstellt ...';

  @override
  String get onboardingLoadingSigning => 'Du wirst angemeldet ...';

  @override
  String get onboardingLoadingSecuring => 'Deine Chats werden gesichert ...';

  @override
  String get onboardingLoadingUploading => 'Dein Foto wird hochgeladen ...';

  @override
  String get onboardingLoadingAlmost => 'Fast geschafft ...';

  @override
  String get onboardingImageProcessError =>
      'Dein Profilbild konnte nicht verarbeitet werden — du kannst es später im Profil nachtragen.';

  @override
  String get onboardingLoginFailedAuto =>
      'Dein Konto wurde erstellt, aber der automatische Login hat nicht geklappt. Bitte melde dich auf der Login-Seite an.';

  @override
  String get loginWelcome => 'Willkommen zurück';

  @override
  String get loginSubtitle => 'Der Pulse wartet auf dich.';

  @override
  String get loginEmailLabel => 'E-Mail-Adresse';

  @override
  String get loginPasswordLabel => 'Passwort';

  @override
  String get loginForgotPassword => 'Passwort vergessen?';

  @override
  String get loginButton => 'Zum Feed einloggen';

  @override
  String get loginDivider => 'ODER WEITER MIT';

  @override
  String get loginGoogle => 'Google';

  @override
  String get loginApple => 'Apple';

  @override
  String get loginNoAccount => 'Neu bei Ranked?';

  @override
  String get loginSignUp => 'Registrieren';

  @override
  String get loginInvalidCredentials => 'Ungültige E-Mail oder Passwort';

  @override
  String get loginAborted => 'Anmeldung abgebrochen.';

  @override
  String get loginServerError =>
      'Verbindung zum Server fehlgeschlagen. Bitte versuche es nochmal.';

  @override
  String get postCommentSectionTitle => 'Kommentare';

  @override
  String get postCommentsLoadError => 'Kommentare konnten nicht geladen werden';

  @override
  String get postBeFirstToPulse => 'Sei der Erste, um zu pulsieren!';

  @override
  String get postCommentHint => 'Schreib einen Kommentar …';

  @override
  String get postEditButton => 'Post bearbeiten';

  @override
  String get postDeleteButton => 'Post löschen';

  @override
  String get postReportButton => 'Post melden';

  @override
  String get shareMessengerNotReady =>
      'Messenger nicht bereit — bitte kurz warten und erneut versuchen.';

  @override
  String get shareSheetTitle => 'Teilen';

  @override
  String get shareNoChats => 'Noch keine Chats zum Teilen.';

  @override
  String get shareCopyLink => 'Link kopieren';

  @override
  String get shareLinkCopied => 'Link kopiert';

  @override
  String shareSentTo(String username) {
    return 'An $username gesendet!';
  }

  @override
  String get feedLocationSaveError => 'Ort konnte nicht gespeichert werden';

  @override
  String get feedForYou => 'Für dich';

  @override
  String get feedLocal => 'Lokal';

  @override
  String get feedNoLocationTitle => 'Kein Ort gesetzt';

  @override
  String get feedNoPostsTitle => 'Noch nichts los hier';

  @override
  String get feedChooseLocationHint =>
      'Wähle deinen Ort, um Posts aus deiner Umgebung zu sehen.';

  @override
  String get feedNoPostsHint =>
      'An deinem Ort wurde noch nichts gepostet — sei die/der Erste!';

  @override
  String get feedChooseLocation => 'Ort wählen';

  @override
  String get storyRowYourPulse => 'Dein Pulse';

  @override
  String get createPostTitle => 'Post erstellen';

  @override
  String get locationPickerTitle => 'Ort wählen';

  @override
  String get locationSearchHint => 'Stadt suchen …';

  @override
  String get locationSearchStartHint => 'Tippe, um deine Stadt zu suchen';

  @override
  String get locationNotFound =>
      'Keinen Ort gefunden — probier eine andere Schreibweise';

  @override
  String get rankingOptinTitle => 'MACH MIT BEIM\nRANKING';

  @override
  String get rankingOptinDescription =>
      'Aktiviere das Ranking und lass dich täglich von der Community bewerten — Productivity, Creativity & Engagement.';

  @override
  String get rankingOptinButton => 'AKTIVIEREN';

  @override
  String get rankingStatsHeader => 'DEINE STATS';

  @override
  String get rankingPointsToday => 'PUNKTE HEUTE';

  @override
  String get rankingStreakLabel => 'DEIN STREAK';

  @override
  String get rankingEvaluatingLabel => 'DU BEWERTEST';

  @override
  String get rankingYourBadge => 'DU';

  @override
  String get rankingNoPointsHeadline => 'Noch keine Punkte heute';

  @override
  String get rankingNoPointsSubline => 'Poste, um bewertet zu werden';

  @override
  String get rankingLeadingHeadline => 'Du führst heute!';

  @override
  String get rankingLeadingSubline => 'Verteidge deinen Platz';

  @override
  String rankingMyRank(int rank) {
    return 'Platz #$rank';
  }

  @override
  String get rankingEmptyLeaderboard => 'Noch keine Rankings heute';

  @override
  String get rankingAlreadyRankedButton => 'HEUTE SCHON GEWERTET';

  @override
  String get rankingGetPartnerButton => 'FINDE DEINEN RANKING-PARTNER';

  @override
  String get rankingNoParticipants =>
      'Aktuell keine Teilnehmer zum Bewerten verfügbar.';

  @override
  String get rankingSwipeLike => 'LIKE';

  @override
  String get rankingSwipeNope => 'NOPE';

  @override
  String get rankingResultLabel => 'PUNKTE VERGEBEN';

  @override
  String get rankingResultDone => 'FERTIG';

  @override
  String get rankingAlreadyVotedHeadline => 'BEREITS\nGEWERTET';

  @override
  String get rankingErrorHeadline => 'FEHLER';

  @override
  String get rankingAlreadyVotedMessage =>
      'Du hast heute schon abgestimmt.\nMorgen bist du wieder dran!';

  @override
  String get rankingErrorMessage =>
      'Etwas ist schiefgelaufen. Versuch es später nochmal.';

  @override
  String get rankingBackButton => 'ZURÜCK';

  @override
  String get profileNoActivity =>
      'Noch keine Aktivität — sobald dich jemand bewertet, steht es hier.';

  @override
  String get profileActivityRated => 'Du wurdest bewertet';

  @override
  String get profileActivityDefault => 'Neue Aktivität';

  @override
  String profileActivityRatedSubtitle(int points) {
    return '+$points Punkte von der Community erhalten';
  }

  @override
  String get profileLeagueMaxReached => 'Höchste Liga erreicht';

  @override
  String profileLeagueProgress(int xp, String next) {
    return 'Noch $xp XP bis $next';
  }

  @override
  String get profileFollow => 'Folgen';

  @override
  String get profileFollowing => 'Gefolgt';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSectionAppearance => 'DARSTELLUNG';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsDarkModeSubtitle => 'Dunkles Erscheinungsbild';

  @override
  String get settingsSectionProfile => 'PROFIL';

  @override
  String get settingsLocation => 'Standort';

  @override
  String get settingsLocationLoading => 'Wird geladen …';

  @override
  String get settingsLocationNotSet => 'Kein Ort gesetzt';

  @override
  String get settingsRemoveLocation => 'Standort entfernen';

  @override
  String get settingsLocationFailed => 'Ort konnte nicht gespeichert werden.';

  @override
  String get settingsClearLocationTitle => 'Standort entfernen?';

  @override
  String get settingsClearLocationMessage =>
      'Ohne Standort kannst du den lokalen Feed nicht nutzen, bis du wieder einen Ort waehlst.';

  @override
  String get settingsClearLocationButton => 'Entfernen';

  @override
  String get settingsClearLocationError =>
      'Entfernen fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get settingsSectionPrivacy => 'PRIVATSPHÄRE';

  @override
  String get settingsBlockedAccounts => 'Blockierte Konten';

  @override
  String get settingsBlockedAccountsSubtitle =>
      'Blockierungen ansehen und aufheben';

  @override
  String get blockedTitle => 'Blockierte Konten';

  @override
  String get blockedEmpty => 'Du hast niemanden blockiert.';

  @override
  String get blockedLoadFailed => 'Die Liste konnte nicht geladen werden.';

  @override
  String get blockedRetry => 'Erneut versuchen';

  @override
  String blockedSince(String date) {
    return 'Blockiert am $date';
  }

  @override
  String get blockedUnblock => 'Aufheben';

  @override
  String blockedUnblockTitle(String name) {
    return '$name nicht mehr blockieren?';
  }

  @override
  String blockedUnblockMessage(String name) {
    return '$name kann dir dann wieder schreiben und deine Inhalte sehen.';
  }

  @override
  String blockedUnblocked(String name) {
    return '$name ist nicht mehr blockiert.';
  }

  @override
  String get blockedUnblockFailed =>
      'Aufheben fehlgeschlagen. Versuch es erneut.';

  @override
  String get settingsSectionLegal => 'RECHTLICHES';

  @override
  String get settingsPrivacy => 'Datenschutz (DSGVO)';

  @override
  String get settingsPrivacySubtitle => 'Wie wir mit deinen Daten umgehen';

  @override
  String get settingsSectionAccount => 'KONTO';

  @override
  String get settingsLogout => 'Abmelden';

  @override
  String get settingsDeleteAccount => 'Account löschen';

  @override
  String get settingsLogoutTitle => 'Abmelden?';

  @override
  String get settingsLogoutMessage => 'Du wirst von diesem Gerät abgemeldet.';

  @override
  String get settingsDeleteAccountTitle => 'Account löschen?';

  @override
  String get settingsDeleteAccountMessage =>
      'Dein Account, alle Posts, Votes und Kommentare werden dauerhaft gelöscht. Das lässt sich nicht rückgängig machen.';

  @override
  String get settingsDeleteAccountButton => 'Endgültig löschen';

  @override
  String get settingsDeleteFailed =>
      'Löschen fehlgeschlagen. Bitte später erneut versuchen.';

  @override
  String get settingsCancelButton => 'Abbrechen';

  @override
  String get settingsDsgvoTitle => 'Datenschutz';

  @override
  String get searchClearHistoryTitle => 'Suchverlauf löschen?';

  @override
  String get searchClearHistoryMessage =>
      'Dies entfernt alle kürzlichen Suchen von diesem Gerät.';

  @override
  String get searchCancelButton => 'Abbrechen';

  @override
  String get searchClearButton => 'Löschen';

  @override
  String get searchPlaceholder => 'Nutzer suchen';

  @override
  String get searchNoUsersFound => 'Keine Nutzer gefunden';

  @override
  String get searchMinCharacters => 'Mindestens 2 Zeichen eintippen';

  @override
  String get searchHistoryRecent => 'Kürzlich';

  @override
  String get searchHistoryEmpty => 'Keine kürzlichen Suchen';

  @override
  String get searchHistoryEmptyMessage =>
      'Erkunde die App – deine letzten Suchen\nwerden hier angezeigt.';

  @override
  String get keyRestoreTitle => 'Chats wiederherstellen';

  @override
  String get keyRestoreMessage =>
      'Deine Chats wurden mit einem anderen Passwort gesichert. Gib dein vorheriges Passwort ein, um sie wiederherzustellen.';

  @override
  String get keyRestorePasswordLabel => 'Vorheriges Passwort';

  @override
  String get keyRestoreWrongPassword =>
      'Das Passwort passt nicht. Versuch es nochmal.';

  @override
  String get keyRestoreButton => 'Wiederherstellen';

  @override
  String get keyRestoreCancelButton => 'Abbrechen';

  @override
  String get keyRestoreForgotPassword =>
      'Passwort vergessen? Chats zurücksetzen';

  @override
  String get keyRestoreResetTitle => 'Chats zurücksetzen?';

  @override
  String get keyRestoreResetMessage =>
      'Das lässt sich nicht rückgängig machen. Bitte lies kurz, was passiert:';

  @override
  String get keyRestoreResetConsequence1 =>
      'Deine bisherigen Nachrichten sind auf allen Geräten nicht mehr lesbar.';

  @override
  String get keyRestoreResetConsequence2 =>
      'Andere angemeldete Geräte werden abgemeldet.';

  @override
  String get keyRestoreResetConsequence3 =>
      'Neue Chats funktionieren ganz normal.';

  @override
  String get keyRestoreResetButton => 'Chats zurücksetzen';

  @override
  String get appDraftRestoreTitle => 'Entwurf wiederherstellen?';

  @override
  String get appDraftRestoreMessage => 'Du hast einen unfertigen Post.';

  @override
  String get appDraftDiscardButton => 'Verwerfen';

  @override
  String get appDraftRestoreButton => 'Wiederherstellen';

  @override
  String get storyDeleteFailedSnackbar => 'Story konnte nicht gelöscht werden';

  @override
  String get storyYourStory => 'Deine Story';

  @override
  String get storyDeleteTitle => 'Story löschen';

  @override
  String get storyDeleteCancel => 'Abbrechen';

  @override
  String get storyProcessingError => 'Bild konnte nicht verarbeitet werden';

  @override
  String get storyUploadError => 'Story-Upload fehlgeschlagen';

  @override
  String get storyCreateTitle => 'Neue Story';

  @override
  String get storyShareMoment => 'Teile deinen Moment';

  @override
  String get storyCreateDescription =>
      'Erstelle in Sekunden eine Story für deine Follower.';

  @override
  String get storyVisibleTime => '24H sichtbar';

  @override
  String get storySourceGallery => 'Galerie';

  @override
  String get storySourceGallerySubtitle => 'Bild wählen';

  @override
  String get storySourceCamera => 'Kamera';

  @override
  String get storySourceCameraSubtitle => 'Live aufnehmen';

  @override
  String get storyUploadingButton => 'Wird geteilt...';

  @override
  String get storyShareButton => 'Story teilen';

  @override
  String get suspendedTitle => 'Konto gesperrt';

  @override
  String suspendedUntil(String date) {
    return 'Dein Konto ist bis $date gesperrt.';
  }

  @override
  String get suspendedPermanent => 'Dein Konto ist dauerhaft gesperrt.';

  @override
  String get suspendedReasonLabel => 'GRUND';

  @override
  String get suspendedHint =>
      'Danach kannst du dich wieder ganz normal anmelden.';

  @override
  String get suspendedBack => 'Zurück zum Login';

  @override
  String get settingsSectionModeration => 'MODERATION';

  @override
  String get settingsModeration => 'Moderation';

  @override
  String get settingsModerationSubtitle => 'Meldungen prüfen';

  @override
  String get moderationTitle => 'Moderation';

  @override
  String get moderationTabReports => 'Meldungen';

  @override
  String get moderationTabAudit => 'Protokoll';

  @override
  String get moderationFilterPending => 'Offen';

  @override
  String get moderationFilterDismissed => 'Abgelehnt';

  @override
  String get moderationFilterActionTaken => 'Erledigt';

  @override
  String get moderationEmptyPending => 'Keine offenen Meldungen. Alles sauber!';

  @override
  String get moderationEmptyDismissed => 'Noch keine abgelehnten Meldungen.';

  @override
  String get moderationEmptyActionTaken => 'Noch keine erledigten Meldungen.';

  @override
  String get moderationLoadFailed =>
      'Die Meldungen konnten nicht geladen werden.';

  @override
  String get moderationRetry => 'Erneut versuchen';

  @override
  String moderationReportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Meldungen',
      one: '1 Meldung',
    );
    return '$_temp0';
  }

  @override
  String moderationLastReported(String date) {
    return 'zuletzt $date';
  }

  @override
  String get moderationBanned => 'Gesperrt';

  @override
  String get moderationBannedPermanent => 'Dauerhaft gesperrt';

  @override
  String get moderationContentDeleted =>
      'Vom User gelöscht – Stand beim Melden';

  @override
  String get moderationNoPreview => 'Keine Vorschau verfügbar';

  @override
  String moderationShowDetails(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Anmerkungen anzeigen',
      one: '1 Anmerkung anzeigen',
    );
    return '$_temp0';
  }

  @override
  String get moderationHideDetails => 'Anmerkungen ausblenden';

  @override
  String get moderationDismiss => 'Kein Verstoß';

  @override
  String get moderationTakeAction => 'Eingreifen';

  @override
  String get moderationActionSheetTitle => 'Was möchtest du tun?';

  @override
  String get moderationActionRemoveHint =>
      'Für alle ausgeblendet. Die Meldungen gelten damit als erledigt.';

  @override
  String get moderationActionRemovePictureHint =>
      'Name und Bio bleiben. Die Meldungen bleiben offen.';

  @override
  String get moderationActionBanHint =>
      'Die Person wird abgemeldet und kann sich bis zum Ende der Sperre nicht anmelden. Die Meldungen bleiben offen.';

  @override
  String get moderationActionMarkDoneHint =>
      'Z. B. wenn es schon anders geklärt ist. Die Karte wandert zu „Erledigt“.';

  @override
  String get moderationActionRestricted =>
      'Gleicher oder höherer Rang als du. Du kannst die Meldungen nur als erledigt markieren.';

  @override
  String get moderationMarkDone => 'Nur als erledigt markieren';

  @override
  String get moderationResolveFailed =>
      'Konnte nicht gespeichert werden. Versuch es nochmal.';

  @override
  String get moderationRemoveTitlePost => 'Beitrag entfernen';

  @override
  String get moderationRemoveTitleComment => 'Kommentar entfernen';

  @override
  String get moderationRemoveTitleStory => 'Story entfernen';

  @override
  String get moderationRemoveTitleProfilePicture => 'Profilbild entfernen';

  @override
  String get moderationRemoveReasonLabel => 'Grund';

  @override
  String get moderationRemoveDetailsHint =>
      'Begründung für die Person (optional)';

  @override
  String get moderationRemoveHint =>
      'Für alle sofort ausgeblendet. Ein Admin kann es 180 Tage lang wiederherstellen.';

  @override
  String get moderationRemoveConfirm => 'Entfernen';

  @override
  String get moderationAuditPlaceholder =>
      'Hier erscheint bald das Protokoll aller Moderations-Aktionen.';

  @override
  String moderationBanTitle(String username) {
    return '$username sperren';
  }

  @override
  String get moderationBanDurationLabel => 'Dauer';

  @override
  String moderationBanDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get moderationBanPermanent => 'Dauerhaft';

  @override
  String get moderationBanReasonLabel => 'Begründung';

  @override
  String get moderationBanReasonHint =>
      'Die Person sieht diesen Text beim Login';

  @override
  String get moderationBanHintNew => 'Die Person wird sofort abgemeldet.';

  @override
  String get moderationBanHintReplace => 'Ersetzt die laufende Sperre.';

  @override
  String get moderationBanConfirm => 'Sperren';

  @override
  String get moderationUnban => 'Entsperren';

  @override
  String moderationUserBanned(String username) {
    return '$username wurde gesperrt';
  }

  @override
  String get moderationForbidden => 'Dafür fehlt dir die Berechtigung';

  @override
  String get moderationActionFailed =>
      'Aktion fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String moderationUnbanTitle(String username) {
    return '$username entsperren?';
  }

  @override
  String get moderationUnbanMessage =>
      'Die Person kann sich sofort wieder anmelden.';

  @override
  String moderationUserUnbanned(String username) {
    return '$username wurde entsperrt';
  }

  @override
  String get moderationContentRemoved => 'Inhalt entfernt';

  @override
  String get moderationPictureRemoved =>
      'Profilbild entfernt. Die Meldungen bleiben offen.';
}
