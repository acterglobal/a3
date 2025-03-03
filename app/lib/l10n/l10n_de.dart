// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class L10nDe extends L10n {
  L10nDe([String locale = 'de']) : super(locale);

  @override
  String get about => 'Über';

  @override
  String get accept => 'Annehmen';

  @override
  String get acceptRequest => 'Anfrage annehmen';

  @override
  String get access => 'Zugang';

  @override
  String get accessAndVisibility => 'Zugang & Sichtbarkeit';

  @override
  String get account => 'Konto';

  @override
  String get actionName => 'Aktionsname';

  @override
  String get actions => 'Aktionen';

  @override
  String activateFeatureDialogTitle(Object feature) {
    return '$feature aktivieren?';
  }

  @override
  String activateFeatureDialogDesc(Object feature) {
    return 'Jedem mit den folgenden Berechtigung die Nutzung von $feature erlauben';
  }

  @override
  String get add => 'hinzufügen';

  @override
  String get addActionWidget => 'Actions Widget hinzufügen';

  @override
  String get addChat => 'Chat hinzufügen';

  @override
  String addedToPusherList(Object email) {
    return '$email zu Pusher Liste hinzufügen';
  }

  @override
  String addedToSpacesAndChats(Object number) {
    return '$number zu Space & Chats hinzugefügt';
  }

  @override
  String get addingEmailAddress => 'Für E-Mail Adresse hinzu';

  @override
  String get addSpace => 'Space hinzufügen';

  @override
  String get addTask => 'Aufgabe hinzufügen';

  @override
  String get admin => 'Admin';

  @override
  String get all => 'Alle';

  @override
  String get allMessages => 'Alle Nachrichten';

  @override
  String allReactionsCount(Object total) {
    return 'Alle $total';
  }

  @override
  String get alreadyConfirmed => 'Bereits bestätigt';

  @override
  String get analyticsTitle => 'Hilf uns dir zu helfen';

  @override
  String get analyticsDescription1 => 'Indem du die Absturzberichte und Fehler mit uns teilst.';

  @override
  String get analyticsDescription2 => 'Diese werden natürlich anonymisiert und enthalten keine vertraulichen Informationen';

  @override
  String get sendCrashReportsTitle => 'Übertrage Absturz- & Fehlerberichte';

  @override
  String get sendCrashReportsInfo => 'Automatisiert Fehlerberichte per Sentry mit dem Acter Team teilen';

  @override
  String get and => 'und';

  @override
  String get anInviteCodeYouWantToRedeem => 'Der einzulösenden Einladungscode';

  @override
  String get anyNumber => 'beliebige Zahl';

  @override
  String get appDefaults => 'App Standards';

  @override
  String get appId => 'App ID';

  @override
  String get appName => 'Appname';

  @override
  String get apps => 'Space Features';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'Bist du sicher, dass du die Nachricht löschen möchtest? Dies ist unwiderruflich.';

  @override
  String get areYouSureYouWantToLeaveRoom => 'Bist du sicher, dass du den Chat verlassen möchtest? Das ist unwiderruflich.';

  @override
  String get areYouSureYouWantToLeaveSpace => 'Bist du sicher, dass du diesen Space verlassen willst?';

  @override
  String get areYouSureYouWantToRemoveAttachmentFromPin => 'Bist du sicher, dass du diesen Anhang vom Pin entfernen willst?';

  @override
  String get areYouSureYouWantToUnregisterEmailAddress => 'Bist du sicher, dass du diese E-Mail-Adresse entfernen willst? Dies kann nicht widerrufen werden.';

  @override
  String get assignedYourself => 'Selbst zuweisen';

  @override
  String get assignmentWithdrawn => 'Zuweisung zurückgezogen';

  @override
  String get aTaskMustHaveATitle => 'Eine Aufgabe braucht einen Titel';

  @override
  String get attachments => 'Anhänge';

  @override
  String get atThisMomentYouAreNotJoiningEvents => 'Du hast derzeit anstehende Events. Um weitere Events zu finden, checke deine Spaces.';

  @override
  String get authenticationRequired => 'Anmeldung benötigt';

  @override
  String get avatar => 'Avatar';

  @override
  String get awaitingConfirmation => 'Warte auf Bestätigung';

  @override
  String get awaitingConfirmationDescription => 'Diese E-Mail-Adresse ist noch nicht bestätigt. Bitte überprüfe deinen E-Mail-Eingang und klicke den Bestätigungslink.';

  @override
  String get back => 'Zurück';

  @override
  String get block => 'Blockieren';

  @override
  String get blockedUsers => 'Blockierte Nutzer';

  @override
  String get blockInfoText => 'Wenn geblockt, wirst du deren Nachrichten nicht mehr angezeigt bekommen und weitere Kontakt-Aufnahme-Versuchen werden unterbunden.';

  @override
  String blockingUserFailed(Object error) {
    return 'Benutzer:im blockieren fehlgeschlagen: $error';
  }

  @override
  String get blockingUserProgress => 'Blockiere Benutzer:in';

  @override
  String get blockingUserSuccess => 'Benutzer:in blockiert. Es braucht mitunter einen Moment bis die Oberfläche das aktualisiert.';

  @override
  String blockTitle(Object userId) {
    return 'Blockiere $userId';
  }

  @override
  String get blockUser => 'Blockiere Nutzer:in';

  @override
  String get blockUserOptional => 'Blockiere Nutzer:in (optional)';

  @override
  String get blockUserWithUsername => 'Blockiere Nutzer per UserID';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get bookmarked => 'Gebookmarkt';

  @override
  String get bookmarkedSpaces => 'Gebookmarkte Spaces';

  @override
  String get builtOnShouldersOfGiants => 'Erbaut auf den Schultern von Giganten';

  @override
  String get calendarEventsFromAllTheSpaces => 'Events von allen deinen Spaces';

  @override
  String get calendar => 'Kalender';

  @override
  String get calendarSyncFeatureTitle => 'Kalender Sync';

  @override
  String get calendarSyncFeatureDesc => 'Synchronisiere (nicht abgelehnte) Events mit dem Geräte-Kalendar (Nur auf Android & iOS)';

  @override
  String get syncThisCalendarTitle => 'Im Geräte-Kalender synchronisieren';

  @override
  String get syncThisCalendarDesc => 'Synchronisiere diese Events im Kalender des Geräts';

  @override
  String get systemLinksTitle => 'System Links';

  @override
  String get systemLinksExplainer => 'Was passiert, wenn ich einen Link klicke';

  @override
  String get systemLinksOpen => 'Öffnen';

  @override
  String get systemLinksCopy => 'In die Zwischenablage kopieren';

  @override
  String get camera => 'Kamera';

  @override
  String get cancel => 'Abbruch';

  @override
  String get cannotEditSpaceWithNoPermissions => 'Space ohne Berechtigungen kann nicht editiert werden';

  @override
  String get changeAppLanguage => 'App Sprache ändern';

  @override
  String get changePowerLevel => 'Zugrifflevels anpassen';

  @override
  String get changeThePowerLevelOf => 'Das Zugriffslevel anpassen von';

  @override
  String get changeYourDisplayName => 'Anzeigename ändern';

  @override
  String get chat => 'Chatten';

  @override
  String get chatNG => 'Next-Generation Chat';

  @override
  String get chatNGExplainer => 'Wechsle zum Chat der nächsten Generation. Features sind evtl. noch nicht stabil';

  @override
  String get customizationsTitle => 'Anpassungen';

  @override
  String get chatMissingPermissionsToSend => 'Du hast keine Berechtigung hier Nachrichten zu schicken';

  @override
  String get behaviorSettingsTitle => 'Verhalten';

  @override
  String get behaviorSettingsExplainer => 'Konfiguriere  das Verhalten der App';

  @override
  String get chatSettingsAutoDownload => 'Medien automatisch herunterladen';

  @override
  String get chatSettingsAutoDownloadExplainer => 'Wann Medien automatisch geladen werden';

  @override
  String get chatSettingsAutoDownloadAlways => 'Immer';

  @override
  String get chatSettingsAutoDownloadWifiOnly => 'Nur über WLAN';

  @override
  String get chatSettingsAutoDownloadNever => 'Nie';

  @override
  String get settingsSubmitting => 'Übermittele Einstellungen';

  @override
  String get settingsSubmittingSuccess => 'Einstellungen übermittelt';

  @override
  String settingsSubmittingFailed(Object error) {
    return 'Übermittlung fehlgeschlagen: $error ';
  }

  @override
  String get chatRoomCreated => 'Chat erstellt';

  @override
  String get chatSendingFailed => 'Fehler beim Verschicken. Versuche erneut …';

  @override
  String get chatSettingsTyping => 'Tippenmeldung senden';

  @override
  String get chatSettingsTypingExplainer => '(bald) Lass die anderen wissen, wenn du tippst';

  @override
  String get chatSettingsReadReceipts => 'Gelesen-beleg senden';

  @override
  String get chatSettingsReadReceiptsExplainer => '(bald) Lasse die anderen wissen, wenn du eine Nachricht gelesen hast';

  @override
  String get chats => 'Chats';

  @override
  String claimedTimes(Object count) {
    return '$count eingelöst';
  }

  @override
  String get clear => 'leeren';

  @override
  String get clearDBAndReLogin => 'DB löschen und erneut einloggen';

  @override
  String get close => 'Schließen';

  @override
  String get closeDialog => 'Dialog schließen';

  @override
  String get closeSessionAndDeleteData => 'Beende diese Session, lösche alle lokalen Daten';

  @override
  String get closeSpace => 'Space schließen';

  @override
  String get closeChat => 'Chat schließen';

  @override
  String get closingRoomTitle => 'Diesen Raum schließen';

  @override
  String get closingRoomTitleDescription => 'Beim Schließen des Raums, wir werden:\n\n- alle Mitglieder mit geringeren Rechten entfernen\n- den Raum aus der Liste im Elternspace entfernen (wenn du die Rechte dazu hast)\n- die Einladungsregel auf \'privat\' setzen.\n- Du wirst den Raum verlassen.\n\nDies kann nicht rückgängig gemacht werden. Bist du sicher, dass du den Raum schließen willst?';

  @override
  String get closingRoom => 'Schließe…';

  @override
  String closingRoomRemovingMembers(Object kicked, Object total) {
    return 'Schließen. Entferne Mitglieder $kicked / $total';
  }

  @override
  String get closingRoomMatrixMsg => 'Der Raum wurde geschlossen';

  @override
  String closingRoomRemovingFromParents(Object currentParent, Object totalParents) {
    return 'Schließe. Entferne Raum von Eltern $currentParent / $totalParents';
  }

  @override
  String closingRoomDoneBut(Object skipped, Object skippedParents) {
    return 'Geschlossen und verlassen. Aber es war nicht möglich $skipped andere Mitglieder zu entfernen und den Raum von $skippedParents Eltern aufgrund fehlender Rechte zu entfernen. Andere haben möglicherweise weiterhin zugriff auf den Raum.';
  }

  @override
  String get closingRoomDone => 'Schließen erfolgreich.';

  @override
  String closingRoomFailed(Object error) {
    return 'Schließen fehlgeschlagen: $error';
  }

  @override
  String get coBudget => 'CoBudget';

  @override
  String get code => 'Kode';

  @override
  String get codeMustBeAtLeast6CharactersLong => 'Kode muss mindestens 6 Zeichen lang sein';

  @override
  String get comment => 'Kommentar';

  @override
  String get comments => 'Kommentare';

  @override
  String commentsListError(Object error) {
    return 'Kommentar List Fehler: $error';
  }

  @override
  String get commentSubmitted => 'Kommentar übermittelt';

  @override
  String get community => 'Gemeinschaft';

  @override
  String get confirmationToken => 'Bestätigungskode';

  @override
  String get confirmedEmailAddresses => 'Bestätigte Email-Adressen';

  @override
  String get confirmedEmailAddressesDescription => 'Bestätigte E-MailA-Adressen, die zu deinem Konto gehören:';

  @override
  String get confirmWithToken => 'Mit Kode bestätigen';

  @override
  String get congrats => 'Gratuliere!';

  @override
  String get connectedToYourAccount => 'Verbunden mit deinem Konto';

  @override
  String get contentSuccessfullyRemoved => 'Inhalte erfolgreich entfernt';

  @override
  String get continueAsGuest => 'Mit Gastzugang fortfahren';

  @override
  String get continueQuestion => 'Weiter?';

  @override
  String get copyUsername => 'Username kopieren';

  @override
  String get copyMessage => 'Kopieren';

  @override
  String get couldNotFetchNews => 'Konnte News nicht laden';

  @override
  String get couldNotLoadAllSessions => 'Konnte nicht alle Sessions laden';

  @override
  String couldNotLoadImage(Object error) {
    return 'Konnte das Bild nicht laden: $error';
  }

  @override
  String countsMembers(Object count) {
    return '$count Teilnehmer:innen';
  }

  @override
  String get create => 'Erstellen';

  @override
  String get createChat => 'Chat erstellen';

  @override
  String get createCode => 'Kode erstellen';

  @override
  String get createDefaultChat => 'Auch Standard-Chat erstellen';

  @override
  String defaultChatName(Object name) {
    return '$name Chat';
  }

  @override
  String get createDMWhenRedeeming => 'Neue DM mit mir bei Einlösung';

  @override
  String get createEventAndBringYourCommunity => 'Erstelle ein Event und bringe deine Community zusammen';

  @override
  String get createGroupChat => 'Gruppenchat erstellen';

  @override
  String get createPin => 'Pin erstellen';

  @override
  String get createPostsAndEngageWithinSpace => 'Erstelle Post mit Call-To-Actions und engagiere die Mitglieder deines Space,';

  @override
  String get createProfile => 'Profil erstellen';

  @override
  String get createSpace => 'Space erstllen';

  @override
  String get createSpaceChat => 'Erstelle Space Chat';

  @override
  String get createSubspace => 'Erstelle Subspace';

  @override
  String get createTaskList => 'Aufgabenliste erstellen';

  @override
  String get createAcopy => 'Als neu kopieren';

  @override
  String get creatingCalendarEvent => 'Erstelle Event';

  @override
  String get creatingChat => 'Chat erstellen';

  @override
  String get creatingCode => 'Kode wird erstellt';

  @override
  String creatingNewsFailed(Object error) {
    return 'Update erstellen fehlgeschlagen: $error';
  }

  @override
  String get creatingSpace => 'Erstelle Space';

  @override
  String creatingSpaceFailed(Object error) {
    return 'Space Erstellen fehlgeschlagen: $error';
  }

  @override
  String creatingTaskFailed(Object error) {
    return 'Aufgaben Erstellen fehlgeschlagen $error';
  }

  @override
  String get custom => 'Individuell';

  @override
  String get customizeAppsAndTheirFeatures => 'Passe die Features des Spaces an';

  @override
  String get customPowerLevel => 'Individuelles Zugriffslevel';

  @override
  String get dangerZone => 'Gefahrenzone';

  @override
  String get deactivate => 'Deaktivieren';

  @override
  String get deactivateAccountDescription => 'Wenn du fort fährst:\n\n- werden alle deine persönlichen Daten vom Homeserver gelöscht, inklusive Anzeigename und Avatar-Bild\n- werden umgehend alle Sessions geschlossen, kein Gerät wird mehr mit dem aktuellen Login fortfahren können\n- Du verlässt alle Räume, Chats, DMs, und Spaces in denen du gerade bist\n- Du wirst nicht in der Lage sein dein Konto wieder zu reaktivieren\n- Du wirst dich nicht mehr länger in dein Konto einloggen können\n- Niemand wird in deinen Nutzernamen (MXID) verwenden können, inklusive Dir: dieser Nutzername wird dauerhaft unnutzbar sein\n- Dein Eintrag wird vom Idenity-Server entfernt, inklusive aller dortigen Information (z.B. Email), falls du den benutzt hast\n- Alle lokalen Informationen, inklusive krytographische Schlüssel werden umgehend gelöscht\n- Deine gesendeten Nachrichten werden weiterhin verfügbar sein, eine E-Mail, die du versandt hast.\n \nDu kannst nichts davon rückgängig machen. Diese ist eine permanente und irreversible Aktion.';

  @override
  String get deactivateAccountPasswordTitle => 'Bitte gib Deine Passwort an um zu bestätigen, dass du deinen Konto deaktivieren willst.';

  @override
  String get deactivateAccountTitle => 'Achtung: Du bist dabei dein Konto dauerhaft zu deaktivieren';

  @override
  String deactivatingFailed(Object error) {
    return 'Deaktivieren fehlgeschlagen\n$error';
  }

  @override
  String get deactivatingYourAccount => 'Deaktiviere deine Konto';

  @override
  String get deactivationAndRemovingFailed => 'Deaktivieren und löschen der lokalen Daten fehlgeschlagen';

  @override
  String get debugInfo => 'Debug Info';

  @override
  String get debugLevel => 'Debug Level';

  @override
  String get decline => 'ablehnen';

  @override
  String get defaultModes => 'Standard Modi';

  @override
  String defaultNotification(Object type) {
    return 'Standard $type';
  }

  @override
  String get delete => 'Löschen';

  @override
  String get deleteAttachment => 'Anhang entfernen';

  @override
  String get deleteCode => 'Kode löschen';

  @override
  String get deleteTarget => 'Ziel löschen';

  @override
  String get deleteNewsDraftTitle => 'Entwurf löschen?';

  @override
  String get deleteNewsDraftText => 'Sicher, dass der Entwurf gelöscht werden soll? Das kann nicht rückgängig gemacht werden.';

  @override
  String get deleteDraftBtn => 'Entwurf löschen';

  @override
  String get deletingPushTarget => 'Lösche Pushziel';

  @override
  String deletionFailed(Object error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get denied => 'Abgelehtn';

  @override
  String get description => 'Beschreibung';

  @override
  String get deviceId => 'Gerät ID';

  @override
  String get deviceIdDigest => 'Gerät ID Hash';

  @override
  String get deviceName => 'Gerätename';

  @override
  String get devicePlatformException => 'Du kannst DevicePlatform.device/web in diesem Kontext nicht nutzen. Falsche Plattform: SettingsSection.build';

  @override
  String get displayName => 'Anzeigename';

  @override
  String get displayNameUpdateSubmitted => 'Anzeigenames-Aktualisierung übermittelt';

  @override
  String directInviteUser(Object userId) {
    return 'Direkt Einladen: $userId';
  }

  @override
  String get dms => 'DMs';

  @override
  String get doYouWantToDeleteInviteCode => 'Möchtest du wirklich den Einaldungskode dauerhaft löschen? Dieser kann dann nicht wieder verwendet werden.';

  @override
  String due(Object date) {
    return 'Fällig: $date';
  }

  @override
  String get dueDate => 'Fälligkeit';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editDetails => 'Details editieren';

  @override
  String get editMessage => 'Nachricht bearbeiten';

  @override
  String get editProfile => 'Profil ändern';

  @override
  String get editSpace => 'Space editieren';

  @override
  String get edited => 'Bearbeitet';

  @override
  String get egGlobalMovement => 'e.g. Globale Bewegung';

  @override
  String get emailAddressToAdd => 'Hinzuzufügende E-Mail-Adresse';

  @override
  String get emailOrPasswordSeemsNotValid => 'Email oder Passwort scheint nicht korrekt zu sein.';

  @override
  String get emptyEmail => 'Bitte geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get emptyPassword => 'Bitte geben Sie das Passwort ein';

  @override
  String get emptyToken => 'Code eingeben';

  @override
  String get emptyUsername => 'Benutzernamen eingeben';

  @override
  String get encrypted => 'Verschlüsselt';

  @override
  String get encryptedSpace => 'Verschlüsselter Space';

  @override
  String get encryptionBackupEnabled => 'Verschlüsselungsbackups aktiviert';

  @override
  String get encryptionBackupEnabledExplainer => 'Deine Schlüssel werden verschlüsselt in deinem Homeserver backup gespeichert';

  @override
  String get encryptionBackupMissing => 'Verschlüsselungsbackup fehlt';

  @override
  String get encryptionBackupMissingExplainer => 'Wir empfehlen die Verwendung des automatischen Verschlüsselungsbackup';

  @override
  String get encryptionBackupProvideKey => 'Rückholschlüssel angeben';

  @override
  String get encryptionBackupProvideKeyExplainer => 'Wir haben eine automatisches Verschlüsselungsbackup gefunden';

  @override
  String get encryptionBackupProvideKeyAction => 'Schlüssel angeben';

  @override
  String get encryptionBackupNoBackup => 'Kein Verschlüsselungsbackup gefunden';

  @override
  String get encryptionBackupNoBackupExplainer => 'Wenn du den Zugang zu deinem Konto verließt, können verschlüsselte Chats unwiderruflich verloren gehen. Wir empfehlen daher die Aktivierung des automatischen Verschlüsselungsbackup.';

  @override
  String get encryptionBackupNoBackupAction => 'Backup aktivieren';

  @override
  String get encryptionBackupEnabling => 'Aktiviere Backup';

  @override
  String encryptionBackupEnablingFailed(Object error) {
    return 'Backupaktivierung fehlgeschlagen: $error';
  }

  @override
  String get encryptionBackupRecovery => 'Kein Backup Rückholschlüssel';

  @override
  String get encryptionBackupRecoveryExplainer => 'Bewahre diesen Backuprückholschlüssel sicher auf.';

  @override
  String get encryptionBackupRecoveryCopiedToClipboard => 'Rückholschlüssel in die Zwischenablage kopiert';

  @override
  String get refreshing => 'Aktualisere';

  @override
  String get encryptionBackupDisable => 'Verschlüsselungsbackup deaktivieren?';

  @override
  String get encryptionBackupDisableExplainer => 'Ein Reset zerstört das Backup lokal wie auch auf deinem Homesever. Dies kann nicht rückgängig gemacht werden. Bist du sicher, dass du fortfahren willst?';

  @override
  String get encryptionBackupDisableActionKeepIt => 'Nein, bitte behalten';

  @override
  String get encryptionBackupDisableActionDestroyIt => 'Ja, zerstöre es';

  @override
  String get encryptionBackupResetting => 'Resette das Backup';

  @override
  String get encryptionBackupResettingSuccess => 'Reset erfolgreich';

  @override
  String encryptionBackupResettingFailed(Object error) {
    return 'Deaktivieren fehlgeschlagen: $error';
  }

  @override
  String get encryptionBackupRecover => 'Verschlüsselungsbackup recovern';

  @override
  String get encryptionBackupRecoverExplainer => 'Gib deinen Rückholschlüssel an um dein Verschlüsselungsbackup zu entschlüsseln';

  @override
  String get encryptionBackupRecoverInputHint => 'Rückholschlüssel';

  @override
  String get encryptionBackupRecoverProvideKey => 'Bitte den Schlüssel angeben';

  @override
  String get encryptionBackupRecoverAction => 'Zurückholen';

  @override
  String get encryptionBackupRecoverRecovering => 'Hole zurück';

  @override
  String get encryptionBackupRecoverRecoveringSuccess => 'Zurückholung erfolgreich';

  @override
  String get encryptionBackupRecoverRecoveringImportFailed => 'Import fehlgeschlagen';

  @override
  String encryptionBackupRecoverRecoveringFailed(Object error) {
    return 'Zurückholung fehlgeschlagen: $error';
  }

  @override
  String get encryptionBackupKeyBackup => 'Schlüsselbackup';

  @override
  String get encryptionBackupKeyBackupExplainer => 'Hier kannst du das Schlüsselbackup konfigurieren';

  @override
  String error(Object error) {
    return 'Fehler: $error';
  }

  @override
  String errorCreatingCalendarEvent(Object error) {
    return 'Fehler beim Erstellen des Event: $error';
  }

  @override
  String errorCreatingChat(Object error) {
    return 'Chat erstellen fehlgeschlagen: $error';
  }

  @override
  String errorSubmittingComment(Object error) {
    return 'Fehler bei der Kommentarübermittelung: $error';
  }

  @override
  String errorUpdatingEvent(Object error) {
    return 'Fehler beim Aktualisieren des Event: $error';
  }

  @override
  String get eventDescriptionsData => 'Eventbeschreibung';

  @override
  String get eventName => 'Eventtiitle';

  @override
  String get events => 'Veranstaltungen';

  @override
  String get eventTitleData => 'Eventtitel';

  @override
  String get experimentalActerFeatures => 'Experimentelle Acter Features';

  @override
  String failedToAcceptInvite(Object error) {
    return 'Einladungsannahme fehlgeschlagen: $error';
  }

  @override
  String failedToRejectInvite(Object error) {
    return 'Einladungsablehnung fehlgeschlagen: $error';
  }

  @override
  String get missingStoragePermissions => 'Wir brauchen Zugriff auf dein Storage um ein Bild wählen zu können';

  @override
  String get file => 'Datei';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get forgotPasswordDescription => 'Um dein Passwort wieder herzustellen, schicken wir dir einen Link an deine E-Mail. Bitte folge dem Prozess dort und am Ende kannst du dein Passwort hier neusetzen.';

  @override
  String get forgotPasswordNewPasswordDescription => 'Sobald du den Prozess hinter dem Link, den wir dir geschickt haben, abgeschlossen hast, kannst du hier ein neues Passwort setzen:';

  @override
  String get formatMustBe => 'Erwartetes Format ist @nutzer:domain.tld';

  @override
  String get foundUsers => 'User gefunden';

  @override
  String get from => 'von';

  @override
  String get gallery => 'Galerie';

  @override
  String get general => 'Allgemein';

  @override
  String get getConversationGoingToStart => 'Starte das Gespräch um mit dem Organizing zu beginnen';

  @override
  String get getInTouchWithOtherChangeMakers => 'Komme in Kontakt mit anderen ChangeMakers, Organizer und Aktivisti und chatte direkt mit ihnen.';

  @override
  String get goToDM => 'Gehe zur DM';

  @override
  String get going => 'Gehe';

  @override
  String get haveProfile => 'Du hast bereits ein Konto?';

  @override
  String get helpCenterTitle => 'Hilfecenter';

  @override
  String get helpCenterDesc => 'Bekomme Tips & Tricks zu Acter';

  @override
  String get hereYouCanChangeTheSpaceDetails => 'Hier kannst du die Spacedetails anpassen';

  @override
  String get hereYouCanSeeAllUsersYouBlocked => 'Hier alle Nutzer:innen, die du geblockt hast.';

  @override
  String get hintMessageDisplayName => 'Den Namen, den andere sehen soll';

  @override
  String get hintMessageInviteCode => 'Einladungs-Kode eingeben um einer Community beizutreten';

  @override
  String get hintMessagePassword => 'Mindestens 6 Zeichen';

  @override
  String get hintMessageUsername => 'Eindeutiger Nutzername für den Kontozugang und die Identifikation';

  @override
  String get homeServerName => 'Heimat Server Name';

  @override
  String get homeServerURL => 'Heimat Server URL';

  @override
  String get httpProxy => 'HTTP Proxy';

  @override
  String get image => 'Bild';

  @override
  String get inConnectedSpaces => 'Durch verbundene Spaces kannst du Arbeitsgruppen für spezifische Aktionen oder Kampagnen organisieren.';

  @override
  String get info => 'Info';

  @override
  String get invalidTokenOrPassword => 'Ungültiger Einladungskode oder Passwort';

  @override
  String get invitationToChat => 'Zum Chat eingeladen durch ';

  @override
  String get invitationToDM => 'Möchte eine DM mit dir beginnen';

  @override
  String get invitationToSpace => 'Zum Space eingeladen durch ';

  @override
  String get invited => 'Eingeladen';

  @override
  String get inviteCode => 'Einladungskode';

  @override
  String get scanQrCode => 'QR Code Scannen';

  @override
  String shareInviteWithCode(Object code) {
    return 'Einladung $code';
  }

  @override
  String get inviteCodeInfo => 'Acter ist weiterhin invite-only. Falls dir bisher kein Invite-Kode einer bestimmten Gruppe oder Initiative zugegangen ist, benutzen den folgen um Acter auszuprobieren.';

  @override
  String get irreversiblyDeactivateAccount => 'Das Konto unwiderruflich deaktivieren';

  @override
  String get itsYou => 'Das bist du';

  @override
  String get join => 'beitreten';

  @override
  String get joined => 'Beigetreten';

  @override
  String joiningFailed(Object error) {
    return 'Beitreten fehlgeschlagen: $error';
  }

  @override
  String get joinActer => 'Acter beitreten';

  @override
  String joinRuleNotSupportedYet(Object role) {
    return 'Beitrittsregel $role noch nicht unterstützt. Sorry';
  }

  @override
  String kickAndBanFailed(Object error) {
    return 'Entfernen & Verbannen des User fehlgeschlagen:\n$error';
  }

  @override
  String get kickAndBanProgress => 'User wird entfernt und verbannt';

  @override
  String get kickAndBanSuccess => 'User entfernt und verbannt';

  @override
  String get kickAndBanUser => 'User entfernen & verbannen';

  @override
  String kickAndBanUserDescription(Object roomId, Object userId) {
    return 'Du bist dabei $userId aus $roomId zu entfernen und dauerhaft zu verbannen';
  }

  @override
  String kickAndBanUserTitle(Object userId) {
    return 'User $userId entfernt und verbannen';
  }

  @override
  String kickFailed(Object error) {
    return 'User entfernen fehlgeschlagen:\n$error';
  }

  @override
  String get kickProgress => 'User entfernen';

  @override
  String get kickSuccess => 'User entfernt';

  @override
  String get kickUser => 'User entfernt';

  @override
  String kickUserDescription(Object roomId, Object userId) {
    return 'Du bist dabei $userId aus $roomId zu entfernen';
  }

  @override
  String kickUserTitle(Object userId) {
    return 'User $userId entfernt';
  }

  @override
  String get labs => 'Labs';

  @override
  String get labsAppFeatures => 'App Features';

  @override
  String get language => 'Deutsch';

  @override
  String get leave => 'Verlassen';

  @override
  String get leaveRoom => 'Chat verlassen';

  @override
  String get leaveSpace => 'Space verlassen';

  @override
  String get leavingSpace => 'Verlasse Space';

  @override
  String get leavingSpaceSuccessful => 'Du hast den Space verlassen';

  @override
  String leavingSpaceFailed(Object error) {
    return 'Fehler beim Verlassen des Space: $error';
  }

  @override
  String get leavingRoom => 'Verlasse Chat';

  @override
  String get letsGetStarted => 'Los geht’s';

  @override
  String get licenses => 'Lizenzen';

  @override
  String get limitedInternConnection => 'Eingeschränkte Internetverbindung';

  @override
  String get link => 'Verbinden';

  @override
  String get linkExistingChat => 'Verbinde bestehenden Chat';

  @override
  String get linkExistingSpace => 'Verbinde bestehenden Space';

  @override
  String get links => 'Link';

  @override
  String get loading => 'Laden';

  @override
  String get linkToChat => 'Chat verbinden';

  @override
  String loadingFailed(Object error) {
    return 'Laden fehlgeschlagen: $error';
  }

  @override
  String get location => 'Lage';

  @override
  String get logIn => 'Einloggen';

  @override
  String get loginAgain => 'Erneut einloggen';

  @override
  String get loginContinue => 'Melde dich an und organize weiter wo du zuletzt aufgehört hast.';

  @override
  String get loginSuccess => 'Anmeldung erfolgreich';

  @override
  String get logOut => 'Abmelden';

  @override
  String get logSettings => 'Log Einstellungen';

  @override
  String get looksGoodAddressConfirmed => 'Sieht gut aus. Adresse bestätigt.';

  @override
  String get makeADifference => 'Erstarke dein digitales Organizing.';

  @override
  String get manage => 'Manage';

  @override
  String get manageBudgetsCooperatively => 'Budget kooperativ verwalten';

  @override
  String get manageYourInvitationCodes => 'Deine Einladungskodes verwalten';

  @override
  String get markToHideAllCurrentAndFutureContent => 'Markieren um allen bestehende und zukünftige Nachrichten von diesem User zu verstecken und Kontaktaufnahmen dauerhaft zu blockieren';

  @override
  String get markedAsDone => 'Als erledigt markieren';

  @override
  String get maybe => 'Vielleicht';

  @override
  String get member => 'Mitglied';

  @override
  String get memberDescriptionsData => 'Mitgliedbeschreibugn';

  @override
  String get memberTitleData => 'Mitgliedtitel';

  @override
  String get members => 'Mitglieder';

  @override
  String get mentionsAndKeywordsOnly => 'Nur Erwähnungen und Schlagwörter';

  @override
  String get message => 'Nachricht';

  @override
  String get messageCopiedToClipboard => 'Nachricht in die Ablage kopiert';

  @override
  String get missingName => 'Bitte geben Sie Ihren Namen ein';

  @override
  String get mobilePushNotifications => 'Mobile Push Benachrichtigungen';

  @override
  String get moderator => 'Moderator';

  @override
  String get more => 'Mehr';

  @override
  String moreRooms(Object count) {
    return '+$count weitere Räume';
  }

  @override
  String get muted => 'Stumm';

  @override
  String get customValueMustBeNumber => 'Bitte gib den Wert als volle Zahl ein.';

  @override
  String get myDashboard => 'Mein Dashboard';

  @override
  String get name => 'Name';

  @override
  String get nameOfTheEvent => 'Name des Event';

  @override
  String get needsAppRestartToTakeEffect => 'Erst nach einen App Neustart effektiv';

  @override
  String get newChat => 'Neuer Chat';

  @override
  String get newEncryptedMessage => 'Neue verschlüsselte Nachricht';

  @override
  String get needYourPasswordToConfirm => 'Braucht dein Passwort zu Bestätigung';

  @override
  String get newMessage => 'neue Nachricht';

  @override
  String get newUpdate => 'Neues Update';

  @override
  String get next => 'Nächste';

  @override
  String get no => 'Nein';

  @override
  String get noChatsFound => 'Keine Chats gefunden';

  @override
  String get noChatsFoundMatchingYourFilter => 'Keine Chats gefunden, die den Suchkriterien & Filtern entsprechen';

  @override
  String get noChatsFoundMatchingYourSearchTerm => 'Keine Chats gefunden die den Suchterm matchen';

  @override
  String get noChatsInThisSpaceYet => 'Noch keine Chats in diesem Space';

  @override
  String get noChatsStillSyncing => 'Synchronisiere…';

  @override
  String get noChatsStillSyncingSubtitle => 'Wir laden deine Chats. Bei großen Konten kann das initiale Laden etwas dauern…';

  @override
  String get noConnectedSpaces => 'Keine verbundenen Spaces';

  @override
  String get noDisplayName => 'Kein Anzeigename';

  @override
  String get noDueDate => 'Keine Fälligkeit';

  @override
  String get noEventsPlannedYet => 'Noch keine Events geplant';

  @override
  String get noIStay => 'Nein, Ich bleibe';

  @override
  String get noMembersFound => 'Keine Mitglieder gefunden. Wie kann das sein, du bist doch hier, oder nicht?';

  @override
  String get noOverwrite => 'Keine Überschreibung';

  @override
  String get noParticipantsGoing => 'Keine Teilnehmer';

  @override
  String get noPinsAvailableDescription => 'Teile wichtige Resourcen mit deiner Community, wie Dokumente, Links, etc, damit alle jederzeit die aktuellsten Daten haben.';

  @override
  String get noPinsAvailableYet => 'Bisher keine Pins';

  @override
  String get noProfile => 'Noch kein Profil?';

  @override
  String get noPushServerConfigured => 'Keine Push Server für diesen Build konfiguriert';

  @override
  String get noPushTargetsAddedYet => 'Bisher keine Pushziele definiert';

  @override
  String get noSpacesFound => 'Keine Spaces gefunden';

  @override
  String get noUsersFoundWithSpecifiedSearchTerm => 'Keine User mit dem Suchterm gefunden';

  @override
  String get notEnoughPowerLevelForInvites => 'Dein Zugriffslelve ist nicht hoch genug um Einladungen zu senden. Bitte den Administrator es zu ändern';

  @override
  String get notFound => '404 - Nicht gefunden';

  @override
  String get notes => 'Notizen';

  @override
  String get notGoing => 'Nicht dabei';

  @override
  String get noThanks => 'Nein, danke';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationsOverwrites => 'Notifiaction Überschreibung';

  @override
  String get notificationsOverwritesDescription => 'Überschreibe deine Notifications configuration für diesen Space';

  @override
  String get notificationsSettingsAndTargets => 'Benachrichtigungseinstellungen und -Ziele';

  @override
  String get notificationStatusSubmitted => 'Benachrichtigungsstatus übermittelt';

  @override
  String notificationStatusUpdateFailed(Object error) {
    return 'Benachritigungsstatus Übermittelung fehlgeschlagen: $error';
  }

  @override
  String get notificationsUnmuted => 'Notifications entstummt';

  @override
  String get notificationTargets => 'Pushziele';

  @override
  String get notifyAboutSpaceUpdates => 'Umgehend über Space Updates benachrichtigen';

  @override
  String get noTopicFound => 'Keine Themen gefunden';

  @override
  String get notVisible => 'Nicht sichtbar';

  @override
  String get notYetSupported => 'Noch nicht supportet';

  @override
  String get noWorriesWeHaveGotYouCovered => 'Keine Sorge! Gib deine E-Mail ein um dein Passwort zurückzusetzen.';

  @override
  String get ok => 'Ok';

  @override
  String get okay => 'Okay';

  @override
  String get on => 'auf';

  @override
  String get onboardText => 'Lass uns beginnen in dem wir dein Profil aufsetzen';

  @override
  String get onlySupportedIosAndAndroid => 'Aktuell nur für Mobile (iOS & Android)';

  @override
  String get optional => 'Optional';

  @override
  String get or => ' - oder - ';

  @override
  String get overview => 'Übersicht';

  @override
  String get parentSpace => 'Elternspace';

  @override
  String get parentSpaces => 'Elternspace';

  @override
  String get parentSpaceMustBeSelected => 'Elternspace muss gewählt werden';

  @override
  String get parents => 'Eltern';

  @override
  String get password => 'Passwort';

  @override
  String get passwordResetTitle => 'Passwort zurücksetzen';

  @override
  String get past => 'Vergangen';

  @override
  String get pending => 'Anhängig';

  @override
  String peopleGoing(Object count) {
    return '$count Teilnehmer';
  }

  @override
  String get personalSettings => 'Persönliche Einstellungen';

  @override
  String get pinName => 'Pintitel';

  @override
  String get pins => 'Pins';

  @override
  String get play => 'Abspielen';

  @override
  String get playbackSpeed => 'Abspielgeschwindigkeit';

  @override
  String get pleaseCheckYourInbox => 'Bitte checke deinen Email-Eingang für die Bestägigungsemail und klicke den Link bevor er verfällt';

  @override
  String get pleaseEnterAName => 'Bitte Namen eingeben';

  @override
  String get pleaseEnterATitle => 'Bitte Titel eingeben';

  @override
  String get pleaseEnterEventName => 'Bitte Eventtitle angeben';

  @override
  String get pleaseFirstSelectASpace => 'Bitte erst den Space auswählen';

  @override
  String errorProcessingSlide(Object error, Object slideIdx) {
    return 'Erstellen von Seite $slideIdx fehlgeschlagen: $error';
  }

  @override
  String get pleaseProvideEmailAddressToAdd => 'Bitte gib die E-Mail-Adresse an, die du hinzufügen möchtest';

  @override
  String get pleaseProvideYourUserPassword => 'Bitte dein Nutzerpassword angeben um das Beenden der Sitzung zu bestätigen.';

  @override
  String get pleaseSelectSpace => 'Bitte einen Space auswählen';

  @override
  String get selectTaskList => 'Wähle eine Aufgabenliste';

  @override
  String get pleaseWait => 'Warten Sie mal…';

  @override
  String get polls => 'Umfragen';

  @override
  String get pollsAndSurveys => 'Umfragen und Befragungen';

  @override
  String postingOfTypeNotYetSupported(Object type) {
    return '$type posten noch nicht unterstützt';
  }

  @override
  String get postingTaskList => 'Erstelle Aufgabenliste';

  @override
  String get postpone => 'Aufschieben';

  @override
  String postponeN(Object days) {
    return 'Um $days tage aufschieben';
  }

  @override
  String get powerLevel => 'Zugriffslevel';

  @override
  String get powerLevelUpdateSubmitted => 'Zugriffslelvel Aktualisierung übermittelt';

  @override
  String get powerLevelAdmin => 'Admin';

  @override
  String get powerLevelModerator => 'Moderator';

  @override
  String get powerLevelRegular => 'Jede:r';

  @override
  String get powerLevelNone => 'keines';

  @override
  String get powerLevelCustom => 'Benutzerdefiniert';

  @override
  String get powerLevelsTitle => 'Allgemeine Zugangslevels';

  @override
  String get powerLevelPostEventsTitle => 'Posting Zugangslevel';

  @override
  String get powerLevelPostEventsDesc => 'Minimales Zugangslevel um überhaupt was posten zu dürfen';

  @override
  String get powerLevelKickTitle => 'Kick Zugangslevel';

  @override
  String get powerLevelKickDesc => 'Minimales Zugangslevel um ein Mitglied zu kicken';

  @override
  String get powerLevelBanTitle => 'Bann Zugangslevel';

  @override
  String get powerLevelBanDesc => 'Minimales Zugangslevel um ein Mitglied verbannen zu können';

  @override
  String get powerLevelInviteTitle => 'Einladungs-Zugangslevel';

  @override
  String get powerLevelInviteDesc => 'Minimales Zugangslevel um Einladen zu können';

  @override
  String get powerLevelRedactTitle => 'Zurücknahme Zugangslevel';

  @override
  String get powerLevelRedactDesc => 'Minimales Zugangslevel um zurücknehmen zu können';

  @override
  String get preview => 'Vorschau';

  @override
  String get privacyPolicy => 'Privatsphären Policy';

  @override
  String get private => 'Privat';

  @override
  String get profile => 'Profil';

  @override
  String get pushKey => 'PushKey';

  @override
  String get pushTargetDeleted => 'Pushziel entfernt';

  @override
  String get pushTargetDetails => 'Pushziel Details';

  @override
  String get pushToThisDevice => 'Zu diesem Gerät pushen';

  @override
  String get quickSelect => 'Schnellauswahl:';

  @override
  String get rageShakeAppName => 'Rageshake App Name';

  @override
  String get rageShakeAppNameDigest => 'Rageshake App Name Prüfsumme';

  @override
  String get rageShakeTargetUrl => 'Rageshake Ziel-URL';

  @override
  String get rageShakeTargetUrlDigest => 'Rageshake Ziel-URL Prüfsumme';

  @override
  String get reason => 'Grund';

  @override
  String get reasonHint => 'Optionaler Grund';

  @override
  String get reasonLabel => 'Grund';

  @override
  String redactionFailed(Object error) {
    return 'Zurücknahme fehlgeschlagen: $error';
  }

  @override
  String get redeem => 'Einlösen';

  @override
  String redeemingFailed(Object error) {
    return 'Einlösen fehlgeschlagen: $error';
  }

  @override
  String get register => 'Anmelden';

  @override
  String registerFailed(Object error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get regular => 'Regulär';

  @override
  String get remove => 'Entfernen';

  @override
  String get removePin => 'Pin entfernen';

  @override
  String get removeThisContent => 'Inhalt entfernen. Dies kann nicht rückgängig gemacht werden. Gib einen optionalen Grund an, warum dies entfernt wurde';

  @override
  String get reply => 'Antwort';

  @override
  String replyTo(Object name) {
    return 'Antworte auf $name';
  }

  @override
  String get replyPreviewUnavailable => 'Keine Vorschau für die Nachricht verfügbar';

  @override
  String get report => 'Melden';

  @override
  String get reportThisEvent => 'Melde dieses Event';

  @override
  String get reportThisMessage => 'Melde diese Nachricht';

  @override
  String get reportMessageContent => 'Melde diese Nachricht an deinen Homeserver Admin. Bedenke, dass Admins Nachrichten nicht lesen können, wenn diese verschlüsselt sind';

  @override
  String get reportPin => 'Pin melden';

  @override
  String get reportThisPost => 'Melde diesen Post';

  @override
  String get reportPostContent => 'Melde diesen Post an deinen Homeserver Admin. Bedenke, dass Admins Nachrichten nicht lesen können, wenn diese verschlüsselt sind.';

  @override
  String get reportSendingFailed => 'Meldung senden fehlgeschlagen';

  @override
  String get reportSent => 'Meldung gesendet!';

  @override
  String get reportThisContent => 'Melde diese Inhalt an deinen Homeserver Admin. Bedenke, dass Admins Nachrichten nicht lesen können, wenn diese verschlüsselt sind.';

  @override
  String get requestToJoin => 'Beitritt anfragen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get resetPassword => 'Passwort zurücksetzen';

  @override
  String get retry => 'Wiederholen';

  @override
  String get roomId => 'Chat ID';

  @override
  String get roomNotFound => 'Chat nicht gefunden';

  @override
  String get roomLinkedButNotUpgraded => 'Hinzugefügt. Du hast allerdings nicht die Rechte die Zugangsregel anzupassen, daher kann es sein, dass andere Spacemitglieder nicht beitreten können.';

  @override
  String get rsvp => 'Teilnahme';

  @override
  String repliedToMsgFailed(Object id) {
    return 'Laden der original Nachricht fehlgeschlagen: $id';
  }

  @override
  String get sasGotIt => 'Verstanden';

  @override
  String sasIncomingReqNotifContent(String sender) {
    return '$sender möchte deine Sitzung verifizieren';
  }

  @override
  String get sasIncomingReqNotifTitle => 'Verifizierungsanfrage';

  @override
  String get sasVerified => 'Verifiziert!';

  @override
  String get save => 'Speichern';

  @override
  String get saveFileAs => 'Datei speichern unter';

  @override
  String get openFile => 'Öffnen';

  @override
  String get shareFile => 'Teilen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get savingCode => 'Speichere Kode';

  @override
  String get search => 'Suchen';

  @override
  String get searchTermFieldHint => 'Suche nach…';

  @override
  String get searchChats => 'Chat durchsuchen';

  @override
  String searchResultFor(Object text) {
    return 'Suchergebnisse für $text …';
  }

  @override
  String get searchUsernameToStartDM => 'Suche User um eine DM zu beginnen';

  @override
  String searchingFailed(Object error) {
    return 'Suche fehlgeschlagen: $error';
  }

  @override
  String get searchSpace => 'Space suchen';

  @override
  String get searchSpaces => 'Suche Spaces';

  @override
  String get searchPublicDirectory => 'Suche im öffentlichen Verzeichnis';

  @override
  String get searchPublicDirectoryNothingFound => 'Kein Eintrag im Verzeichnis gefunden';

  @override
  String get seeOpenTasks => 'Offene Aufgaben ansehen';

  @override
  String get seenBy => 'Gesehen durch';

  @override
  String get select => 'Auswählen';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get unselectAll => 'Alle abwählen';

  @override
  String get selectAnyRoomToSeeIt => 'Wähle einen beliebigen Chat aus um ihm anzusehen';

  @override
  String get selectDue => 'Fälligkeit wählen';

  @override
  String get selectLanguage => 'Sprache wählen';

  @override
  String get selectParentSpace => 'Elternspace wählen';

  @override
  String get send => 'Senden';

  @override
  String get sendingAttachment => 'Sende Anhang';

  @override
  String get sendingReport => 'Sende Meldung';

  @override
  String get sendingEmail => 'E-Mail senden';

  @override
  String sendingEmailFailed(Object error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String sendingRsvpFailed(Object error) {
    return 'Event-Antwort senden fehlgeschlagen: $error';
  }

  @override
  String get sentAnImage => 'Bild gesendet.';

  @override
  String get server => 'Server';

  @override
  String get sessions => 'Sitzung';

  @override
  String get sessionTokenName => 'Sitzungskode Name';

  @override
  String get setDebugLevel => 'Setze Debug Level';

  @override
  String get setHttpProxy => 'Setze HTTP Proxy';

  @override
  String get settings => 'Einstellungen';

  @override
  String get securityAndPrivacy => 'Sicherheit & Privatsphäre';

  @override
  String get settingsKeyBackUpTitle => 'Schlüsselbackup';

  @override
  String get settingsKeyBackUpDesc => 'Verwalte das Verschlüsselungsbackup';

  @override
  String get share => 'Teilen';

  @override
  String get shareIcal => 'iCal teilen';

  @override
  String shareFailed(Object error) {
    return 'Teilen fehlgeschlagen: $error';
  }

  @override
  String get sharedCalendarAndEvents => 'Gemeinsamer Kalender und Events';

  @override
  String get signUp => 'Beitreten';

  @override
  String get skip => 'Überspringen';

  @override
  String get slidePosting => 'Poste Slides';

  @override
  String slidesNotYetSupported(Object type) {
    return '$type Slide noch nicht unterstützt';
  }

  @override
  String get someErrorOccurredLeavingRoom => 'Fehler beim Verlassen des Chats';

  @override
  String get space => 'Space';

  @override
  String get spaceConfiguration => 'Space Konfiguration';

  @override
  String get spaceConfigurationDescription => 'Konfiguriere, wer den Space sehen und ihm beitreten kann';

  @override
  String get spaceName => 'Spacename';

  @override
  String get spaceNotificationOverwrite => 'Space Notifiactions Einstellungen';

  @override
  String get spaceNotifications => 'Space Notifications';

  @override
  String get spaceOrSpaceIdMustBeProvided => 'Space oder spaceId muss angegen werden';

  @override
  String get spaces => 'Spaces';

  @override
  String get spacesAndChats => 'Spaces & Chats';

  @override
  String get spacesAndChatsToAddThemTo => 'zu Spaces & Chats hinzufügen';

  @override
  String get startDM => 'DM starten';

  @override
  String get state => 'Status';

  @override
  String get submit => 'Übermitteln';

  @override
  String get submittingComment => 'Übermittele Kommentar';

  @override
  String get suggested => 'Vorgeschlagen';

  @override
  String get suggestedUsers => 'Vorgeschlagene User';

  @override
  String get joiningSuggested => 'Vorschlägen beitreten';

  @override
  String get suggestedRoomsTitle => 'Zum Beitritt vorgeschlagen';

  @override
  String get suggestedRoomsSubtitle => 'Wir schlagen vor auch den folgenden beizutreten';

  @override
  String get addSuggested => 'Als Vorschlag markieren';

  @override
  String get removeSuggested => 'Vorschlagung zurücknehmen';

  @override
  String get superInvitations => 'Einladungskodes';

  @override
  String get superInvites => 'Einladungskodes';

  @override
  String superInvitedBy(Object user) {
    return '$user läd dich ein';
  }

  @override
  String superInvitedTo(Object count) {
    return '$count Räumen beizutreten';
  }

  @override
  String superInvitesPreviewMissing(Object token) {
    return 'Dein Server hat keine Möglichkeit einer Einladungs-Vorschau. Du kannst den Code $token dennoch einlösen';
  }

  @override
  String superInvitesDeleted(Object token) {
    return 'Der Code $token ist nicht mehr gültig.';
  }

  @override
  String get takeAFirstStep => 'Mache den ersten Schritt hin zu erfolgreichem Organizing in dem Du ein Konto anlegst oder dich einloggst.';

  @override
  String get taskListName => 'Aufgabenlistenname';

  @override
  String get tasks => 'Aufgaben';

  @override
  String get termsOfService => 'AGBs';

  @override
  String get termsText1 => 'Indem Sie auf Anmelden klicken, erklären Sie sich mit unserer';

  @override
  String theCurrentJoinRulesOfSpace(Object parentSpaceName, Object roomName) {
    return 'Die aktuelle Beitrittsregeln bedeuten, dass $roomName nicht für die Mitglieder von $parentSpaceName sichtbar ist. Sollen wir die Beitrittsregel anpassen und allen Mitgliedern von $parentSpaceName den Zugang zu $roomName erlauben?';
  }

  @override
  String get theParentSpace => 'der Elternspace';

  @override
  String get thereIsNothingScheduledYet => 'Es wurde bisher nichts geplant';

  @override
  String get theSelectedRooms => 'die gewählten Chats';

  @override
  String get theyWontBeAbleToJoinAgain => 'Kann dann nicht wieder beitreten';

  @override
  String get thirdParty => 'Drittanbieter';

  @override
  String get thisApaceIsEndToEndEncrypted => 'Dieser Space ist ende-zu-ende verschlüsselt';

  @override
  String get thisApaceIsNotEndToEndEncrypted => 'Dieser Space ist nicht ende-zu-ende verschlüsselt';

  @override
  String get thisIsAMultilineDescription => 'This is a multiline description of the task with lengthy texts and stuff';

  @override
  String get thisIsNotAProperActerSpace => 'Dies ist kein ordentlicher Acter Space. Einige Features sind mitunter nicht verfügbar.';

  @override
  String get thisMessageHasBeenDeleted => 'Diese Nachricht wurde gelöscht';

  @override
  String get thisWillAllowThemToContactYouAgain => 'Dies verhindert, dass sie wieder Kontakt mit dir aufnehmen';

  @override
  String get title => 'Titel';

  @override
  String get titleTheNewTask => 'Titel der neuen Aufgabe...';

  @override
  String typingUser1(Object user) {
    return '$user tippt…';
  }

  @override
  String typingUser2(Object user1, Object user2) {
    return '$user1 und $user2 tippen…';
  }

  @override
  String typingUserN(Object user, Object userCount) {
    return '$user und $userCount weitere tippen';
  }

  @override
  String get to => 'zu';

  @override
  String get toAccess => 'Für den Zugriff auf';

  @override
  String get needToBeMemberOf => 'musst du Mitglied sein von';

  @override
  String get today => 'Heute';

  @override
  String get token => 'Code';

  @override
  String get tokenAndPasswordMustBeProvided => 'Passwort und Code müssen angegeben werden';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get topic => 'Thema';

  @override
  String get tryingToConfirmToken => 'Versuche den Code zu bestätigen';

  @override
  String tryingToJoin(Object name) {
    return 'Trete $name bei';
  }

  @override
  String get tryToJoin => 'Versuche beizutreten';

  @override
  String get typeName => 'Name eingeben';

  @override
  String get unblock => 'Blockierung aufheben';

  @override
  String get unblockingUser => 'Userblockierung aufheben';

  @override
  String unblockingUserFailed(Object error) {
    return 'Blockierungsaufgabe fehlgeschlagen: $error';
  }

  @override
  String get unblockingUserProgress => 'Hebe Userblockierung auf';

  @override
  String get unblockingUserSuccess => 'Userblockierung aufgehoben. Es braucht eventuell einen Moment bevor die Oberfläche dies korrekt anzeigt.';

  @override
  String unblockTitle(Object userId) {
    return 'Blockierung von $userId aufheben';
  }

  @override
  String get unblockUser => 'Userblockierung aufheben';

  @override
  String unclearJoinRule(Object rule) {
    return 'Unklare Beitrittsregel $rule';
  }

  @override
  String get unreadMarkerFeatureTitle => 'Gelesen Tracking';

  @override
  String get unreadMarkerFeatureDescription => 'Verfolge und zeige welche Chats bereits gelesen wurden';

  @override
  String get undefined => 'undefiniert';

  @override
  String get unknown => 'unbekannt';

  @override
  String get unknownRoom => 'Unbekannter Chat';

  @override
  String get unlink => 'Entlinken';

  @override
  String get unmute => 'Ent-Stummschalten';

  @override
  String get unset => 'zurücksetzen';

  @override
  String get unsupportedPleaseUpgrade => 'Nicht unterstützt - Bitte aktualisiere die App!';

  @override
  String get unverified => 'Unverifiziert';

  @override
  String get unverifiedSessions => 'Unverifizierte Sitzungen';

  @override
  String get unverifiedSessionsDescription => 'Es sind Geräte in deinem Konto eingeloggt, die nicht verifiziert sind. Dies kann ein Sicherheitsrisiko sein. Bitte überprüfe, dass dies okay ist.';

  @override
  String unverifiedSessionsCount(int count) {
    return 'Es sind $count unverifizierte Sitzung eingeloggt';
  }

  @override
  String get upcoming => 'Kommende';

  @override
  String get updatePowerLevel => 'Zugriffslevel aktualisieren';

  @override
  String updateFeaturePowerLevelDialogTitle(Object feature) {
    return 'Berechtigungen von $feature aktualisieren';
  }

  @override
  String updateFeaturePowerLevelDialogFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'Von $memberStatus ($currentPowerLevel) zu';
  }

  @override
  String get updateFeaturePowerLevelDialogFromDefaultTo => 'von Standard zu';

  @override
  String get updatingDisplayName => 'Anzeigennamen aktualisieren';

  @override
  String get updatingDue => 'Aktualisiere Fälligkeit';

  @override
  String get updatingEvent => 'Aktualisiere Event';

  @override
  String updatingPowerLevelOf(Object userId) {
    return 'Aktualisiere Zugriffslevel von $userId';
  }

  @override
  String get updatingProfileImage => 'Aktualisiere Profilbild';

  @override
  String get updatingRSVP => 'Aktualisiere RSVP';

  @override
  String get updatingSpace => 'Aktualisiere Space';

  @override
  String get uploadAvatar => 'Avatar hochladen';

  @override
  String usedTimes(Object count) {
    return '$count benutzt';
  }

  @override
  String userAddedToBlockList(Object user) {
    return '$user zu Blockliste hinzugefügt. Es kann einen Moment dauern bevor dies in de UI sichtbar wird';
  }

  @override
  String get users => 'Nutzer';

  @override
  String get usersfoundDirectory => 'User in Verzeichnis gefunden';

  @override
  String get username => 'Benutzername';

  @override
  String get linkCopiedToClipboard => 'Link zur Zwischenablage kopiert';

  @override
  String get usernameCopiedToClipboard => 'Benutzername zur Zwischenablage kopiert';

  @override
  String get userRemovedFromList => 'Nutzer von der Liste entfernt. DIe UI braucht eventuell bevor dies sichtbar wird';

  @override
  String get usersYouBlocked => 'Von dir blockierte Nutzer';

  @override
  String get validEmail => 'Bitte gib eine gültige E-mail ein';

  @override
  String get verificationConclusionCompromised => 'Einer der folgen könnte kompromitiert sein:\n\n   - dein Homeserver\n   - der Homeserver des Nutzer den du zu verifizieren versuchts\n   - deine oder die Internetverbindung deines Gegenüber\n   - dein oder das Gerät deines Gegenüber';

  @override
  String verificationConclusionOkDone(String sender) {
    return 'Du hast $sender erfolgreich verifiziert!';
  }

  @override
  String get verificationConclusionOkSelfNotice => 'Deine Sitzung ist nun verifiziert. Verschlüsselte Nachricht werden mit ihr ausgetauscht und andere Nutzer bekommen sie als vertrauenswürdig angezeigt.';

  @override
  String get verificationEmojiNotice => 'Vergleiche die unterschiedliche Emoji, stelle sicher, dass diese in der Richtigen Reihenfolge erscheinen.';

  @override
  String get verificationRequestAccept => 'Um fortzufahren bitte die Verifikationsanfrage auf dem anderen Gerät annehmen.';

  @override
  String verificationRequestWaitingFor(String sender) {
    return 'Warte auf $sender…';
  }

  @override
  String get verificationSasDoNotMatch => 'Stimmen nicht überein';

  @override
  String get verificationSasMatch => 'Stimmen überein';

  @override
  String get verificationScanEmojiTitle => 'Kann nicht scannen';

  @override
  String get verificationScanSelfEmojiSubtitle => 'Stattdessen per Emoji-Vergleich verifizieren';

  @override
  String get verificationScanSelfNotice => 'Scanne den Code mit dem anderen Gerät oder wechsle um mit diesem Gerät zu scannen';

  @override
  String get verified => 'Verifiziert';

  @override
  String get verifiedSessionsDescription => 'All deine Geräte sind verifiziert. Dein Konto ist abgesichert.';

  @override
  String get verifyOtherSession => 'Andere Sitzung verifizieren';

  @override
  String get verifySession => 'Sitzung verifizieren';

  @override
  String get verifyThisSession => 'Verifiziere diese Sitzung';

  @override
  String get version => 'Version';

  @override
  String get via => 'per';

  @override
  String get video => 'Video';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get welcomeTo => 'Willkommen bei ';

  @override
  String get whatToCallThisChat => 'Wie soll dieser Chat heißen?';

  @override
  String get yes => 'Ja';

  @override
  String get yesLeave => 'Ja, verlassen';

  @override
  String get yesPleaseUpdate => 'Ja, bitte upgraden';

  @override
  String get youAreAbleToJoinThisRoom => 'Du kannst beitreten';

  @override
  String youAreAboutToBlock(Object userId) {
    return 'Du bist dabei $userId zu blockieren';
  }

  @override
  String youAreAboutToUnblock(Object userId) {
    return 'Du bist dabei die Blockierung von $userId aufzuheben';
  }

  @override
  String get youAreBothIn => 'ihr seid beide in ';

  @override
  String get youAreCurrentlyNotConnectedToAnySpaces => 'Du hast aktuell keine Space';

  @override
  String get spaceShortDescription => 'Erstelle einen Space um mit dem Organizing und Kollaborieren zu beginnen!';

  @override
  String get youAreDoneWithAllYourTasks => 'Du bist mit allen Aufgaben fertig!';

  @override
  String get youAreNotAMemberOfAnySpaceYet => 'Du bist bisher kein Mitglied eines Spaces';

  @override
  String get youAreNotPartOfThisGroup => 'Du bist nicht Teil der Gruppe. Willst du beitreten?';

  @override
  String get youHaveNoDMsAtTheMoment => 'Du hast aktuell keine DMs';

  @override
  String get youHaveNoUpdates => 'Du hast keine Updates';

  @override
  String get youHaveNotCreatedInviteCodes => 'Du hast bisher keine Einladungscodes generiert';

  @override
  String get youMustSelectSpace => 'Du must einen Space auswählen';

  @override
  String get youNeedBeInvitedToJoinThisRoom => 'Du musst eingeladen werden um dem Chat beitreten zu können';

  @override
  String get youNeedToEnterAComment => 'Du musst einen Kommentar eingeben';

  @override
  String get youNeedToEnterCustomValueAsNumber => 'Du musst den Wert als Zahl angeben.';

  @override
  String youCantExceedPowerLevel(Object powerLevel) {
    return 'Du kannst das Zugriffslevel $powerLevel nicht übersteigen';
  }

  @override
  String get yourActiveDevices => 'Deine aktiven Geräte';

  @override
  String get yourPassword => 'Dein Passwort';

  @override
  String get yourSessionHasBeenTerminatedByServer => 'Deine Sitzung wurde vom Server beendet. Bitte log dich erneut ein';

  @override
  String get yourTextSlidesMustContainsSomeText => 'Die Text-Slide muss Text enthalten';

  @override
  String get yourSafeAndSecureSpace => 'Dein sicherer Space für Digitalen Aktivismus.';

  @override
  String adding(Object email) {
    return 'füge $email hinzu';
  }

  @override
  String get addTextSlide => 'Text-Slide hinzufügen';

  @override
  String get addImageSlide => 'Bild-Slide hinzufügen';

  @override
  String get addVideoSlide => 'Video-Slide hinzufügen';

  @override
  String get acter => 'Acter';

  @override
  String get acterApp => 'Acter App';

  @override
  String get activate => 'Aktivieren';

  @override
  String get changingNotificationMode => 'Ändere Benachrichtigungsmodus.…';

  @override
  String get createComment => 'Kommentar erstellen';

  @override
  String get createNewPin => 'Neuen Pin erstellen';

  @override
  String get createNewSpace => 'Neuen Space erstellen';

  @override
  String get createNewTaskList => 'Neue Aufgabenliste erstellen';

  @override
  String get creatingPin => 'Erstelle Pin…';

  @override
  String get deactivateAccount => 'Konto deaktivieren';

  @override
  String get deletingCode => 'Code löschen';

  @override
  String get dueToday => 'Heute fällig';

  @override
  String get dueTomorrow => 'Morgen fällig';

  @override
  String get dueSuccess => 'Fälligkeit geändert';

  @override
  String get endDate => 'Enddatum';

  @override
  String get endTime => 'Endzeit';

  @override
  String get emailAddress => 'E-Mail Adresse';

  @override
  String get emailAddresses => 'E-Mail Adressen';

  @override
  String get errorParsinLink => 'Link parsen gescheitert';

  @override
  String errorCreatingPin(Object error) {
    return 'Pin erstellen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingAttachments(Object error) {
    return 'Fehler beim Laden der Anhänge: $error';
  }

  @override
  String errorLoadingAvatar(Object error) {
    return 'Avatarladen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'Profilladen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingUsers(Object error) {
    return 'Userladen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingTasks(Object error) {
    return 'Aufgabenladen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingSpace(Object error) {
    return 'Spaceladen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingRelatedChats(Object error) {
    return 'Laden verwandter Chats fehlgeschlagen: $error';
  }

  @override
  String errorLoadingPin(Object error) {
    return 'Pinsladen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingEventDueTo(Object error) {
    return 'Eventladen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingImage(Object error) {
    return 'Imageladen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingRsvpStatus(Object error) {
    return 'RSVP-status laden fehlgeschlagen: $error';
  }

  @override
  String errorLoadingEmailAddresses(Object error) {
    return 'Fehler beim Laden der E-Mail-Adressen: $error';
  }

  @override
  String errorLoadingMembersCount(Object error) {
    return 'Mitgliederzahlladen fehlgeschlagen: $error';
  }

  @override
  String errorLoadingTileDueTo(Object error) {
    return 'Laden des Titel fehlgeschlagen: $error';
  }

  @override
  String errorLoadingMember(Object error, Object memberId) {
    return 'Laden des Mitglied $memberId fehlgeschlagen: $error';
  }

  @override
  String errorSendingAttachment(Object error) {
    return 'Senden des Anhangs fehlgeschlagen: $error';
  }

  @override
  String get eventCreate => 'Event erstellen';

  @override
  String get eventEdit => 'Event bearbeiten';

  @override
  String get eventRemove => 'Event löschen';

  @override
  String get eventReport => 'Event melden';

  @override
  String get eventUpdate => 'Event aktualisieren';

  @override
  String get eventShare => 'Event teilen';

  @override
  String failedToAdd(Object error, Object something) {
    return 'Hinzufügen von $something fehlgeschlagen: $error';
  }

  @override
  String failedToChangePin(Object error) {
    return 'Pin-änderung fehlgeschlagen: $error';
  }

  @override
  String failedToChangePowerLevel(Object error) {
    return 'Ändern des Zugriffslevels fehlgeschlagen: $error';
  }

  @override
  String failedToChangeNotificationMode(Object error) {
    return 'Ändern des Benachrichtigungsmodus fehlgeschlagen: $error';
  }

  @override
  String failedToChangePushNotificationSettings(Object error) {
    return 'Ändern der Push-Einstellungen fehlgeschlagen: $error';
  }

  @override
  String failedToToggleSettingOf(Object error, Object module) {
    return 'Umschalten der $module Einstellung fehlgeschlagen: $error';
  }

  @override
  String failedToEditSpace(Object error) {
    return 'Spaceänderung fehlgeschlagen: $error';
  }

  @override
  String failedToAssignSelf(Object error) {
    return 'Freiwilligmelden fehlgeschlagen: $error';
  }

  @override
  String failedToUnassignSelf(Object error) {
    return 'Zurückziehen fehlgeschlagen: $error';
  }

  @override
  String failedToSend(Object error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String failedToCreateChat(Object error) {
    return 'Chat erstellen fehlgeschlagen: $error';
  }

  @override
  String failedToCreateTaskList(Object error) {
    return 'Erstellen der Aufgabenliste fehlgeschlagen: $error';
  }

  @override
  String failedToConfirmToken(Object error) {
    return 'Kode-Bestätigung fehlgeschlagen: $error';
  }

  @override
  String failedToSubmitEmail(Object error) {
    return 'Fehler beim Übermitteln der Email: $error';
  }

  @override
  String get failedToDecryptMessage => 'Konnte Nachricht nicht entschlüsseln. Sitzungsschlüssel erneut angefragt';

  @override
  String failedToDeleteAttachment(Object error) {
    return 'Löschen des Anhangs fehlgeschlagen: $error';
  }

  @override
  String get failedToDetectMimeType => 'Konnte Dateityp nicht ermitteln';

  @override
  String failedToLeaveRoom(Object error) {
    return 'Verlassen des Chat fehlgeschlagen: $error';
  }

  @override
  String failedToLoadSpace(Object error) {
    return 'Laden des Space fehlgeschlagen: $error';
  }

  @override
  String failedToLoadEvent(Object error) {
    return 'Laden des Events fehlgeschlagen: $error';
  }

  @override
  String failedToLoadInviteCodes(Object error) {
    return 'Invite-Codes laden fehlgeschlagen: $error';
  }

  @override
  String failedToLoadPushTargets(Object error) {
    return 'Laden der Pushziele fehlgeschlagen: $error';
  }

  @override
  String failedToLoadEventsDueTo(Object error) {
    return 'Laden der Events fehlgeschlagen: $error';
  }

  @override
  String failedToLoadChatsDueTo(Object error) {
    return 'Laden der Chats fehlgeschlagen: $error';
  }

  @override
  String failedToShareRoom(Object error) {
    return 'Teilen des Chat fehlgeschlagen: $error';
  }

  @override
  String get forgotYourPassword => 'Passwort vergessen?';

  @override
  String get editInviteCode => 'Einladungs-Code bearbeiten';

  @override
  String get createInviteCode => 'Einladungs-Code erstellen';

  @override
  String get selectSpacesAndChats => 'Räume und Chats auswählen';

  @override
  String get autoJoinSpacesAndChatsInfo => 'Beim Einlösen dieses Codes tritt die Person den ausgewählten Spaces und Chats automatisch bei.';

  @override
  String get createDM => 'DM erstellen';

  @override
  String get autoDMWhileRedeemCode => 'Beim Einlösen von Code wird eine DM mit dir erzeugt';

  @override
  String get redeemInviteCode => 'Einladung einlösen';

  @override
  String saveInviteCodeFailed(Object error) {
    return 'Speichern des Code fehlgeschlagen: $error';
  }

  @override
  String createInviteCodeFailed(Object error) {
    return 'Erstellen des Code fehlgeschlagen: $error';
  }

  @override
  String deleteInviteCodeFailed(Object error) {
    return 'Löschen des Code fehlgeschlagen: $error';
  }

  @override
  String get loadingChat => 'Lade Chats…';

  @override
  String get loadingCommentsList => 'Lade Kommentarliste';

  @override
  String get loadingPin => 'Lade Pin';

  @override
  String get loadingRoom => 'Lade Chat';

  @override
  String get loadingRsvpStatus => 'Lade RSVP status';

  @override
  String get loadingTargets => 'Lade Ziele';

  @override
  String get loadingOtherChats => 'Lade weiter Chats';

  @override
  String get loadingFirstSync => 'Lade ersten Sync';

  @override
  String get loadingImage => 'Lade Bild';

  @override
  String get loadingVideo => 'Lade Video';

  @override
  String loadingEventsFailed(Object error) {
    return 'Laden der Events fehlgeschlagen: $error';
  }

  @override
  String loadingTasksFailed(Object error) {
    return 'Laden der Aufgaben fehlgeschlagen: $error';
  }

  @override
  String loadingSpacesFailed(Object error) {
    return 'Laden der Spaces fehlgeschlagen: $error';
  }

  @override
  String loadingRoomFailed(Object error) {
    return 'Laden des Chat fehlgeschlagen: $error';
  }

  @override
  String loadingMembersCountFailed(Object error) {
    return 'Laden der Mitgliederzahl fehlgeschlagen: $error';
  }

  @override
  String get longPressToActivate => 'lange gedrückt halten zum Aktivieren';

  @override
  String get pinCreatedSuccessfully => 'Pin erfolgreich erstellt';

  @override
  String get pleaseSelectValidEndTime => 'Bitte eine gültige Endzeit angeben';

  @override
  String get pleaseSelectValidEndDate => 'Bitte ein gültiges Enddatum angeben';

  @override
  String powerLevelSubmitted(Object module) {
    return 'Zugriffslevel update für $module übermittelt';
  }

  @override
  String get optionalParentSpace => 'Optionaler Elternspace';

  @override
  String redeeming(Object token) {
    return '$token einlösen';
  }

  @override
  String get encryptedDMChat => 'Verschüsselter DM-Chat';

  @override
  String get encryptedChatMessage => 'Verschlüsselte Nachricht. Tap für mehr';

  @override
  String get encryptedChatMessageInfoTitle => 'Gesperrte Nachricht';

  @override
  String get encryptedChatMessageInfo => 'Chat Nachrichten sind ende-zu-ende-verschlüsselt. Das heißt, dass nur die Geräte die zum Zeitpunkt des Absendens angemeldet waren diese Nachricht entschlüsseln können. Falls du später beigetreten bist, dich neu eingeloggt oder ein neues Gerät eingeloggt hast kann es sein, dass du noch keinen Zugriff auf den Entschlüsselungs-Schlüssel hast. Du kannst diesen bekommen indem du diese Sitzung mit einer bestehenden verifizierst, das Verschlüsselungsbackup aktivierst oder das Gerät gegenüber einer Sitzung eines anderen User verifizierst.';

  @override
  String get chatMessageDeleted => 'Nachricht gelöscht';

  @override
  String chatJoinedDisplayName(Object name) {
    return '$name ist beigetreten';
  }

  @override
  String chatJoinedUserId(Object userId) {
    return '$userId ist beigetreten';
  }

  @override
  String get chatYouJoined => 'Du bist beigetreten';

  @override
  String get chatYouLeft => 'Du hast verlassen';

  @override
  String chatYouBanned(Object name) {
    return 'Du hast $name verbannt';
  }

  @override
  String chatYouUnbanned(Object name) {
    return 'You unbanned $name';
  }

  @override
  String chatYouKicked(Object name) {
    return 'You kicked $name';
  }

  @override
  String chatYouKickedBanned(Object name) {
    return 'You kicked and banned $name';
  }

  @override
  String chatUserLeft(Object name) {
    return '$name left';
  }

  @override
  String chatUserBanned(Object name, Object user) {
    return '$name banned $user';
  }

  @override
  String chatUserUnbanned(Object name, Object user) {
    return '$name unbanned $user';
  }

  @override
  String chatUserKicked(Object name, Object user) {
    return '$name kicked $user';
  }

  @override
  String chatUserKickedBanned(Object name, Object user) {
    return '$name kicked and banned $user';
  }

  @override
  String get chatYouAcceptedInvite => 'Du hast die Einladung angenommen';

  @override
  String chatYouInvited(Object name) {
    return 'Du hast eingeladen';
  }

  @override
  String chatInvitedDisplayName(Object invitee, Object name) {
    return '$name eingeladen';
  }

  @override
  String chatInvitedUserId(Object inviteeId, Object userId) {
    return '$userId eingeladen';
  }

  @override
  String chatInvitationAcceptedDisplayName(Object name) {
    return '$name hat die Einladung angenommen';
  }

  @override
  String chatInvitationAcceptedUserId(Object userId) {
    return '$userId hat die Einladung angenommen';
  }

  @override
  String chatDisplayNameUpdate(Object name) {
    return '$name updated display name from';
  }

  @override
  String chatDisplayNameSet(Object name) {
    return '$name set display name';
  }

  @override
  String chatDisplayNameUnset(Object name) {
    return '$name removed display name';
  }

  @override
  String chatUserAvatarChange(Object name) {
    return '$name updated profile avatar';
  }

  @override
  String get dmChat => 'DM Chat';

  @override
  String get regularSpaceOrChat => 'Regulärer Space oder Chat';

  @override
  String get encryptedSpaceOrChat => 'Verschlüsselter Space oder Chat';

  @override
  String get encryptedChatInfo => 'Alle Nachrichten in diesem Chat sind ende-zu-ende-verschlüsselt. Niemand außerhalb des Chats, auch nicht Acter oder irgend ein Matrix-Server der die Nachricht sieht, kann sie lesen.';

  @override
  String get removeThisPin => 'Pin löschen';

  @override
  String get removeThisPost => 'Post löschen';

  @override
  String get removingContent => 'Inhalt löschen';

  @override
  String get removingAttachment => 'Anhang löschen';

  @override
  String get reportThis => 'Melden';

  @override
  String get reportThisPin => 'Pin melden';

  @override
  String reportSendingFailedDueTo(Object error) {
    return 'Meldungssendung fehlgeschlagen: $error';
  }

  @override
  String get resettingPassword => 'Passwort zurücksetzen';

  @override
  String resettingPasswordFailed(Object error) {
    return 'Zurücksetzen fehlgeschlagen: $error';
  }

  @override
  String get resettingPasswordSuccessful => 'Passwort erfolgreich zurückgesetzt.';

  @override
  String get sharedSuccessfully => 'Erfolgreich geteilt';

  @override
  String get changedPushNotificationSettingsSuccessfully => 'Push Benachrichtigungs Einstellungen erfoglreich geändert';

  @override
  String get startDateRequired => 'Startdatum notwendig!';

  @override
  String get startTimeRequired => 'Startzeit notwendig!';

  @override
  String get endDateRequired => 'Enddatum notwendig!';

  @override
  String get endTimeRequired => 'Endzeit notwendig!';

  @override
  String get searchUser => 'Suche User';

  @override
  String seeAllMyEvents(Object count) {
    return 'Alle meine $count events ansehen';
  }

  @override
  String get selectSpace => 'Space auswählen';

  @override
  String get selectChat => 'Chat auswählen';

  @override
  String get selectCustomDate => 'Datum wählen';

  @override
  String get selectPicture => 'Bild auswählen';

  @override
  String get selectVideo => 'Video auswählen';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get selectTime => 'Zeit auswählen';

  @override
  String get sendDM => 'DM senden';

  @override
  String get showMore => 'mehr zeigen';

  @override
  String get showLess => 'weniger zeigen';

  @override
  String get joinSpace => 'Space beitreten';

  @override
  String get joinExistingSpace => 'Bestehenden Space beitreten';

  @override
  String get mySpaces => 'Deine Spaces';

  @override
  String get startDate => 'Anfangsdatum';

  @override
  String get startTime => 'Anfangszeit';

  @override
  String get startGroupDM => 'Gruppen DM beginnen';

  @override
  String get moreSubspaces => 'weiter Subspaces';

  @override
  String get myTasks => 'Deine Aufgaben';

  @override
  String updatingDueFailed(Object error) {
    return 'Fälligkeitsupdae fehlgeschlagen: $error';
  }

  @override
  String get unlinkRoom => 'Chat entlinken';

  @override
  String changeThePowerFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'von $memberStatus $currentPowerLevel zu';
  }

  @override
  String get createOrJoinSpaceDescription => 'Erstelle oder tritt einem Space bei um mit dem Organizing und Kollaborieren zu beginnen!';

  @override
  String get introPageDescriptionPre => 'Acter ist mehr als eine App\nEs ist';

  @override
  String get isLinked => 'Ist hier verlinkt';

  @override
  String get canLink => 'Du kannst dies verlinken';

  @override
  String get canLinkButNotUpgrade => 'Du kannst dies verlinken, aber die Zugangsregel nicht ändern';

  @override
  String get introPageDescriptionHl => ' - Community von ChangeMarkern.';

  @override
  String get introPageDescriptionPost => ' ';

  @override
  String get introPageDescription2ndLine => 'Verbinde dich mit anderen Aktivisti, teile Erkenntnisse und kollaboriere an bedeutsamen Projekten.';

  @override
  String get logOutConformationDescription1 => 'Vorsicht ';

  @override
  String get logOutConformationDescription2 => 'Sich abmelden entfernt die lokalen Daten, inklusive der Verschlüsselungsdaten. Wenn dies deine letzte eingeloggte Sitzung ist, kann es sein, dass du dadurch den Zugang zu allen bisherigen Daten verlierst.';

  @override
  String get logOutConformationDescription3 => ' Bist du sicher, dass du dich abmelden willst?';

  @override
  String membersCount(Object count) {
    return '$count Mitglieder';
  }

  @override
  String get renderSyncingTitle => 'Synchronisiere mit deinem Homeserver';

  @override
  String get renderSyncingSubTitle => 'Dies kann etwas dauern, solltest du ein großes Konto haben';

  @override
  String errorSyncing(Object error) {
    return 'Synchronisierung fehlgeschlagen: $error';
  }

  @override
  String get retrying => 'erneuter Versuch…';

  @override
  String retryIn(Object minutes, Object seconds) {
    return 'Werde in $minutes:$seconds erneut versuchen';
  }

  @override
  String get invitations => 'Einladungen';

  @override
  String invitingLoading(Object userId) {
    return 'Lade $userId ein';
  }

  @override
  String invitingError(Object error, Object userId) {
    return 'User $userId nicht gefunden oder nicht existent: $error';
  }

  @override
  String get invite => 'Einladen';

  @override
  String errorUnverifiedSessions(Object error) {
    return 'Sitzungen laden fehlgeschlagen: $error';
  }

  @override
  String unverifiedSessionsTitle(Object count) {
    return 'Es sind $count unverifizierte Sitzung eingeloggt';
  }

  @override
  String get review => 'Prüfen';

  @override
  String get activities => 'Aktivitäten';

  @override
  String get activitiesDescription => 'Alles wichtige, dass deiner Aufmerksamkeit bedarf, ist hier zu finden';

  @override
  String get noActivityTitle => 'Bisher keine Aktivitäten für dich';

  @override
  String get noActivitySubtitle => 'Informiert dich über wichtiges wie Benachrichtigungen, Einladungen oder Anfragen.';

  @override
  String get joining => 'Trete bei';

  @override
  String get joinedDelayed => 'Einladung angenommen, aber die Bestätigung scheint seine Zeit zu brauchen';

  @override
  String get rejecting => 'Weise ab';

  @override
  String get rejected => 'Abgewiesen';

  @override
  String get failedToReject => 'Abweisen fehlgeschlagen';

  @override
  String reportedBugSuccessful(Object issueId) {
    return 'Bug erfoglreich gemeldet! (#$issueId)';
  }

  @override
  String get thanksForReport => 'Danke, dass du den Bug gemeldet hast!';

  @override
  String bugReportingError(Object error) {
    return 'Bug-Meldung fehlgeschlagen: $error';
  }

  @override
  String get bugReportTitle => 'Ein Problem melden';

  @override
  String get bugReportDescription => 'Kurze Beschreibung des Problem';

  @override
  String get emptyDescription => 'Bitte eine Beschreibung angeben';

  @override
  String get includeUserId => 'Meine Matrix Nuter ID übermitteln';

  @override
  String get includeLog => 'Aktuelle Log-Dateien übermitteln';

  @override
  String get includePrevLog => 'Log-Dateien der vorherigen Sitzung übermitteln';

  @override
  String get includeScreenshot => 'Screenshot übermitteln';

  @override
  String get includeErrorAndStackTrace => 'Fehler & Stacktrace mitschicken';

  @override
  String get jumpTo => 'Wechsle zu';

  @override
  String get noMatchingPinsFound => 'Keine Pins gefunden';

  @override
  String get update => 'Update';

  @override
  String get event => 'Event';

  @override
  String get taskList => 'Aufgabenliste';

  @override
  String get pin => 'Pin';

  @override
  String get poll => 'Umfrage';

  @override
  String get discussion => 'Diskussion';

  @override
  String get fatalError => 'Fataler Fehler';

  @override
  String get nukeLocalData => 'Lokale Daten zerstören';

  @override
  String get reportBug => 'Bug melden';

  @override
  String get somethingWrong => 'Etwas ist erheblich schief gelaufen:';

  @override
  String get copyToClipboard => 'in die Zwischemablage kopieren';

  @override
  String get errorCopiedToClipboard => 'Error & Stack in die Zwischenablage kopiert';

  @override
  String get showStacktrace => 'Stack zeigen';

  @override
  String get hideStacktrace => 'Stack verstecken';

  @override
  String get sharingRoom => 'Teile diesen Chat…';

  @override
  String get changingSettings => 'Ändere Einstellung…';

  @override
  String changingSettingOf(Object module) {
    return 'Änderung Einstellung von $module';
  }

  @override
  String changedSettingOf(Object module) {
    return 'Einstellung von $module geändert';
  }

  @override
  String changingPowerLevelOf(Object module) {
    return 'Ändere Zugriffslevel von $module';
  }

  @override
  String get assigningSelf => 'Zuweisen…';

  @override
  String get unassigningSelf => 'Hebe Zuweisung auf…';

  @override
  String get homeTabTutorialTitle => 'Home';

  @override
  String get homeTabTutorialDescription => 'Dies ist deine Übersicht zu deinen Spaces, deinen anstehende Events und offenen Aufgaben.';

  @override
  String get updatesTabTutorialTitle => 'Updates';

  @override
  String get updatesTabTutorialDescription => 'Newsstream der neuesten Updates und Call-to-actions direkt von deinem Space.';

  @override
  String get chatsTabTutorialTitle => 'Chats';

  @override
  String get chatsTabTutorialDescription => 'Hier findest du eine Chats - mit Gruppen und Einzellpersonen. Chats können verschiedenen Spaces für breitere Kollaboration zugewiesen werden.';

  @override
  String get activityTabTutorialTitle => 'Aktivitäten';

  @override
  String get activityTabTutorialDescription => 'Wichtiges aus deinen Spaces, wie Einladungen und Anfragen. Sowie Benachrichtigungen bei Sicherheitsaspekten, die deine Aufmerksamkeit bedürfen';

  @override
  String get jumpToTabTutorialTitle => 'Wechlse Zu';

  @override
  String get jumpToTabTutorialDescription => 'Die Suche für deine Spaces und Daten darin und Direktwahl für übliche Aktionen.';

  @override
  String get createSpaceTutorialTitle => 'Neuen Space erstellen';

  @override
  String get createSpaceTutorialDescription => 'Tritt einem bestehenden Space auf unserem Server oder dem Matrix Universum bei oder erstelle deinen eigenen Space.';

  @override
  String get joinSpaceTutorialTitle => 'Bestehendem Space beitreten';

  @override
  String get joinSpaceTutorialDescription => 'Tritt einem bestehenden Space auf unserem Server oder dem Matrix Universum bei oder erstelle deinen eigenen Space.';

  @override
  String get spaceOverviewTutorialTitle => 'Spacedetails';

  @override
  String get spaceOverviewTutorialDescription => 'Spaces sind der Mittelpunkt des Organizing. Erstelle Pins, Tasks und Events und manage über Chats und Subspaces.';

  @override
  String get subscribedToParentMsg => 'Benachrichtigungen auf dem Hauptobject deaktiveren, um diese hier zu aktievieren';

  @override
  String get parentSubscribedAction => 'Benachrichtigungen über Objekt aktiv';

  @override
  String get subscribeAction => 'Benachrichtigungen aktivieren';

  @override
  String get unsubscribeAction => 'Benachrichtigungen deaktivieren';

  @override
  String get commentEmptyStateTitle => 'Keine Kommentare gefunden.';

  @override
  String get commentEmptyStateAction => 'Erstelle den ersten Kommentar';

  @override
  String get previous => 'Vorherige';

  @override
  String get finish => 'Beenden';

  @override
  String get saveUsernameTitle => 'Hast du deinen Usernamen gespeichert?';

  @override
  String get saveUsernameDescription1 => 'Bitte notiere deinen Username. Es ist dein Zugang zu deinem Profil und allen deinen Informationen und Spaces.';

  @override
  String get saveUsernameDescription2 => 'Dein Username ist unabdingbar um dein Passwort zurücksetzen zu können.';

  @override
  String get saveUsernameDescription3 => 'Ohne ihn ist der Zugang zu deinem Profil dauerhaft verloren.';

  @override
  String get acterUsername => 'Dein Acter Username';

  @override
  String get autoSubscribeFeatureDesc => 'bei Erstellen oder Interaktion mit Objekten';

  @override
  String get autoSubscribeSettingsTitle => 'Automatische abbonieren';

  @override
  String get copyToClip => 'In die Zwischenablage kopieren';

  @override
  String get wizzardContinue => 'Weiter';

  @override
  String get protectPrivacyTitle => 'Deine Privatsphäre schützen';

  @override
  String get protectPrivacyDescription1 => 'Dein Profil sicher zu halten ist uns bei Acter sehr wichtig. Daher kannst du es nutzen ohne weitere Profile oder Emails angeben zu müssen, die Dinge über dich verraten könnten.';

  @override
  String get protectPrivacyDescription2 => 'Aber wir empfehlen es mit einer E-Mail zu verlinken, um z.B. Passwort Reset durchführen zu können.';

  @override
  String get linkEmailToProfile => 'Mit Email verknüpfen';

  @override
  String get emailOptional => 'Email (Optional)';

  @override
  String get hintEmail => 'Gib deine Email Adresse an';

  @override
  String get linkingEmailAddress => 'Verknüpfe deine Email-Adresse';

  @override
  String get avatarAddTitle => 'User Profilbild hinzufügen';

  @override
  String get avatarEmpty => 'Bitte wähle dein Profilbild';

  @override
  String get avatarUploading => 'Lade das Profilbild hoch';

  @override
  String avatarUploadFailed(Object error) {
    return 'Fehler beim Hochladen des Profilbilds: $error';
  }

  @override
  String get sendEmail => 'Email senden';

  @override
  String get inviteCopiedToClipboard => 'Einaldundskode in die Zwischenablage kopiert';

  @override
  String get updateName => 'Name aktualisieren';

  @override
  String get updateDescription => 'Beschreibung aktualisieren';

  @override
  String get editName => 'Name editieren';

  @override
  String get editDescription => 'Beschreibung editieren';

  @override
  String updateNameFailed(Object error) {
    return 'Namesaktualisierung fehlgeschlagen: $error';
  }

  @override
  String updateDescriptionFailed(Object error) {
    return 'Beschreibungsaktualisierungfehlgeschlagen: $error';
  }

  @override
  String get eventParticipants => 'Teilnehmende';

  @override
  String get upcomingEvents => 'Anstehende Events';

  @override
  String get spaceInviteDescription => 'Möchtest du jemand zu diesen Space einladen?';

  @override
  String get inviteSpaceMembersTitle => 'Space Mitglieder einladen';

  @override
  String get inviteSpaceMembersSubtitle => 'Mitglieder des ausgewählen Space einladen';

  @override
  String get inviteIndividualUsersTitle => 'Individuelle User einladen';

  @override
  String get inviteIndividualUsersSubtitle => 'User einladen, die bereits auf Acter sind';

  @override
  String get inviteIndividualUsersDescription => 'Lade ein, wer schon auf der Acter platform ist';

  @override
  String get inviteJoinActer => 'Einladung um Acter beizutreten';

  @override
  String get inviteJoinActerDescription => 'Du kannst einen eigenen Registrierungskode erstellen mit dem Menschen Acter und auch automatisch diesem Space beitreten können';

  @override
  String get generateInviteCode => 'Einladungs-Kode generieren';

  @override
  String get pendingInvites => 'Offene Einladungen';

  @override
  String pendingInvitesCount(Object count) {
    return 'Du hast $count Einladungen';
  }

  @override
  String get noPendingInvitesTitle => 'Keine offenen Einladungen gefunden';

  @override
  String get noUserFoundTitle => 'Keine User gefunden';

  @override
  String get noUserFoundSubtitle => 'Suche nach Users mit ihrem Usernamen oder Anzeigenamen';

  @override
  String get done => 'Fertig';

  @override
  String get downloadFileDialogTitle => 'Speicherort wählen';

  @override
  String downloadFileSuccess(Object path) {
    return 'Datei gespeichert unter $path';
  }

  @override
  String cancelInviteLoading(Object userId) {
    return 'Einladung an $userId wird gelöscht';
  }

  @override
  String cancelInviteError(Object error, Object userId) {
    return 'User $userId nicht gefunden: $error';
  }

  @override
  String get shareInviteCode => 'Einlaungs-Kode teilen';

  @override
  String get appUnavailable => 'App nicht verfügbar';

  @override
  String shareInviteContent(Object code, Object roomName, Object userName) {
    return '$userName möchte dich zu $roomName einladen.\nBitte führe folgende Schritte durch um mitzumachen:\n\n1. Lade dir die Acter App hier herunter: https://app-redir.acter.global/\n\n2. Benutze den folgenden Einladungs-Kode um dich zu registrieren:\nEinladungs-Kode: $code\n\nDas war’s schon! Viel Erfolg bei eurem neuen Weg euch zu organisieren!';
  }

  @override
  String activateInviteCodeFailed(Object error) {
    return 'Kode-Aktivierung fehlgeschlagen: $error';
  }

  @override
  String get revoke => 'Zurücknehmen';

  @override
  String get otherSpaces => 'Andere Spaces';

  @override
  String get invitingSpaceMembersLoading => 'Space Mitglieder einladen';

  @override
  String invitingSpaceMembersProgress(Object count, Object total) {
    return 'Einladung von Space Mitgliedern $count / $total';
  }

  @override
  String invitingSpaceMembersError(Object error) {
    return 'Fehler beim Einladen der Space Mitglieder: $error';
  }

  @override
  String membersInvited(Object count) {
    return '$count Mitglieder eingeladen';
  }

  @override
  String get selectVisibility => 'Sichtbarkeit wählen';

  @override
  String get visibilityTitle => 'Sichtbarkeit';

  @override
  String get visibilitySubtitle => 'Wähle wer diesem Space beitreten kann.';

  @override
  String get visibilityNoPermission => 'Du hast nicht die nötigen Berechtigungen um die Space Sichtbarkeit zu ändern';

  @override
  String get public => 'Öffentlich';

  @override
  String get publicVisibilitySubtitle => 'Jede:r kann finden und beitreten';

  @override
  String get privateVisibilitySubtitle => 'Nur Eingeladene können beitreten';

  @override
  String get limited => 'Limitiert';

  @override
  String get limitedVisibilitySubtitle => 'Mitglieder der ausgewählten Spaces können finden und beitreten';

  @override
  String get visibilityAndAccessibility => 'Sichtbarkeit und Zugang';

  @override
  String updatingVisibilityFailed(Object error) {
    return 'Ändern der Raum Sichtbarkeit fehlgeschlagen: $error';
  }

  @override
  String get spaceWithAccess => 'Spaces mit Zugang';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get changePasswordDescription => 'Ändere dein Passwort';

  @override
  String get oldPassword => 'Altes Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmPassword => 'Neues Passwort bestätigen';

  @override
  String get emptyOldPassword => 'Bitte das alte Passwort eingeben';

  @override
  String get emptyNewPassword => 'Bitte das neue Passwort eingeben';

  @override
  String get emptyConfirmPassword => 'Bitte das neue Passwort zur Bestätigung eingeben';

  @override
  String get validateSamePassword => 'Die Passwörter müssen übereinstimmen';

  @override
  String get changingYourPassword => 'Ändere dein Passwort';

  @override
  String changePasswordFailed(Object error) {
    return 'Passwortänderung fehlgeschlagen: $error';
  }

  @override
  String get passwordChangedSuccessfully => 'Passwort erfolgreich geändernt';

  @override
  String get emptyTaskList => 'Bisher keine Aufgabenlisten erstellt';

  @override
  String get addMoreDetails => 'Mehr Details hinzufügen';

  @override
  String get taskName => 'Aufgnamentitel';

  @override
  String get addingTask => 'Füge Aufgabe hinzu';

  @override
  String countTasksCompleted(Object count) {
    return '$count Abgeschlossen';
  }

  @override
  String get showCompleted => 'Abgeschlossene anzeigen';

  @override
  String get hideCompleted => 'Abgeschlossene verstecken';

  @override
  String get assignment => 'Zuteilung';

  @override
  String get noAssignment => 'Keine Zuteilung';

  @override
  String get assignMyself => 'Mir zuteilen';

  @override
  String get removeMyself => 'Meine Zuteilung entfernen';

  @override
  String get updateTask => 'Aufgabe aktualisieren';

  @override
  String get updatingTask => 'Aufgabe aktualiseren';

  @override
  String updatingTaskFailed(Object error) {
    return 'Aufgaben Aktualisierung fehlgeschlagen: $error';
  }

  @override
  String get editTitle => 'Titel ändern';

  @override
  String get updatingDescription => 'Aktualisiere Beschreibung';

  @override
  String errorUpdatingDescription(Object error) {
    return 'Beschreibungs-Aktualisierung fehlgeschlagen: $error';
  }

  @override
  String get editLink => 'Link ändern';

  @override
  String get updatingLinking => 'Link aktualisieren';

  @override
  String get deleteTaskList => 'ToDo-Liste löschen';

  @override
  String get deleteTaskItem => 'Aufgabe löschen';

  @override
  String get reportTaskList => 'ToDo-Liste melden';

  @override
  String get reportTaskItem => 'Aufgabe melden';

  @override
  String get unconfirmedEmailsActivityTitle => 'Du hast unbestätigte E-Mail Addressen';

  @override
  String get unconfirmedEmailsActivitySubtitle => 'Bitte folge dem Link, den wir dir per E-Mail geschickt haben um diese zu bestätigen';

  @override
  String get seeAll => 'Alle zeigen';

  @override
  String get addPin => 'Pin hinzufügen';

  @override
  String get addEvent => 'Event hinzufügen';

  @override
  String get linkChat => 'Chat verlinken';

  @override
  String get linkSpace => 'Space verlinken';

  @override
  String failedToUploadAvatar(Object error) {
    return 'Avatar upload fehlgeschlagen: $error';
  }

  @override
  String get noMatchingTasksListFound => 'Keine passenden ToDo-Listen gefunden';

  @override
  String get noTasksListAvailableYet => 'Noch keine ToDo-Listen verfügbar';

  @override
  String get noTasksListAvailableDescription => 'Teile und gemeinschaftlich organisiere Aufgaben über ToDo-Listen.';

  @override
  String loadingMembersFailed(Object error) {
    return 'Mitglieder laden fehlgeschlagen: $error';
  }

  @override
  String get ongoing => 'aktuell';

  @override
  String get noMatchingEventsFound => 'Keine passenden Events gefunden';

  @override
  String get noEventsFound => 'Keine Events gefunden';

  @override
  String get noEventAvailableDescription => 'Erstelle ein Event und bringe deine Gemeinschaft zusammen.';

  @override
  String get myEvents => 'Meine Events';

  @override
  String get eventStarted => 'Begonnen';

  @override
  String get eventStarts => 'Beginnt';

  @override
  String get eventEnded => 'Endet';

  @override
  String get happeningNow => 'Findet jetzt statt';

  @override
  String get myUpcomingEvents => 'Meine kommenden Events';

  @override
  String get live => 'Live';

  @override
  String get forbidden => 'Untersagt';

  @override
  String get forbiddenRoomExplainer => 'Access to the room has been denied. Please contact the author to be invited';

  @override
  String accessDeniedToRoom(Object roomId) {
    return 'Zugang zu $roomId abgelehnt';
  }

  @override
  String get changeDate => 'Datum ändern';

  @override
  String deepLinkNotSupported(Object link) {
    return 'Link $link nicht unterstützt';
  }

  @override
  String get deepLinkWrongFormat => 'Kein Link. Kann es nicht öffnen.';

  @override
  String get updatingDate => 'Aktualisiere Datum';

  @override
  String get pleaseEnterALink => 'Bitte einen Link eingeben';

  @override
  String get pleaseEnterAValidLink => 'Bitte einen gültigen Link eingeben';

  @override
  String get addLink => 'Link hinzufügen';

  @override
  String get attachmentEmptyStateTitle => 'Keine Anhänge gefunden.';

  @override
  String get referencesEmptyStateTitle => 'Keine Referenzen gefunden.';

  @override
  String get text => 'Text';

  @override
  String get audio => 'Audio';

  @override
  String get pinDetails => 'Pin Details';

  @override
  String get inSpaceLabelInline => 'In:';

  @override
  String get comingSoon => 'Noch nicht unterstützt. kommt bald!';

  @override
  String get colonCharacter => ' : ';

  @override
  String get andSeparator => ' und ';

  @override
  String andNMore(Object count) {
    return ', und $count mehr';
  }

  @override
  String errorLoadingSpaces(Object error) {
    return 'Fehler beim Space Laden: $error';
  }

  @override
  String get eventNoLongerAvailable => 'Event nicht länger verfügbar';

  @override
  String get eventDeletedOrFailedToLoad => 'Das Event wurde gelöscht oder kann nicht geladen werden';

  @override
  String get chatNotEncrypted => 'Dieser Chat ist nicht ende-zu-ende-verschlüsselt';

  @override
  String get updatingIcon => 'Icon aktualiseren';

  @override
  String get selectColor => 'Farbe wählen';

  @override
  String get selectIcon => 'Icon wählen';

  @override
  String get createCategory => 'Kategorie erstellen';

  @override
  String get organize => 'Organisieren';

  @override
  String get updatingCategories => 'Kategorien aktualisieren';

  @override
  String get uncategorized => 'Ohne Kategorie';

  @override
  String updatingCategoriesFailed(Object error) {
    return 'Kategorien-Update fehlgeschlagen: $error';
  }

  @override
  String get addingNewCategory => 'Füge neue Kategorie hinzu';

  @override
  String addingNewCategoriesFailed(Object error) {
    return 'Kategorie-Hinzufügen fehlgeschlagen: $error';
  }

  @override
  String get action => 'Aktion';

  @override
  String get addCategory => 'Kategorie hinzufügen';

  @override
  String get editCategory => 'Kategorie bearbeiten';

  @override
  String get deleteCategory => 'Kategorie löschen';

  @override
  String get boost => 'Boost';

  @override
  String get boosts => 'Boosts';

  @override
  String get requiredPowerLevel => 'Benötigte Rechte';

  @override
  String minPowerLevelDesc(Object featureName) {
    return 'Minimales Rechtelevel um $featureName zu posten';
  }

  @override
  String get minPowerLevelRsvp => 'Minimal Rechtelevel um auf Kalendar Event einladungen zu antworten';

  @override
  String get commentsOnBoost => 'Boost kommentieren';

  @override
  String get commentsOnPin => 'Pin kommentieren';

  @override
  String get adminPowerLevel => 'Admin Rechtelevel';

  @override
  String get rsvpPowerLevel => 'RSVP Rechtelevel';

  @override
  String get taskListPowerLevel => 'Aufgabenlisten Rechtelevel';

  @override
  String get tasksPowerLevel => 'Aufgaben Rechtelevel';

  @override
  String get appSettings => 'App Einstellungen';

  @override
  String get activeApps => 'Aktive Apps';

  @override
  String get postSpaceWiseBoost => 'Space-weiten Boost posten';

  @override
  String get postSpaceWiseStories => 'Post space-wide stories';

  @override
  String get pinImportantInformation => 'Wichtige Informationen anpinnen';

  @override
  String get calenderWithEvents => 'Kalender mit Events';

  @override
  String get pinNoLongerAvailable => 'Pin nicht mehr verfügbar';

  @override
  String get inviteCodeEmptyState => 'No invite codes are generated yet';

  @override
  String get pinDeletedOrFailedToLoad => 'Vielleicht wurde der Pin gelöscht oder konnte nicht geladen werden';

  @override
  String get sharePin => 'Pin teilen';

  @override
  String get selectPin => 'Pin wählen';

  @override
  String get selectEvent => 'Event auswählen';

  @override
  String get shareTaskList => 'Aufgabenliste teilen';

  @override
  String get shareSpace => 'Share Space';

  @override
  String get shareChat => 'Share Chat';

  @override
  String get addBoost => 'Boost hinzufügen';

  @override
  String get addTaskList => 'Aufgabenliste hinzufügen';

  @override
  String get task => 'Aufgabe';

  @override
  String get signal => 'Signal';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get whatsAppBusiness => 'WA Business';

  @override
  String get telegram => 'Telegram';

  @override
  String get copy => 'kopieren';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get qr => 'QR';

  @override
  String get newBoost => 'Neuer\nBoost';

  @override
  String get addComment => 'Kommentieren';

  @override
  String get references => 'Referenzen';

  @override
  String get removeReference => 'Referenz entfernen';

  @override
  String get suggestedChats => 'Vorgeschlagene Chats';

  @override
  String get suggestedSpaces => 'Vorgeschlagene Spaces';

  @override
  String get removeReferenceConfirmation => 'Bist du sicher, dass du diese Referenz entfernen möchtest?';

  @override
  String noObjectAccess(Object objectType, Object spaceName) {
    return 'Du bist nicht teil von $spaceName, daher hast du keinen Zugriff auf $objectType';
  }

  @override
  String get shareLink => 'Link teilen';

  @override
  String get shareSuperInvite => 'Share Invitation Code';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get unableToLoadVideo => 'Video laden fehlgeschlagen';

  @override
  String get unableToLoadImage => 'Image laden fehlgeschlagen';

  @override
  String get story => 'Story';

  @override
  String get storyInfo => 'Everyone can see, this is from you';

  @override
  String get boostInfo => 'Important News. Sends a push notification to space members';

  @override
  String get notHaveBoostStoryPermission => 'You do not have permission to post Boost or Story in selected space';

  @override
  String get pleaseSelectePostType => 'Please select post type';

  @override
  String get postTo => 'Post to';

  @override
  String get post => 'Post';

  @override
  String get stories => 'Stories';

  @override
  String get addStory => 'Add Story';

  @override
  String get unableToLoadFile => 'Unable to load file';
}
