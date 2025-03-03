// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class L10nPl extends L10n {
  L10nPl([String locale = 'pl']) : super(locale);

  @override
  String get about => 'O Acter';

  @override
  String get accept => 'Akceptuj';

  @override
  String get acceptRequest => 'Akceptuj żądanie';

  @override
  String get access => 'Dostęp';

  @override
  String get accessAndVisibility => 'Dostęp i widoczność';

  @override
  String get account => 'Konto';

  @override
  String get actionName => 'Nazwa działania';

  @override
  String get actions => 'Działania';

  @override
  String activateFeatureDialogTitle(Object feature) {
    return 'Activate $feature?';
  }

  @override
  String activateFeatureDialogDesc(Object feature) {
    return 'Allow anyone with permission following permissions to use $feature';
  }

  @override
  String get add => 'dodać';

  @override
  String get addActionWidget => 'Dodaj widżet akcji';

  @override
  String get addChat => 'Dodaj czat';

  @override
  String addedToPusherList(Object email) {
    return '$email dodany do listy popychaczy';
  }

  @override
  String addedToSpacesAndChats(Object number) {
    return 'Dodano do $number przestrzeni i czatów';
  }

  @override
  String get addingEmailAddress => 'Dodawanie adresu e-mail';

  @override
  String get addSpace => 'Dodaj miejsce';

  @override
  String get addTask => 'Dodaj zadanie';

  @override
  String get admin => 'Admin';

  @override
  String get all => 'Wszystko';

  @override
  String get allMessages => 'Wszystkie wiadomości';

  @override
  String allReactionsCount(Object total) {
    return 'All $total';
  }

  @override
  String get alreadyConfirmed => 'Już potwierdzone';

  @override
  String get analyticsTitle => 'Help us help you';

  @override
  String get analyticsDescription1 => 'By sharing crash analytics and error reports with us.';

  @override
  String get analyticsDescription2 => 'These are of course anonymized and do not contain any private information';

  @override
  String get sendCrashReportsTitle => 'Send crash & error reports';

  @override
  String get sendCrashReportsInfo => 'Share crash tracebacks via sentry with the Acter team automatically';

  @override
  String get and => 'i';

  @override
  String get anInviteCodeYouWantToRedeem => 'Kod zaproszenia, który chcesz zrealizować';

  @override
  String get anyNumber => 'dowolny numer';

  @override
  String get appDefaults => 'Domyślne ustawienia aplikacji';

  @override
  String get appId => 'AppID';

  @override
  String get appName => 'Nazwa aplikacji';

  @override
  String get apps => 'Apps';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'Czy na pewno chcesz usunąć tę wiadomość? Tej czynności nie można cofnąć.';

  @override
  String get areYouSureYouWantToLeaveRoom => 'Czy na pewno chcesz opuścić to miejsce? Tego działania nie można cofnąć';

  @override
  String get areYouSureYouWantToLeaveSpace => 'Czy na pewno chcesz opuścić to miejsce?';

  @override
  String get areYouSureYouWantToRemoveAttachmentFromPin => 'Czy na pewno chcesz usunąć ten załącznik z pinezki?';

  @override
  String get areYouSureYouWantToUnregisterEmailAddress => 'Czy na pewno chcesz wyrejestrować ten adres e-mail? Tej czynności nie można cofnąć.';

  @override
  String get assignedYourself => 'przypisany sobie';

  @override
  String get assignmentWithdrawn => 'Zadanie wycofane';

  @override
  String get aTaskMustHaveATitle => 'Zadanie musi mieć tytuł';

  @override
  String get attachments => 'Załączniki';

  @override
  String get atThisMomentYouAreNotJoiningEvents => 'W tej chwili nie dołączasz do żadnych nadchodzących wydarzeń. Aby dowiedzieć się, jakie wydarzenia są zaplanowane, sprawdź swoje miejsca.';

  @override
  String get authenticationRequired => 'Wymagane uwierzytelnienie';

  @override
  String get avatar => 'Awatar';

  @override
  String get awaitingConfirmation => 'Oczekuje na potwierdzenie';

  @override
  String get awaitingConfirmationDescription => 'Te adresy e-mail nie zostały jeszcze potwierdzone. Przejdź do swojej skrzynki odbiorczej i sprawdź link potwierdzający.';

  @override
  String get back => 'Back';

  @override
  String get block => 'Blokuj';

  @override
  String get blockedUsers => 'Zablokowani użytkownicy';

  @override
  String get blockInfoText => 'Po zablokowaniu nie będziesz już widzieć ich wiadomości i zablokuje to ich próby bezpośredniego kontaktu z Tobą.';

  @override
  String blockingUserFailed(Object error) {
    return 'Blokowanie użytkownika nie powiodło się: $error';
  }

  @override
  String get blockingUserProgress => 'Blokowanie użytkownika';

  @override
  String get blockingUserSuccess => 'Użytkownik zablokowany. Może minąć trochę czasu, zanim interfejs użytkownika odzwierciedli tę aktualizację.';

  @override
  String blockTitle(Object userId) {
    return 'Blokuj $userId';
  }

  @override
  String get blockUser => 'Blokuj użytkownika';

  @override
  String get blockUserOptional => 'Blokuj użytkownika (opcjonalnie)';

  @override
  String get blockUserWithUsername => 'Blokowanie użytkownika z nazwą użytkownika';

  @override
  String get bookmark => 'Zakładka';

  @override
  String get bookmarked => 'Dodany do zakładek';

  @override
  String get bookmarkedSpaces => 'Bookmarked Spaces';

  @override
  String get builtOnShouldersOfGiants => 'Zbudowany na ramionach gigantów';

  @override
  String get calendarEventsFromAllTheSpaces => 'Kalendarz wydarzeń ze wszystkich przestrzeni, których jesteś częścią';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarSyncFeatureTitle => 'Calendar Sync';

  @override
  String get calendarSyncFeatureDesc => 'Sync (tentative and accepted) events with device calendar (Android & iOS only)';

  @override
  String get syncThisCalendarTitle => 'Include in Calendar Sync';

  @override
  String get syncThisCalendarDesc => 'Sync these events in the device calendar';

  @override
  String get systemLinksTitle => 'System Links';

  @override
  String get systemLinksExplainer => 'What to do when a link is pressed';

  @override
  String get systemLinksOpen => 'Open';

  @override
  String get systemLinksCopy => 'Copy to Clipboard';

  @override
  String get camera => 'Kamera';

  @override
  String get cancel => 'Anuluj';

  @override
  String get cannotEditSpaceWithNoPermissions => 'Nie można edytować przestrzeni bez uprawnień';

  @override
  String get changeAppLanguage => 'Zmiana języka aplikacji';

  @override
  String get changePowerLevel => 'Zmiana poziomu mocy';

  @override
  String get changeThePowerLevelOf => 'Zmiana poziomu mocy';

  @override
  String get changeYourDisplayName => 'Zmiana wyświetlanej nazwy';

  @override
  String get chat => 'Czat';

  @override
  String get chatNG => 'Next-Generation Chat';

  @override
  String get chatNGExplainer => 'Switch to next generation Chat. Features might not be stable';

  @override
  String get customizationsTitle => 'Customizations';

  @override
  String get chatMissingPermissionsToSend => 'Nie masz uprawnień do wysyłania wiadomości tutaj';

  @override
  String get behaviorSettingsTitle => 'Behavior';

  @override
  String get behaviorSettingsExplainer => 'Configure the behavior of your App';

  @override
  String get chatSettingsAutoDownload => 'Automatyczne pobieranie multimediów';

  @override
  String get chatSettingsAutoDownloadExplainer => 'Kiedy automatycznie pobierać multimedia';

  @override
  String get chatSettingsAutoDownloadAlways => 'Zawsze';

  @override
  String get chatSettingsAutoDownloadWifiOnly => 'Tylko podczas korzystania z WiFi';

  @override
  String get chatSettingsAutoDownloadNever => 'Nigdy';

  @override
  String get settingsSubmitting => 'Przesyłanie ustawień';

  @override
  String get settingsSubmittingSuccess => 'Przesłane ustawienia';

  @override
  String settingsSubmittingFailed(Object error) {
    return 'Przesyłanie nie powiodło się: $error ';
  }

  @override
  String get chatRoomCreated => 'Utworzono pokój rozmów';

  @override
  String get chatSendingFailed => 'Failed to sent. Will retry…';

  @override
  String get chatSettingsTyping => 'Wysyłanie powiadomień o wpisywaniu';

  @override
  String get chatSettingsTypingExplainer => '(wkrótce) Poinformuj innych, kiedy piszesz';

  @override
  String get chatSettingsReadReceipts => 'Wysyłanie potwierdzeń odczytu';

  @override
  String get chatSettingsReadReceiptsExplainer => '(wkrótce) Informowanie innych o przeczytaniu wiadomości';

  @override
  String get chats => 'Czaty';

  @override
  String claimedTimes(Object count) {
    return 'Zgłoszono $count razy';
  }

  @override
  String get clear => 'Wyczyść';

  @override
  String get clearDBAndReLogin => 'Wyczyść DB i zaloguj się ponownie';

  @override
  String get close => 'Zamknij';

  @override
  String get closeDialog => 'Zamknij okno dialogowe';

  @override
  String get closeSessionAndDeleteData => 'Zamknięcie sesji i usunięcie danych lokalnych';

  @override
  String get closeSpace => 'Close Space';

  @override
  String get closeChat => 'Close Chat';

  @override
  String get closingRoomTitle => 'Close this Room';

  @override
  String get closingRoomTitleDescription => 'When closing this room, we will :\n\n - Remove everyone with a lower permission level then yours from it\n - Remove it as a child from the parent spaces (where you have the permissions to do so),\n - Set the invite rule to \'private\'\n - You will leave the room.\n\nThis can not be undone. Are you sure you want to close this?';

  @override
  String get closingRoom => 'Closing…';

  @override
  String closingRoomRemovingMembers(Object kicked, Object total) {
    return 'Closing in process. Removing member $kicked / $total';
  }

  @override
  String get closingRoomMatrixMsg => 'The room was closed';

  @override
  String closingRoomRemovingFromParents(Object currentParent, Object totalParents) {
    return 'Closing in process. Removing room from parent $currentParent / $totalParents';
  }

  @override
  String closingRoomDoneBut(Object skipped, Object skippedParents) {
    return 'Closed and you’ve left. But was unable to remove $skipped other Users and remove it as child from $skippedParents Spaces due to lack of permission. Others might still have access to it.';
  }

  @override
  String get closingRoomDone => 'Closed successfully.';

  @override
  String closingRoomFailed(Object error) {
    return 'Closing failed: $error';
  }

  @override
  String get coBudget => 'CoBudget';

  @override
  String get code => 'Kod';

  @override
  String get codeMustBeAtLeast6CharactersLong => 'Kod musi składać się z co najmniej 6 znaków';

  @override
  String get comment => 'Komentarz';

  @override
  String get comments => 'Komentarze';

  @override
  String commentsListError(Object error) {
    return 'Błąd listy komentarzy: $error';
  }

  @override
  String get commentSubmitted => 'Przesłany komentarz';

  @override
  String get community => 'Wspólnota';

  @override
  String get confirmationToken => 'Token potwierdzenia';

  @override
  String get confirmedEmailAddresses => 'Potwierdzone adresy e-mail';

  @override
  String get confirmedEmailAddressesDescription => 'Potwierdzone adresy e-mail powiązane z kontem:';

  @override
  String get confirmWithToken => 'Potwierdź za pomocą tokena';

  @override
  String get congrats => 'Gratulacje!';

  @override
  String get connectedToYourAccount => 'Połączenie z kontem';

  @override
  String get contentSuccessfullyRemoved => 'Zawartość została pomyślnie usunięta';

  @override
  String get continueAsGuest => 'Kontynuuj jako gość';

  @override
  String get continueQuestion => 'Kontynuować?';

  @override
  String get copyUsername => 'Kopiuj nazwę użytkownika';

  @override
  String get copyMessage => 'Kopiuj';

  @override
  String get couldNotFetchNews => 'Nie udało się pobrać wiadomości';

  @override
  String get couldNotLoadAllSessions => 'Nie można załadować wszystkich sesji';

  @override
  String couldNotLoadImage(Object error) {
    return 'Nie można załadować obrazu z powodu $error';
  }

  @override
  String countsMembers(Object count) {
    return '$count członków';
  }

  @override
  String get create => 'Utwórz';

  @override
  String get createChat => 'Utwórz czat';

  @override
  String get createCode => 'Utwórz kod';

  @override
  String get createDefaultChat => 'Create default chat room, too';

  @override
  String defaultChatName(Object name) {
    return '$name chat';
  }

  @override
  String get createDMWhenRedeeming => 'Utwórz DM podczas realizacji';

  @override
  String get createEventAndBringYourCommunity => 'Stwórz nowe wydarzenie i zjednocz swoją społeczność';

  @override
  String get createGroupChat => 'Tworzenie czatu grupowego';

  @override
  String get createPin => 'Utwórz pinezkę';

  @override
  String get createPostsAndEngageWithinSpace => 'Twórz przydatne posty i angażuj wszystkich w swojej przestrzeni.';

  @override
  String get createProfile => 'Utwórz profil';

  @override
  String get createSpace => 'Utwórz przestrzeń';

  @override
  String get createSpaceChat => 'Utwórz czat przestrzenny';

  @override
  String get createSubspace => 'Tworzenie podprzestrzeni';

  @override
  String get createTaskList => 'Tworzenie listy zadań';

  @override
  String get createAcopy => 'Copy as new';

  @override
  String get creatingCalendarEvent => 'Tworzenie wydarzenia kalendarza';

  @override
  String get creatingChat => 'Tworzenie czatu';

  @override
  String get creatingCode => 'Tworzenie kodu';

  @override
  String creatingNewsFailed(Object error) {
    return 'Creating update failed $error';
  }

  @override
  String get creatingSpace => 'Tworzenie przestrzeni';

  @override
  String creatingSpaceFailed(Object error) {
    return 'Tworzenie przestrzeni nie powiodło się: $error';
  }

  @override
  String creatingTaskFailed(Object error) {
    return 'Tworzenie zadania nie powiodło się $error';
  }

  @override
  String get custom => 'Niestandardowe';

  @override
  String get customizeAppsAndTheirFeatures => 'Dostosowywanie aplikacji i ich funkcji';

  @override
  String get customPowerLevel => 'Niestandardowy poziom mocy';

  @override
  String get dangerZone => 'Strefa zagrożenia';

  @override
  String get deactivate => 'Dezaktywuj';

  @override
  String get deactivateAccountDescription => 'Jeśli kontynuujesz:\n\n - Wszystkie dane osobowe użytkownika zostaną usunięte z serwera domowego, w tym nazwa wyświetlana i awatar \n- Wszystkie sesje zostaną natychmiast zamknięte, żadne inne urządzenie nie będzie mogło kontynuować sesji. \n- Opuścisz wszystkie pokoje, czaty, przestrzenie i DM, w których jesteś. \n- Nie będzie możliwe ponowne aktywowanie konta. \n- Nie będzie już możliwe zalogowanie się. \n- Nikt nie będzie mógł ponownie użyć Twojej nazwy użytkownika (MXID), w tym Ty: ta nazwa użytkownika pozostanie niedostępna na czas nieokreślony. \n- Zostaniesz usunięty z serwera tożsamości, jeśli podałeś jakiekolwiek informacje, które można znaleźć za jego pośrednictwem (np. adres e-mail lub numer telefonu). \n- Wszystkie dane lokalne, w tym klucze szyfrowania, zostaną trwale usunięte z tego urządzenia. \n- Twoje stare wiadomości będą nadal widoczne dla osób, które je otrzymały, podobnie jak wiadomości e-mail wysłane w przeszłości. \n\nNie będzie można tego cofnąć. Jest to działanie trwałe i nieodwracalne.';

  @override
  String get deactivateAccountPasswordTitle => 'Podaj hasło użytkownika, aby potwierdzić chęć dezaktywacji konta.';

  @override
  String get deactivateAccountTitle => 'Ostrożnie: Zamierzasz trwale dezaktywować swoje konto';

  @override
  String deactivatingFailed(Object error) {
    return 'Dezaktywacja nie powiodła się: \n $error';
  }

  @override
  String get deactivatingYourAccount => 'Dezaktywacja konta';

  @override
  String get deactivationAndRemovingFailed => 'Dezaktywacja i usunięcie wszystkich danych lokalnych nie powiodło się';

  @override
  String get debugInfo => 'Informacje debugowania';

  @override
  String get debugLevel => 'Poziom debugowania';

  @override
  String get decline => 'Spadek';

  @override
  String get defaultModes => 'Tryby domyślne';

  @override
  String defaultNotification(Object type) {
    return 'Domyślny $type';
  }

  @override
  String get delete => 'Usuń';

  @override
  String get deleteAttachment => 'Usuń załącznik';

  @override
  String get deleteCode => 'Usuń kod';

  @override
  String get deleteTarget => 'Usuń cel';

  @override
  String get deleteNewsDraftTitle => 'Delete draft?';

  @override
  String get deleteNewsDraftText => 'Are you sure you want to delete this draft? This can’t be undone.';

  @override
  String get deleteDraftBtn => 'Delete draft';

  @override
  String get deletingPushTarget => 'Usuwanie celu push';

  @override
  String deletionFailed(Object error) {
    return 'Usunięcie nie powiodło się: $error';
  }

  @override
  String get denied => 'Odmowa';

  @override
  String get description => 'Opis';

  @override
  String get deviceId => 'Device Id';

  @override
  String get deviceIdDigest => 'Device Id Digest';

  @override
  String get deviceName => 'Nazwa urządzenia';

  @override
  String get devicePlatformException => 'W tym kontekście nie można używać DevicePlatform.device/web. Nieprawidłowa platforma: SettingsSection.build';

  @override
  String get displayName => 'Wyświetlana nazwa';

  @override
  String get displayNameUpdateSubmitted => 'Przesłano aktualizację nazwy wyświetlanej';

  @override
  String directInviteUser(Object userId) {
    return 'Directly invite $userId';
  }

  @override
  String get dms => 'DM-y';

  @override
  String get doYouWantToDeleteInviteCode => 'Czy naprawdę chcesz nieodwracalnie usunąć kod super zaproszenia? Później nie będzie można go użyć ponownie.';

  @override
  String due(Object date) {
    return 'Termin: $date';
  }

  @override
  String get dueDate => 'Termin';

  @override
  String get edit => 'Edytuj';

  @override
  String get editDetails => 'Edytuj szczegóły';

  @override
  String get editMessage => 'Edytuj wiadomość';

  @override
  String get editProfile => 'Edytuj profil';

  @override
  String get editSpace => 'Edytuj przestrzeń';

  @override
  String get edited => 'Edytowano';

  @override
  String get egGlobalMovement => 'np. Global Movement';

  @override
  String get emailAddressToAdd => 'Adres e-mail do dodania';

  @override
  String get emailOrPasswordSeemsNotValid => 'Adres e-mail lub hasło są nieprawidłowe.';

  @override
  String get emptyEmail => 'Wprowadź adres e-mail';

  @override
  String get emptyPassword => 'Wprowadź hasło';

  @override
  String get emptyToken => 'Wprowadź kod';

  @override
  String get emptyUsername => 'Wprowadź nazwę użytkownika';

  @override
  String get encrypted => 'Szyfrowanie';

  @override
  String get encryptedSpace => 'Zaszyfrowana przestrzeń';

  @override
  String get encryptionBackupEnabled => 'Kopie zapasowe z włączonym szyfrowaniem';

  @override
  String get encryptionBackupEnabledExplainer => 'Klucze są przechowywane w zaszyfrowanej kopii zapasowej na serwerze domowym.';

  @override
  String get encryptionBackupMissing => 'Brak kopii zapasowych szyfrowania';

  @override
  String get encryptionBackupMissingExplainer => 'Zalecamy korzystanie z automatycznych kopii zapasowych kluczy szyfrowania';

  @override
  String get encryptionBackupProvideKey => 'Zapewnienie klucza odzyskiwania';

  @override
  String get encryptionBackupProvideKeyExplainer => 'Znaleźliśmy automatyczną kopię zapasową szyfrowania';

  @override
  String get encryptionBackupProvideKeyAction => 'Podaj klucz';

  @override
  String get encryptionBackupNoBackup => 'Nie znaleziono kopii zapasowej szyfrowania';

  @override
  String get encryptionBackupNoBackupExplainer => 'W przypadku utraty dostępu do konta konwersacje mogą stać się niemożliwe do odzyskania. Zalecamy włączenie automatycznego szyfrowania kopii zapasowych.';

  @override
  String get encryptionBackupNoBackupAction => 'Włącz kopię zapasową';

  @override
  String get encryptionBackupEnabling => 'Włączanie tworzenia kopii zapasowych';

  @override
  String encryptionBackupEnablingFailed(Object error) {
    return 'Włączenie tworzenia kopii zapasowej nie powiodło się: $error';
  }

  @override
  String get encryptionBackupRecovery => 'Klucz odzyskiwania kopii zapasowej';

  @override
  String get encryptionBackupRecoveryExplainer => 'Klucz odzyskiwania kopii zapasowej należy bezpiecznie przechowywać.';

  @override
  String get encryptionBackupRecoveryCopiedToClipboard => 'Klucz odzyskiwania skopiowany do schowka';

  @override
  String get refreshing => 'Refreshing';

  @override
  String get encryptionBackupDisable => 'Wyłączyć kopię zapasową klucza?';

  @override
  String get encryptionBackupDisableExplainer => 'Zresetowanie kopii zapasowej klucza zniszczy go lokalnie i na serwerze domowym. Nie można tego cofnąć. Czy na pewno chcesz kontynuować?';

  @override
  String get encryptionBackupDisableActionKeepIt => 'Nie, zachowaj to';

  @override
  String get encryptionBackupDisableActionDestroyIt => 'Tak, zniszcz to';

  @override
  String get encryptionBackupResetting => 'Resetowanie kopii zapasowej';

  @override
  String get encryptionBackupResettingSuccess => 'Resetowanie powiodło się';

  @override
  String encryptionBackupResettingFailed(Object error) {
    return 'Nie udało się wyłączyć: $error';
  }

  @override
  String get encryptionBackupRecover => 'Odzyskaj kopię zapasową szyfrowania';

  @override
  String get encryptionBackupRecoverExplainer => 'Dostawca klucza odzyskiwania do odszyfrowania kopii zapasowej szyfrowania';

  @override
  String get encryptionBackupRecoverInputHint => 'Klucz odzyskiwania';

  @override
  String get encryptionBackupRecoverProvideKey => 'Prosimy o podanie klucza';

  @override
  String get encryptionBackupRecoverAction => 'Odzyskaj';

  @override
  String get encryptionBackupRecoverRecovering => 'Odzyskiwanie';

  @override
  String get encryptionBackupRecoverRecoveringSuccess => 'Odzyskiwanie zakończone sukcesem';

  @override
  String get encryptionBackupRecoverRecoveringImportFailed => 'Import nie powiódł się';

  @override
  String encryptionBackupRecoverRecoveringFailed(Object error) {
    return 'Nie udało się odzyskać: $error';
  }

  @override
  String get encryptionBackupKeyBackup => 'Kopia zapasowa klucza';

  @override
  String get encryptionBackupKeyBackupExplainer => 'Tutaj można skonfigurować kopię zapasową klucza';

  @override
  String error(Object error) {
    return 'Błąd $error';
  }

  @override
  String errorCreatingCalendarEvent(Object error) {
    return 'Błąd podczas tworzenia wydarzenia kalendarza: $error';
  }

  @override
  String errorCreatingChat(Object error) {
    return 'Błąd podczas tworzenia czatu: $error';
  }

  @override
  String errorSubmittingComment(Object error) {
    return 'Błąd przesyłania komentarza: $error';
  }

  @override
  String errorUpdatingEvent(Object error) {
    return 'Błąd aktualizacji zdarzenia: $error';
  }

  @override
  String get eventDescriptionsData => 'Dane opisów zdarzeń';

  @override
  String get eventName => 'Nazwa wydarzenia';

  @override
  String get events => 'Wydarzenia';

  @override
  String get eventTitleData => 'Dane tytułu wydarzenia';

  @override
  String get experimentalActerFeatures => 'Funkcje Experimental Acter';

  @override
  String failedToAcceptInvite(Object error) {
    return 'Failed to accept invite: $error';
  }

  @override
  String failedToRejectInvite(Object error) {
    return 'Failed to reject invite: $error';
  }

  @override
  String get missingStoragePermissions => 'You must grant us permissions to storage to pick an Image file';

  @override
  String get file => 'Plik';

  @override
  String get forgotPassword => 'Zapomniałeś hasła?';

  @override
  String get forgotPasswordDescription => 'Aby odzyskać hasło, po prostu wyślij nam swoją nazwę użytkownika pocztą elektroniczną, a nasz zespół szybko pomoże Ci odzyskać dostęp do Twojego profilu.';

  @override
  String get forgotPasswordNewPasswordDescription => 'Once you’ve finished the process behind the link of the email we’ve sent you, you can set a new password here:';

  @override
  String get formatMustBe => 'Format musi być następujący: @user:server.tld';

  @override
  String get foundUsers => 'Znaleziono użytkowników';

  @override
  String get from => 'Od';

  @override
  String get gallery => 'Galeria';

  @override
  String get general => 'Ogólne';

  @override
  String get getConversationGoingToStart => 'Rozpocznij rozmowę, aby rozpocząć współpracę organizacyjną';

  @override
  String get getInTouchWithOtherChangeMakers => 'Skontaktuj się z innymi twórcami zmian, organizatorami lub aktywistami i porozmawiaj z nimi bezpośrednio.';

  @override
  String get goToDM => 'Przejdź do DM';

  @override
  String get going => 'Iść';

  @override
  String get haveProfile => 'Masz już profil?';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get helpCenterDesc => 'Get helpful tips about Acter';

  @override
  String get hereYouCanChangeTheSpaceDetails => 'Tutaj można zmienić szczegóły przestrzeni';

  @override
  String get hereYouCanSeeAllUsersYouBlocked => 'Tutaj możesz zobaczyć wszystkich zablokowanych użytkowników.';

  @override
  String get hintMessageDisplayName => 'Wprowadź nazwę, którą mają widzieć inni';

  @override
  String get hintMessageInviteCode => 'Wprowadź kod zaproszenia, aby dołączyć do społeczności';

  @override
  String get hintMessagePassword => 'Co najmniej 6 znaków';

  @override
  String get hintMessageUsername => 'Unikalna nazwa użytkownika do logowania i identyfikacji';

  @override
  String get homeServerName => 'Nazwa serwera domowego';

  @override
  String get homeServerURL => 'Adres URL serwera domowego';

  @override
  String get httpProxy => 'HTTP Proxy';

  @override
  String get image => 'Obraz';

  @override
  String get inConnectedSpaces => 'W połączonych przestrzeniach można skupić się na konkretnych działaniach lub kampaniach grup roboczych i rozpocząć organizację.';

  @override
  String get info => 'Info';

  @override
  String get invalidTokenOrPassword => 'Nieprawidłowy token lub hasło';

  @override
  String get invitationToChat => 'Zaproszony do dołączenia do czatu przez ';

  @override
  String get invitationToDM => 'Chce rozpocząć z tobą DM';

  @override
  String get invitationToSpace => 'Zaproszeni do dołączenia do przestrzeni kosmicznej przez ';

  @override
  String get invited => 'Invited';

  @override
  String get inviteCode => 'Kod zaproszenia';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String shareInviteWithCode(Object code) {
    return 'Invite $code';
  }

  @override
  String get inviteCodeInfo => 'Kod zaproszenia to unikalny klucz dostępu, który umożliwia dołączenie do społeczności. Służy on jako specjalny klucz, dzięki któremu tylko osoby posiadające kod mogą zostać członkami. Może on być tworzony i dystrybuowany przez lidera społeczności.';

  @override
  String get irreversiblyDeactivateAccount => 'Nieodwracalna dezaktywacja tego konta';

  @override
  String get itsYou => 'To ty';

  @override
  String get join => 'dołączyć';

  @override
  String get joined => 'Połączony';

  @override
  String joiningFailed(Object error) {
    return 'Joining failed: $error';
  }

  @override
  String get joinActer => 'Dołącz do Acter';

  @override
  String joinRuleNotSupportedYet(Object role) {
    return 'Reguła dołączania $role nie jest jeszcze obsługiwana. Przepraszamy';
  }

  @override
  String kickAndBanFailed(Object error) {
    return 'Wykopanie i zbanowanie użytkownika nie powiodło się: \n $error';
  }

  @override
  String get kickAndBanProgress => 'Kopanie i banowanie użytkowników';

  @override
  String get kickAndBanSuccess => 'Użytkownik wyrzucony i zbanowany';

  @override
  String get kickAndBanUser => 'Kopnięcie i zbanowanie użytkownika';

  @override
  String kickAndBanUserDescription(Object roomId, Object userId) {
    return 'Zamierzasz wyrzucić i trwale zbanować $userId z $roomId';
  }

  @override
  String kickAndBanUserTitle(Object userId) {
    return 'Wykopanie i zbanowanie użytkownika $userId';
  }

  @override
  String kickFailed(Object error) {
    return 'Kopnięcie użytkownika nie powiodło się: \n $error';
  }

  @override
  String get kickProgress => 'Użytkownik kopiący';

  @override
  String get kickSuccess => 'Użytkownik kopnięty';

  @override
  String get kickUser => 'Użytkownik Kick';

  @override
  String kickUserDescription(Object roomId, Object userId) {
    return 'Zamierzasz wyrzucić $userId z $roomId';
  }

  @override
  String kickUserTitle(Object userId) {
    return 'Kick User $userId';
  }

  @override
  String get labs => 'Laboratoria';

  @override
  String get labsAppFeatures => 'Funkcje aplikacji';

  @override
  String get language => 'Język';

  @override
  String get leave => 'wychodzić';

  @override
  String get leaveRoom => 'Opuścić pokój';

  @override
  String get leaveSpace => 'Pozostawić przestrzeń';

  @override
  String get leavingSpace => 'Opuszczanie przestrzeni';

  @override
  String get leavingSpaceSuccessful => 'Opuściłeś przestrzeń';

  @override
  String leavingSpaceFailed(Object error) {
    return 'Błąd opuszczania spacji: $error';
  }

  @override
  String get leavingRoom => 'Opuszczanie pokoju';

  @override
  String get letsGetStarted => 'Zaczynajmy';

  @override
  String get licenses => 'Licencje';

  @override
  String get limitedInternConnection => 'Ograniczone połączenie z Internetem';

  @override
  String get link => 'Link';

  @override
  String get linkExistingChat => 'Link do istniejącego czatu';

  @override
  String get linkExistingSpace => 'Połączenie istniejącej przestrzeni';

  @override
  String get links => 'Linki';

  @override
  String get loading => 'Ładowanie';

  @override
  String get linkToChat => 'Link do czatu';

  @override
  String loadingFailed(Object error) {
    return 'Ładowanie nie powiodło się: $error';
  }

  @override
  String get location => 'Lokalizacja';

  @override
  String get logIn => 'Zaloguj się';

  @override
  String get loginAgain => 'Zaloguj się ponownie';

  @override
  String get loginContinue => 'Zaloguj się i kontynuuj organizowanie od miejsca, w którym ostatnio skończyłeś.';

  @override
  String get loginSuccess => 'Logowanie powiodło się';

  @override
  String get logOut => 'Wylogowanie';

  @override
  String get logSettings => 'Ustawienia dziennika';

  @override
  String get looksGoodAddressConfirmed => 'Wygląda dobrze. Adres potwierdzony.';

  @override
  String get makeADifference => 'Zrób różnicę';

  @override
  String get manage => 'Manage';

  @override
  String get manageBudgetsCooperatively => 'Wspólne zarządzanie budżetami';

  @override
  String get manageYourInvitationCodes => 'Zarządzanie kodami zaproszeń';

  @override
  String get markToHideAllCurrentAndFutureContent => 'Zaznacz, aby ukryć całą bieżącą i przyszłą zawartość od tego użytkownika i zablokować mu możliwość kontaktowania się z Tobą';

  @override
  String get markedAsDone => 'oznaczone jako wykonane';

  @override
  String get maybe => 'Może';

  @override
  String get member => 'Członek';

  @override
  String get memberDescriptionsData => 'Dane opisów członków';

  @override
  String get memberTitleData => 'Dane dotyczące tytułu członkowskiego';

  @override
  String get members => 'Członkowie';

  @override
  String get mentionsAndKeywordsOnly => 'Tylko wzmianki i słowa kluczowe';

  @override
  String get message => 'Wiadomość';

  @override
  String get messageCopiedToClipboard => 'Wiadomość skopiowana do schowka';

  @override
  String get missingName => 'Wprowadź swoje imię i nazwisko';

  @override
  String get mobilePushNotifications => 'Mobilne powiadomienia push';

  @override
  String get moderator => 'Moderator';

  @override
  String get more => 'Więcej';

  @override
  String moreRooms(Object count) {
    return '+$count additional rooms';
  }

  @override
  String get muted => 'Wyciszony';

  @override
  String get customValueMustBeNumber => 'You need to enter the custom value as a number.';

  @override
  String get myDashboard => 'Mój pulpit nawigacyjny';

  @override
  String get name => 'Nazwa';

  @override
  String get nameOfTheEvent => 'Nazwa wydarzenia';

  @override
  String get needsAppRestartToTakeEffect => 'Wymaga ponownego uruchomienia aplikacji';

  @override
  String get newChat => 'Nowy czat';

  @override
  String get newEncryptedMessage => 'Nowa zaszyfrowana wiadomość';

  @override
  String get needYourPasswordToConfirm => 'Potrzebujesz hasła, aby potwierdzić';

  @override
  String get newMessage => 'Nowa wiadomość';

  @override
  String get newUpdate => 'Nowa aktualizacja';

  @override
  String get next => 'Następny';

  @override
  String get no => 'Nie';

  @override
  String get noChatsFound => 'nie znaleziono czatów';

  @override
  String get noChatsFoundMatchingYourFilter => 'Nie znaleziono czatów pasujących do filtrów i wyszukiwania';

  @override
  String get noChatsFoundMatchingYourSearchTerm => 'Nie znaleziono czatów pasujących do wyszukiwanego hasła';

  @override
  String get noChatsInThisSpaceYet => 'Brak czatów w tym miejscu';

  @override
  String get noChatsStillSyncing => 'Synchronizing…';

  @override
  String get noChatsStillSyncingSubtitle => 'We are loading your chats. On large accounts the initial loading takes a bit…';

  @override
  String get noConnectedSpaces => 'Brak połączonych przestrzeni';

  @override
  String get noDisplayName => 'brak wyświetlanej nazwy';

  @override
  String get noDueDate => 'Brak terminu płatności';

  @override
  String get noEventsPlannedYet => 'Nie zaplanowano jeszcze żadnych wydarzeń';

  @override
  String get noIStay => 'Nie, zostaję';

  @override
  String get noMembersFound => 'Nie znaleziono żadnych członków. Jak to możliwe, przecież tu jesteś, prawda?';

  @override
  String get noOverwrite => 'Bez nadpisywania';

  @override
  String get noParticipantsGoing => 'Brak uczestników';

  @override
  String get noPinsAvailableDescription => 'Udostępniaj społeczności ważne zasoby, takie jak dokumenty lub linki, aby wszyscy byli na bieżąco.';

  @override
  String get noPinsAvailableYet => 'Piny nie są jeszcze dostępne';

  @override
  String get noProfile => 'Nie masz jeszcze profilu?';

  @override
  String get noPushServerConfigured => 'W kompilacji nie skonfigurowano serwera wypychania';

  @override
  String get noPushTargetsAddedYet => 'Nie dodano jeszcze celów push';

  @override
  String get noSpacesFound => 'Nie znaleziono spacji';

  @override
  String get noUsersFoundWithSpecifiedSearchTerm => 'Nie znaleziono użytkowników z podanym wyszukiwanym hasłem';

  @override
  String get notEnoughPowerLevelForInvites => 'Niewystarczający poziom mocy dla zaproszeń, poproś administratora pokoju o zmianę';

  @override
  String get notFound => '404 - Not Found';

  @override
  String get notes => 'Notatki';

  @override
  String get notGoing => 'Nie idę';

  @override
  String get noThanks => 'Nie, dziękuję';

  @override
  String get notifications => 'Notyfikacje';

  @override
  String get notificationsOverwrites => 'Nadpisywanie powiadomień';

  @override
  String get notificationsOverwritesDescription => 'Zastąp konfiguracje powiadomień dla tej przestrzeni';

  @override
  String get notificationsSettingsAndTargets => 'Ustawienia powiadomień i cele';

  @override
  String get notificationStatusSubmitted => 'Przesłany status powiadomienia';

  @override
  String notificationStatusUpdateFailed(Object error) {
    return 'Aktualizacja statusu powiadomienia nie powiodła się: $error';
  }

  @override
  String get notificationsUnmuted => 'Wyciszone powiadomienia';

  @override
  String get notificationTargets => 'Cele powiadomień';

  @override
  String get notifyAboutSpaceUpdates => 'Natychmiastowe powiadamianie o aktualizacjach przestrzeni kosmicznej';

  @override
  String get noTopicFound => 'Nie znaleziono tematu';

  @override
  String get notVisible => 'Niewidoczny';

  @override
  String get notYetSupported => 'Jeszcze nieobsługiwane';

  @override
  String get noWorriesWeHaveGotYouCovered => 'Bez obaw! Mamy wszystko pod kontrolą.';

  @override
  String get ok => 'Ok';

  @override
  String get okay => 'Okay';

  @override
  String get on => 'na';

  @override
  String get onboardText => 'Zacznijmy od skonfigurowania swojego profilu';

  @override
  String get onlySupportedIosAndAndroid => 'Obecnie obsługiwane tylko na urządzeniach mobilnych (iOS i Android)';

  @override
  String get optional => 'Opcjonalnie';

  @override
  String get or => ' albo ';

  @override
  String get overview => 'Przegląd';

  @override
  String get parentSpace => 'Przestrzeń rodzicielska';

  @override
  String get parentSpaces => 'Parent Spaces';

  @override
  String get parentSpaceMustBeSelected => 'Przestrzeń rodzicielska musi być wybrane';

  @override
  String get parents => 'Rodzice';

  @override
  String get password => 'Hasło';

  @override
  String get passwordResetTitle => 'Password Reset';

  @override
  String get past => 'Przeszłość';

  @override
  String get pending => 'W toku';

  @override
  String peopleGoing(Object count) {
    return '$count Ludzie idą';
  }

  @override
  String get personalSettings => 'Ustawienia osobiste';

  @override
  String get pinName => 'Nazwa pinu';

  @override
  String get pins => 'Szpilki';

  @override
  String get play => 'Grać';

  @override
  String get playbackSpeed => 'Prędkość odtwarzania';

  @override
  String get pleaseCheckYourInbox => 'Sprawdź swoją skrzynkę odbiorczą, aby uzyskać wiadomość e-mail z potwierdzeniem';

  @override
  String get pleaseEnterAName => 'Wprowadź nazwę';

  @override
  String get pleaseEnterATitle => 'Wprowadź tytuł';

  @override
  String get pleaseEnterEventName => 'Wprowadź nazwę wydarzenia';

  @override
  String get pleaseFirstSelectASpace => 'Najpierw wybierz miejsce';

  @override
  String errorProcessingSlide(Object error, Object slideIdx) {
    return 'We couldn’t process slide $slideIdx: $error';
  }

  @override
  String get pleaseProvideEmailAddressToAdd => 'Podaj adres e-mail, który chcesz dodać';

  @override
  String get pleaseProvideYourUserPassword => 'Podaj hasło użytkownika, aby potwierdzić, że chcesz zakończyć tę sesję.';

  @override
  String get pleaseSelectSpace => 'Wybierz miejsce';

  @override
  String get selectTaskList => 'Select Task List';

  @override
  String get pleaseWait => 'Proszę czekać…';

  @override
  String get polls => 'Sondaże';

  @override
  String get pollsAndSurveys => 'Ankiety i sondaże';

  @override
  String postingOfTypeNotYetSupported(Object type) {
    return 'Wysyłanie $type nie jest jeszcze obsługiwane';
  }

  @override
  String get postingTaskList => 'Lista zadań do wysłania';

  @override
  String get postpone => 'Postpone';

  @override
  String postponeN(Object days) {
    return 'Postpone $days days';
  }

  @override
  String get powerLevel => 'Poziom mocy';

  @override
  String get powerLevelUpdateSubmitted => 'Aktualizacja PowerLevel przesłana';

  @override
  String get powerLevelAdmin => 'Admin';

  @override
  String get powerLevelModerator => 'Moderator';

  @override
  String get powerLevelRegular => 'Everyone';

  @override
  String get powerLevelNone => 'None';

  @override
  String get powerLevelCustom => 'Custom';

  @override
  String get powerLevelsTitle => 'General Permission levels';

  @override
  String get powerLevelPostEventsTitle => 'Posting Permission Level';

  @override
  String get powerLevelPostEventsDesc => 'Minimal Permission Level to post anything at all';

  @override
  String get powerLevelKickTitle => 'Kick Permission Level';

  @override
  String get powerLevelKickDesc => 'Minimal Permission Level to kick someone';

  @override
  String get powerLevelBanTitle => 'Ban Permission Level';

  @override
  String get powerLevelBanDesc => 'Minimal Permission Level to ban someone';

  @override
  String get powerLevelInviteTitle => 'Invite Permission Level';

  @override
  String get powerLevelInviteDesc => 'Minimal Permission Level to invite someone';

  @override
  String get powerLevelRedactTitle => 'Redact Permission Level';

  @override
  String get powerLevelRedactDesc => 'Minimal Permission Level to redact other peoples content';

  @override
  String get preview => 'Podgląd';

  @override
  String get privacyPolicy => 'Polityka prywatności';

  @override
  String get private => 'Prywatny';

  @override
  String get profile => 'Profil';

  @override
  String get pushKey => 'PushKey';

  @override
  String get pushTargetDeleted => 'Cel push usunięty';

  @override
  String get pushTargetDetails => 'Push Target Szczegóły';

  @override
  String get pushToThisDevice => 'Push do tego urządzenia';

  @override
  String get quickSelect => 'Szybki wybór:';

  @override
  String get rageShakeAppName => 'Nazwa aplikacji Rageshake';

  @override
  String get rageShakeAppNameDigest => 'Rageshake App Name Digest';

  @override
  String get rageShakeTargetUrl => 'Docelowy adres URL Rageshake';

  @override
  String get rageShakeTargetUrlDigest => 'Rageshake Target Url Digest';

  @override
  String get reason => 'Powód';

  @override
  String get reasonHint => 'opcjonalny powód';

  @override
  String get reasonLabel => 'Powód';

  @override
  String redactionFailed(Object error) {
    return 'Wysyłanie redakcji nie powiodło się z powodu';
  }

  @override
  String get redeem => 'wykupić';

  @override
  String redeemingFailed(Object error) {
    return 'Realizacja nie powiodła się: $error';
  }

  @override
  String get register => 'Rejestr';

  @override
  String registerFailed(Object error) {
    return 'Registration failed: $error';
  }

  @override
  String get regular => 'Regularny';

  @override
  String get remove => 'Usunąć';

  @override
  String get removePin => 'Usuń sworzeń';

  @override
  String get removeThisContent => 'Usuń tę zawartość. Nie można tego cofnąć. Podaj opcjonalny powód, aby wyjaśnić, dlaczego ta zawartość została usunięta';

  @override
  String get reply => 'Odpowiedź';

  @override
  String replyTo(Object name) {
    return 'Odpowiedzieć do $name';
  }

  @override
  String get replyPreviewUnavailable => 'Brak podglądu wiadomości, na którą odpowiadasz';

  @override
  String get report => 'Raport';

  @override
  String get reportThisEvent => 'Zgłoś to wydarzenie';

  @override
  String get reportThisMessage => 'Zgłoś tę wiadomość';

  @override
  String get reportMessageContent => 'Zgłoś tę wiadomość administratorowi serwera domowego. Należy pamiętać, że administrator nie będzie w stanie odczytać ani wyświetlić żadnych plików, jeśli pokój jest zaszyfrowany';

  @override
  String get reportPin => 'Raport Pin';

  @override
  String get reportThisPost => 'Zgłoś ten post';

  @override
  String get reportPostContent => 'Zgłoś ten post administratorowi serwera domowego. Należy pamiętać, że administrator nie będzie w stanie odczytać ani wyświetlić żadnych plików w zaszyfrowanych przestrzeniach.';

  @override
  String get reportSendingFailed => 'Wysyłanie raportu nie powiodło się';

  @override
  String get reportSent => 'Raport wysłany!';

  @override
  String get reportThisContent => 'Zgłoś tę zawartość administratorowi serwera domowego. Należy pamiętać, że administrator nie będzie mógł odczytywać ani przeglądać plików w zaszyfrowanych przestrzeniach.';

  @override
  String get requestToJoin => 'prośba o dołączenie';

  @override
  String get reset => 'Reset';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get retry => 'Ponów próbę';

  @override
  String get roomId => 'roomId';

  @override
  String get roomNotFound => 'Nie znaleziono pokoju';

  @override
  String get roomLinkedButNotUpgraded => 'Added. However you are not able to upgrade its join rule settings and thus not all people from this space might be able to join it.';

  @override
  String get rsvp => 'RSVP';

  @override
  String repliedToMsgFailed(Object id) {
    return 'Failed to load original message id: $id';
  }

  @override
  String get sasGotIt => 'Rozumiem';

  @override
  String sasIncomingReqNotifContent(String sender) {
    return '$sender chce zweryfikować Twoją sesję';
  }

  @override
  String get sasIncomingReqNotifTitle => 'Wniosek o weryfikację';

  @override
  String get sasVerified => 'Zweryfikowano!';

  @override
  String get save => 'Zapisz';

  @override
  String get saveFileAs => 'Save file as';

  @override
  String get openFile => 'Open';

  @override
  String get shareFile => 'Share';

  @override
  String get saveChanges => 'Zapisz zmiany';

  @override
  String get savingCode => 'Kod oszczędzania';

  @override
  String get search => 'Wyszukiwanie';

  @override
  String get searchTermFieldHint => 'Search for…';

  @override
  String get searchChats => 'Wyszukiwanie czatów';

  @override
  String searchResultFor(Object text) {
    return 'Wynik wyszukiwania dla $text…';
  }

  @override
  String get searchUsernameToStartDM => 'Wyszukaj nazwę użytkownika, aby rozpocząć DM';

  @override
  String searchingFailed(Object error) {
    return 'Wyszukiwanie nie powiodło się $error';
  }

  @override
  String get searchSpace => 'przestrzeń wyszukiwania';

  @override
  String get searchSpaces => 'Search Spaces';

  @override
  String get searchPublicDirectory => 'Search Public Directory';

  @override
  String get searchPublicDirectoryNothingFound => 'No entry found in the public directory';

  @override
  String get seeOpenTasks => 'zobacz otwarte zadania';

  @override
  String get seenBy => 'Widziane przez';

  @override
  String get select => 'Wybierz';

  @override
  String get selectAll => 'Select all';

  @override
  String get unselectAll => 'Unselect all';

  @override
  String get selectAnyRoomToSeeIt => 'Wybierz dowolny pokój, aby go zobaczyć';

  @override
  String get selectDue => 'Wybierz termin';

  @override
  String get selectLanguage => 'Wybierz język';

  @override
  String get selectParentSpace => 'Wybierz przestrzeń nadrzędną';

  @override
  String get send => 'Wyślij';

  @override
  String get sendingAttachment => 'Wysyłanie załącznika';

  @override
  String get sendingReport => 'Wysyłanie raportu';

  @override
  String get sendingEmail => 'Sending Email';

  @override
  String sendingEmailFailed(Object error) {
    return 'Sending failed: $error';
  }

  @override
  String sendingRsvpFailed(Object error) {
    return 'Sending RSVP failed: $error';
  }

  @override
  String get sentAnImage => 'wysłał obraz.';

  @override
  String get server => 'Serwer';

  @override
  String get sessions => 'Sesje';

  @override
  String get sessionTokenName => 'Nazwa tokenu sesji';

  @override
  String get setDebugLevel => 'Ustawianie poziomu debugowania';

  @override
  String get setHttpProxy => 'Ustaw serwer proxy HTTP';

  @override
  String get settings => 'Ustawienia';

  @override
  String get securityAndPrivacy => 'Bezpieczeństwo i prywatność';

  @override
  String get settingsKeyBackUpTitle => 'Kopia zapasowa klucza';

  @override
  String get settingsKeyBackUpDesc => 'Zarządzanie kopiami zapasowymi kluczy';

  @override
  String get share => 'Udział';

  @override
  String get shareIcal => 'Udostępnianie iCal';

  @override
  String shareFailed(Object error) {
    return 'Udostępnianie nie powiodło się: $error';
  }

  @override
  String get sharedCalendarAndEvents => 'Wspólny kalendarz i wydarzenia';

  @override
  String get signUp => 'Zarejestruj się';

  @override
  String get skip => 'Pomiń';

  @override
  String get slidePosting => 'Publikowanie slajdów';

  @override
  String slidesNotYetSupported(Object type) {
    return '$type slajdów nie jest jeszcze obsługiwany';
  }

  @override
  String get someErrorOccurredLeavingRoom => 'Wystąpił błąd pozostawiający miejsce';

  @override
  String get space => 'Przestrzeń';

  @override
  String get spaceConfiguration => 'Konfiguracja przestrzeni';

  @override
  String get spaceConfigurationDescription => 'Skonfiguruj, kto może wyświetlać i jak dołączyć do tej przestrzeni';

  @override
  String get spaceName => 'Nazwa przestrzeni';

  @override
  String get spaceNotificationOverwrite => 'Powiadomienie o nadpisaniu miejsca';

  @override
  String get spaceNotifications => 'Powiadomienia dotyczące przestrzeni';

  @override
  String get spaceOrSpaceIdMustBeProvided => 'należy podać space lub spaceId';

  @override
  String get spaces => 'Przestrzenie';

  @override
  String get spacesAndChats => 'Spaces & Chats';

  @override
  String get spacesAndChatsToAddThemTo => 'Przestrzenie i czaty, do których można je dodać';

  @override
  String get startDM => 'Start DM';

  @override
  String get state => 'stan';

  @override
  String get submit => 'Prześlij';

  @override
  String get submittingComment => 'Przesyłanie komentarza';

  @override
  String get suggested => 'Suggested';

  @override
  String get suggestedUsers => 'Suggested Users';

  @override
  String get joiningSuggested => 'Joining suggested';

  @override
  String get suggestedRoomsTitle => 'Suggested to join';

  @override
  String get suggestedRoomsSubtitle => 'We suggest you also join the following';

  @override
  String get addSuggested => 'Mark as suggested';

  @override
  String get removeSuggested => 'Remove suggestion';

  @override
  String get superInvitations => 'Super zaproszenia';

  @override
  String get superInvites => 'Super zaproszenia';

  @override
  String superInvitedBy(Object user) {
    return '$user invites you';
  }

  @override
  String superInvitedTo(Object count) {
    return 'To join $count room';
  }

  @override
  String superInvitesPreviewMissing(Object token) {
    return 'Your Server doesn’t support previewing Invite Codes. You can still try to redeem $token though';
  }

  @override
  String superInvitesDeleted(Object token) {
    return 'The invite code $token is not valid anymore.';
  }

  @override
  String get takeAFirstStep => 'Zrób pierwszy krok w kierunku skutecznej organizacji, tworząc swój profil lub logując się teraz!';

  @override
  String get taskListName => 'Nazwa listy zadań';

  @override
  String get tasks => 'Zadania';

  @override
  String get termsOfService => 'Warunki świadczenia usług';

  @override
  String get termsText1 => 'Klikając, aby utworzyć profil, wyrażasz zgodę na nasze';

  @override
  String theCurrentJoinRulesOfSpace(Object parentSpaceName, Object roomName) {
    return 'Obecne zasady dołączania $roomName oznaczają, że nie będzie on widoczny dla członków $parentSpaceName. Czy powinniśmy zaktualizować reguły dołączania, aby umożliwić członkom przestrzeni $parentSpaceName zobaczenie i dołączenie do $roomName?';
  }

  @override
  String get theParentSpace => 'przestrzeń nadrzędna';

  @override
  String get thereIsNothingScheduledYet => 'Nic nie jest jeszcze zaplanowane';

  @override
  String get theSelectedRooms => 'wybrane pokoje';

  @override
  String get theyWontBeAbleToJoinAgain => 'Nie będą mogli dołączyć ponownie';

  @override
  String get thirdParty => '3. strona';

  @override
  String get thisApaceIsEndToEndEncrypted => 'Przestrzeń ta jest szyfrowana od końca do końca';

  @override
  String get thisApaceIsNotEndToEndEncrypted => 'Przestrzeń ta nie jest szyfrowana od końca do końca';

  @override
  String get thisIsAMultilineDescription => 'To jest wielowierszowy opis zadania z długimi tekstami i innymi rzeczami';

  @override
  String get thisIsNotAProperActerSpace => 'To nie jest właściwa przestrzeń Acter. Niektóre funkcje mogą być niedostępne.';

  @override
  String get thisMessageHasBeenDeleted => 'Ta wiadomość została usunięta';

  @override
  String get thisWillAllowThemToContactYouAgain => 'Umożliwi im to ponowny kontakt z użytkownikiem';

  @override
  String get title => 'Tytuł';

  @override
  String get titleTheNewTask => 'Tytuł nowego zadania.';

  @override
  String typingUser1(Object user) {
    return '$user wpisuje...';
  }

  @override
  String typingUser2(Object user1, Object user2) {
    return '$user1 i $user2 wpisują...';
  }

  @override
  String typingUserN(Object user, Object userCount) {
    return '$user i $userCount inni wpisują';
  }

  @override
  String get to => 'do';

  @override
  String get toAccess => 'to access';

  @override
  String get needToBeMemberOf => 'you need to be member of';

  @override
  String get today => 'Dzisiaj';

  @override
  String get token => 'token';

  @override
  String get tokenAndPasswordMustBeProvided => 'Należy podać token i hasło';

  @override
  String get tomorrow => 'Jutro';

  @override
  String get topic => 'Topic';

  @override
  String get tryingToConfirmToken => 'Próba potwierdzenia tokena';

  @override
  String tryingToJoin(Object name) {
    return 'Próba dołączenia do $name';
  }

  @override
  String get tryToJoin => 'Spróbuj dołączyć';

  @override
  String get typeName => 'Nazwa typu';

  @override
  String get unblock => 'Odblokowanie';

  @override
  String get unblockingUser => 'Odblokowanie użytkownika';

  @override
  String unblockingUserFailed(Object error) {
    return 'Odblokowanie użytkownika nie powiodło się: $error';
  }

  @override
  String get unblockingUserProgress => 'Odblokowanie użytkownika';

  @override
  String get unblockingUserSuccess => 'Użytkownik odblokowany. Może minąć trochę czasu, zanim interfejs użytkownika odzwierciedli tę aktualizację.';

  @override
  String unblockTitle(Object userId) {
    return 'Odblokuj $userId';
  }

  @override
  String get unblockUser => 'Odblokuj użytkownika';

  @override
  String unclearJoinRule(Object rule) {
    return 'Niejasna reguła łączenia $rule';
  }

  @override
  String get unreadMarkerFeatureTitle => 'Unread Markers';

  @override
  String get unreadMarkerFeatureDescription => 'Track and show which Chats have been read';

  @override
  String get undefined => 'niezdefiniowany';

  @override
  String get unknown => 'nieznany';

  @override
  String get unknownRoom => 'Nieznany pokój';

  @override
  String get unlink => 'Odłącz';

  @override
  String get unmute => 'Wyłącz wyciszenie';

  @override
  String get unset => 'nieustawiony';

  @override
  String get unsupportedPleaseUpgrade => 'Nieobsługiwane - prosimy o aktualizację!';

  @override
  String get unverified => 'Niezweryfikowany';

  @override
  String get unverifiedSessions => 'Niezweryfikowane sesje';

  @override
  String get unverifiedSessionsDescription => 'Na koncie zalogowane są urządzenia, które nie zostały zweryfikowane. Może to stanowić zagrożenie dla bezpieczeństwa. Upewnij się, że wszystko jest w porządku.';

  @override
  String unverifiedSessionsCount(int count) {
    return 'There are $count unverified sessions logged in';
  }

  @override
  String get upcoming => 'Nadchodzące';

  @override
  String get updatePowerLevel => 'Aktualizacja poziomu mocy';

  @override
  String updateFeaturePowerLevelDialogTitle(Object feature) {
    return 'Update Permission of $feature';
  }

  @override
  String updateFeaturePowerLevelDialogFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'from $memberStatus ($currentPowerLevel) to';
  }

  @override
  String get updateFeaturePowerLevelDialogFromDefaultTo => 'from default to';

  @override
  String get updatingDisplayName => 'Aktualizacja wyświetlanej nazwy';

  @override
  String get updatingDue => 'Wymagana aktualizacja';

  @override
  String get updatingEvent => 'Aktualizacja zdarzenia';

  @override
  String updatingPowerLevelOf(Object userId) {
    return 'Aktualizacja poziomu uprawnień $userId';
  }

  @override
  String get updatingProfileImage => 'Aktualizacja obrazu profilowego';

  @override
  String get updatingRSVP => 'Aktualizacja RSVP';

  @override
  String get updatingSpace => 'Aktualizacja przestrzeni';

  @override
  String get uploadAvatar => 'Prześlij awatar';

  @override
  String usedTimes(Object count) {
    return 'Używany $count razy';
  }

  @override
  String userAddedToBlockList(Object user) {
    return '$user dodany do listy blokowanych. Aktualizacja interfejsu użytkownika może trochę potrwać';
  }

  @override
  String get users => 'Users';

  @override
  String get usersfoundDirectory => 'Users found in public directory';

  @override
  String get username => 'Nazwa użytkownika';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get usernameCopiedToClipboard => 'Nazwa użytkownika skopiowana do schowka';

  @override
  String get userRemovedFromList => 'Użytkownik usunięty z listy. Aktualizacja interfejsu użytkownika może trochę potrwać';

  @override
  String get usersYouBlocked => 'Zablokowani użytkownicy';

  @override
  String get validEmail => 'Wprowadź prawidłowy adres e-mail';

  @override
  String get verificationConclusionCompromised => 'Jeden z poniższych elementów może być zagrożony:\n\n   - Serwer domowy użytkownika\n   - Serwer domowy, z którym połączony jest weryfikowany użytkownik\n   - Połączenie internetowe użytkownika lub innych użytkowników\n   - Urządzenie użytkownika lub innych użytkowników';

  @override
  String verificationConclusionOkDone(String sender) {
    return 'Pomyślnie zweryfikowano $sender!';
  }

  @override
  String get verificationConclusionOkSelfNotice => 'Nowa sesja jest teraz zweryfikowana. Ma ona dostęp do zaszyfrowanych wiadomości, a inni użytkownicy będą postrzegać ją jako zaufaną.';

  @override
  String get verificationEmojiNotice => 'Porównaj unikalne emoji, upewniając się, że pojawiają się w tej samej kolejności.';

  @override
  String get verificationRequestAccept => 'Aby kontynuować, zaakceptuj prośbę o weryfikację na drugim urządzeniu.';

  @override
  String verificationRequestWaitingFor(String sender) {
    return 'Oczekiwanie na $sender…';
  }

  @override
  String get verificationSasDoNotMatch => 'Nie pasują one do siebie';

  @override
  String get verificationSasMatch => 'Pasują do siebie';

  @override
  String get verificationScanEmojiTitle => 'Nie można skanować';

  @override
  String get verificationScanSelfEmojiSubtitle => 'Zweryfikuj, porównując emoji';

  @override
  String get verificationScanSelfNotice => 'Zeskanuj kod za pomocą innego urządzenia lub przełącz się i zeskanuj za pomocą tego urządzenia';

  @override
  String get verified => 'Zweryfikowano';

  @override
  String get verifiedSessionsDescription => 'Wszystkie urządzenia są zweryfikowane. Twoje konto jest bezpieczne.';

  @override
  String get verifyOtherSession => 'Weryfikacja innej sesji';

  @override
  String get verifySession => 'Weryfikacja sesji';

  @override
  String get verifyThisSession => 'Zweryfikuj tę sesję';

  @override
  String get version => 'Wersja';

  @override
  String get via => 'przez';

  @override
  String get video => 'Wideo';

  @override
  String get welcomeBack => 'Witamy z powrotem';

  @override
  String get welcomeTo => 'Witamy w';

  @override
  String get whatToCallThisChat => 'Jak nazwać ten czat?';

  @override
  String get yes => 'Tak';

  @override
  String get yesLeave => 'Tak, zostaw';

  @override
  String get yesPleaseUpdate => 'Tak, prosimy o aktualizację';

  @override
  String get youAreAbleToJoinThisRoom => 'Możesz dołączyć do tego pokoju';

  @override
  String youAreAboutToBlock(Object userId) {
    return 'Zamierzasz odblokować $userId';
  }

  @override
  String youAreAboutToUnblock(Object userId) {
    return 'Zamierzasz odblokować $userId';
  }

  @override
  String get youAreBothIn => 'you are both in ';

  @override
  String get youAreCurrentlyNotConnectedToAnySpaces => 'Obecnie nie jesteś połączony z żadną przestrzenią';

  @override
  String get spaceShortDescription => 'przestrzeń, aby zacząć organizować i współpracować!';

  @override
  String get youAreDoneWithAllYourTasks => 'wszystkie zadania zostały wykonane!';

  @override
  String get youAreNotAMemberOfAnySpaceYet => 'Nie jesteś jeszcze członkiem żadnej przestrzeni';

  @override
  String get youAreNotPartOfThisGroup => 'Nie należysz do tej grupy. Chcesz do niej dołączyć?';

  @override
  String get youHaveNoDMsAtTheMoment => 'W tej chwili nie masz DM';

  @override
  String get youHaveNoUpdates => 'Nie masz żadnych aktualizacji';

  @override
  String get youHaveNotCreatedInviteCodes => 'Nie utworzono jeszcze żadnych kodów zaproszeń';

  @override
  String get youMustSelectSpace => 'Należy wybrać spację';

  @override
  String get youNeedBeInvitedToJoinThisRoom => 'Aby dołączyć do tego pokoju, musisz zostać zaproszony';

  @override
  String get youNeedToEnterAComment => 'Musisz wpisać komentarz';

  @override
  String get youNeedToEnterCustomValueAsNumber => 'Wartość niestandardową należy wprowadzić jako liczbę.';

  @override
  String youCantExceedPowerLevel(Object powerLevel) {
    return 'Nie można przekroczyć poziomu mocy $powerLevel';
  }

  @override
  String get yourActiveDevices => 'Aktywne urządzenia';

  @override
  String get yourPassword => 'Twoje hasło';

  @override
  String get yourSessionHasBeenTerminatedByServer => 'Twoja sesja została przerwana przez serwer, musisz zalogować się ponownie';

  @override
  String get yourTextSlidesMustContainsSomeText => 'Slajdy tekstowe muszą zawierać tekst';

  @override
  String get yourSafeAndSecureSpace => 'Bezpieczna przestrzeń dla cyfrowego aktywizmu';

  @override
  String adding(Object email) {
    return 'dodanie $email';
  }

  @override
  String get addTextSlide => 'Dodaj slajd tekstowy';

  @override
  String get addImageSlide => 'Dodaj slajd obrazu';

  @override
  String get addVideoSlide => 'Dodaj slajd wideo';

  @override
  String get acter => 'Acter';

  @override
  String get acterApp => 'Acter App';

  @override
  String get activate => 'Activate';

  @override
  String get changingNotificationMode => 'Zmiana trybu powiadomień…';

  @override
  String get createComment => 'Utwórz komentarz';

  @override
  String get createNewPin => 'Utwórz nowy pin';

  @override
  String get createNewSpace => 'Stwórz nową przestrzeń';

  @override
  String get createNewTaskList => 'Tworzenie nowej listy zadań';

  @override
  String get creatingPin => 'Tworzenie pin…';

  @override
  String get deactivateAccount => 'Dezaktywacja konta';

  @override
  String get deletingCode => 'Usuwanie kodu';

  @override
  String get dueToday => 'Do dzisiaj';

  @override
  String get dueTomorrow => 'Do jutra';

  @override
  String get dueSuccess => 'Termin został pomyślnie zmieniony';

  @override
  String get endDate => 'Data zakończenia';

  @override
  String get endTime => 'Czas zakończenia';

  @override
  String get emailAddress => 'Adres e-mail';

  @override
  String get emailAddresses => 'Adresy e-mail';

  @override
  String get errorParsinLink => 'Parsing Link failed';

  @override
  String errorCreatingPin(Object error) {
    return 'Wystąpił błąd podczas tworzenia pinu $error';
  }

  @override
  String errorLoadingAttachments(Object error) {
    return 'Błąd ładowania załączników: $error';
  }

  @override
  String errorLoadingAvatar(Object error) {
    return 'Błąd ładowania awatara: $error';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'Błąd ładowania profilu: $error';
  }

  @override
  String errorLoadingUsers(Object error) {
    return 'Błąd ładowania użytkowników: $error';
  }

  @override
  String errorLoadingTasks(Object error) {
    return 'Błąd ładowania zadań: $error';
  }

  @override
  String errorLoadingSpace(Object error) {
    return 'Błąd ładowania przestrzeni: $error';
  }

  @override
  String errorLoadingRelatedChats(Object error) {
    return 'Błąd ładowania powiązanych czatów: $error';
  }

  @override
  String errorLoadingPin(Object error) {
    return 'Błąd ładowania pinu: $error';
  }

  @override
  String errorLoadingEventDueTo(Object error) {
    return 'Błąd ładowania zdarzenia z powodu: $error';
  }

  @override
  String errorLoadingImage(Object error) {
    return 'Błąd ładowania obrazu: $error';
  }

  @override
  String errorLoadingRsvpStatus(Object error) {
    return 'Błąd ładowania statusu rsvp: $error';
  }

  @override
  String errorLoadingEmailAddresses(Object error) {
    return 'Błąd ładowania adresów e-mail: $error';
  }

  @override
  String errorLoadingMembersCount(Object error) {
    return 'Błąd ładowania liczby członków: $error';
  }

  @override
  String errorLoadingTileDueTo(Object error) {
    return 'Błąd ładowania kafelka z powodu: $error';
  }

  @override
  String errorLoadingMember(Object error, Object memberId) {
    return 'Błąd ładowania członka: $memberId $error';
  }

  @override
  String errorSendingAttachment(Object error) {
    return 'Błąd wysyłania załącznika: $error';
  }

  @override
  String get eventCreate => 'Utwórz zdarzenie';

  @override
  String get eventEdit => 'Edytuj wydarzenie';

  @override
  String get eventRemove => 'Usuń zdarzenie';

  @override
  String get eventReport => 'Zgłoś zdarzenie';

  @override
  String get eventUpdate => 'Aktualizacja wydarzenia';

  @override
  String get eventShare => 'Udostępnij wydarzenie';

  @override
  String failedToAdd(Object error, Object something) {
    return 'Nie udało się dodać: $error';
  }

  @override
  String failedToChangePin(Object error) {
    return 'Failed to change pin: $error';
  }

  @override
  String failedToChangePowerLevel(Object error) {
    return 'Nie udało się zmienić poziomu mocy: $error';
  }

  @override
  String failedToChangeNotificationMode(Object error) {
    return 'Nie udało się zmienić trybu powiadomień: $error';
  }

  @override
  String failedToChangePushNotificationSettings(Object error) {
    return 'Nie udało się zmienić ustawień powiadomień push: $error';
  }

  @override
  String failedToToggleSettingOf(Object error, Object module) {
    return 'Nie udało się przełączyć ustawienia $module: $error';
  }

  @override
  String failedToEditSpace(Object error) {
    return 'Nie udało się edytować przestrzeni: $error';
  }

  @override
  String failedToAssignSelf(Object error) {
    return 'Nie udało się przypisać self: $error';
  }

  @override
  String failedToUnassignSelf(Object error) {
    return 'Nie udało się usunąć przypisania self: $error';
  }

  @override
  String failedToSend(Object error) {
    return 'Nie udało się wysłać: $error';
  }

  @override
  String failedToCreateChat(Object error) {
    return 'Nie udało się utworzyć czatu: $error';
  }

  @override
  String failedToCreateTaskList(Object error) {
    return 'Nie udało się utworzyć listy zadań:  $error';
  }

  @override
  String failedToConfirmToken(Object error) {
    return 'Nie udało się potwierdzić tokena: $error';
  }

  @override
  String failedToSubmitEmail(Object error) {
    return 'Nie udało się przesłać wiadomości e-mail: $error';
  }

  @override
  String get failedToDecryptMessage => 'Nie udało się odszyfrować wiadomości. Ponowne żądanie kluczy sesji';

  @override
  String failedToDeleteAttachment(Object error) {
    return 'Nie udało się usunąć załącznika z powodu: $error';
  }

  @override
  String get failedToDetectMimeType => 'Nie udało się wykryć typu mime';

  @override
  String failedToLeaveRoom(Object error) {
    return 'Nie udało się opuścić pokoju: $error';
  }

  @override
  String failedToLoadSpace(Object error) {
    return 'Nie udało się załadować przestrzeni: $error';
  }

  @override
  String failedToLoadEvent(Object error) {
    return 'Nie udało się załadować zdarzenia: $error';
  }

  @override
  String failedToLoadInviteCodes(Object error) {
    return 'Nie udało się załadować kodów zaproszeń: $error';
  }

  @override
  String failedToLoadPushTargets(Object error) {
    return 'Nie udało się załadować celów push: $error';
  }

  @override
  String failedToLoadEventsDueTo(Object error) {
    return 'Nie udało się załadować zdarzeń z powodu: $error';
  }

  @override
  String failedToLoadChatsDueTo(Object error) {
    return 'Nie udało się załadować czatu z powodu: $error';
  }

  @override
  String failedToShareRoom(Object error) {
    return 'Nie udało się udostępnić tego pokoju: $error';
  }

  @override
  String get forgotYourPassword => 'Zapomniałeś hasła?';

  @override
  String get editInviteCode => 'Edytuj kod zaproszenia';

  @override
  String get createInviteCode => 'Utwórz kod zaproszenia';

  @override
  String get selectSpacesAndChats => 'Select spaces and chats';

  @override
  String get autoJoinSpacesAndChatsInfo => 'While redeeming this code, selected spaces and chats are auto join.';

  @override
  String get createDM => 'Create DM';

  @override
  String get autoDMWhileRedeemCode => 'While redeeming code, DM will be created\'';

  @override
  String get redeemInviteCode => 'Redeem Invite Code';

  @override
  String saveInviteCodeFailed(Object error) {
    return 'Zapisywanie kodu nie powiodło się: $error';
  }

  @override
  String createInviteCodeFailed(Object error) {
    return 'Tworzenie kodu nie powiodło się: $error';
  }

  @override
  String deleteInviteCodeFailed(Object error) {
    return 'Usunięcie kodu nie powiodło się: $error';
  }

  @override
  String get loadingChat => 'Ładowanie czatu…';

  @override
  String get loadingCommentsList => 'Ładowanie listy komentarzy';

  @override
  String get loadingPin => 'Sworzeń ładujący';

  @override
  String get loadingRoom => 'Pomieszczenie załadunkowe';

  @override
  String get loadingRsvpStatus => 'Ładowanie statusu rsvp';

  @override
  String get loadingTargets => 'Ładowanie celów';

  @override
  String get loadingOtherChats => 'Ładowanie innych czatów';

  @override
  String get loadingFirstSync => 'Ładowanie pierwszej synchronizacji';

  @override
  String get loadingImage => 'Ładowanie obrazu';

  @override
  String get loadingVideo => 'Ładowanie wideo';

  @override
  String loadingEventsFailed(Object error) {
    return 'Ładowanie zdarzeń nie powiodło się: $error';
  }

  @override
  String loadingTasksFailed(Object error) {
    return 'Ładowanie zadań nie powiodło się: $error';
  }

  @override
  String loadingSpacesFailed(Object error) {
    return 'Ładowanie przestrzeni nie powiodło się: $error';
  }

  @override
  String loadingRoomFailed(Object error) {
    return 'Ładowanie pokoju nie powiodło się: $error';
  }

  @override
  String loadingMembersCountFailed(Object error) {
    return 'Ładowanie liczby członków nie powiodło się: $error';
  }

  @override
  String get longPressToActivate => 'długie naciśnięcie, aby aktywować';

  @override
  String get pinCreatedSuccessfully => 'Pin utworzony pomyślnie';

  @override
  String get pleaseSelectValidEndTime => 'Wybierz prawidłowy czas zakończenia';

  @override
  String get pleaseSelectValidEndDate => 'Wybierz prawidłową datę zakończenia';

  @override
  String powerLevelSubmitted(Object module) {
    return 'Przesłano aktualizację poziomu mocy dla $module';
  }

  @override
  String get optionalParentSpace => 'Opcjonalna przestrzeń dla rodziców';

  @override
  String redeeming(Object token) {
    return 'Wykorzystanie $token';
  }

  @override
  String get encryptedDMChat => 'Szyfrowany czat DM';

  @override
  String get encryptedChatMessage => 'Encrypted Message locked. Tap for more';

  @override
  String get encryptedChatMessageInfoTitle => 'Locked Message';

  @override
  String get encryptedChatMessageInfo => 'Chat messages are end-to-end-encrypted. That means only devices connected at the time the message is sent can decrypt them. If you joined later, just logged in or used a new device, you don’t have the keys to decrypt this message yet. You can get it by verifying this session with another device of your account, by providing a encryption backup key or by verifying with another user that has access to the key.';

  @override
  String get chatMessageDeleted => 'Message deleted';

  @override
  String chatJoinedDisplayName(Object name) {
    return '$name joined';
  }

  @override
  String chatJoinedUserId(Object userId) {
    return '$userId joined';
  }

  @override
  String get chatYouJoined => 'You joined';

  @override
  String get chatYouLeft => 'You left';

  @override
  String chatYouBanned(Object name) {
    return 'You banned $name';
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
  String get chatYouAcceptedInvite => 'You accepted the invite';

  @override
  String chatYouInvited(Object name) {
    return 'You invited $name';
  }

  @override
  String chatInvitedDisplayName(Object invitee, Object name) {
    return '$name invited $invitee';
  }

  @override
  String chatInvitedUserId(Object inviteeId, Object userId) {
    return '$userId invited $inviteeId';
  }

  @override
  String chatInvitationAcceptedDisplayName(Object name) {
    return '$name accepted invitation';
  }

  @override
  String chatInvitationAcceptedUserId(Object userId) {
    return '$userId accepted invitation';
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
  String get regularSpaceOrChat => 'Zwykła przestrzeń lub czat';

  @override
  String get encryptedSpaceOrChat => 'Szyfrowana przestrzeń lub czat';

  @override
  String get encryptedChatInfo => 'All messages in this chat are end-to-end encrypted. No one outside of this chat, not even Acter or any Matrix Server routing the message, can read them.';

  @override
  String get removeThisPin => 'Usuń ten pin';

  @override
  String get removeThisPost => 'Usuń ten post';

  @override
  String get removingContent => 'Usuwanie zawartości';

  @override
  String get removingAttachment => 'Usuwanie załącznika';

  @override
  String get reportThis => 'Zgłoś to';

  @override
  String get reportThisPin => 'Zgłoś ten pin';

  @override
  String reportSendingFailedDueTo(Object error) {
    return 'Wysyłanie raportu nie powiodło się z powodu: $error';
  }

  @override
  String get resettingPassword => 'Resetting your password';

  @override
  String resettingPasswordFailed(Object error) {
    return 'Reset failed: $error';
  }

  @override
  String get resettingPasswordSuccessful => 'Password successfully reset.';

  @override
  String get sharedSuccessfully => 'Udostępnione z powodzeniem';

  @override
  String get changedPushNotificationSettingsSuccessfully => 'Pomyślnie zmieniono ustawienia powiadomień push';

  @override
  String get startDateRequired => 'Wymagana data rozpoczęcia!';

  @override
  String get startTimeRequired => 'Wymagany czas rozpoczęcia!';

  @override
  String get endDateRequired => 'Wymagana data zakończenia!';

  @override
  String get endTimeRequired => 'Wymagany czas zakończenia!';

  @override
  String get searchUser => 'search user';

  @override
  String seeAllMyEvents(Object count) {
    return 'Zobacz wszystkie moje wydarzenia $count';
  }

  @override
  String get selectSpace => 'Wybierz miejsce';

  @override
  String get selectChat => 'Wybierz czat';

  @override
  String get selectCustomDate => 'Select specific date';

  @override
  String get selectPicture => 'Wybierz obraz';

  @override
  String get selectVideo => 'Wybierz wideo';

  @override
  String get selectDate => 'Wybierz datę';

  @override
  String get selectTime => 'Wybierz czas';

  @override
  String get sendDM => 'Wyślij DM';

  @override
  String get showMore => 'pokaż więcej';

  @override
  String get showLess => 'pokaż mniej';

  @override
  String get joinSpace => 'Dołącz do przestrzeni';

  @override
  String get joinExistingSpace => 'Dołącz do istniejącej przestrzeni';

  @override
  String get mySpaces => 'Moje przestrzenie';

  @override
  String get startDate => 'Data rozpoczęcia';

  @override
  String get startTime => 'Godzina rozpoczęcia';

  @override
  String get startGroupDM => 'Grupa startowa DM';

  @override
  String get moreSubspaces => 'Więcej podprzestrzeni';

  @override
  String get myTasks => 'Moje zadania';

  @override
  String updatingDueFailed(Object error) {
    return 'Aktualizacja nie powiodła się: $error';
  }

  @override
  String get unlinkRoom => 'Odłącz pomieszczenie';

  @override
  String changeThePowerFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'od $memberStatus $currentPowerLevel do';
  }

  @override
  String get createOrJoinSpaceDescription => 'Stwórz przestrzeń lub dołącz do niej, aby zacząć organizować i współpracować!';

  @override
  String get introPageDescriptionPre => 'Acter to coś więcej niż tylko aplikacja';

  @override
  String get isLinked => 'is linked in here';

  @override
  String get canLink => 'You can link this';

  @override
  String get canLinkButNotUpgrade => 'You can link this, but not update its join permissions';

  @override
  String get introPageDescriptionHl => ' społeczność twórców zmian.';

  @override
  String get introPageDescriptionPost => '';

  @override
  String get introPageDescription2ndLine => 'Nawiązuj kontakty z innymi aktywistami, dziel się spostrzeżeniami i współpracuj przy znaczących projektach.';

  @override
  String get logOutConformationDescription1 => 'Uwaga: ';

  @override
  String get logOutConformationDescription2 => 'Wylogowanie usuwa lokalne dane, w tym klucze szyfrowania. Jeśli jest to twoje ostatnie zalogowane urządzenie, możesz nie być w stanie odszyfrować poprzedniej zawartości.';

  @override
  String get logOutConformationDescription3 => ' Czy na pewno chcesz się wylogować?';

  @override
  String membersCount(Object count) {
    return '$count Członkowie';
  }

  @override
  String get renderSyncingTitle => 'Synchronizacja z serwerem domowym';

  @override
  String get renderSyncingSubTitle => 'Może to trochę potrwać, jeśli masz duże konto';

  @override
  String errorSyncing(Object error) {
    return 'Błąd synchronizacji: $error';
  }

  @override
  String get retrying => 'ponowna próba …';

  @override
  String retryIn(Object minutes, Object seconds) {
    return 'Ponowi próbę za $minutes:$seconds';
  }

  @override
  String get invitations => 'Zaproszenia';

  @override
  String invitingLoading(Object userId) {
    return 'Inviting $userId';
  }

  @override
  String invitingError(Object error, Object userId) {
    return 'User $userId not found or existing: $error';
  }

  @override
  String get invite => 'Zaproszenie';

  @override
  String errorUnverifiedSessions(Object error) {
    return 'Nie można załadować niezweryfikowanych sesji: $error';
  }

  @override
  String unverifiedSessionsTitle(Object count) {
    return 'Zalogowano $count niezweryfikowanych sesji';
  }

  @override
  String get review => 'Recenzja';

  @override
  String get activities => 'Działania';

  @override
  String get activitiesDescription => 'Wszystkie ważne rzeczy wymagające uwagi można znaleźć tutaj';

  @override
  String get noActivityTitle => 'Brak aktywności';

  @override
  String get noActivitySubtitle => 'Powiadamia o ważnych rzeczach, takich jak wiadomości, zaproszenia lub prośby.';

  @override
  String get joining => 'Łączenie';

  @override
  String get joinedDelayed => 'Accepted invitation, confirmation takes its time though';

  @override
  String get rejecting => 'Odrzucenie';

  @override
  String get rejected => 'Odrzucono';

  @override
  String get failedToReject => 'Nie udało się odrzucić';

  @override
  String reportedBugSuccessful(Object issueId) {
    return 'Błąd został pomyślnie zgłoszony! (#$issueId)';
  }

  @override
  String get thanksForReport => 'Dzięki za zgłoszenie tego błędu!';

  @override
  String bugReportingError(Object error) {
    return 'Błąd zgłaszania błędu: 1$error';
  }

  @override
  String get bugReportTitle => 'Zgłoś problem';

  @override
  String get bugReportDescription => 'Krótki opis problemu';

  @override
  String get emptyDescription => 'Wprowadź opis';

  @override
  String get includeUserId => 'Dołącz mój identyfikator Matrix';

  @override
  String get includeLog => 'Dołącz bieżące dzienniki';

  @override
  String get includePrevLog => 'Dołącz dzienniki z poprzedniego uruchomienia';

  @override
  String get includeScreenshot => 'Dołącz zrzut ekranu';

  @override
  String get includeErrorAndStackTrace => 'Include Error & Stacktrace';

  @override
  String get jumpTo => 'skok do';

  @override
  String get noMatchingPinsFound => 'Nie znaleziono pasujących pinów';

  @override
  String get update => 'Aktualizacja';

  @override
  String get event => 'Wydarzenie';

  @override
  String get taskList => 'Lista zadań';

  @override
  String get pin => 'Pin';

  @override
  String get poll => 'Ankieta';

  @override
  String get discussion => 'Dyskusja';

  @override
  String get fatalError => 'Błąd krytyczny';

  @override
  String get nukeLocalData => 'Nuke danych lokalnych';

  @override
  String get reportBug => 'Zgłoś błąd';

  @override
  String get somethingWrong => 'Coś poszło nie tak:';

  @override
  String get copyToClipboard => 'Kopiuj do schowka';

  @override
  String get errorCopiedToClipboard => 'Błąd i śledzenie ruchu skopiowane do schowka';

  @override
  String get showStacktrace => 'Pokaż ślad historii';

  @override
  String get hideStacktrace => 'Ukryj ślad historii';

  @override
  String get sharingRoom => 'Dzielenie tego pokoju…';

  @override
  String get changingSettings => 'Zmiana ustawień…';

  @override
  String changingSettingOf(Object module) {
    return 'Zmiana ustawień $module';
  }

  @override
  String changedSettingOf(Object module) {
    return 'Zmieniono ustawienie $module';
  }

  @override
  String changingPowerLevelOf(Object module) {
    return 'Zmiana poziomu mocy $module';
  }

  @override
  String get assigningSelf => 'Przypisywanie sobie…';

  @override
  String get unassigningSelf => 'Nieprzypisywanie sobie…';

  @override
  String get homeTabTutorialTitle => 'Pulpit nawigacyjny';

  @override
  String get homeTabTutorialDescription => 'Tutaj znajdziesz swoje przestrzenie oraz przegląd wszystkich nadchodzących wydarzeń i oczekujących zadań dla tych przestrzeni.';

  @override
  String get updatesTabTutorialTitle => 'Aktualizacje';

  @override
  String get updatesTabTutorialDescription => 'Strumień wiadomości o najnowszych aktualizacjach i wezwaniach do działania z Twojej przestrzeni.';

  @override
  String get chatsTabTutorialTitle => 'Czaty';

  @override
  String get chatsTabTutorialDescription => 'Jest to miejsce do czatowania - z grupami lub pojedynczymi osobami. czaty mogą być połączone z różnymi przestrzeniami w celu szerszej współpracy.';

  @override
  String get activityTabTutorialTitle => 'Aktywność';

  @override
  String get activityTabTutorialDescription => 'Ważne informacje z przestrzeni, takie jak zaproszenia lub prośby. Dodatkowo będziesz powiadamiany przez Acter o kwestiach bezpieczeństwa';

  @override
  String get jumpToTabTutorialTitle => 'Skocz do';

  @override
  String get jumpToTabTutorialDescription => 'Wyszukiwanie w przestrzeni i pinezkach, a także szybkie akcje i szybki dostęp do kilku sekcji';

  @override
  String get createSpaceTutorialTitle => 'Stwórz nową przestrzeń';

  @override
  String get createSpaceTutorialDescription => 'Dołącz do istniejącej przestrzeni na naszym serwerze Acter lub w uniwersum Matrix albo stwórz własną przestrzeń.';

  @override
  String get joinSpaceTutorialTitle => 'Dołącz do istniejącej przestrzeni';

  @override
  String get joinSpaceTutorialDescription => 'Dołącz do istniejącej przestrzeni na naszym serwerze Acter lub w uniwersum Matrix albo stwórz własną przestrzeń. [Pokażę tylko opcje i na tym zakończę].';

  @override
  String get spaceOverviewTutorialTitle => 'Szczegóły dotyczące przestrzeni';

  @override
  String get spaceOverviewTutorialDescription => 'Przestrzeń jest punktem wyjścia do organizowania. Twórz i nawiguj po pinezkach (zasobach), zadaniach i wydarzeniach. Dodawaj czaty lub podprzestrzenie.';

  @override
  String get subscribedToParentMsg => 'Disable Notifications on main object to configure notification here';

  @override
  String get parentSubscribedAction => 'Notifications active through object';

  @override
  String get subscribeAction => 'Activate Notifications';

  @override
  String get unsubscribeAction => 'De-Activate Notifications';

  @override
  String get commentEmptyStateTitle => 'Nie znaleziono żadnych komentarzy';

  @override
  String get commentEmptyStateAction => 'Zostaw pierwszy komentarz';

  @override
  String get previous => 'Poprzedni';

  @override
  String get finish => 'Zakończenie';

  @override
  String get saveUsernameTitle => 'Czy zapisałeś swoją nazwę użytkownika?';

  @override
  String get saveUsernameDescription1 => 'Pamiętaj, aby zanotować swoją nazwę użytkownika. Jest to klucz dostępu do profilu i wszystkich związanych z nim informacji i przestrzeni.';

  @override
  String get saveUsernameDescription2 => 'Jeśli zapomniałeś hasła, twoja nazwa użytkownika jest kołem ratunkowym do jego zresetowania.';

  @override
  String get saveUsernameDescription3 => 'Bez tego dostęp do profilu i postępów zostanie trwale utracony.';

  @override
  String get acterUsername => 'Twoja nazwa użytkownika na Acter';

  @override
  String get autoSubscribeFeatureDesc => 'upon creation or interaction with objects';

  @override
  String get autoSubscribeSettingsTitle => 'Automatically subscribe ';

  @override
  String get copyToClip => 'Kopiuj do schowka';

  @override
  String get wizzardContinue => 'Kontynuuj';

  @override
  String get protectPrivacyTitle => 'Ochrona prywatności';

  @override
  String get protectPrivacyDescription1 => 'W Acter bezpieczeństwo konta jest bardzo ważne. Dlatego możesz z niego korzystać bez łączenia swojego profilu z adresem e-mail, aby zapewnić sobie dodatkową prywatność i ochronę.';

  @override
  String get protectPrivacyDescription2 => 'Jeśli jednak wolisz, nadal możesz połączyć je ze sobą, np. w celu odzyskania hasła.';

  @override
  String get linkEmailToProfile => 'E-mail połączony z profilem';

  @override
  String get emailOptional => 'E-mail (opcjonalnie)';

  @override
  String get hintEmail => 'Wprowadź swój adres e-mail';

  @override
  String get linkingEmailAddress => 'Łączenie adresu e-mail';

  @override
  String get avatarAddTitle => 'Dodaj awatar użytkownika';

  @override
  String get avatarEmpty => 'Wybierz swój awatar';

  @override
  String get avatarUploading => 'Wgrywanie awatara profilu';

  @override
  String avatarUploadFailed(Object error) {
    return 'Nie udało się przesłać awatara użytkownika: $error';
  }

  @override
  String get sendEmail => 'Send email';

  @override
  String get inviteCopiedToClipboard => 'Invite code copied to clipboard';

  @override
  String get updateName => 'Updating name';

  @override
  String get updateDescription => 'Updating description';

  @override
  String get editName => 'Edit Name';

  @override
  String get editDescription => 'Edit Description';

  @override
  String updateNameFailed(Object error) {
    return 'Updating name failed: $error';
  }

  @override
  String updateDescriptionFailed(Object error) {
    return 'Updating description failed: $error';
  }

  @override
  String get eventParticipants => 'Event Participants';

  @override
  String get upcomingEvents => 'Upcoming Events';

  @override
  String get spaceInviteDescription => 'Anyone you would like to invite to this space?';

  @override
  String get inviteSpaceMembersTitle => 'Invite Space Members';

  @override
  String get inviteSpaceMembersSubtitle => 'Invite users from selected space';

  @override
  String get inviteIndividualUsersTitle => 'Invite Individual Users';

  @override
  String get inviteIndividualUsersSubtitle => 'Invite users who are already on the Acter';

  @override
  String get inviteIndividualUsersDescription => 'Invite anyone who is part of the the Acter platform';

  @override
  String get inviteJoinActer => 'Invite to join Acter';

  @override
  String get inviteJoinActerDescription => 'You can invite people to join Acter and automatically join this space with a custom registration code and share that with them';

  @override
  String get generateInviteCode => 'Generate Invite Code';

  @override
  String get pendingInvites => 'Pending Invites';

  @override
  String pendingInvitesCount(Object count) {
    return 'You have $count pending Invites';
  }

  @override
  String get noPendingInvitesTitle => 'No pending Invites found';

  @override
  String get noUserFoundTitle => 'No users found';

  @override
  String get noUserFoundSubtitle => 'Search users with their username or display name';

  @override
  String get done => 'Done';

  @override
  String get downloadFileDialogTitle => 'Please select where to store the file';

  @override
  String downloadFileSuccess(Object path) {
    return 'File saved to $path';
  }

  @override
  String cancelInviteLoading(Object userId) {
    return 'Canceling invitation of $userId';
  }

  @override
  String cancelInviteError(Object error, Object userId) {
    return 'User $userId not found: $error';
  }

  @override
  String get shareInviteCode => 'Share Invite Code';

  @override
  String get appUnavailable => 'App Unavailable';

  @override
  String shareInviteContent(Object code, Object roomName, Object userName) {
    return '$userName would like to invite you to the $roomName.\nPlease follow below steps to join:\n\nSTEP-1: Download the Acter App from below links https://app-redir.acter.global/\n\nSTEP-2: Use the below invitation code on the registration.\nInvitation Code : $code\n\nThat’s it! Enjoy the new safe and secure way of organizing!';
  }

  @override
  String activateInviteCodeFailed(Object error) {
    return 'Activate code failed: $error';
  }

  @override
  String get revoke => 'Revoke';

  @override
  String get otherSpaces => 'Other Spaces';

  @override
  String get invitingSpaceMembersLoading => 'Inviting Space Members';

  @override
  String invitingSpaceMembersProgress(Object count, Object total) {
    return 'Inviting Space Member $count / $total';
  }

  @override
  String invitingSpaceMembersError(Object error) {
    return 'Inviting Space Members Error: $error';
  }

  @override
  String membersInvited(Object count) {
    return '$count members invited';
  }

  @override
  String get selectVisibility => 'Select Visibility';

  @override
  String get visibilityTitle => 'Visibility';

  @override
  String get visibilitySubtitle => 'Select who can join this space.';

  @override
  String get visibilityNoPermission => 'You don’t have necessary permissions to change this space visibility';

  @override
  String get public => 'Public';

  @override
  String get publicVisibilitySubtitle => 'Anyone can find and join';

  @override
  String get privateVisibilitySubtitle => 'Only invited people can join';

  @override
  String get limited => 'Limited';

  @override
  String get limitedVisibilitySubtitle => 'Anyone in selected spaces can find and join';

  @override
  String get visibilityAndAccessibility => 'Visibility and Accessibility';

  @override
  String updatingVisibilityFailed(Object error) {
    return 'Updating room visibility failed: $error';
  }

  @override
  String get spaceWithAccess => 'Space with access';

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordDescription => 'Change your Password';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get emptyOldPassword => 'Please enter old password';

  @override
  String get emptyNewPassword => 'Please enter new password';

  @override
  String get emptyConfirmPassword => 'Please enter confirm password';

  @override
  String get validateSamePassword => 'Password must be same';

  @override
  String get changingYourPassword => 'Changing your password';

  @override
  String changePasswordFailed(Object error) {
    return 'Change password failed: $error';
  }

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get emptyTaskList => 'No Task list created yet';

  @override
  String get addMoreDetails => 'Add More Details';

  @override
  String get taskName => 'Task name';

  @override
  String get addingTask => 'Adding Task';

  @override
  String countTasksCompleted(Object count) {
    return '$count Completed';
  }

  @override
  String get showCompleted => 'Show Completed';

  @override
  String get hideCompleted => 'Hide Completed';

  @override
  String get assignment => 'Assignment';

  @override
  String get noAssignment => 'No Assignment';

  @override
  String get assignMyself => 'Assign Myself';

  @override
  String get removeMyself => 'Remove Myself';

  @override
  String get updateTask => 'Update Task';

  @override
  String get updatingTask => 'Updating Task';

  @override
  String updatingTaskFailed(Object error) {
    return 'Updating Task failed $error';
  }

  @override
  String get editTitle => 'Edit Title';

  @override
  String get updatingDescription => 'Updating Description';

  @override
  String errorUpdatingDescription(Object error) {
    return 'Error updating description: $error';
  }

  @override
  String get editLink => 'Edit Link';

  @override
  String get updatingLinking => 'Updating link';

  @override
  String get deleteTaskList => 'Delete Task List';

  @override
  String get deleteTaskItem => 'Delete Task Item';

  @override
  String get reportTaskList => 'Report Task List';

  @override
  String get reportTaskItem => 'Report Task Item';

  @override
  String get unconfirmedEmailsActivityTitle => 'You have unconfirmed E-Mail Addresses';

  @override
  String get unconfirmedEmailsActivitySubtitle => 'Please follow the link we’ve sent you in the email and then confirm them here';

  @override
  String get seeAll => 'See all';

  @override
  String get addPin => 'Add Pin';

  @override
  String get addEvent => 'Add Event';

  @override
  String get linkChat => 'Link Chat';

  @override
  String get linkSpace => 'Link Space';

  @override
  String failedToUploadAvatar(Object error) {
    return 'Failed to upload avatar: $error';
  }

  @override
  String get noMatchingTasksListFound => 'No matching tasks list found';

  @override
  String get noTasksListAvailableYet => 'No tasks list available yet';

  @override
  String get noTasksListAvailableDescription => 'Share and manage important task with your community such as any TO-DO list so everyone is updated.';

  @override
  String loadingMembersFailed(Object error) {
    return 'Loading members failed: $error';
  }

  @override
  String get ongoing => 'Ongoing';

  @override
  String get noMatchingEventsFound => 'No matching events found';

  @override
  String get noEventsFound => 'No events found';

  @override
  String get noEventAvailableDescription => 'Create new event and bring your community together.';

  @override
  String get myEvents => 'My Events';

  @override
  String get eventStarted => 'Started';

  @override
  String get eventStarts => 'Starts';

  @override
  String get eventEnded => 'Ended';

  @override
  String get happeningNow => 'Happening Now';

  @override
  String get myUpcomingEvents => 'My Upcoming Events';

  @override
  String get live => 'Live';

  @override
  String get forbidden => 'Forbidden';

  @override
  String get forbiddenRoomExplainer => 'Access to the room has been denied. Please contact the author to be invited';

  @override
  String accessDeniedToRoom(Object roomId) {
    return 'Access to $roomId denied';
  }

  @override
  String get changeDate => 'Change Date';

  @override
  String deepLinkNotSupported(Object link) {
    return 'Link $link not supported';
  }

  @override
  String get deepLinkWrongFormat => 'Not a link. Can\'t open.';

  @override
  String get updatingDate => 'Updating Date';

  @override
  String get pleaseEnterALink => 'Please enter a link';

  @override
  String get pleaseEnterAValidLink => 'Please enter a valid link';

  @override
  String get addLink => 'Add Link';

  @override
  String get attachmentEmptyStateTitle => 'No attachments found.';

  @override
  String get referencesEmptyStateTitle => 'No references found.';

  @override
  String get text => 'text';

  @override
  String get audio => 'Audio';

  @override
  String get pinDetails => 'Pin Details';

  @override
  String get inSpaceLabelInline => 'In:';

  @override
  String get comingSoon => 'Not supported yet, coming soon!';

  @override
  String get colonCharacter => ' : ';

  @override
  String get andSeparator => ' and ';

  @override
  String andNMore(Object count) {
    return ', and $count more';
  }

  @override
  String errorLoadingSpaces(Object error) {
    return 'Error loading spaces: $error';
  }

  @override
  String get eventNoLongerAvailable => 'Event no longer available';

  @override
  String get eventDeletedOrFailedToLoad => 'This may due to event deletion or failed to load';

  @override
  String get chatNotEncrypted => 'This chat is not end-to-end-encrypted';

  @override
  String get updatingIcon => 'Updating Icon';

  @override
  String get selectColor => 'Select color';

  @override
  String get selectIcon => 'Select icon';

  @override
  String get createCategory => 'Create Category';

  @override
  String get organize => 'Organize';

  @override
  String get updatingCategories => 'Updating categories';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String updatingCategoriesFailed(Object error) {
    return 'Updating categories failed $error';
  }

  @override
  String get addingNewCategory => 'Adding new category';

  @override
  String addingNewCategoriesFailed(Object error) {
    return 'Adding new category failed $error';
  }

  @override
  String get action => 'Action';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get boost => 'Boost';

  @override
  String get boosts => 'Boosts';

  @override
  String get requiredPowerLevel => 'Required PowerLevel';

  @override
  String minPowerLevelDesc(Object featureName) {
    return 'Minimum power level required to post $featureName';
  }

  @override
  String get minPowerLevelRsvp => 'Minimum power level to RSVP to calendar events';

  @override
  String get commentsOnBoost => 'Comments on Boost';

  @override
  String get commentsOnPin => 'Comments on Pin';

  @override
  String get adminPowerLevel => 'Admin PowerLevel';

  @override
  String get rsvpPowerLevel => 'RSVP PowerLevel';

  @override
  String get taskListPowerLevel => 'TaskList PowerLevel';

  @override
  String get tasksPowerLevel => 'Tasks PowerLevel';

  @override
  String get appSettings => 'App Settings';

  @override
  String get activeApps => 'Active Apps';

  @override
  String get postSpaceWiseBoost => 'Post space-wide boost';

  @override
  String get postSpaceWiseStories => 'Post space-wide stories';

  @override
  String get pinImportantInformation => 'Pin important information';

  @override
  String get calenderWithEvents => 'Calender with Events';

  @override
  String get pinNoLongerAvailable => 'Pin no longer available';

  @override
  String get inviteCodeEmptyState => 'No invite codes are generated yet';

  @override
  String get pinDeletedOrFailedToLoad => 'This may due to pin deletion or failed to load';

  @override
  String get sharePin => 'Share Pin';

  @override
  String get selectPin => 'Select Pin';

  @override
  String get selectEvent => 'Select Event';

  @override
  String get shareTaskList => 'Share TaskList';

  @override
  String get shareSpace => 'Share Space';

  @override
  String get shareChat => 'Share Chat';

  @override
  String get addBoost => 'Add Boost';

  @override
  String get addTaskList => 'Add TaskList';

  @override
  String get task => 'Task';

  @override
  String get signal => 'Signal';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get whatsAppBusiness => 'WA Business';

  @override
  String get telegram => 'Telegram';

  @override
  String get copy => 'copy';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get qr => 'QR';

  @override
  String get newBoost => 'New\nBoost';

  @override
  String get addComment => 'Add Comment';

  @override
  String get references => 'References';

  @override
  String get removeReference => 'Remove Reference';

  @override
  String get suggestedChats => 'Suggested Chats';

  @override
  String get suggestedSpaces => 'Suggested Spaces';

  @override
  String get removeReferenceConfirmation => 'Are you sure you want to remove this reference?';

  @override
  String noObjectAccess(Object objectType, Object spaceName) {
    return 'You are not part of $spaceName so you can\'t access this $objectType';
  }

  @override
  String get shareLink => 'Share link';

  @override
  String get shareSuperInvite => 'Share Invitation Code';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get unableToLoadVideo => 'Unable to load video';

  @override
  String get unableToLoadImage => 'Unable to load image';

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
