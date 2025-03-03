// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class L10nFr extends L10n {
  L10nFr([String locale = 'fr']) : super(locale);

  @override
  String get about => 'À propos';

  @override
  String get accept => 'Accepter';

  @override
  String get acceptRequest => 'Accepter la requête';

  @override
  String get access => 'Accès';

  @override
  String get accessAndVisibility => 'Accès & Visibilité';

  @override
  String get account => 'Compte';

  @override
  String get actionName => 'Nom de l\'action';

  @override
  String get actions => 'Actions';

  @override
  String activateFeatureDialogTitle(Object feature) {
    return 'Activate $feature?';
  }

  @override
  String activateFeatureDialogDesc(Object feature) {
    return 'Allow anyone with permission following permissions to use $feature';
  }

  @override
  String get add => 'ajouter';

  @override
  String get addActionWidget => 'Ajouter un widget d\'action';

  @override
  String get addChat => 'Ajouter une discussion';

  @override
  String addedToPusherList(Object email) {
    return '$email ajouté à la liste des pusher';
  }

  @override
  String addedToSpacesAndChats(Object number) {
    return 'Ajouté à $number espaces et discussions';
  }

  @override
  String get addingEmailAddress => 'Ajout d\'une adresse e-mail';

  @override
  String get addSpace => 'Ajouter un Espace';

  @override
  String get addTask => 'Ajouter une Tâche';

  @override
  String get admin => 'Admin';

  @override
  String get all => 'Tout';

  @override
  String get allMessages => 'Tous les messages';

  @override
  String allReactionsCount(Object total) {
    return 'All $total';
  }

  @override
  String get alreadyConfirmed => 'Déjà confirmé';

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
  String get and => 'et';

  @override
  String get anInviteCodeYouWantToRedeem => 'Un code d\'invitation que vous souhaitez utiliser';

  @override
  String get anyNumber => 'n\'importe quel nombre';

  @override
  String get appDefaults => 'Application par défaut';

  @override
  String get appId => 'AppId';

  @override
  String get appName => 'Nom de l\'application';

  @override
  String get apps => 'Caractéristiques de l\'Espace';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'Êtes-vous sûr de vouloir supprimer ce message ? Cette action ne peut être annulée.';

  @override
  String get areYouSureYouWantToLeaveRoom => 'Êtes-vous sûr de vouloir quitter le chat ? Cette action ne peut pas être annulée';

  @override
  String get areYouSureYouWantToLeaveSpace => 'Êtes-vous sûr de vouloir quitter cet espace ?';

  @override
  String get areYouSureYouWantToRemoveAttachmentFromPin => 'Êtes-vous sûr de vouloir retirer cette pièce jointe de l\'épingle ?';

  @override
  String get areYouSureYouWantToUnregisterEmailAddress => 'Êtes-vous sûr de vouloir annuler l\'enregistrement de cette adresse email ? Cette action ne peut être annulée.';

  @override
  String get assignedYourself => 'assigné à moi-même';

  @override
  String get assignmentWithdrawn => 'Assignation retirée';

  @override
  String get aTaskMustHaveATitle => 'Une tâche doit avoir un titre';

  @override
  String get attachments => 'Pièces jointes';

  @override
  String get atThisMomentYouAreNotJoiningEvents => 'En ce moment, vous ne participez à aucun événement à venir. Pour connaître les événements prévus, consultez vos espaces.';

  @override
  String get authenticationRequired => 'Authentification requise';

  @override
  String get avatar => 'Avatar';

  @override
  String get awaitingConfirmation => 'En attente de confirmation';

  @override
  String get awaitingConfirmationDescription => 'Ces adresses email n\'ont pas encore été confirmées. Veuillez consulter votre boîte de réception et vérifier le lien de confirmation.';

  @override
  String get back => 'Back';

  @override
  String get block => 'Bloquer';

  @override
  String get blockedUsers => 'Bloquers des utilisateurs';

  @override
  String get blockInfoText => 'Une fois bloqué, vous ne verrez plus leurs messages et ils ne pourront plus vous contacter directement.';

  @override
  String blockingUserFailed(Object error) {
    return 'Échec du blocage de l\'utilisateur : $error';
  }

  @override
  String get blockingUserProgress => 'Bloquage Utilisateur';

  @override
  String get blockingUserSuccess => 'L\'utilisateur a été bloqué. Il faudra patienter un moment avant que l\'interface utilisateur ne soit mise à jour.';

  @override
  String blockTitle(Object userId) {
    return 'Bloquer $userId';
  }

  @override
  String get blockUser => 'Bloquer Utilisateur';

  @override
  String get blockUserOptional => 'Bloquer Utilisateur (optionnel)';

  @override
  String get blockUserWithUsername => 'Bloquer l\'utilisateur avec le nom d\'utilisateur';

  @override
  String get bookmark => 'Favoris';

  @override
  String get bookmarked => 'Mis en Favoris';

  @override
  String get bookmarkedSpaces => 'Espaces mis en favoris';

  @override
  String get builtOnShouldersOfGiants => 'Des nains sur des épaules de géants';

  @override
  String get calendarEventsFromAllTheSpaces => 'Calendrier des événements de tous les Espaces auxquels vous appartenez';

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
  String get camera => 'Caméra';

  @override
  String get cancel => 'Annuler';

  @override
  String get cannotEditSpaceWithNoPermissions => 'Impossible de modifier l\'espace sans autorisation';

  @override
  String get changeAppLanguage => 'Modifier la langue de l\'Application';

  @override
  String get changePowerLevel => 'Modifier le Niveau d\'Autorisation';

  @override
  String get changeThePowerLevelOf => 'Modifier le droit d\'accès à';

  @override
  String get changeYourDisplayName => 'Modifier votre nom affiché';

  @override
  String get chat => 'Chat';

  @override
  String get chatNG => 'Next-Generation Chat';

  @override
  String get chatNGExplainer => 'Switch to next generation Chat. Features might not be stable';

  @override
  String get customizationsTitle => 'Customizations';

  @override
  String get chatMissingPermissionsToSend => 'Vous n\'avez pas le droit d\'envoyer des messages ici';

  @override
  String get behaviorSettingsTitle => 'Behavior';

  @override
  String get behaviorSettingsExplainer => 'Configure the behavior of your App';

  @override
  String get chatSettingsAutoDownload => 'Téléchargement Automatique des Médias';

  @override
  String get chatSettingsAutoDownloadExplainer => 'Quand télécharger automatiquement les médias';

  @override
  String get chatSettingsAutoDownloadAlways => 'Toujours';

  @override
  String get chatSettingsAutoDownloadWifiOnly => 'Uniquement avec le WiFi';

  @override
  String get chatSettingsAutoDownloadNever => 'Jamais';

  @override
  String get settingsSubmitting => 'Soumission des Paramètres';

  @override
  String get settingsSubmittingSuccess => 'Paramètres transmis';

  @override
  String settingsSubmittingFailed(Object error) {
    return 'Échec de l\'envoi : $error ';
  }

  @override
  String get chatRoomCreated => 'Chat créé';

  @override
  String get chatSendingFailed => 'Échec de l\'envoi. Nous allons réessayer ...';

  @override
  String get chatSettingsTyping => 'Envoi de notifications de saisie';

  @override
  String get chatSettingsTypingExplainer => '(bientôt) Informer les autres lorsque vous êtes en train d\'écrire';

  @override
  String get chatSettingsReadReceipts => 'Envoyer des accusés de réception';

  @override
  String get chatSettingsReadReceiptsExplainer => '(bientôt) Informer les autres lorsque vous avez lu le message';

  @override
  String get chats => 'Chats';

  @override
  String claimedTimes(Object count) {
    return 'Réclamé $count fois';
  }

  @override
  String get clear => 'Effacer';

  @override
  String get clearDBAndReLogin => 'Effacer la base de données et se reconnecter';

  @override
  String get close => 'Fermer';

  @override
  String get closeDialog => 'Fermer la fenêtre de Dialogue';

  @override
  String get closeSessionAndDeleteData => 'Fermer cette session, en supprimant les données locales';

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
  String get code => 'Code';

  @override
  String get codeMustBeAtLeast6CharactersLong => 'Le code doit comporter au moins 6 caractères';

  @override
  String get comment => 'Commenter';

  @override
  String get comments => 'Commentaires';

  @override
  String commentsListError(Object error) {
    return 'Liste d\'erreurs de commentaires : $error';
  }

  @override
  String get commentSubmitted => 'Commentaire envoyé';

  @override
  String get community => 'Communauté';

  @override
  String get confirmationToken => 'Token de confirmation';

  @override
  String get confirmedEmailAddresses => 'Adresses Emails confirmées';

  @override
  String get confirmedEmailAddressesDescription => 'Adresses emails confirmées connectées à votre compte :';

  @override
  String get confirmWithToken => 'Confirmer avec le Token';

  @override
  String get congrats => 'Félicitations !';

  @override
  String get connectedToYourAccount => 'Connecté à votre compte';

  @override
  String get contentSuccessfullyRemoved => 'Contenu supprimé avec succès';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get continueQuestion => 'Poursuivre ?';

  @override
  String get copyUsername => 'Copier le nom d\'utilisateur';

  @override
  String get copyMessage => 'Copier';

  @override
  String get couldNotFetchNews => 'Impossible d\'obtenir des informations';

  @override
  String get couldNotLoadAllSessions => 'Impossible de charger toutes les sessions';

  @override
  String couldNotLoadImage(Object error) {
    return 'Impossible de charger l\'image à cause de $error';
  }

  @override
  String countsMembers(Object count) {
    return '$count Membres';
  }

  @override
  String get create => 'Créer';

  @override
  String get createChat => 'Créer une session de Chat';

  @override
  String get createCode => 'Créer un code';

  @override
  String get createDefaultChat => 'Create default chat room, too';

  @override
  String defaultChatName(Object name) {
    return '$name chat';
  }

  @override
  String get createDMWhenRedeeming => 'Créer un MD lors de la requête';

  @override
  String get createEventAndBringYourCommunity => 'Créer un nouvel événement et rassembler votre communauté';

  @override
  String get createGroupChat => 'Créer un groupe de Chat';

  @override
  String get createPin => 'Créer une Épingle';

  @override
  String get createPostsAndEngageWithinSpace => 'Créer des posts utiles et engager tout le monde dans votre espace.';

  @override
  String get createProfile => 'Créer un profil';

  @override
  String get createSpace => 'Créer un Espace';

  @override
  String get createSpaceChat => 'Créer un Espace de Chat';

  @override
  String get createSubspace => 'Créer un Sous-espace';

  @override
  String get createTaskList => 'Créer une liste de tâches';

  @override
  String get createAcopy => 'Copy as new';

  @override
  String get creatingCalendarEvent => 'Création d\'un Événement au Calendrier';

  @override
  String get creatingChat => 'Création d\'un Chat';

  @override
  String get creatingCode => 'Création d\'un code';

  @override
  String creatingNewsFailed(Object error) {
    return 'Creating update failed $error';
  }

  @override
  String get creatingSpace => 'Création d\'Espace';

  @override
  String creatingSpaceFailed(Object error) {
    return 'La création d\'espace a échoué : $error';
  }

  @override
  String creatingTaskFailed(Object error) {
    return 'La création de la tâche a échoué $error';
  }

  @override
  String get custom => 'Personnaliser';

  @override
  String get customizeAppsAndTheirFeatures => 'Personnaliser les caractéristiques nécessaires pour cet espace';

  @override
  String get customPowerLevel => 'Personnaliser le Niveau d\'autorisation';

  @override
  String get dangerZone => 'Zone de danger';

  @override
  String get deactivate => 'Désactiver';

  @override
  String get deactivateAccountDescription => 'Si vous procédez :\n\n - Toutes vos données personnelles seront supprimées de votre homeserver, y compris votre nom d\'utilisateur et votre avatar \n - Toutes vos sessions seront immédiatement fermées, aucun autre appareil ne pourra continuer ses sessions \n - Vous quitterez tous les salons, chats, espaces et MDs dans lesquels vous vous trouvez \n - Vous ne pourrez pas réactiver votre compte \n - Vous ne pourrez plus vous connecter \n - Personne ne pourra réutiliser votre nom d\'utilisateur (MXID), y compris vous : ce nom d\'utilisateur restera indisponible indéfiniment \n - Vous serez retiré du serveur d\'identité si vous avez fourni des informations pouvant être trouvées par ce biais (par exemple, votre adresse électronique ou votre numéro de téléphone) \n - Toutes les données locales, y compris les clés de cryptage, seront définitivement supprimées de cet appareil \n - Vos anciens messages seront toujours visibles pour les personnes qui les ont reçus, tout comme les courriels que vous avez envoyés par le passé \n\n Vous ne pourrez pas revenir sur cette décision. Il s\'agit d\'une action permanente et irrévocable.';

  @override
  String get deactivateAccountPasswordTitle => 'Veuillez indiquer votre mot de passe d\'utilisateur pour confirmer que vous souhaitez désactiver votre compte.';

  @override
  String get deactivateAccountTitle => 'Attention : Vous êtes sur le point de désactiver définitivement votre compte';

  @override
  String deactivatingFailed(Object error) {
    return 'Échec de la désactivation : \n $error';
  }

  @override
  String get deactivatingYourAccount => 'Désactivation de votre compte';

  @override
  String get deactivationAndRemovingFailed => 'La désactivation et la suppression de toutes les données locales ont échoué';

  @override
  String get debugInfo => 'Info Débogage';

  @override
  String get debugLevel => 'Niveau débogage';

  @override
  String get decline => 'Décliner';

  @override
  String get defaultModes => 'Modes par défaut';

  @override
  String defaultNotification(Object type) {
    return 'Défaut $type';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteAttachment => 'Supprimer la pièce jointe';

  @override
  String get deleteCode => 'Supprimer le code';

  @override
  String get deleteTarget => 'Supprimer la cible';

  @override
  String get deleteNewsDraftTitle => 'Delete draft?';

  @override
  String get deleteNewsDraftText => 'Are you sure you want to delete this draft? This can’t be undone.';

  @override
  String get deleteDraftBtn => 'Delete draft';

  @override
  String get deletingPushTarget => 'Supprimer la cible de notification push';

  @override
  String deletionFailed(Object error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get denied => 'Refusé';

  @override
  String get description => 'Description';

  @override
  String get deviceId => 'Identifiant du dispositif';

  @override
  String get deviceIdDigest => 'Id de l\'appareil Digest';

  @override
  String get deviceName => 'Nom du dispositif';

  @override
  String get devicePlatformException => 'Vous ne pouvez pas utiliser DevicePlatform.device/web dans ce contexte. Mauvaise plate-forme : SettingsSection.build';

  @override
  String get displayName => 'Nom affiché';

  @override
  String get displayNameUpdateSubmitted => 'Mise à jour du nom affiché soumise';

  @override
  String directInviteUser(Object userId) {
    return 'Inviter directement $userId';
  }

  @override
  String get dms => 'MDs';

  @override
  String get doYouWantToDeleteInviteCode => 'Voulez-vous vraiment supprimer de manière irréversible le code d\'invitation ? Il ne pourra plus être utilisé par la suite.';

  @override
  String due(Object date) {
    return 'Limite : $date';
  }

  @override
  String get dueDate => 'Date limite';

  @override
  String get edit => 'Modifier';

  @override
  String get editDetails => 'Modifier les Détails';

  @override
  String get editMessage => 'Modifier le Message';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get editSpace => 'Éditer l\'Espace';

  @override
  String get edited => 'Édité';

  @override
  String get egGlobalMovement => 'eg. Mouvement global';

  @override
  String get emailAddressToAdd => 'Adresse e-mail à ajouter';

  @override
  String get emailOrPasswordSeemsNotValid => 'L\'email ou le mot de passe n\'est pas valide.';

  @override
  String get emptyEmail => 'Veuillez saisir l\'email';

  @override
  String get emptyPassword => 'Veuillez saisir le Mot de passe';

  @override
  String get emptyToken => 'Veuillez saisir le code';

  @override
  String get emptyUsername => 'Veuillez saisir le Nom d\'utilisateur';

  @override
  String get encrypted => 'Crypté';

  @override
  String get encryptedSpace => 'Espace crypté';

  @override
  String get encryptionBackupEnabled => 'Sauvegardes chiffrées activées';

  @override
  String get encryptionBackupEnabledExplainer => 'Vos clés sont stockées dans une sauvegarde cryptée sur votre serveur domestique';

  @override
  String get encryptionBackupMissing => 'Absence de sauvegardes de cryptage';

  @override
  String get encryptionBackupMissingExplainer => 'Nous recommandons d\'utiliser des sauvegardes automatiques de clés de cryptage';

  @override
  String get encryptionBackupProvideKey => 'Fournir une Clé de Récupération';

  @override
  String get encryptionBackupProvideKeyExplainer => 'Nous avons trouvé une sauvegarde automatique cryptée';

  @override
  String get encryptionBackupProvideKeyAction => 'Fournir la Clé';

  @override
  String get encryptionBackupNoBackup => 'Aucune sauvegarde cryptée n\'a été trouvée';

  @override
  String get encryptionBackupNoBackupExplainer => 'Si vous perdez l\'accès à votre compte, les conversations risquent d\'être perdues. Nous vous recommandons d\'activer les sauvegardes automatiques par cryptage.';

  @override
  String get encryptionBackupNoBackupAction => 'Activer la Sauvegarde';

  @override
  String get encryptionBackupEnabling => 'Activation de la sauvegarde';

  @override
  String encryptionBackupEnablingFailed(Object error) {
    return 'L\'activation de la sauvegarde a échoué : $error';
  }

  @override
  String get encryptionBackupRecovery => 'Votre clé de Récupération de Sauvegarde';

  @override
  String get encryptionBackupRecoveryExplainer => 'Conservez cette Clé de Récupération de Sauvegarde en lieu sûr.';

  @override
  String get encryptionBackupRecoveryCopiedToClipboard => 'Clé de Récupération copiée dans le presse-papiers';

  @override
  String get refreshing => 'Refreshing';

  @override
  String get encryptionBackupDisable => 'Désactiver la Sauvegarde des Clés ?';

  @override
  String get encryptionBackupDisableExplainer => 'La réinitialisation de la sauvegarde de la clé la détruira en local et sur votre serveur domestique. Cette opération ne peut pas être annulée. Êtes-vous sûr de vouloir continuer ?';

  @override
  String get encryptionBackupDisableActionKeepIt => 'Non, conservez-la';

  @override
  String get encryptionBackupDisableActionDestroyIt => 'Oui, détruisez-la';

  @override
  String get encryptionBackupResetting => 'Réinitialiser la Sauvegarde';

  @override
  String get encryptionBackupResettingSuccess => 'Réinitialisation réussie';

  @override
  String encryptionBackupResettingFailed(Object error) {
    return 'Échec de la désactivation : $error';
  }

  @override
  String get encryptionBackupRecover => 'Récupérer la Sauvegarde Cryptée';

  @override
  String get encryptionBackupRecoverExplainer => 'Fournir votre clé de récupération pour décrypter la sauvegarde cryptée';

  @override
  String get encryptionBackupRecoverInputHint => 'Clé de récupération';

  @override
  String get encryptionBackupRecoverProvideKey => 'Veuillez fournir la clé';

  @override
  String get encryptionBackupRecoverAction => 'Récupérer';

  @override
  String get encryptionBackupRecoverRecovering => 'Récupération';

  @override
  String get encryptionBackupRecoverRecoveringSuccess => 'Récupération réussie';

  @override
  String get encryptionBackupRecoverRecoveringImportFailed => 'Échec de l\'importation';

  @override
  String encryptionBackupRecoverRecoveringFailed(Object error) {
    return 'La récupération a échoué : $error';
  }

  @override
  String get encryptionBackupKeyBackup => 'Clé de sauvegarde';

  @override
  String get encryptionBackupKeyBackupExplainer => 'Ici, vous configurez la clé de la sauvegarde';

  @override
  String error(Object error) {
    return 'Erreur $error';
  }

  @override
  String errorCreatingCalendarEvent(Object error) {
    return 'Erreur lors de la création d\'un événement du calendrier : $error';
  }

  @override
  String errorCreatingChat(Object error) {
    return 'Erreur lors de la création d\'un chat : $error';
  }

  @override
  String errorSubmittingComment(Object error) {
    return 'Erreur lors de l\'envoi du commentaire : $error';
  }

  @override
  String errorUpdatingEvent(Object error) {
    return 'Erreur de mise à jour de l\'événement : $error';
  }

  @override
  String get eventDescriptionsData => 'Données relatives à la description des événements';

  @override
  String get eventName => 'Nom de l\'événement';

  @override
  String get events => 'Evénements';

  @override
  String get eventTitleData => 'Données sur le titre de l\'événement';

  @override
  String get experimentalActerFeatures => 'Caractéristiques de Acter expérimental';

  @override
  String failedToAcceptInvite(Object error) {
    return 'L\'invitation n\'a pas été acceptée : $error';
  }

  @override
  String failedToRejectInvite(Object error) {
    return 'Échec du rejet de l\'invitation : $error';
  }

  @override
  String get missingStoragePermissions => 'You must grant us permissions to storage to pick an Image file';

  @override
  String get file => 'Fichier';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordDescription => 'Pour réinitialiser votre mot de passe, nous vous enverrons un lien de vérification à votre adresse e-mail. Suivez la procédure et, après avoir confirmé, vous pourrez réinitialiser votre mot de passe ici.';

  @override
  String get forgotPasswordNewPasswordDescription => 'Une fois que vous avez complété le processus en suivant le lien de l\'e-mail que nous vous avons envoyé, vous pouvez définir un nouveau mot de passe ici :';

  @override
  String get formatMustBe => 'Le format doit être @user:server.tld';

  @override
  String get foundUsers => 'Trouver des Utilisateurs';

  @override
  String get from => 'de';

  @override
  String get gallery => 'Galerie';

  @override
  String get general => 'Général';

  @override
  String get getConversationGoingToStart => 'Engager la conversation pour commencer à organiser la collaboration';

  @override
  String get getInTouchWithOtherChangeMakers => 'Entrez en contact avec d\'autres acteurs du changement, organisateurs ou activistes et discutez directement avec eux.';

  @override
  String get goToDM => 'Aller au MD';

  @override
  String get going => 'Partir';

  @override
  String get haveProfile => 'Vous avez déjà un profil ?';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get helpCenterDesc => 'Get helpful tips about Acter';

  @override
  String get hereYouCanChangeTheSpaceDetails => 'Vous pouvez ici modifier les détails de l\'espace';

  @override
  String get hereYouCanSeeAllUsersYouBlocked => 'Ici, vous pouvez voir tous les utilisateurs que vous avez bloqués.';

  @override
  String get hintMessageDisplayName => 'Saisir le nom que vous voulez que les autres voient';

  @override
  String get hintMessageInviteCode => 'Entrez votre code d\'invitation';

  @override
  String get hintMessagePassword => 'Au moins 6 caractères';

  @override
  String get hintMessageUsername => 'Nom d\'utilisateur unique pour la connexion et l\'identification';

  @override
  String get homeServerName => 'Nom du serveur domestique';

  @override
  String get homeServerURL => 'URL du Serveur domestique';

  @override
  String get httpProxy => 'Proxy HTTP';

  @override
  String get image => 'Image';

  @override
  String get inConnectedSpaces => 'Dans les espaces connectés, vous pouvez vous concentrer sur des actions ou des campagnes spécifiques de vos groupes de travail et commencer à vous organiser.';

  @override
  String get info => 'Info';

  @override
  String get invalidTokenOrPassword => 'Token ou mot de passe invalide';

  @override
  String get invitationToChat => 'Invité à rejoindre le chat par ';

  @override
  String get invitationToDM => 'Veut discuter en MD avec vous';

  @override
  String get invitationToSpace => 'Invité à rejoindre l\'espace par ';

  @override
  String get invited => 'Invité';

  @override
  String get inviteCode => 'Code d\'invitation';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String shareInviteWithCode(Object code) {
    return 'Invite $code';
  }

  @override
  String get inviteCodeInfo => 'Acter est toujours accessible uniquement sur invitation. Si vous n\'avez pas reçu de code d\'invitation de la part d\'un groupe ou d\'une initiative spécifique, utilisez le code ci-dessous pour découvrir Acter.';

  @override
  String get irreversiblyDeactivateAccount => 'Désactiver ce compte de manière irréversible';

  @override
  String get itsYou => 'Ceci c\'est vous';

  @override
  String get join => 'rejoindre';

  @override
  String get joined => 'Rejoint';

  @override
  String joiningFailed(Object error) {
    return 'Joining failed: $error';
  }

  @override
  String get joinActer => 'Rejoignez Acter';

  @override
  String joinRuleNotSupportedYet(Object role) {
    return 'Règle d\'adhésion $role n\'est pas encore prise en charge. Désolé';
  }

  @override
  String kickAndBanFailed(Object error) {
    return 'La suppression et le ban des utilisateurs ont échoué : \n $error';
  }

  @override
  String get kickAndBanProgress => 'Suppression et ban d\'un utilisateur';

  @override
  String get kickAndBanSuccess => 'Utilisateur supprimé et banni';

  @override
  String get kickAndBanUser => 'Supprimer et Bannir un Utilisateur';

  @override
  String kickAndBanUserDescription(Object roomId, Object userId) {
    return 'Vous êtes sur le point de supprimer et d\'interdire définitivement $userId de $roomId';
  }

  @override
  String kickAndBanUserTitle(Object userId) {
    return 'Supprimer et Bannir un Utilisateur $userId';
  }

  @override
  String kickFailed(Object error) {
    return 'La suppression de l\'utilisateur a échoué : \n $error';
  }

  @override
  String get kickProgress => 'Supprimer un utilisateur';

  @override
  String get kickSuccess => 'Utilisateur supprimé';

  @override
  String get kickUser => 'Supprimer un Utilisateur';

  @override
  String kickUserDescription(Object roomId, Object userId) {
    return 'Vous êtes sur le point de supprimer $userId de $roomId';
  }

  @override
  String kickUserTitle(Object userId) {
    return 'Supprimer l\'Utilisateur $userId';
  }

  @override
  String get labs => 'Labos';

  @override
  String get labsAppFeatures => 'Caractéristiques de l\'application';

  @override
  String get language => 'Langue';

  @override
  String get leave => 'Quitter';

  @override
  String get leaveRoom => 'Quitter le Chat';

  @override
  String get leaveSpace => 'Quitter l\'Espace';

  @override
  String get leavingSpace => 'Quitter l\'Espace';

  @override
  String get leavingSpaceSuccessful => 'Vous avez quitté l\'Espace';

  @override
  String leavingSpaceFailed(Object error) {
    return 'Erreur de quitter l\'espace : $error';
  }

  @override
  String get leavingRoom => 'Quitter le Chat';

  @override
  String get letsGetStarted => 'Commençons';

  @override
  String get licenses => 'Licences';

  @override
  String get limitedInternConnection => 'Connexion Internet limitée';

  @override
  String get link => 'Lien';

  @override
  String get linkExistingChat => 'Lier vers le Chat existant';

  @override
  String get linkExistingSpace => 'Lier vers l\'Espace existant';

  @override
  String get links => 'Liens';

  @override
  String get loading => 'Chargement';

  @override
  String get linkToChat => 'Lien vers le Chat';

  @override
  String loadingFailed(Object error) {
    return 'Échec du chargement : $error';
  }

  @override
  String get location => 'Localisation';

  @override
  String get logIn => 'Se connecter';

  @override
  String get loginAgain => 'Se connecter à nouveau';

  @override
  String get loginContinue => 'Connectez-vous et poursuivez l\'organisation là où vous l\'avez laissée.';

  @override
  String get loginSuccess => 'Connexion réussie';

  @override
  String get logOut => 'Déconnexion';

  @override
  String get logSettings => 'Paramètres de connexion';

  @override
  String get looksGoodAddressConfirmed => 'Tout semble en ordre. Adresse confirmée.';

  @override
  String get makeADifference => 'Débloquez votre organisation numérique.';

  @override
  String get manage => 'Gérer';

  @override
  String get manageBudgetsCooperatively => 'Gérer les budgets de manière coopérative';

  @override
  String get manageYourInvitationCodes => 'Gérez vos codes d\'invitation';

  @override
  String get markToHideAllCurrentAndFutureContent => 'Marquer pour masquer tous les contenus actuels et futurs de cet utilisateur et l\'empêcher de vous contacter';

  @override
  String get markedAsDone => 'marqué comme fait';

  @override
  String get maybe => 'Peut-être';

  @override
  String get member => 'Membre';

  @override
  String get memberDescriptionsData => 'Données relatives à la description des membres';

  @override
  String get memberTitleData => 'Données relatives au titre du membre';

  @override
  String get members => 'Membres';

  @override
  String get mentionsAndKeywordsOnly => 'Mentions et mots-clés uniquement';

  @override
  String get message => 'Message';

  @override
  String get messageCopiedToClipboard => 'Message copié dans le presse-papiers';

  @override
  String get missingName => 'Veuillez saisir votre Nom';

  @override
  String get mobilePushNotifications => 'Notifications Push mobile';

  @override
  String get moderator => 'Modérateur';

  @override
  String get more => 'Plus';

  @override
  String moreRooms(Object count) {
    return '+$count additional rooms';
  }

  @override
  String get muted => 'Mise en sourdine';

  @override
  String get customValueMustBeNumber => 'You need to enter the custom value as a number.';

  @override
  String get myDashboard => 'Mon tableau de bord';

  @override
  String get name => 'Nom';

  @override
  String get nameOfTheEvent => 'Nom de l\'événement';

  @override
  String get needsAppRestartToTakeEffect => 'Il faut redémarrer l\'application pour qu\'elle prenne effet';

  @override
  String get newChat => 'Nouveau Chat';

  @override
  String get newEncryptedMessage => 'Nouveau Message Cypté';

  @override
  String get needYourPasswordToConfirm => 'Besoin de votre mot de passe pour confirmer';

  @override
  String get newMessage => 'Nouveau message';

  @override
  String get newUpdate => 'Nouvelle Mise à jour';

  @override
  String get next => 'Suivant';

  @override
  String get no => 'Non';

  @override
  String get noChatsFound => 'aucun chat trouvé';

  @override
  String get noChatsFoundMatchingYourFilter => 'Aucun chat ne correspond à vos filtres et à votre recherche';

  @override
  String get noChatsFoundMatchingYourSearchTerm => 'Aucun chat ne correspond à votre recherche';

  @override
  String get noChatsInThisSpaceYet => 'Pas de chats dans cet espace pour le moment';

  @override
  String get noChatsStillSyncing => 'Synchronisation...';

  @override
  String get noChatsStillSyncingSubtitle => 'Nous sommes en train de charger vos chats. Sur les gros comptes, le chargement initial prend un peu de temps ...';

  @override
  String get noConnectedSpaces => 'Aucun espace connecté';

  @override
  String get noDisplayName => 'pas de nom affiché';

  @override
  String get noDueDate => 'Pas de date d\'échéance';

  @override
  String get noEventsPlannedYet => 'Aucun événement n\'est prévu pour l\'instant';

  @override
  String get noIStay => 'Non, je reste';

  @override
  String get noMembersFound => 'Aucun membre n\'a été trouvé. Comment est-ce possible, vous êtes ici, n\'est-ce pas ?';

  @override
  String get noOverwrite => 'Pas d\'Écrasement';

  @override
  String get noParticipantsGoing => 'Aucun participant ne part';

  @override
  String get noPinsAvailableDescription => 'Partagez des ressources importantes avec votre communauté, telles que des documents ou des liens, afin que tout le monde soit informé.';

  @override
  String get noPinsAvailableYet => 'Aucune épingle disponible pour le moment';

  @override
  String get noProfile => 'Vous n\'avez pas encore de profil ?';

  @override
  String get noPushServerConfigured => 'Pas de serveur push configuré sur le build';

  @override
  String get noPushTargetsAddedYet => 'Aucune cible push n\'a été ajoutée pour l\'instant';

  @override
  String get noSpacesFound => 'Aucun espace n\'a été trouvé';

  @override
  String get noUsersFoundWithSpecifiedSearchTerm => 'Aucun Utilisateur n\'a été trouvé avec le terme de recherche spécifié';

  @override
  String get notEnoughPowerLevelForInvites => 'Le niveau de permission n\'est pas suffisant pour les invitations, demandez à l\'administrateur de le modifier';

  @override
  String get notFound => '404 - Not Found';

  @override
  String get notes => 'Notes';

  @override
  String get notGoing => 'Ne pas partir';

  @override
  String get noThanks => 'Non, merci';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsOverwrites => 'Notifications Écrasement';

  @override
  String get notificationsOverwritesDescription => 'Remplacer les configurations de notifications pour cet espace';

  @override
  String get notificationsSettingsAndTargets => 'Paramètres de notifications et cibles';

  @override
  String get notificationStatusSubmitted => 'Statut de la notification soumise';

  @override
  String notificationStatusUpdateFailed(Object error) {
    return 'Échec de la mise à jour du statut de la notification : $error';
  }

  @override
  String get notificationsUnmuted => 'Notifications activées';

  @override
  String get notificationTargets => 'Cibles de notification';

  @override
  String get notifyAboutSpaceUpdates => 'Notifier immédiatement les mises à jour de l\'espace';

  @override
  String get noTopicFound => 'Aucun sujet trouvé';

  @override
  String get notVisible => 'Non visible';

  @override
  String get notYetSupported => 'Pas encore pris en charge';

  @override
  String get noWorriesWeHaveGotYouCovered => 'Ne vous inquiétez pas ! Saisissez votre adresse email pour réinitialiser votre mot de passe.';

  @override
  String get ok => 'Ok';

  @override
  String get okay => 'D\'accord';

  @override
  String get on => 'sur';

  @override
  String get onboardText => 'Commençons par créer votre profil';

  @override
  String get onlySupportedIosAndAndroid => 'Uniquement sur mobile (iOS & Android) pour l\'instant';

  @override
  String get optional => 'Optionnel';

  @override
  String get or => ' ou ';

  @override
  String get overview => 'Vue d\'ensemble';

  @override
  String get parentSpace => 'Espace parent';

  @override
  String get parentSpaces => 'Espaces parent';

  @override
  String get parentSpaceMustBeSelected => 'L\'espace parents doit être sélectionné';

  @override
  String get parents => 'Parents';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordResetTitle => 'Mot de passe Réinitialisé';

  @override
  String get past => 'Passé';

  @override
  String get pending => 'En attente';

  @override
  String peopleGoing(Object count) {
    return '$count Personnes partent';
  }

  @override
  String get personalSettings => 'Paramètres personnels';

  @override
  String get pinName => 'Nom de l\'épingle';

  @override
  String get pins => 'Épingles';

  @override
  String get play => 'Jouer';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get pleaseCheckYourInbox => 'Veuillez vérifier votre boîte de réception pour l\'e-mail de validation et cliquez sur le lien avant qu\'il n\'expire';

  @override
  String get pleaseEnterAName => 'Veuillez saisir un nom';

  @override
  String get pleaseEnterATitle => 'Veuillez saisir un titre';

  @override
  String get pleaseEnterEventName => 'Veuillez saisir le nom de l\'événement';

  @override
  String get pleaseFirstSelectASpace => 'Veuillez d\'abord sélectionner un espace';

  @override
  String errorProcessingSlide(Object error, Object slideIdx) {
    return 'We couldn’t process slide $slideIdx: $error';
  }

  @override
  String get pleaseProvideEmailAddressToAdd => 'Veuillez indiquer l\'adresse email que vous souhaitez ajouter';

  @override
  String get pleaseProvideYourUserPassword => 'Veuillez indiquer votre mot de passe d\'utilisateur pour confirmer que vous souhaitez mettre fin à cette session.';

  @override
  String get pleaseSelectSpace => 'Veuillez sélectionner un espace';

  @override
  String get selectTaskList => 'Select Task List';

  @override
  String get pleaseWait => 'Veuillez patienter…';

  @override
  String get polls => 'Sondages';

  @override
  String get pollsAndSurveys => 'Sondages et Enquêtes';

  @override
  String postingOfTypeNotYetSupported(Object type) {
    return 'L\'affichage de $type n\'est pas encore pris en charge';
  }

  @override
  String get postingTaskList => 'Publication de la liste des tâches';

  @override
  String get postpone => 'Reporter';

  @override
  String postponeN(Object days) {
    return 'Reporter $days jours';
  }

  @override
  String get powerLevel => 'Niveau d\'Autorisation';

  @override
  String get powerLevelUpdateSubmitted => 'Mise à jour du Niveau d\'autorisation soumise';

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
  String get preview => 'Prévisualisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get private => 'Privé';

  @override
  String get profile => 'Profil';

  @override
  String get pushKey => 'PushKey';

  @override
  String get pushTargetDeleted => 'Cible push supprimée';

  @override
  String get pushTargetDetails => 'Détails de la cible push';

  @override
  String get pushToThisDevice => 'Push à ce dispositif';

  @override
  String get quickSelect => 'Sélection rapide :';

  @override
  String get rageShakeAppName => 'Rageshake App Name';

  @override
  String get rageShakeAppNameDigest => 'Rageshake App Name Digest';

  @override
  String get rageShakeTargetUrl => 'Rageshake Url Cible';

  @override
  String get rageShakeTargetUrlDigest => 'Rageshake Target Url Digest';

  @override
  String get reason => 'Raison';

  @override
  String get reasonHint => 'motif optionnel';

  @override
  String get reasonLabel => 'Raison';

  @override
  String redactionFailed(Object error) {
    return 'L\'envoi de la réaction a échoué en raison d\'une';
  }

  @override
  String get redeem => 'Réclamer';

  @override
  String redeemingFailed(Object error) {
    return 'L\'échange a échoué : $error';
  }

  @override
  String get register => 'Enregistrer';

  @override
  String registerFailed(Object error) {
    return 'Échec de l\'enregistrement';
  }

  @override
  String get regular => 'Régulière';

  @override
  String get remove => 'Retirer';

  @override
  String get removePin => 'Retirer l\'épingle';

  @override
  String get removeThisContent => 'Supprimer ce contenu. Cette opération ne peut être annulée. Veuillez fournir une raison facultative pour expliquer pourquoi ce contenu a été supprimé';

  @override
  String get reply => 'Répondre';

  @override
  String replyTo(Object name) {
    return 'Répondre à $name';
  }

  @override
  String get replyPreviewUnavailable => 'Pas d\'aperçu disponible pour le message auquel vous répondez';

  @override
  String get report => 'Signaler';

  @override
  String get reportThisEvent => 'Signaler cet événement';

  @override
  String get reportThisMessage => 'Signaler ce message';

  @override
  String get reportMessageContent => 'Signalez ce message à l\'administrateur de votre serveur domestique. Veuillez noter que l\'administrateur ne sera pas en mesure de lire ou de visualiser les fichiers si le chat est crypté';

  @override
  String get reportPin => 'Signaler l\'Épingle';

  @override
  String get reportThisPost => 'Signaler ce post';

  @override
  String get reportPostContent => 'Signalez ce message à l\'administrateur de votre serveur domestique. Veuillez noter que l\'administrateur ne sera pas en mesure de lire ou de voir les fichiers dans les espaces cryptés.';

  @override
  String get reportSendingFailed => 'Échec de l\'envoi du rapport';

  @override
  String get reportSent => 'Rapport envoyé !';

  @override
  String get reportThisContent => 'Signalez ce contenu à l\'administrateur de votre serveur domestique. Veuillez noter que votre administrateur ne sera pas en mesure de lire ou de visualiser les fichiers dans les espaces cryptés.';

  @override
  String get requestToJoin => 'demande pour rejoindre';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get resetPassword => 'Réinitialiser le Mot de passe';

  @override
  String get retry => 'Réessayer';

  @override
  String get roomId => 'ChatId';

  @override
  String get roomNotFound => 'Chat introuvable';

  @override
  String get roomLinkedButNotUpgraded => 'Added. However you are not able to upgrade its join rule settings and thus not all people from this space might be able to join it.';

  @override
  String get rsvp => 'RSVP';

  @override
  String repliedToMsgFailed(Object id) {
    return 'Failed to load original message id: $id';
  }

  @override
  String get sasGotIt => 'Compris';

  @override
  String sasIncomingReqNotifContent(String sender) {
    return '$sender souhaite vérifier votre session';
  }

  @override
  String get sasIncomingReqNotifTitle => 'Demande de vérification';

  @override
  String get sasVerified => 'Vérifié !';

  @override
  String get save => 'Sauvegarder';

  @override
  String get saveFileAs => 'Save file as';

  @override
  String get openFile => 'Open';

  @override
  String get shareFile => 'Share';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get savingCode => 'Code de sauvegarde';

  @override
  String get search => 'Recherche';

  @override
  String get searchTermFieldHint => 'Recherche de...';

  @override
  String get searchChats => 'Rechercher des chats';

  @override
  String searchResultFor(Object text) {
    return 'Résultat de la recherche pour $text…';
  }

  @override
  String get searchUsernameToStartDM => 'Chercher un Nom d\'utilisateur pour démarrer un MD';

  @override
  String searchingFailed(Object error) {
    return 'Échec de la recherche $error';
  }

  @override
  String get searchSpace => 'recherche d\'espace';

  @override
  String get searchSpaces => 'Recherche d\'espaces';

  @override
  String get searchPublicDirectory => 'Recherche dans l\'Annuaire Public';

  @override
  String get searchPublicDirectoryNothingFound => 'Aucune entrée n\'a été trouvée dans le répertoire public';

  @override
  String get seeOpenTasks => 'voir les tâches en cours';

  @override
  String get seenBy => 'Vu par';

  @override
  String get select => 'Sélectionner';

  @override
  String get selectAll => 'Select all';

  @override
  String get unselectAll => 'Unselect all';

  @override
  String get selectAnyRoomToSeeIt => 'Sélectionnez n\'importe quel Chat pour l\'afficher';

  @override
  String get selectDue => 'Sélectionner l\'échéance';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get selectParentSpace => 'Sélectionner l\'espace parent';

  @override
  String get send => 'Envoyer';

  @override
  String get sendingAttachment => 'Envoi de la Pièce jointe';

  @override
  String get sendingReport => 'Rapport d\'envoi';

  @override
  String get sendingEmail => 'Envoi de mail';

  @override
  String sendingEmailFailed(Object error) {
    return 'L\'envoi a échoué : $error';
  }

  @override
  String sendingRsvpFailed(Object error) {
    return 'Sending RSVP failed: $error';
  }

  @override
  String get sentAnImage => 'a envoyé une image.';

  @override
  String get server => 'Serveur';

  @override
  String get sessions => 'Sessions';

  @override
  String get sessionTokenName => 'Nom du token de session';

  @override
  String get setDebugLevel => 'Définir le niveau de débogage';

  @override
  String get setHttpProxy => 'Définir le Proxy HTTP';

  @override
  String get settings => 'Paramètres';

  @override
  String get securityAndPrivacy => 'Sécurité et vie privée';

  @override
  String get settingsKeyBackUpTitle => 'Clé de Sauvegarde';

  @override
  String get settingsKeyBackUpDesc => 'Gérer la sauvegarde de la clé';

  @override
  String get share => 'Partager';

  @override
  String get shareIcal => 'Partager iCal';

  @override
  String shareFailed(Object error) {
    return 'Échec du partage : $error';
  }

  @override
  String get sharedCalendarAndEvents => 'Calendrier et événements partagés';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get skip => 'Passer';

  @override
  String get slidePosting => 'Diffusion de diapositives';

  @override
  String slidesNotYetSupported(Object type) {
    return '$type diapositives non encore prises en charge';
  }

  @override
  String get someErrorOccurredLeavingRoom => 'Une erreur s\'est produite en quittant le Chat';

  @override
  String get space => 'Espace';

  @override
  String get spaceConfiguration => 'Configuration de l\'Espace';

  @override
  String get spaceConfigurationDescription => 'Configurer, qui peut voir et comment rejoindre cet espace';

  @override
  String get spaceName => 'Nom de l\'espace';

  @override
  String get spaceNotificationOverwrite => 'Écrasement de la notification de l\'espace';

  @override
  String get spaceNotifications => 'Notifications de l\'espace';

  @override
  String get spaceOrSpaceIdMustBeProvided => 'l\'espace ou l\'identifiant de l\'espace doit être fourni';

  @override
  String get spaces => 'Espaces';

  @override
  String get spacesAndChats => 'Espaces & Chats';

  @override
  String get spacesAndChatsToAddThemTo => 'Espaces & Chats sur lesquels les ajouter';

  @override
  String get startDM => 'Lancer un MD';

  @override
  String get state => 'statut';

  @override
  String get submit => 'Envoyer';

  @override
  String get submittingComment => 'Envoi de commentaire';

  @override
  String get suggested => 'Suggested';

  @override
  String get suggestedUsers => 'Utilisateurs suggérés';

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
  String get superInvitations => 'Codes d\'invitation';

  @override
  String get superInvites => 'Codes d\'invitation';

  @override
  String superInvitedBy(Object user) {
    return '$user vous invite';
  }

  @override
  String superInvitedTo(Object count) {
    return 'Pour rejoindre $count salle';
  }

  @override
  String superInvitesPreviewMissing(Object token) {
    return 'Votre Serveur ne prend pas en charge la prévisualisation des Codes d\'Invitation. Vous pouvez tout de même essayer de réclamer $token';
  }

  @override
  String superInvitesDeleted(Object token) {
    return 'Le code d\'invitation $token n\'est plus valide.';
  }

  @override
  String get takeAFirstStep => 'L\'application sécurisée d\'organisation qui grandit avec vos aspirations. Fournir un espace sûr pour les actions.';

  @override
  String get taskListName => 'Nom de la liste de tâche';

  @override
  String get tasks => 'Tâches';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get termsText1 => 'En cliquant sur créer un profil, vous acceptez notre';

  @override
  String theCurrentJoinRulesOfSpace(Object parentSpaceName, Object roomName) {
    return 'Les règles d\'adhésion actuelles de $roomName signifie qu\'il ne sera pas visible pour les membres de $parentSpaceName. Devons-nous mettre à jour les règles d\'adhésion pour permettre aux membres de l\'espace $parentSpaceName de voir et de joindre $roomName ?';
  }

  @override
  String get theParentSpace => 'l\'espace parent';

  @override
  String get thereIsNothingScheduledYet => 'Rien n\'est encore programmé';

  @override
  String get theSelectedRooms => 'les chats sélectionnés';

  @override
  String get theyWontBeAbleToJoinAgain => 'Ils ne pourront plus s\'inscrire à nouveau';

  @override
  String get thirdParty => 'tierce Partie';

  @override
  String get thisApaceIsEndToEndEncrypted => 'Cet espace est crypté de bout en bout';

  @override
  String get thisApaceIsNotEndToEndEncrypted => 'Cet espace n\'est pas crypté de bout en bout';

  @override
  String get thisIsAMultilineDescription => 'Il s\'agit d\'une description de la tâche sur plusieurs lignes, avec des textes longs et d\'autres éléments';

  @override
  String get thisIsNotAProperActerSpace => 'Il ne s\'agit pas d\'un vrai espace acter. Certaines fonctionnalités peuvent ne pas être disponibles.';

  @override
  String get thisMessageHasBeenDeleted => 'Ce message a été supprimé';

  @override
  String get thisWillAllowThemToContactYouAgain => 'Ceci leur permettra de vous recontacter';

  @override
  String get title => 'Titre';

  @override
  String get titleTheNewTask => 'Titre de la nouvelle tâche...';

  @override
  String typingUser1(Object user) {
    return '$user est en train d\'écrire...';
  }

  @override
  String typingUser2(Object user1, Object user2) {
    return '$user1 et $user2 sont en train de taper...';
  }

  @override
  String typingUserN(Object user, Object userCount) {
    return '$user et $userCount d\'autres sont en train d\'écrire';
  }

  @override
  String get to => 'pour';

  @override
  String get toAccess => 'to access';

  @override
  String get needToBeMemberOf => 'you need to be member of';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get token => 'token';

  @override
  String get tokenAndPasswordMustBeProvided => 'Le Token et le mot de passe doivent être fournis';

  @override
  String get tomorrow => 'Demain';

  @override
  String get topic => 'Sujet';

  @override
  String get tryingToConfirmToken => 'Tentative de confirmation du token';

  @override
  String tryingToJoin(Object name) {
    return 'Tentative de joindre $name';
  }

  @override
  String get tryToJoin => 'Tenter de rejoindre';

  @override
  String get typeName => 'Saisir Nom';

  @override
  String get unblock => 'Débloquer';

  @override
  String get unblockingUser => 'Déblocage de l\'Utilisateur';

  @override
  String unblockingUserFailed(Object error) {
    return 'Échec du Déblocage de l\'Utilisateur : $error';
  }

  @override
  String get unblockingUserProgress => 'Déblocage d\'Utilisateur';

  @override
  String get unblockingUserSuccess => 'Utilisateur débloqué. Il faudra peut-être attendre un peu avant que l\'interface utilisateur ne tienne compte de cette mise à jour.';

  @override
  String unblockTitle(Object userId) {
    return 'Débloquer $userId';
  }

  @override
  String get unblockUser => 'Débloquer Utilisateur';

  @override
  String unclearJoinRule(Object rule) {
    return 'Règle d\'adhésion pas claire $rule';
  }

  @override
  String get unreadMarkerFeatureTitle => 'Marqueurs non lus';

  @override
  String get unreadMarkerFeatureDescription => 'Suivre et afficher les chats qui ont été lus';

  @override
  String get undefined => 'indéfini';

  @override
  String get unknown => 'inconnue';

  @override
  String get unknownRoom => 'Chat inconnu';

  @override
  String get unlink => 'Détacher';

  @override
  String get unmute => 'Démuter';

  @override
  String get unset => 'non paramétré';

  @override
  String get unsupportedPleaseUpgrade => 'Non supporté - Veuillez mettre à jour !';

  @override
  String get unverified => 'Non vérifié';

  @override
  String get unverifiedSessions => 'Sessions non vérifiées';

  @override
  String get unverifiedSessionsDescription => 'Certains appareils connectés à votre compte ne sont pas vérifiés. Cela peut constituer un risque pour la sécurité. Veuillez vous assurer que tout est en ordre.';

  @override
  String unverifiedSessionsCount(int count) {
    return 'There are $count unverified sessions logged in';
  }

  @override
  String get upcoming => 'À venir';

  @override
  String get updatePowerLevel => 'Mettre à jour le niveau de Permission';

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
  String get updatingDisplayName => 'Mise à jour du nom affiché';

  @override
  String get updatingDue => 'Mettre à jour la date d\'échéance';

  @override
  String get updatingEvent => 'Mise à jour de l\'Événement';

  @override
  String updatingPowerLevelOf(Object userId) {
    return 'Mise à jour du    niveau de permission de $userId';
  }

  @override
  String get updatingProfileImage => 'Mise à jour de la photo de profil';

  @override
  String get updatingRSVP => 'Mise à jour de RSVP';

  @override
  String get updatingSpace => 'Mettre à jour l\'Espace';

  @override
  String get uploadAvatar => 'Charger un Avatar';

  @override
  String usedTimes(Object count) {
    return 'Utilisé $count fois';
  }

  @override
  String userAddedToBlockList(Object user) {
    return '$user ajouté à la liste de blocage. La mise à jour de l\'interface utilisateur pourrait prendre un peu de temps';
  }

  @override
  String get users => 'Users';

  @override
  String get usersfoundDirectory => 'Utilisateurs trouvés dans le répertoire public';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get usernameCopiedToClipboard => 'Nom d\'utilisateur copié dans le presse-papiers';

  @override
  String get userRemovedFromList => 'Utilisateur supprimé de la liste. La mise à jour de l\'interface utilisateur peut prendre un peu de temps';

  @override
  String get usersYouBlocked => 'Utilisateurs que vous avez bloqués';

  @override
  String get validEmail => 'Veuillez saisir un e-mail valide';

  @override
  String get verificationConclusionCompromised => 'L\'un des éléments suivants peut être compromis :\n\n   - Votre serveur domestique\n   - Le serveur domestique auquel l\'utilisateur que vous vérifiez est connecté\n   - Votre connexion internet ou celle des autres utilisateurs\n   - Votre appareil ou celui des autres utilisateurs';

  @override
  String verificationConclusionOkDone(String sender) {
    return 'Vous avez vérifié avec succès l\'identité de $sender !';
  }

  @override
  String get verificationConclusionOkSelfNotice => 'Votre nouvelle session est désormais vérifiée. Elle a accès à vos messages cryptés et les autres utilisateurs la verront comme fiable.';

  @override
  String get verificationEmojiNotice => 'Comparez les emoji uniques en veillant à ce qu\'ils apparaissent dans le même ordre.';

  @override
  String get verificationRequestAccept => 'Pour continuer, veuillez accepter la demande de vérification sur votre autre appareil.';

  @override
  String verificationRequestWaitingFor(String sender) {
    return 'En attente de $sender…';
  }

  @override
  String get verificationSasDoNotMatch => 'Ils ne correspondent pas';

  @override
  String get verificationSasMatch => 'Ils correspondent';

  @override
  String get verificationScanEmojiTitle => 'Impossible de scanner';

  @override
  String get verificationScanSelfEmojiSubtitle => 'Vérifier en comparant les emoji';

  @override
  String get verificationScanSelfNotice => 'Scannez le code avec votre autre appareil ou changez d\'appareil et scannez avec celui-ci';

  @override
  String get verified => 'Vérifié';

  @override
  String get verifiedSessionsDescription => 'Tous vos appareils sont vérifiés. Votre compte est sécurisé.';

  @override
  String get verifyOtherSession => 'Vérifier les autres sessions';

  @override
  String get verifySession => 'Vérifier la session';

  @override
  String get verifyThisSession => 'Vérifier cette session';

  @override
  String get version => 'Version';

  @override
  String get via => 'via';

  @override
  String get video => 'Vidéo';

  @override
  String get welcomeBack => 'Bienvenue à nouveau';

  @override
  String get welcomeTo => 'Bienvenue à ';

  @override
  String get whatToCallThisChat => 'Comment appeler ce chat ?';

  @override
  String get yes => 'Oui';

  @override
  String get yesLeave => 'Oui, Quitter';

  @override
  String get yesPleaseUpdate => 'Oui, veuillez mettre à jour';

  @override
  String get youAreAbleToJoinThisRoom => 'Vous pouvez participer à ce Chat';

  @override
  String youAreAboutToBlock(Object userId) {
    return 'Vous êtes sur le point de bloquer $userId';
  }

  @override
  String youAreAboutToUnblock(Object userId) {
    return 'Vous êtes sur le point de débloquer $userId';
  }

  @override
  String get youAreBothIn => 'you are both in ';

  @override
  String get youAreCurrentlyNotConnectedToAnySpaces => 'Vous n\'êtes actuellement connecté à aucun espaces';

  @override
  String get spaceShortDescription => 'un espace, pour commencer à organiser et à collaborer !';

  @override
  String get youAreDoneWithAllYourTasks => 'vous avez terminé toutes vos tâches !';

  @override
  String get youAreNotAMemberOfAnySpaceYet => 'Vous n\'êtes pas encore membre d\'aucun espace';

  @override
  String get youAreNotPartOfThisGroup => 'Vous ne faites pas partie de ce groupe. Souhaitez-vous le rejoindre ?';

  @override
  String get youHaveNoDMsAtTheMoment => 'Vous n\'avez pas de MDs pour le moment';

  @override
  String get youHaveNoUpdates => 'Vous n\'avez pas de mises à jour';

  @override
  String get youHaveNotCreatedInviteCodes => 'Vous n\'avez pas encore créé de codes d\'invitation';

  @override
  String get youMustSelectSpace => 'Vous devez sélectionner un espace';

  @override
  String get youNeedBeInvitedToJoinThisRoom => 'Vous devez être invité pour participer à ce Chat';

  @override
  String get youNeedToEnterAComment => 'Vous devez saisir un commentaire';

  @override
  String get youNeedToEnterCustomValueAsNumber => 'Vous devez saisir la valeur personnalisée sous la forme d\'un nombre.';

  @override
  String youCantExceedPowerLevel(Object powerLevel) {
    return 'Vous ne pouvez pas dépasser un niveau d\'autorisation de $powerLevel';
  }

  @override
  String get yourActiveDevices => 'Vos appareils actifs';

  @override
  String get yourPassword => 'Votre Mot de passe';

  @override
  String get yourSessionHasBeenTerminatedByServer => 'Votre session a été interrompue par le serveur, vous devez vous reconnecter';

  @override
  String get yourTextSlidesMustContainsSomeText => 'Vos diapositives doivent contenir du texte';

  @override
  String get yourSafeAndSecureSpace => 'Votre espace sûr et sécurisé pour organiser le changement.';

  @override
  String adding(Object email) {
    return 'ajout $email';
  }

  @override
  String get addTextSlide => 'Ajouter une diapositive textuelle';

  @override
  String get addImageSlide => 'Ajouter une diapositive d\'image';

  @override
  String get addVideoSlide => 'Ajouter une diapositive vidéo';

  @override
  String get acter => 'Acter';

  @override
  String get acterApp => 'Application Acter';

  @override
  String get activate => 'Activate';

  @override
  String get changingNotificationMode => 'Changement du mode de notification…';

  @override
  String get createComment => 'Créer un Commentaire';

  @override
  String get createNewPin => 'Créer une nouvelle Épingle';

  @override
  String get createNewSpace => 'Créer un Nouvel Espace';

  @override
  String get createNewTaskList => 'Créer une nouvelle liste de tâches';

  @override
  String get creatingPin => 'Création d\'une épingle…';

  @override
  String get deactivateAccount => 'Désactiver le Compte';

  @override
  String get deletingCode => 'Suppression du code';

  @override
  String get dueToday => 'Échéance aujourd\'hui';

  @override
  String get dueTomorrow => 'Échéance demain';

  @override
  String get dueSuccess => 'Échéance modifiée avec succès';

  @override
  String get endDate => 'Date de fin';

  @override
  String get endTime => 'Heure de fin';

  @override
  String get emailAddress => 'Adresse e-mail';

  @override
  String get emailAddresses => 'Adresses e-mail';

  @override
  String get errorParsinLink => 'Parsing Link failed';

  @override
  String errorCreatingPin(Object error) {
    return 'Une erreur s\'est produite lors de la création de l\'épingle $error';
  }

  @override
  String errorLoadingAttachments(Object error) {
    return 'Erreur de chargement des pièces jointes : $error';
  }

  @override
  String errorLoadingAvatar(Object error) {
    return 'Erreur de chargement de l\'avatar : $error';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'Erreur de chargement du profil : $error';
  }

  @override
  String errorLoadingUsers(Object error) {
    return 'Erreur de chargement des utilisateurs : $error';
  }

  @override
  String errorLoadingTasks(Object error) {
    return 'Erreur de chargement des tâches : $error';
  }

  @override
  String errorLoadingSpace(Object error) {
    return 'Erreur de chargement de l\'espace : $error';
  }

  @override
  String errorLoadingRelatedChats(Object error) {
    return 'Erreur de chargement des chats liés : $error';
  }

  @override
  String errorLoadingPin(Object error) {
    return 'Erreur de chargement de l\'épingle : $error';
  }

  @override
  String errorLoadingEventDueTo(Object error) {
    return 'Erreur de chargement de l\'événement due à : $error';
  }

  @override
  String errorLoadingImage(Object error) {
    return 'Erreur de chargement de l\'image : $error';
  }

  @override
  String errorLoadingRsvpStatus(Object error) {
    return 'Erreur de chargement du statut rsvp : $error';
  }

  @override
  String errorLoadingEmailAddresses(Object error) {
    return 'Erreur de chargement des adresses email : $error';
  }

  @override
  String errorLoadingMembersCount(Object error) {
    return 'Erreur de chargement du nombre de membres : $error';
  }

  @override
  String errorLoadingTileDueTo(Object error) {
    return 'Erreur de chargement de la tuile due à : $error';
  }

  @override
  String errorLoadingMember(Object error, Object memberId) {
    return 'Erreur de chargement du membre : $memberId $error';
  }

  @override
  String errorSendingAttachment(Object error) {
    return 'Erreur dans l\'envoi de la pièce jointe : $error';
  }

  @override
  String get eventCreate => 'Créer un événement';

  @override
  String get eventEdit => 'Modifier événement';

  @override
  String get eventRemove => 'Supprimer événement';

  @override
  String get eventReport => 'Reporter événement';

  @override
  String get eventUpdate => 'Mettre à jour événement';

  @override
  String get eventShare => 'Partager événement';

  @override
  String failedToAdd(Object error, Object something) {
    return 'Échec de l\'ajout : $error';
  }

  @override
  String failedToChangePin(Object error) {
    return 'Failed to change pin: $error';
  }

  @override
  String failedToChangePowerLevel(Object error) {
    return 'Échec de la modification du niveau de permission : $error';
  }

  @override
  String failedToChangeNotificationMode(Object error) {
    return 'Échec de la modification du mode de notification : $error';
  }

  @override
  String failedToChangePushNotificationSettings(Object error) {
    return 'Échec de la modification des paramètres de notification push : $error';
  }

  @override
  String failedToToggleSettingOf(Object error, Object module) {
    return 'Échec du changement de réglage de $module : $error';
  }

  @override
  String failedToEditSpace(Object error) {
    return 'Échec de modifier l\'espace : $error';
  }

  @override
  String failedToAssignSelf(Object error) {
    return 'Échec de l\'assignation de soi : $error';
  }

  @override
  String failedToUnassignSelf(Object error) {
    return 'Échec de la désaffectation de soi : $error';
  }

  @override
  String failedToSend(Object error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String failedToCreateChat(Object error) {
    return 'Échec de création d\'un chat :  $error';
  }

  @override
  String failedToCreateTaskList(Object error) {
    return 'Échec de la création d\'une liste de tâches :  $error';
  }

  @override
  String failedToConfirmToken(Object error) {
    return 'Échec de confirmation du token : $error';
  }

  @override
  String failedToSubmitEmail(Object error) {
    return 'Échec de l\'envoi de l\'e-mail : $error';
  }

  @override
  String get failedToDecryptMessage => 'Le message n\'a pas été décrypté. Demander à nouveau les clés de session';

  @override
  String failedToDeleteAttachment(Object error) {
    return 'Échec de la suppression de la pièce jointe en raison de : $error';
  }

  @override
  String get failedToDetectMimeType => 'Échec de la détection du mime type';

  @override
  String failedToLeaveRoom(Object error) {
    return 'Échec de quitter le Chat : $error';
  }

  @override
  String failedToLoadSpace(Object error) {
    return 'Échec du chargement de l\'espace : $error';
  }

  @override
  String failedToLoadEvent(Object error) {
    return 'Échec du chargement de l\'événement : $error';
  }

  @override
  String failedToLoadInviteCodes(Object error) {
    return 'Échec du chargement des codes d\'invitation : $error';
  }

  @override
  String failedToLoadPushTargets(Object error) {
    return 'Échec du chargement des cibles push : $error';
  }

  @override
  String failedToLoadEventsDueTo(Object error) {
    return 'Échec du chargement des événements en raison de : $error';
  }

  @override
  String failedToLoadChatsDueTo(Object error) {
    return 'Échec du chargement des chats en raison de : $error';
  }

  @override
  String failedToShareRoom(Object error) {
    return 'Échec du partage de ce Chat : $error';
  }

  @override
  String get forgotYourPassword => 'Mot de passe oublié ?';

  @override
  String get editInviteCode => 'Modifier le Code d\'Invitation';

  @override
  String get createInviteCode => 'Créer un Code d\'Invitation';

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
    return 'L\'enregistrement du code a échoué : $error';
  }

  @override
  String createInviteCodeFailed(Object error) {
    return 'La création du code a échoué : $error';
  }

  @override
  String deleteInviteCodeFailed(Object error) {
    return 'La suppression du code a échoué : $error';
  }

  @override
  String get loadingChat => 'Chargement du chat…';

  @override
  String get loadingCommentsList => 'Chargement de la liste des commentaires';

  @override
  String get loadingPin => 'Chargement de l\'épingle';

  @override
  String get loadingRoom => 'Chargement du Chat';

  @override
  String get loadingRsvpStatus => 'Chargement du statut rsvp';

  @override
  String get loadingTargets => 'Chargement des cibles';

  @override
  String get loadingOtherChats => 'Chargement d\'autres chats';

  @override
  String get loadingFirstSync => 'Chargement de la première synchronisation';

  @override
  String get loadingImage => 'Chargement de l\'image';

  @override
  String get loadingVideo => 'Chargement de la vidéo';

  @override
  String loadingEventsFailed(Object error) {
    return 'Le chargement des événements a échoué : $error';
  }

  @override
  String loadingTasksFailed(Object error) {
    return 'Le chargement des tâches a échoué : $error';
  }

  @override
  String loadingSpacesFailed(Object error) {
    return 'Échec du chargement des espaces : $error';
  }

  @override
  String loadingRoomFailed(Object error) {
    return 'Le chargement du Chat a échoué : $error';
  }

  @override
  String loadingMembersCountFailed(Object error) {
    return 'Le chargement du nombre de membres a échoué : $error';
  }

  @override
  String get longPressToActivate => 'appuyer longuement pour activer';

  @override
  String get pinCreatedSuccessfully => 'Épingle créée avec succès';

  @override
  String get pleaseSelectValidEndTime => 'Veuillez choisir une heure de fin valide';

  @override
  String get pleaseSelectValidEndDate => 'Veuillez sélectionner une date de fin valide';

  @override
  String powerLevelSubmitted(Object module) {
    return 'Mise à jour du niveau de permission pour $module soumise';
  }

  @override
  String get optionalParentSpace => 'Espace Parent optionnel';

  @override
  String redeeming(Object token) {
    return 'Réclamer $token';
  }

  @override
  String get encryptedDMChat => 'Chat MD crypté';

  @override
  String get encryptedChatMessage => 'Message crypté verrouillé. Tapez pour en savoir plus';

  @override
  String get encryptedChatMessageInfoTitle => 'Message verrouillé';

  @override
  String get encryptedChatMessageInfo => 'Les messages de chat sont cryptés de bout en bout. Cela signifie que seuls les appareils connectés au moment de l\'envoi du message peuvent le décrypter. Si vous vous êtes inscrit plus tard, si vous venez de vous connecter ou si vous avez utilisé un nouvel appareil, vous n\'avez pas les clés pour décrypter ce message. Vous pouvez les obtenir en vérifiant cette session avec un autre appareil de votre compte, en fournissant une clé de cryptage de secours ou en vérifiant avec un autre utilisateur qui a accès à la clé.';

  @override
  String get chatMessageDeleted => 'Message supprimé';

  @override
  String chatJoinedDisplayName(Object name) {
    return '$name a rejoint';
  }

  @override
  String chatJoinedUserId(Object userId) {
    return '$userId a rejoint';
  }

  @override
  String get chatYouJoined => 'Vous avez rejoint';

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
  String get chatYouAcceptedInvite => 'Vous avez accepté l\'invitation';

  @override
  String chatYouInvited(Object name) {
    return 'Vous avez invité';
  }

  @override
  String chatInvitedDisplayName(Object invitee, Object name) {
    return '$name a invité';
  }

  @override
  String chatInvitedUserId(Object inviteeId, Object userId) {
    return '$userId a invité';
  }

  @override
  String chatInvitationAcceptedDisplayName(Object name) {
    return '$name a accepté l\'invitation';
  }

  @override
  String chatInvitationAcceptedUserId(Object userId) {
    return '$userId a accepté l\'invitation';
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
  String get dmChat => 'Chat en MD';

  @override
  String get regularSpaceOrChat => 'Espace régulier ou Chat';

  @override
  String get encryptedSpaceOrChat => 'Espace chiffré ou Chat';

  @override
  String get encryptedChatInfo => 'Tous les messages de ce chat sont cryptés de bout en bout. Personne en dehors de ce chat, pas même Acter ou un Serveur Matrix transmettant le message, ne peut les lire.';

  @override
  String get removeThisPin => 'Retirer cette Épingle';

  @override
  String get removeThisPost => 'Supprimer ce post';

  @override
  String get removingContent => 'Suppression de contenu';

  @override
  String get removingAttachment => 'Retrait de la pièce jointe';

  @override
  String get reportThis => 'Signaler ça';

  @override
  String get reportThisPin => 'Signaler cette Épingle';

  @override
  String reportSendingFailedDueTo(Object error) {
    return 'L\'envoi du rapport a échoué en raison d\'une : $error';
  }

  @override
  String get resettingPassword => 'Réinitialisation du mot de passe';

  @override
  String resettingPasswordFailed(Object error) {
    return 'Échec de la réinitialisation : $error';
  }

  @override
  String get resettingPasswordSuccessful => 'Le mot de passe a été réinitialisé avec succès.';

  @override
  String get sharedSuccessfully => 'Partagé avec succès';

  @override
  String get changedPushNotificationSettingsSuccessfully => 'Modification réussie des paramètres de notification push';

  @override
  String get startDateRequired => 'Date de début requise !';

  @override
  String get startTimeRequired => 'Heure de début requise !';

  @override
  String get endDateRequired => 'Date de fin requise !';

  @override
  String get endTimeRequired => 'Heure de fin requise !';

  @override
  String get searchUser => 'Rechercher utilisateur';

  @override
  String seeAllMyEvents(Object count) {
    return 'Voir tous mes $count événements';
  }

  @override
  String get selectSpace => 'Sélectionner Espace';

  @override
  String get selectChat => 'Sélectionner Chat';

  @override
  String get selectCustomDate => 'Sélectionner une date spécifique';

  @override
  String get selectPicture => 'Sélectionner Image';

  @override
  String get selectVideo => 'Sélectionner Vidéo';

  @override
  String get selectDate => 'Sélectionner une date';

  @override
  String get selectTime => 'Sélectionner l\'heure';

  @override
  String get sendDM => 'Envoyer un MD';

  @override
  String get showMore => 'Voir plus';

  @override
  String get showLess => 'Voir moins';

  @override
  String get joinSpace => 'Rejoindre l\'Espace';

  @override
  String get joinExistingSpace => 'Rejoindre un Espace Existant';

  @override
  String get mySpaces => 'Mes Espaces';

  @override
  String get startDate => 'Date de début';

  @override
  String get startTime => 'Heure de début';

  @override
  String get startGroupDM => 'Création d\'un groupe MD';

  @override
  String get moreSubspaces => 'Plus de Sous-espaces';

  @override
  String get myTasks => 'Mes Tâches';

  @override
  String updatingDueFailed(Object error) {
    return 'La mise à jour a échoué : $error';
  }

  @override
  String get unlinkRoom => 'Délier le Chat';

  @override
  String changeThePowerFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'de $memberStatus $currentPowerLevel à';
  }

  @override
  String get createOrJoinSpaceDescription => 'Créez ou rejoignez un espace, pour commencer à organiser et à collaborer !';

  @override
  String get introPageDescriptionPre => 'Acter is more than just an app.\nIt’s';

  @override
  String get isLinked => 'is linked in here';

  @override
  String get canLink => 'You can link this';

  @override
  String get canLinkButNotUpgrade => 'You can link this, but not update its join permissions';

  @override
  String get introPageDescriptionHl => ' community of change makers.';

  @override
  String get introPageDescriptionPost => ' ';

  @override
  String get introPageDescription2ndLine => 'Connect with fellow activists, share insights, and collaborate on creating meaningful change.';

  @override
  String get logOutConformationDescription1 => 'Attention : ';

  @override
  String get logOutConformationDescription2 => 'La déconnexion supprime les données locales, y compris les clés de cryptage. S\'il s\'agit de votre dernier appareil connecté, il se peut que vous ne puissiez pas décrypter le contenu précédent.';

  @override
  String get logOutConformationDescription3 => ' Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String membersCount(Object count) {
    return '$count Membres';
  }

  @override
  String get renderSyncingTitle => 'Synchronisation avec votre serveur domestique';

  @override
  String get renderSyncingSubTitle => 'Cela peut prendre un certain temps si vous avez un gros compte';

  @override
  String errorSyncing(Object error) {
    return 'Erreur de synchronisation : $error';
  }

  @override
  String get retrying => 'nouvelle tentative …';

  @override
  String retryIn(Object minutes, Object seconds) {
    return 'Nouvelle tentative dans un délai de $minutes : $seconds';
  }

  @override
  String get invitations => 'Invitations';

  @override
  String invitingLoading(Object userId) {
    return 'Inviter $userId';
  }

  @override
  String invitingError(Object error, Object userId) {
    return 'L\'utilisateur $userId n\'a pas été trouvé ou n\'existe pas : $error';
  }

  @override
  String get invite => 'Inviter';

  @override
  String errorUnverifiedSessions(Object error) {
    return 'Impossible de charger les sessions non vérifiées : $error';
  }

  @override
  String unverifiedSessionsTitle(Object count) {
    return 'Il y a $count sessions non vérifiées connectées';
  }

  @override
  String get review => 'Revue';

  @override
  String get activities => 'Activités';

  @override
  String get activitiesDescription => 'Toutes les informations importantes qui requièrent votre attention se trouvent ici';

  @override
  String get noActivityTitle => 'Pas encore d\'activité pour vous';

  @override
  String get noActivitySubtitle => 'Vous informe des choses importantes telles que les messages, les invitations ou les demandes.';

  @override
  String get joining => 'Rejoindre';

  @override
  String get joinedDelayed => 'Invitation acceptée, la confirmation prend du temps';

  @override
  String get rejecting => 'Rejet';

  @override
  String get rejected => 'Rejeté';

  @override
  String get failedToReject => 'Échec de rejet';

  @override
  String reportedBugSuccessful(Object issueId) {
    return 'Le bug a été signalé avec succès ! (#$issueId)';
  }

  @override
  String get thanksForReport => 'Merci d\'avoir signalé ce bogue !';

  @override
  String bugReportingError(Object error) {
    return 'Erreur dans le signalement du bug : $error';
  }

  @override
  String get bugReportTitle => 'Signaler un problème';

  @override
  String get bugReportDescription => 'Brève description du problème';

  @override
  String get emptyDescription => 'Veuillez saisir la description';

  @override
  String get includeUserId => 'Inclure mon ID Matrix';

  @override
  String get includeLog => 'Inclure les logs actuels';

  @override
  String get includePrevLog => 'Inclure les logs de l\'exécution précédente';

  @override
  String get includeScreenshot => 'Inclure une capture d\'écran';

  @override
  String get includeErrorAndStackTrace => 'Include Error & Stacktrace';

  @override
  String get jumpTo => 'Aller à';

  @override
  String get noMatchingPinsFound => 'aucune épingle correspondante n\'a été trouvée';

  @override
  String get update => 'Mise à jour';

  @override
  String get event => 'Événement';

  @override
  String get taskList => 'Liste des tâches';

  @override
  String get pin => 'Épingle';

  @override
  String get poll => 'Sondage';

  @override
  String get discussion => 'Discussion';

  @override
  String get fatalError => 'Erreur fatale';

  @override
  String get nukeLocalData => 'Effacer les données locales';

  @override
  String get reportBug => 'Signaler un bug';

  @override
  String get somethingWrong => 'Quelque chose a terriblement mal tourné :';

  @override
  String get copyToClipboard => 'Copier dans le presse-papiers';

  @override
  String get errorCopiedToClipboard => 'Erreur et Trace d\'appels copiés dans le presse-papiers';

  @override
  String get showStacktrace => 'Afficher la Trace d\'appels';

  @override
  String get hideStacktrace => 'Masquer la trace d\'appels';

  @override
  String get sharingRoom => 'Partager ce Chat…';

  @override
  String get changingSettings => 'Modification des paramètres…';

  @override
  String changingSettingOf(Object module) {
    return 'Modification du réglage de $module';
  }

  @override
  String changedSettingOf(Object module) {
    return 'Paramètres modifiés du $module';
  }

  @override
  String changingPowerLevelOf(Object module) {
    return 'Modifier le niveau d\'autorisation de $module';
  }

  @override
  String get assigningSelf => 'Assigner à soi-même…';

  @override
  String get unassigningSelf => 'Se désassigner…';

  @override
  String get homeTabTutorialTitle => 'Tableau de bord';

  @override
  String get homeTabTutorialDescription => 'Vous trouverez ici vos espaces et un aperçu de tous les événements à venir et des tâches en cours pour ces espaces.';

  @override
  String get updatesTabTutorialTitle => 'Mises à jour';

  @override
  String get updatesTabTutorialDescription => 'Flux d\'informations sur les dernières mises à jour et les appels à l\'action de vos espaces.';

  @override
  String get chatsTabTutorialTitle => 'Chats';

  @override
  String get chatsTabTutorialDescription => 'C\'est l\'endroit où l\'on discute - avec des groupes ou des individus. Les discussions peuvent être reliées à d\'autres espaces pour une collaboration plus large.';

  @override
  String get activityTabTutorialTitle => 'Activité';

  @override
  String get activityTabTutorialDescription => 'Les informations importantes de vos espaces, comme les invitations ou les demandes. En outre, Acter vous informera des problèmes de sécurité';

  @override
  String get jumpToTabTutorialTitle => 'Aller à';

  @override
  String get jumpToTabTutorialDescription => 'Votre recherche sur les espaces et les épingles, ainsi que des actions rapides et un accès rapide à plusieurs sections';

  @override
  String get createSpaceTutorialTitle => 'Créer un Nouvel Espace';

  @override
  String get createSpaceTutorialDescription => 'Rejoignez un espace existant sur notre serveur Acter ou dans l\'univers Matrix ou créez votre propre espace.';

  @override
  String get joinSpaceTutorialTitle => 'Rejoindre un Espace Existant';

  @override
  String get joinSpaceTutorialDescription => 'Rejoignez un espace existant sur notre serveur Acter ou dans l\'univers de Matrix ou créez votre propre espace. [montrer les options et s\'arrêter là pour l\'instant]';

  @override
  String get spaceOverviewTutorialTitle => 'Détails de l\'espace';

  @override
  String get spaceOverviewTutorialDescription => 'Un espace est le point de départ de votre organisation. Créez des épingles (ressources), des tâches et des événements et naviguez dedans. Ajoutez des chats ou des sous-espaces.';

  @override
  String get subscribedToParentMsg => 'Disable Notifications on main object to configure notification here';

  @override
  String get parentSubscribedAction => 'Notifications active through object';

  @override
  String get subscribeAction => 'Activate Notifications';

  @override
  String get unsubscribeAction => 'De-Activate Notifications';

  @override
  String get commentEmptyStateTitle => 'Aucun commentaire trouvé.';

  @override
  String get commentEmptyStateAction => 'Laisser le premier commentaire';

  @override
  String get previous => 'Précédent';

  @override
  String get finish => 'Terminer';

  @override
  String get saveUsernameTitle => 'Avez-vous sauvegardé votre nom d\'utilisateur ?';

  @override
  String get saveUsernameDescription1 => 'Pensez à noter votre nom d\'utilisateur. C\'est votre clé d\'accès à votre profil et à toutes les informations et espaces qui y sont liés.';

  @override
  String get saveUsernameDescription2 => 'Votre nom d\'utilisateur est essentiel pour la réinitialisation du mots de passe.';

  @override
  String get saveUsernameDescription3 => 'Sans cela, l\'accès à votre profil et à vos progrès sera définitivement perdu.';

  @override
  String get acterUsername => 'Votre nom d\'utilisateur Acter';

  @override
  String get autoSubscribeFeatureDesc => 'upon creation or interaction with objects';

  @override
  String get autoSubscribeSettingsTitle => 'Automatically subscribe ';

  @override
  String get copyToClip => 'Copier dans le presse-papiers';

  @override
  String get wizzardContinue => 'Continuer';

  @override
  String get protectPrivacyTitle => 'Protéger votre vie privée';

  @override
  String get protectPrivacyDescription1 => 'Sur Acter, il est important que votre compte soit sécurisé. C\'est pourquoi vous pouvez l\'utiliser sans lier votre profil à votre e-mail pour plus de confidentialité et de protection.';

  @override
  String get protectPrivacyDescription2 => 'Mais si vous préférez, vous pouvez toujours les relier entre eux, par exemple pour la récupération d\'un mot de passe.';

  @override
  String get linkEmailToProfile => 'Lien entre l\'E-mail et le Profil';

  @override
  String get emailOptional => 'Email (optionnel)';

  @override
  String get hintEmail => 'Saisissez votre adresse e-mail';

  @override
  String get linkingEmailAddress => 'Relier votre adresse e-mail';

  @override
  String get avatarAddTitle => 'Ajouter un Avatar d\'Utilisateur';

  @override
  String get avatarEmpty => 'Veuillez sélectionner votre avatar';

  @override
  String get avatarUploading => 'Téléversement de l\'avatar du profil';

  @override
  String avatarUploadFailed(Object error) {
    return 'Échec du téléchargement de l\'avatar de l\'utilisateur : $error';
  }

  @override
  String get sendEmail => 'Envoyer un e-mail';

  @override
  String get inviteCopiedToClipboard => 'Code d\'invitation copié dans le presse-papiers';

  @override
  String get updateName => 'Mettre à jour le nom';

  @override
  String get updateDescription => 'Mettre à jour la description';

  @override
  String get editName => 'Modifier le Nom';

  @override
  String get editDescription => 'Modifier la Description';

  @override
  String updateNameFailed(Object error) {
    return 'La mise à jour du nom a échoué : $error';
  }

  @override
  String updateDescriptionFailed(Object error) {
    return 'La mise à jour de la description a échoué : $error';
  }

  @override
  String get eventParticipants => 'Participants à l\'événement';

  @override
  String get upcomingEvents => 'Événements à venir';

  @override
  String get spaceInviteDescription => 'Y a-t-il quelqu\'un que vous aimeriez inviter dans cet espace ?';

  @override
  String get inviteSpaceMembersTitle => 'Inviter les Membres de l\'Espace';

  @override
  String get inviteSpaceMembersSubtitle => 'Inviter les utilisateurs de l\'espace sélectionné';

  @override
  String get inviteIndividualUsersTitle => 'Inviter des Utilisateurs Individuels';

  @override
  String get inviteIndividualUsersSubtitle => 'Inviter des utilisateurs qui sont déjà sur Acter';

  @override
  String get inviteIndividualUsersDescription => 'Inviter toute personne faisant partie de la plateforme Acter';

  @override
  String get inviteJoinActer => 'Invitation à rejoindre Acter';

  @override
  String get inviteJoinActerDescription => 'Vous pouvez inviter des personnes à rejoindre Acter et à s\'inscrire automatiquement dans cet espace avec un code d\'enregistrement personnalisé et le partager avec eux';

  @override
  String get generateInviteCode => 'Générer un Code d\'Invitation';

  @override
  String get pendingInvites => 'Invitations en attente';

  @override
  String pendingInvitesCount(Object count) {
    return 'You have $count pending Invites';
  }

  @override
  String get noPendingInvitesTitle => 'Aucune invitation en cours n\'a été trouvée';

  @override
  String get noUserFoundTitle => 'Aucun utilisateur trouvé';

  @override
  String get noUserFoundSubtitle => 'Rechercher des utilisateurs à partir de leur nom d\'utilisateur ou de leur nom affiché';

  @override
  String get done => 'Fait';

  @override
  String get downloadFileDialogTitle => 'Veuillez sélectionner l\'endroit où stocker le fichier';

  @override
  String downloadFileSuccess(Object path) {
    return '\'Fichier enregistré sur $path';
  }

  @override
  String cancelInviteLoading(Object userId) {
    return 'Annulation de l\'invitation de $userId';
  }

  @override
  String cancelInviteError(Object error, Object userId) {
    return 'L\'utilisateur $userId n\'a pas été trouvé : $error';
  }

  @override
  String get shareInviteCode => 'Partager le code d\'invitation';

  @override
  String get appUnavailable => 'Application Indisponible';

  @override
  String shareInviteContent(Object code, Object roomName, Object userName) {
    return '$userName souhaite vous inviter à la $roomName.\nVeuillez suivre les étapes ci-dessous pour joindre :\n\nÉTAPE-1 : Téléchargez l\'application Acter à partir des liens ci-dessous https://app-redir.acter.global/\n\nÉTAPE-2 : Utilisez le code d\'invitation ci-dessous lors de l\'inscription.\nCode d\'invitation : $code\n\nLe tour est joué ! Profitez de ce nouveau mode d\'organisation sûr et sécurisé !';
  }

  @override
  String activateInviteCodeFailed(Object error) {
    return 'L\'activation du code a échoué : $error';
  }

  @override
  String get revoke => 'Révoquer';

  @override
  String get otherSpaces => 'Autres Espaces';

  @override
  String get invitingSpaceMembersLoading => 'Inviter les Membres de l\'Espace';

  @override
  String invitingSpaceMembersProgress(Object count, Object total) {
    return 'Inviting Space Member $count / $total';
  }

  @override
  String invitingSpaceMembersError(Object error) {
    return 'Erreur d\'invitation des Membres de l\'Espace : $error';
  }

  @override
  String membersInvited(Object count) {
    return '$count membres invités';
  }

  @override
  String get selectVisibility => 'Choisir la Visibilité';

  @override
  String get visibilityTitle => 'Visibilité';

  @override
  String get visibilitySubtitle => 'Sélectionnez les personnes autorisées à rejoindre cet espace.';

  @override
  String get visibilityNoPermission => 'Vous n\'avez pas les permissions nécessaires pour modifier la visibilité de cet espace';

  @override
  String get public => 'Public';

  @override
  String get publicVisibilitySubtitle => 'Tout le monde peut trouver et rejoindre';

  @override
  String get privateVisibilitySubtitle => 'Seules les personnes invitées peuvent rejoindre';

  @override
  String get limited => 'Limitée';

  @override
  String get limitedVisibilitySubtitle => 'Toute personne se trouvant dans les espaces sélectionnés pourra trouver et rejoindre';

  @override
  String get visibilityAndAccessibility => 'Visibilité et accessibilité';

  @override
  String updatingVisibilityFailed(Object error) {
    return 'Updating room visibility failed: $error';
  }

  @override
  String get spaceWithAccess => 'Espace avec accès';

  @override
  String get changePassword => 'Changer le Mot de passe';

  @override
  String get changePasswordDescription => 'Modifier votre Mot de passe';

  @override
  String get oldPassword => 'Ancien Mot de passe';

  @override
  String get newPassword => 'Nouveau Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le Mot de passe';

  @override
  String get emptyOldPassword => 'Veuillez saisir l\'ancien mot de passe';

  @override
  String get emptyNewPassword => 'Veuillez saisir un nouveau mot de passe';

  @override
  String get emptyConfirmPassword => 'Veuillez confirmer le mot de passe';

  @override
  String get validateSamePassword => 'Le mot de passe doit être le même';

  @override
  String get changingYourPassword => 'Changement de mot de passe';

  @override
  String changePasswordFailed(Object error) {
    return 'Le changement de mot de passe a échoué : $error';
  }

  @override
  String get passwordChangedSuccessfully => 'Le mot de passe a été modifié avec succès';

  @override
  String get emptyTaskList => 'Aucune liste de tâches n\'a encore été créée';

  @override
  String get addMoreDetails => 'Ajouter Plus de Détails';

  @override
  String get taskName => 'Nom de la tâche';

  @override
  String get addingTask => 'Ajout d\'une Tâche';

  @override
  String countTasksCompleted(Object count) {
    return '$count Terminé';
  }

  @override
  String get showCompleted => 'Affichage Effectué';

  @override
  String get hideCompleted => 'Cacher Complété';

  @override
  String get assignment => 'Assignation';

  @override
  String get noAssignment => 'Pas d\'Assignation';

  @override
  String get assignMyself => 'S\'auto-assigner';

  @override
  String get removeMyself => 'Se retirer soi-même';

  @override
  String get updateTask => 'Mettre à jour la Tâche';

  @override
  String get updatingTask => 'Mise à jour de la Tâche';

  @override
  String updatingTaskFailed(Object error) {
    return 'Échec de la mise à jour de la tâche $error';
  }

  @override
  String get editTitle => 'Modifier le Titre';

  @override
  String get updatingDescription => 'Mise à jour de la Description';

  @override
  String errorUpdatingDescription(Object error) {
    return 'Erreur de mise à jour de la description : $error';
  }

  @override
  String get editLink => 'Modifier le Lien';

  @override
  String get updatingLinking => 'Mise à jour du lien';

  @override
  String get deleteTaskList => 'Supprimer la Liste des Tâches';

  @override
  String get deleteTaskItem => 'Supprimer un Élément de la Tâche';

  @override
  String get reportTaskList => 'Signaler la Liste des Tâches';

  @override
  String get reportTaskItem => 'Signaler un Élément de la Tâche';

  @override
  String get unconfirmedEmailsActivityTitle => 'Vous avez des adresses e-mail non confirmées';

  @override
  String get unconfirmedEmailsActivitySubtitle => 'Veuillez suivre le lien que nous vous avons envoyé dans l\'e-mail, puis confirmer ici';

  @override
  String get seeAll => 'Afficher tout';

  @override
  String get addPin => 'Ajouter une Épingle';

  @override
  String get addEvent => 'Ajouter un Événement';

  @override
  String get linkChat => 'Lier le Chat';

  @override
  String get linkSpace => 'Lien vers l\'Espace';

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
    return 'Le chargement des membres a échoué : $error';
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
  String get comingSoon => 'Prochainement';

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
    return 'Erreur de chargement des espaces : $error';
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
  String get sharePin => 'Partager l\'Épingle';

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
