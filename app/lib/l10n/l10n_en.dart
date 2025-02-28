// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get accept => 'Accept';

  @override
  String get acceptRequest => 'Accept Request';

  @override
  String get access => 'Access';

  @override
  String get accessAndVisibility => 'Access & Visibility';

  @override
  String get account => 'Account';

  @override
  String get actionName => 'Action name';

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
  String get add => 'add';

  @override
  String get addActionWidget => 'Add an action widget';

  @override
  String get addChat => 'Add Chat';

  @override
  String addedToPusherList(Object email) {
    return '$email added to pusher list';
  }

  @override
  String addedToSpacesAndChats(Object number) {
    return 'Added to $number spaces & chats';
  }

  @override
  String get addingEmailAddress => 'Adding email address';

  @override
  String get addSpace => 'Add Space';

  @override
  String get addTask => 'Add Task';

  @override
  String get admin => 'Admin';

  @override
  String get all => 'All';

  @override
  String get allMessages => 'All Messages';

  @override
  String allReactionsCount(Object total) {
    return 'All $total';
  }

  @override
  String get alreadyConfirmed => 'Already confirmed';

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
  String get and => 'and';

  @override
  String get anInviteCodeYouWantToRedeem => 'An invite code you want to redeem';

  @override
  String get anyNumber => 'any number';

  @override
  String get appDefaults => 'App Defaults';

  @override
  String get appId => 'AppId';

  @override
  String get appName => 'App Name';

  @override
  String get apps => 'Space Features';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'Are you sure you want to delete this message? This action cannot be undone.';

  @override
  String get areYouSureYouWantToLeaveRoom => 'Are you sure you want to leave chat? This action cannot be undone';

  @override
  String get areYouSureYouWantToLeaveSpace => 'Are you sure you want to leave this space?';

  @override
  String get areYouSureYouWantToRemoveAttachmentFromPin => 'Are you sure you want to remove this attachment from pin?';

  @override
  String get areYouSureYouWantToUnregisterEmailAddress => 'Are you sure you want to unregister this email address? This action cannot be undone.';

  @override
  String get assignedYourself => 'assigned yourself';

  @override
  String get assignmentWithdrawn => 'Assignment withdrawn';

  @override
  String get aTaskMustHaveATitle => 'A task must have a title';

  @override
  String get attachments => 'Attachments';

  @override
  String get atThisMomentYouAreNotJoiningEvents => 'At this moment, you are not joining any upcoming events. To find out what events are scheduled, check your spaces.';

  @override
  String get authenticationRequired => 'Authentication required';

  @override
  String get avatar => 'Avatar';

  @override
  String get awaitingConfirmation => 'Awaiting confirmation';

  @override
  String get awaitingConfirmationDescription => 'These email addresses have not yet been confirmed. Please go to your inbox and check for the confirmation link.';

  @override
  String get back => 'Back';

  @override
  String get block => 'Block';

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String get blockInfoText => 'Once blocked you won’t see their messages anymore and it will block their attempt to contact you directly.';

  @override
  String blockingUserFailed(Object error) {
    return 'Blocking User failed: $error';
  }

  @override
  String get blockingUserProgress => 'Blocking User';

  @override
  String get blockingUserSuccess => 'User blocked. It might takes a bit before the UI reflects this update.';

  @override
  String blockTitle(Object userId) {
    return 'Block $userId';
  }

  @override
  String get blockUser => 'Block User';

  @override
  String get blockUserOptional => 'Block User (optional)';

  @override
  String get blockUserWithUsername => 'Block user with username';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get bookmarked => 'Bookmarked';

  @override
  String get bookmarkedSpaces => 'Bookmarked Spaces';

  @override
  String get builtOnShouldersOfGiants => 'Built on the shoulders of giants';

  @override
  String get calendarEventsFromAllTheSpaces => 'Calendar events from all the Spaces you are part of';

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
  String get camera => 'Camera';

  @override
  String get cancel => 'Cancel';

  @override
  String get cannotEditSpaceWithNoPermissions => 'Cannot edit space with no permissions';

  @override
  String get changeAppLanguage => 'Change App Language';

  @override
  String get changePowerLevel => 'Change Permission Level';

  @override
  String get changeThePowerLevelOf => 'Change the permission level of';

  @override
  String get changeYourDisplayName => 'Change your display name';

  @override
  String get chat => 'Chat';

  @override
  String get chatNG => 'Next-Generation Chat';

  @override
  String get chatNGExplainer => 'Switch to next generation Chat. Features might not be stable';

  @override
  String get customizationsTitle => 'Customizations';

  @override
  String get chatMissingPermissionsToSend => 'You don’t have permissions to sent messages here';

  @override
  String get behaviorSettingsTitle => 'Behavior';

  @override
  String get behaviorSettingsExplainer => 'Configure the behavior of your App';

  @override
  String get chatSettingsAutoDownload => 'Auto Download Media';

  @override
  String get chatSettingsAutoDownloadExplainer => 'When to automatically download media';

  @override
  String get chatSettingsAutoDownloadAlways => 'Always';

  @override
  String get chatSettingsAutoDownloadWifiOnly => 'Only when on WiFi';

  @override
  String get chatSettingsAutoDownloadNever => 'Never';

  @override
  String get settingsSubmitting => 'Submitting Settings';

  @override
  String get settingsSubmittingSuccess => 'Settings submitted';

  @override
  String settingsSubmittingFailed(Object error) {
    return 'Failed to submit: $error ';
  }

  @override
  String get chatRoomCreated => 'Chat Created';

  @override
  String get chatSendingFailed => 'Failed to sent. Will retry…';

  @override
  String get chatSettingsTyping => 'Send typing notifications';

  @override
  String get chatSettingsTypingExplainer => '(soon) Inform others when you are typing';

  @override
  String get chatSettingsReadReceipts => 'Send read receipts';

  @override
  String get chatSettingsReadReceiptsExplainer => '(soon) Inform others when you read a message';

  @override
  String get chats => 'Chats';

  @override
  String claimedTimes(Object count) {
    return 'Claimed $count times';
  }

  @override
  String get clear => 'Clear';

  @override
  String get clearDBAndReLogin => 'Clear DB and re-login';

  @override
  String get close => 'Close';

  @override
  String get closeDialog => 'Close Dialog';

  @override
  String get closeSessionAndDeleteData => 'Close this session, deleting local data';

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
  String get codeMustBeAtLeast6CharactersLong => 'Code must be at least 6 characters long';

  @override
  String get comment => 'Comment';

  @override
  String get comments => 'Comments';

  @override
  String commentsListError(Object error) {
    return 'Comments list error: $error';
  }

  @override
  String get commentSubmitted => 'Comment submitted';

  @override
  String get community => 'Community';

  @override
  String get confirmationToken => 'Confirmation Token';

  @override
  String get confirmedEmailAddresses => 'Confirmed Email Addresses';

  @override
  String get confirmedEmailAddressesDescription => 'Confirmed emails addresses connected to your account:';

  @override
  String get confirmWithToken => 'Confirm with Token';

  @override
  String get congrats => 'Congrats!';

  @override
  String get connectedToYourAccount => 'Connected to your account';

  @override
  String get contentSuccessfullyRemoved => 'Content successfully removed';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get continueQuestion => 'Continue?';

  @override
  String get copyUsername => 'Copy username';

  @override
  String get copyMessage => 'Copy';

  @override
  String get couldNotFetchNews => 'Couldn’t fetch news';

  @override
  String get couldNotLoadAllSessions => 'Couldn’t load all sessions';

  @override
  String couldNotLoadImage(Object error) {
    return 'Could not load image due to $error';
  }

  @override
  String countsMembers(Object count) {
    return '$count Members';
  }

  @override
  String get create => 'Create';

  @override
  String get createChat => 'Create Chat';

  @override
  String get createCode => 'Create Code';

  @override
  String get createDefaultChat => 'Create default chat room, too';

  @override
  String defaultChatName(Object name) {
    return '$name chat';
  }

  @override
  String get createDMWhenRedeeming => 'Create DM when redeeming';

  @override
  String get createEventAndBringYourCommunity => 'Create new event and bring your community together';

  @override
  String get createGroupChat => 'Create Group Chat';

  @override
  String get createPin => 'Create Pin';

  @override
  String get createPostsAndEngageWithinSpace => 'Create actionable posts and engage everyone within your space.';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get createSpace => 'Create Space';

  @override
  String get createSpaceChat => 'Create Space Chat';

  @override
  String get createSubspace => 'Create Subspace';

  @override
  String get createTaskList => 'Create task list';

  @override
  String get createAcopy => 'Copy as new';

  @override
  String get creatingCalendarEvent => 'Creating Calendar Event';

  @override
  String get creatingChat => 'Creating Chat';

  @override
  String get creatingCode => 'Creating code';

  @override
  String creatingNewsFailed(Object error) {
    return 'Creating update failed $error';
  }

  @override
  String get creatingSpace => 'Creating Space';

  @override
  String creatingSpaceFailed(Object error) {
    return 'Creating space failed: $error';
  }

  @override
  String creatingTaskFailed(Object error) {
    return 'Creating Task failed $error';
  }

  @override
  String get custom => 'Custom';

  @override
  String get customizeAppsAndTheirFeatures => 'Customize the features needed for this space';

  @override
  String get customPowerLevel => 'Custom permission  level';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get deactivateAccountDescription => 'If you proceed:\n\n - All your personal data will be removed from your homeserver, including display name and avatar \n - All your sessions will be closed immediately, no other device will be able to continue their sessions \n - You will leave all rooms, chats, spaces and DMs that you are in \n - You will not be able to reactivate your account \n - You will no longer be able to log in \n - No one will be able to reuse your username (MXID), including you: this username will remain unavailable indefinitely \n - You will be removed from the identity server, if you provided any information to be found through that (e.g. email or phone number) \n - All local data, including any encryption keys, will be permanently deleted from this device \n - Your old messages will still be visible to people who received them, just like emails you sent in the past. \n\n You will not be able to reverse any of this. This is a permanent and irrevocable action.';

  @override
  String get deactivateAccountPasswordTitle => 'Please provide your user password to confirm you want to deactivate your account.';

  @override
  String get deactivateAccountTitle => 'Careful: You are about to permanently deactivate your account';

  @override
  String deactivatingFailed(Object error) {
    return 'Deactivating failed: \n $error';
  }

  @override
  String get deactivatingYourAccount => 'Deactivating your account';

  @override
  String get deactivationAndRemovingFailed => 'Deactivation and removing all local data failed';

  @override
  String get debugInfo => 'Debug Info';

  @override
  String get debugLevel => 'Debug level';

  @override
  String get decline => 'Decline';

  @override
  String get defaultModes => 'Default Modes';

  @override
  String defaultNotification(Object type) {
    return 'Default $type';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteAttachment => 'Delete attachment';

  @override
  String get deleteCode => 'Delete code';

  @override
  String get deleteTarget => 'Delete Target';

  @override
  String get deleteNewsDraftTitle => 'Delete draft?';

  @override
  String get deleteNewsDraftText => 'Are you sure you want to delete this draft? This can’t be undone.';

  @override
  String get deleteDraftBtn => 'Delete draft';

  @override
  String get deletingPushTarget => 'Deleting push target';

  @override
  String deletionFailed(Object error) {
    return 'Deletion failed: $error';
  }

  @override
  String get denied => 'Denied';

  @override
  String get description => 'Description';

  @override
  String get deviceId => 'Device Id';

  @override
  String get deviceIdDigest => 'Device Id Digest';

  @override
  String get deviceName => 'Device Name';

  @override
  String get devicePlatformException => 'You can’t use the DevicePlatform.device/web in this context. Incorrect platform: SettingsSection.build';

  @override
  String get displayName => 'Display Name';

  @override
  String get displayNameUpdateSubmitted => 'Display name update submitted';

  @override
  String directInviteUser(Object userId) {
    return 'Directly invite $userId';
  }

  @override
  String get dms => 'DMs';

  @override
  String get doYouWantToDeleteInviteCode => 'Do you really want to irreversibly delete the invite code? It can’t be used again after.';

  @override
  String due(Object date) {
    return 'Due: $date';
  }

  @override
  String get dueDate => 'Due date';

  @override
  String get edit => 'Edit';

  @override
  String get editDetails => 'Edit Details';

  @override
  String get editMessage => 'Edit Message';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editSpace => 'Edit Space';

  @override
  String get edited => 'Edited';

  @override
  String get egGlobalMovement => 'eg. Global Movement';

  @override
  String get emailAddressToAdd => 'Email address to add';

  @override
  String get emailOrPasswordSeemsNotValid => 'Email or password seems to be not valid.';

  @override
  String get emptyEmail => 'Please enter email';

  @override
  String get emptyPassword => 'Please enter Password';

  @override
  String get emptyToken => 'Please enter code';

  @override
  String get emptyUsername => 'Please enter Username';

  @override
  String get encrypted => 'Encrypted';

  @override
  String get encryptedSpace => 'Encrypted Space';

  @override
  String get encryptionBackupEnabled => 'Encryption backups enabled';

  @override
  String get encryptionBackupEnabledExplainer => 'Your keys are stored in an encrypted backup on your home server';

  @override
  String get encryptionBackupMissing => 'Encryption backups missing';

  @override
  String get encryptionBackupMissingExplainer => 'We recommend to use automatic encryption key backups';

  @override
  String get encryptionBackupProvideKey => 'Provide Recovery Key';

  @override
  String get encryptionBackupProvideKeyExplainer => 'We have found an automatic encryption backup';

  @override
  String get encryptionBackupProvideKeyAction => 'Provide Key';

  @override
  String get encryptionBackupNoBackup => 'No encryption backup found';

  @override
  String get encryptionBackupNoBackupExplainer => 'If you lose access to your account, conversations might become unrecoverable. We recommend enabling automatic encryption backups.';

  @override
  String get encryptionBackupNoBackupAction => 'Enable Backup';

  @override
  String get encryptionBackupEnabling => 'Enabling backup';

  @override
  String encryptionBackupEnablingFailed(Object error) {
    return 'Enabling backup failed: $error';
  }

  @override
  String get encryptionBackupRecovery => 'Your Backup Recover key';

  @override
  String get encryptionBackupRecoveryExplainer => 'Store this Backup Recovery Key securely.';

  @override
  String get encryptionBackupRecoveryCopiedToClipboard => 'Recovery Key copied to clipboard';

  @override
  String get refreshing => 'Refreshing';

  @override
  String get encryptionBackupDisable => 'Disable your Key Backup?';

  @override
  String get encryptionBackupDisableExplainer => 'Resetting the key backup will destroy it locally and on your homeserver. This can’t be undone. Are you sure you want to continue?';

  @override
  String get encryptionBackupDisableActionKeepIt => 'No, keep it';

  @override
  String get encryptionBackupDisableActionDestroyIt => 'Yes, destroy it';

  @override
  String get encryptionBackupResetting => 'Resetting Backup';

  @override
  String get encryptionBackupResettingSuccess => 'Reset successful';

  @override
  String encryptionBackupResettingFailed(Object error) {
    return 'Failed to disable: $error';
  }

  @override
  String get encryptionBackupRecover => 'Recover Encryption Backup';

  @override
  String get encryptionBackupRecoverExplainer => 'Provider you recovery key to decrypt the encryption backup';

  @override
  String get encryptionBackupRecoverInputHint => 'Recovery key';

  @override
  String get encryptionBackupRecoverProvideKey => 'Please provide the key';

  @override
  String get encryptionBackupRecoverAction => 'Recover';

  @override
  String get encryptionBackupRecoverRecovering => 'Recovering';

  @override
  String get encryptionBackupRecoverRecoveringSuccess => 'Recovery successful';

  @override
  String get encryptionBackupRecoverRecoveringImportFailed => 'Import failed';

  @override
  String encryptionBackupRecoverRecoveringFailed(Object error) {
    return 'Failed to recover: $error';
  }

  @override
  String get encryptionBackupKeyBackup => 'Key backup';

  @override
  String get encryptionBackupKeyBackupExplainer => 'Here you configure the Key Backup';

  @override
  String error(Object error) {
    return 'Error $error';
  }

  @override
  String errorCreatingCalendarEvent(Object error) {
    return 'Error Creating Calendar Event: $error';
  }

  @override
  String errorCreatingChat(Object error) {
    return 'Error creating chat: $error';
  }

  @override
  String errorSubmittingComment(Object error) {
    return 'Error submitting comment: $error';
  }

  @override
  String errorUpdatingEvent(Object error) {
    return 'Error updating event: $error';
  }

  @override
  String get eventDescriptionsData => 'Event descriptions data';

  @override
  String get eventName => 'Event Name';

  @override
  String get events => 'Events';

  @override
  String get eventTitleData => 'Event title data';

  @override
  String get experimentalActerFeatures => 'Experimental Acter features';

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
  String get file => 'File';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPasswordDescription => 'To reset your password, we will send a verification link to your email. Follow the process there and once confirmed, you can reset your password here.';

  @override
  String get forgotPasswordNewPasswordDescription => 'Once you’ve finished the process behind the link of the email we’ve sent you, you can set a new password here:';

  @override
  String get formatMustBe => 'Format must be @user:server.tld';

  @override
  String get foundUsers => 'Found Users';

  @override
  String get from => 'from';

  @override
  String get gallery => 'Gallery';

  @override
  String get general => 'General';

  @override
  String get getConversationGoingToStart => 'Get the conversation going to start organizing collaborating';

  @override
  String get getInTouchWithOtherChangeMakers => 'Get in touch with other change makers, organizers or activists and chat directly with them.';

  @override
  String get goToDM => 'Go to DM';

  @override
  String get going => 'Going';

  @override
  String get haveProfile => 'Already have a profile?';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get helpCenterDesc => 'Get helpful tips about Acter';

  @override
  String get hereYouCanChangeTheSpaceDetails => 'Here you can change the space details';

  @override
  String get hereYouCanSeeAllUsersYouBlocked => 'Here you can see all users you’ve blocked.';

  @override
  String get hintMessageDisplayName => 'Enter the name you want others to see';

  @override
  String get hintMessageInviteCode => 'Enter your invite code';

  @override
  String get hintMessagePassword => 'At least 6 characters';

  @override
  String get hintMessageUsername => 'Unique username for logging in and identification';

  @override
  String get homeServerName => 'Home Server Name';

  @override
  String get homeServerURL => 'Home Server URL';

  @override
  String get httpProxy => 'HTTP Proxy';

  @override
  String get image => 'Image';

  @override
  String get inConnectedSpaces => 'In connected spaces, you can focus on specific actions or campaigns of your working groups and start organizing.';

  @override
  String get info => 'Info';

  @override
  String get invalidTokenOrPassword => 'Invalid token or password';

  @override
  String get invitationToChat => 'Invited to join chat by ';

  @override
  String get invitationToDM => 'Wants to start a DM with you';

  @override
  String get invitationToSpace => 'Invited to join space by ';

  @override
  String get invited => 'Invited';

  @override
  String get inviteCode => 'Invite Code';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String shareInviteWithCode(Object code) {
    return 'Invite $code';
  }

  @override
  String get inviteCodeInfo => 'Acter is still invite-only access. In case you were not given an invite code by a specific group or initiative, use below code to check out Acter.';

  @override
  String get irreversiblyDeactivateAccount => 'Irreversibly deactivate this account';

  @override
  String get itsYou => 'This is you';

  @override
  String get join => 'join';

  @override
  String get joined => 'Joined';

  @override
  String joiningFailed(Object error) {
    return 'Joining failed: $error';
  }

  @override
  String get joinActer => 'Join Acter';

  @override
  String joinRuleNotSupportedYet(Object role) {
    return 'Join Rule $role not supported yet. Sorry';
  }

  @override
  String kickAndBanFailed(Object error) {
    return 'Removing & banning user failed: \n $error';
  }

  @override
  String get kickAndBanProgress => 'Removing and Banning user';

  @override
  String get kickAndBanSuccess => 'User removed and banned';

  @override
  String get kickAndBanUser => 'Remove & Ban User';

  @override
  String kickAndBanUserDescription(Object roomId, Object userId) {
    return 'You are about to remove and permanently ban $userId from $roomId';
  }

  @override
  String kickAndBanUserTitle(Object userId) {
    return 'Remove & Ban User $userId';
  }

  @override
  String kickFailed(Object error) {
    return 'Removing user failed: \n $error';
  }

  @override
  String get kickProgress => 'Removing user';

  @override
  String get kickSuccess => 'User removed';

  @override
  String get kickUser => 'Remove User';

  @override
  String kickUserDescription(Object roomId, Object userId) {
    return 'You are about to remove $userId from $roomId';
  }

  @override
  String kickUserTitle(Object userId) {
    return 'Remove User $userId';
  }

  @override
  String get labs => 'Labs';

  @override
  String get labsAppFeatures => 'App Features';

  @override
  String get language => 'Language';

  @override
  String get leave => 'Leave';

  @override
  String get leaveRoom => 'Leave Chat';

  @override
  String get leaveSpace => 'Leave Space';

  @override
  String get leavingSpace => 'Leaving Space';

  @override
  String get leavingSpaceSuccessful => 'You’ve left the Space';

  @override
  String leavingSpaceFailed(Object error) {
    return 'Error leaving the space: $error';
  }

  @override
  String get leavingRoom => 'Leaving Chat';

  @override
  String get letsGetStarted => 'Let’s get started';

  @override
  String get licenses => 'Licenses';

  @override
  String get limitedInternConnection => 'Limited Internet connection';

  @override
  String get link => 'Link';

  @override
  String get linkExistingChat => 'Link existing Chat';

  @override
  String get linkExistingSpace => 'Link existing Space';

  @override
  String get links => 'Links';

  @override
  String get loading => 'Loading';

  @override
  String get linkToChat => 'Link to Chat';

  @override
  String loadingFailed(Object error) {
    return 'Loading failed: $error';
  }

  @override
  String get location => 'Location';

  @override
  String get logIn => 'Log In';

  @override
  String get loginAgain => 'Login again';

  @override
  String get loginContinue => 'Log in and continue organizing from where you last left off.';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get logOut => 'Logout';

  @override
  String get logSettings => 'Log Settings';

  @override
  String get looksGoodAddressConfirmed => 'Looks good. Address confirmed.';

  @override
  String get makeADifference => 'Unlock your digital organizing.';

  @override
  String get manage => 'Manage';

  @override
  String get manageBudgetsCooperatively => 'Manage budgets cooperatively';

  @override
  String get manageYourInvitationCodes => 'Manage your invitation codes';

  @override
  String get markToHideAllCurrentAndFutureContent => 'Mark to hide all current and future content from this user and block them from contacting you';

  @override
  String get markedAsDone => 'marked as done';

  @override
  String get maybe => 'Maybe';

  @override
  String get member => 'Member';

  @override
  String get memberDescriptionsData => 'Member descriptions data';

  @override
  String get memberTitleData => 'Member title data';

  @override
  String get members => 'Members';

  @override
  String get mentionsAndKeywordsOnly => 'Mentions and Keywords only';

  @override
  String get message => 'Message';

  @override
  String get messageCopiedToClipboard => 'Message copied to clipboard';

  @override
  String get missingName => 'Please enter your Name';

  @override
  String get mobilePushNotifications => 'Mobile Push Notifications';

  @override
  String get moderator => 'Moderator';

  @override
  String get more => 'More';

  @override
  String moreRooms(Object count) {
    return '+$count additional rooms';
  }

  @override
  String get muted => 'Muted';

  @override
  String get customValueMustBeNumber => 'You need to enter the custom value as a number.';

  @override
  String get myDashboard => 'My Dashboard';

  @override
  String get name => 'Name';

  @override
  String get nameOfTheEvent => 'Name of the event';

  @override
  String get needsAppRestartToTakeEffect => 'Needs an app restart to take effect';

  @override
  String get newChat => 'New Chat';

  @override
  String get newEncryptedMessage => 'New Encrypted Message';

  @override
  String get needYourPasswordToConfirm => 'Need your password to confirm';

  @override
  String get newMessage => 'New message';

  @override
  String get newUpdate => 'New Update';

  @override
  String get next => 'Next';

  @override
  String get no => 'No';

  @override
  String get noChatsFound => 'no chats found';

  @override
  String get noChatsFoundMatchingYourFilter => 'No chats found matching your filters & search';

  @override
  String get noChatsFoundMatchingYourSearchTerm => 'No chats found matching your search term';

  @override
  String get noChatsInThisSpaceYet => 'No chats in this space yet';

  @override
  String get noChatsStillSyncing => 'Synchronizing…';

  @override
  String get noChatsStillSyncingSubtitle => 'We are loading your chats. On large accounts the initial loading takes a bit…';

  @override
  String get noConnectedSpaces => 'No connected spaces';

  @override
  String get noDisplayName => 'no display name';

  @override
  String get noDueDate => 'No due date';

  @override
  String get noEventsPlannedYet => 'No events planned yet';

  @override
  String get noIStay => 'No, I stay';

  @override
  String get noMembersFound => 'No members found. How can that even be, you are here, aren’t you?';

  @override
  String get noOverwrite => 'No Overwrite';

  @override
  String get noParticipantsGoing => 'No participants going';

  @override
  String get noPinsAvailableDescription => 'Share important resources with your community such as documents or links so everyone is updated.';

  @override
  String get noPinsAvailableYet => 'No pins available yet';

  @override
  String get noProfile => 'Don’t have a profile yet?';

  @override
  String get noPushServerConfigured => 'No push server configured on build';

  @override
  String get noPushTargetsAddedYet => 'no push targets added yet';

  @override
  String get noSpacesFound => 'No spaces found';

  @override
  String get noUsersFoundWithSpecifiedSearchTerm => 'No Users found with specified search term';

  @override
  String get notEnoughPowerLevelForInvites => 'Not enough permission level for invites, ask administrator to change it';

  @override
  String get notFound => '404 - Not Found';

  @override
  String get notes => 'Notes';

  @override
  String get notGoing => 'Not Going';

  @override
  String get noThanks => 'No, thanks';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsOverwrites => 'Notifications Overwrites';

  @override
  String get notificationsOverwritesDescription => 'Overwrite your notifications configurations for this space';

  @override
  String get notificationsSettingsAndTargets => 'Notifications settings and targets';

  @override
  String get notificationStatusSubmitted => 'Notification status submitted';

  @override
  String notificationStatusUpdateFailed(Object error) {
    return 'Notification status update failed: $error';
  }

  @override
  String get notificationsUnmuted => 'Notifications unmuted';

  @override
  String get notificationTargets => 'Notification Targets';

  @override
  String get notifyAboutSpaceUpdates => 'Notify about Space Updates immediately';

  @override
  String get noTopicFound => 'No topic found';

  @override
  String get notVisible => 'Not visible';

  @override
  String get notYetSupported => 'Not yet supported';

  @override
  String get noWorriesWeHaveGotYouCovered => 'No worries! Enter your email to reset your password.';

  @override
  String get ok => 'Ok';

  @override
  String get okay => 'Okay';

  @override
  String get on => 'on';

  @override
  String get onboardText => 'Let’s get started by setting up your profile';

  @override
  String get onlySupportedIosAndAndroid => 'Only supported on mobile (iOS & Android) right now';

  @override
  String get optional => 'Optional';

  @override
  String get or => ' or ';

  @override
  String get overview => 'Overview';

  @override
  String get parentSpace => 'Parent Space';

  @override
  String get parentSpaces => 'Parent Spaces';

  @override
  String get parentSpaceMustBeSelected => 'Parent Space must be selected';

  @override
  String get parents => 'Parents';

  @override
  String get password => 'Password';

  @override
  String get passwordResetTitle => 'Password Reset';

  @override
  String get past => 'Past';

  @override
  String get pending => 'Pending';

  @override
  String peopleGoing(Object count) {
    return '$count People going';
  }

  @override
  String get personalSettings => 'Personal Settings';

  @override
  String get pinName => 'Pin Name';

  @override
  String get pins => 'Pins';

  @override
  String get play => 'Play';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get pleaseCheckYourInbox => 'Please check your inbox for the validation email and click the link before it expires';

  @override
  String get pleaseEnterAName => 'Please enter a name';

  @override
  String get pleaseEnterATitle => 'Please enter a title';

  @override
  String get pleaseEnterEventName => 'Please enter event name';

  @override
  String get pleaseFirstSelectASpace => 'Please first select a space';

  @override
  String errorProcessingSlide(Object error, Object slideIdx) {
    return 'We couldn’t process slide $slideIdx: $error';
  }

  @override
  String get pleaseProvideEmailAddressToAdd => 'Please provide the email address you’d like to add';

  @override
  String get pleaseProvideYourUserPassword => 'Please provide your user password to confirm you want to end that session.';

  @override
  String get pleaseSelectSpace => 'Please select space';

  @override
  String get selectTaskList => 'Select Task List';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get polls => 'Polls';

  @override
  String get pollsAndSurveys => 'Polls and Surveys';

  @override
  String postingOfTypeNotYetSupported(Object type) {
    return 'Posting of $type not yet supported';
  }

  @override
  String get postingTaskList => 'Posting TaskList';

  @override
  String get postpone => 'Postpone';

  @override
  String postponeN(Object days) {
    return 'Postpone $days days';
  }

  @override
  String get powerLevel => 'Permission Level';

  @override
  String get powerLevelUpdateSubmitted => 'Permission Level update submitted';

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
  String get preview => 'Preview';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get private => 'Private';

  @override
  String get profile => 'Profile';

  @override
  String get pushKey => 'PushKey';

  @override
  String get pushTargetDeleted => 'Push target deleted';

  @override
  String get pushTargetDetails => 'Push Target Details';

  @override
  String get pushToThisDevice => 'Push to this device';

  @override
  String get quickSelect => 'Quick select:';

  @override
  String get rageShakeAppName => 'Rageshake App Name';

  @override
  String get rageShakeAppNameDigest => 'Rageshake App Name Digest';

  @override
  String get rageShakeTargetUrl => 'Rageshake Target Url';

  @override
  String get rageShakeTargetUrlDigest => 'Rageshake Target Url Digest';

  @override
  String get reason => 'Reason';

  @override
  String get reasonHint => 'optional reason';

  @override
  String get reasonLabel => 'Reason';

  @override
  String redactionFailed(Object error) {
    return 'Redaction sending failed: $error';
  }

  @override
  String get redeem => 'Redeem';

  @override
  String redeemingFailed(Object error) {
    return 'Redeeming failed: $error';
  }

  @override
  String get register => 'Register';

  @override
  String registerFailed(Object error) {
    return 'Registration failed: $error';
  }

  @override
  String get regular => 'Regular';

  @override
  String get remove => 'Remove';

  @override
  String get removePin => 'Remove Pin';

  @override
  String get removeThisContent => 'Remove this content. This can not be undone. Provide an optional reason to explain, why this was removed';

  @override
  String get reply => 'Reply';

  @override
  String replyTo(Object name) {
    return 'Reply to $name';
  }

  @override
  String get replyPreviewUnavailable => 'No preview available for the message you are replying to';

  @override
  String get report => 'Report';

  @override
  String get reportThisEvent => 'Report this event';

  @override
  String get reportThisMessage => 'Report this message';

  @override
  String get reportMessageContent => 'Report this message to your homeserver administrator. Please note that adminstrator wouldn’t be able to read or view any files, if chat is encrypted';

  @override
  String get reportPin => 'Report Pin';

  @override
  String get reportThisPost => 'Report this post';

  @override
  String get reportPostContent => 'Report this post to your homeserver administrator. Please note that administrator would’t be able to read or view any files in encrypted spaces.';

  @override
  String get reportSendingFailed => 'Report sending failed';

  @override
  String get reportSent => 'Report sent!';

  @override
  String get reportThisContent => 'Report this content to your homeserver administrator. Please note that your administrator won’t be able to read or view files in encrypted spaces.';

  @override
  String get requestToJoin => 'request to join';

  @override
  String get reset => 'Reset';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get retry => 'Retry';

  @override
  String get roomId => 'ChatId';

  @override
  String get roomNotFound => 'Chat not found';

  @override
  String get roomLinkedButNotUpgraded => 'Added. However you are not able to upgrade its join rule settings and thus not all people from this space might be able to join it.';

  @override
  String get rsvp => 'RSVP';

  @override
  String repliedToMsgFailed(Object id) {
    return 'Failed to load original message id: $id';
  }

  @override
  String get sasGotIt => 'Got it';

  @override
  String sasIncomingReqNotifContent(String sender) {
    return '$sender wants to verify your session';
  }

  @override
  String get sasIncomingReqNotifTitle => 'Verification Request';

  @override
  String get sasVerified => 'Verified!';

  @override
  String get save => 'Save';

  @override
  String get saveFileAs => 'Save file as';

  @override
  String get openFile => 'Open';

  @override
  String get shareFile => 'Share';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get savingCode => 'Saving code';

  @override
  String get search => 'Search';

  @override
  String get searchTermFieldHint => 'Search for…';

  @override
  String get searchChats => 'Search chats';

  @override
  String searchResultFor(Object text) {
    return 'Search result for $text…';
  }

  @override
  String get searchUsernameToStartDM => 'Search Username to start a DM';

  @override
  String searchingFailed(Object error) {
    return 'Searching failed $error';
  }

  @override
  String get searchSpace => 'search space';

  @override
  String get searchSpaces => 'Search Spaces';

  @override
  String get searchPublicDirectory => 'Search Public Directory';

  @override
  String get searchPublicDirectoryNothingFound => 'No entry found in the public directory';

  @override
  String get seeOpenTasks => 'see open tasks';

  @override
  String get seenBy => 'Seen By';

  @override
  String get select => 'Select';

  @override
  String get selectAll => 'Select all';

  @override
  String get unselectAll => 'Unselect all';

  @override
  String get selectAnyRoomToSeeIt => 'Select any Chat to see it';

  @override
  String get selectDue => 'Select Due';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get selectParentSpace => 'Select parent space';

  @override
  String get send => 'Send';

  @override
  String get sendingAttachment => 'Sending Attachment';

  @override
  String get sendingReport => 'Sending Report';

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
  String get sentAnImage => 'sent an image.';

  @override
  String get server => 'Server';

  @override
  String get sessions => 'Session';

  @override
  String get sessionTokenName => 'Session Token Name';

  @override
  String get setDebugLevel => 'Set debug level';

  @override
  String get setHttpProxy => 'Set HTTP Proxy';

  @override
  String get settings => 'Settings';

  @override
  String get securityAndPrivacy => 'Security & Privacy';

  @override
  String get settingsKeyBackUpTitle => 'Key Backup';

  @override
  String get settingsKeyBackUpDesc => 'Manage the key backup';

  @override
  String get share => 'Share';

  @override
  String get shareIcal => 'Share iCal';

  @override
  String shareFailed(Object error) {
    return 'Sharing failed: $error';
  }

  @override
  String get sharedCalendarAndEvents => 'Shared Calendar and events';

  @override
  String get signUp => 'Sign Up';

  @override
  String get skip => 'Skip';

  @override
  String get slidePosting => 'Slide posting';

  @override
  String slidesNotYetSupported(Object type) {
    return '$type slides not yet supported';
  }

  @override
  String get someErrorOccurredLeavingRoom => 'Some error occurred leaving Chat';

  @override
  String get space => 'Space';

  @override
  String get spaceConfiguration => 'Space Configuration';

  @override
  String get spaceConfigurationDescription => 'Configure, who can view and how to join this space';

  @override
  String get spaceName => 'Space Name';

  @override
  String get spaceNotificationOverwrite => 'Space notification overwrite';

  @override
  String get spaceNotifications => 'Space Notifications';

  @override
  String get spaceOrSpaceIdMustBeProvided => 'space or spaceId must be provided';

  @override
  String get spaces => 'Spaces';

  @override
  String get spacesAndChats => 'Spaces & Chats';

  @override
  String get spacesAndChatsToAddThemTo => 'Spaces & Chats to add them to';

  @override
  String get startDM => 'Start DM';

  @override
  String get state => 'state';

  @override
  String get submit => 'Submit';

  @override
  String get submittingComment => 'Submitting comment';

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
  String get superInvitations => 'Invitation Codes';

  @override
  String get superInvites => 'Invitation Codes';

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
  String get takeAFirstStep => 'The secure organizing app that grows with your aspirations. Providing a safe space for movements.';

  @override
  String get taskListName => 'Task list name';

  @override
  String get tasks => 'Tasks';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsText1 => 'By clicking to create profile you agree to our';

  @override
  String theCurrentJoinRulesOfSpace(Object parentSpaceName, Object roomName) {
    return 'The current join rules of $roomName mean it won’t be visible for $parentSpaceName’s members. Should we update the join rules to allow for $parentSpaceName’s space member to see and join the $roomName?';
  }

  @override
  String get theParentSpace => 'the parent space';

  @override
  String get thereIsNothingScheduledYet => 'There’s nothing scheduled yet';

  @override
  String get theSelectedRooms => 'the selected chats';

  @override
  String get theyWontBeAbleToJoinAgain => 'They won’t be able to join again';

  @override
  String get thirdParty => '3rd Party';

  @override
  String get thisApaceIsEndToEndEncrypted => 'This space is end-to-end-encrypted';

  @override
  String get thisApaceIsNotEndToEndEncrypted => 'This space is not end-to-end-encrypted';

  @override
  String get thisIsAMultilineDescription => 'This is a multiline description of the task with lengthy texts and stuff';

  @override
  String get thisIsNotAProperActerSpace => 'This is not a proper acter space. Some features may not be available.';

  @override
  String get thisMessageHasBeenDeleted => 'This message has been deleted';

  @override
  String get thisWillAllowThemToContactYouAgain => 'This will allow them to contact you again';

  @override
  String get title => 'Title';

  @override
  String get titleTheNewTask => 'Title the new task..';

  @override
  String typingUser1(Object user) {
    return '$user is typing…';
  }

  @override
  String typingUser2(Object user1, Object user2) {
    return '$user1 and $user2 are typing…';
  }

  @override
  String typingUserN(Object user, Object userCount) {
    return '$user and $userCount others are typing';
  }

  @override
  String get to => 'to';

  @override
  String get toAccess => 'to access';

  @override
  String get needToBeMemberOf => 'you need to be member of';

  @override
  String get today => 'Today';

  @override
  String get token => 'token';

  @override
  String get tokenAndPasswordMustBeProvided => 'Token and password must be provided';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get topic => 'Topic';

  @override
  String get tryingToConfirmToken => 'Trying to confirm token';

  @override
  String tryingToJoin(Object name) {
    return 'Joining $name';
  }

  @override
  String get tryToJoin => 'Try to join';

  @override
  String get typeName => 'Type Name';

  @override
  String get unblock => 'Unblock';

  @override
  String get unblockingUser => 'Unblocking User';

  @override
  String unblockingUserFailed(Object error) {
    return 'Unblocking User failed: $error';
  }

  @override
  String get unblockingUserProgress => 'Unblocking User';

  @override
  String get unblockingUserSuccess => 'User unblocked. It might takes a bit before the UI reflects this update.';

  @override
  String unblockTitle(Object userId) {
    return 'Unblock $userId';
  }

  @override
  String get unblockUser => 'Unblock User';

  @override
  String unclearJoinRule(Object rule) {
    return 'Unclear join rule $rule';
  }

  @override
  String get unreadMarkerFeatureTitle => 'Unread Markers';

  @override
  String get unreadMarkerFeatureDescription => 'Track and show which Chats have been read';

  @override
  String get undefined => 'undefined';

  @override
  String get unknown => 'unknown';

  @override
  String get unknownRoom => 'Unknown Chat';

  @override
  String get unlink => 'Unlink';

  @override
  String get unmute => 'Unmute';

  @override
  String get unset => 'unset';

  @override
  String get unsupportedPleaseUpgrade => 'Unsupported - Please upgrade!';

  @override
  String get unverified => 'Unverified';

  @override
  String get unverifiedSessions => 'Unverified Sessions';

  @override
  String get unverifiedSessionsDescription => 'You have devices logged in your account that aren’t verified. This can be a security risk. Please ensure this is okay.';

  @override
  String unverifiedSessionsCount(int count) {
    return 'There are $count unverified sessions logged in';
  }

  @override
  String get upcoming => 'Upcoming';

  @override
  String get updatePowerLevel => 'Update Permission level';

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
  String get updatingDisplayName => 'Updating display name';

  @override
  String get updatingDue => 'Updating due';

  @override
  String get updatingEvent => 'Updating Event';

  @override
  String updatingPowerLevelOf(Object userId) {
    return 'Updating Permission  level of $userId';
  }

  @override
  String get updatingProfileImage => 'Updating profile image';

  @override
  String get updatingRSVP => 'Updating RSVP';

  @override
  String get updatingSpace => 'Updating Space';

  @override
  String get uploadAvatar => 'Upload Avatar';

  @override
  String usedTimes(Object count) {
    return 'Used $count times';
  }

  @override
  String userAddedToBlockList(Object user) {
    return '$user added to block list. UI might take a bit too update';
  }

  @override
  String get users => 'Users';

  @override
  String get usersfoundDirectory => 'Users found in public directory';

  @override
  String get username => 'Username';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get usernameCopiedToClipboard => 'Username copied to clipboard';

  @override
  String get userRemovedFromList => 'User removed from list. UI might take a bit too update';

  @override
  String get usersYouBlocked => 'Users you blocked';

  @override
  String get validEmail => 'Please enter a valid email';

  @override
  String get verificationConclusionCompromised => 'One of the following may be compromised:\n\n   - Your homeserver\n   - The homeserver the user you’re verifying is connected to\n   - Yours, or the other users’ internet connection\n   - Yours, or the other users’ device';

  @override
  String verificationConclusionOkDone(String sender) {
    return 'You’ve successfully verified $sender!';
  }

  @override
  String get verificationConclusionOkSelfNotice => 'Your new session is now verified. It has access to your encrypted messages, and other users will see it as trusted.';

  @override
  String get verificationEmojiNotice => 'Compare the unique emoji, ensuring they appear in the same order.';

  @override
  String get verificationRequestAccept => 'To proceed, please accept the verification request on your other device.';

  @override
  String verificationRequestWaitingFor(String sender) {
    return 'Waiting for $sender…';
  }

  @override
  String get verificationSasDoNotMatch => 'They don’t match';

  @override
  String get verificationSasMatch => 'They match';

  @override
  String get verificationScanEmojiTitle => 'Can’t scan';

  @override
  String get verificationScanSelfEmojiSubtitle => 'Verify by comparing emoji instead';

  @override
  String get verificationScanSelfNotice => 'Scan the code with your other device or switch and scan with this device';

  @override
  String get verified => 'Verified';

  @override
  String get verifiedSessionsDescription => 'All your devices are verified. Your account is secure.';

  @override
  String get verifyOtherSession => 'Verify other session';

  @override
  String get verifySession => 'Verify session';

  @override
  String get verifyThisSession => 'Verify this session';

  @override
  String get version => 'Version';

  @override
  String get via => 'via';

  @override
  String get video => 'Video';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get welcomeTo => 'Welcome to ';

  @override
  String get whatToCallThisChat => 'What to call this chat?';

  @override
  String get yes => 'Yes';

  @override
  String get yesLeave => 'Yes, Leave';

  @override
  String get yesPleaseUpdate => 'Yes, please update';

  @override
  String get youAreAbleToJoinThisRoom => 'You can join this';

  @override
  String youAreAboutToBlock(Object userId) {
    return 'You are about to block $userId';
  }

  @override
  String youAreAboutToUnblock(Object userId) {
    return 'You are about to unblock $userId';
  }

  @override
  String get youAreBothIn => 'you are both in ';

  @override
  String get youAreCurrentlyNotConnectedToAnySpaces => 'You are currently not connected to any spaces';

  @override
  String get spaceShortDescription => 'Create or Join a space, to start organizing and collaborating!';

  @override
  String get youAreDoneWithAllYourTasks => 'you are done with all your tasks!';

  @override
  String get youAreNotAMemberOfAnySpaceYet => 'You are not a member of any space yet';

  @override
  String get youAreNotPartOfThisGroup => 'You are not part of this group. Would you like to join?';

  @override
  String get youHaveNoDMsAtTheMoment => 'You have no DMs at the moment';

  @override
  String get youHaveNoUpdates => 'You have no updates';

  @override
  String get youHaveNotCreatedInviteCodes => 'You have not yet created any invite codes';

  @override
  String get youMustSelectSpace => 'You must select a space';

  @override
  String get youNeedBeInvitedToJoinThisRoom => 'You need be invited to join this Chat';

  @override
  String get youNeedToEnterAComment => 'You need to enter a comment';

  @override
  String get youNeedToEnterCustomValueAsNumber => 'You need to enter the custom value as a number.';

  @override
  String youCantExceedPowerLevel(Object powerLevel) {
    return 'You can’t exceed a permission level of $powerLevel';
  }

  @override
  String get yourActiveDevices => 'Your active devices';

  @override
  String get yourPassword => 'Your Password';

  @override
  String get yourSessionHasBeenTerminatedByServer => 'Your session has been terminated by the server, you need to log in again';

  @override
  String get yourTextSlidesMustContainsSomeText => 'Your text slide must contain some text';

  @override
  String get yourSafeAndSecureSpace => 'Your safe and secure space for organizing change.';

  @override
  String adding(Object email) {
    return 'adding $email';
  }

  @override
  String get addTextSlide => 'Add text slide';

  @override
  String get addImageSlide => 'Add image slide';

  @override
  String get addVideoSlide => 'Add video slide';

  @override
  String get acter => 'Acter';

  @override
  String get acterApp => 'Acter App';

  @override
  String get activate => 'Activate';

  @override
  String get changingNotificationMode => 'Changing notification mode…';

  @override
  String get createComment => 'Create Comment';

  @override
  String get createNewPin => 'Create new Pin';

  @override
  String get createNewSpace => 'Create New Space';

  @override
  String get createNewTaskList => 'Create new task list';

  @override
  String get creatingPin => 'Creating pin…';

  @override
  String get deactivateAccount => 'Deactivate Account';

  @override
  String get deletingCode => 'Deleting code';

  @override
  String get dueToday => 'Due today';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String get dueSuccess => 'Due successfully changed';

  @override
  String get endDate => 'End Date';

  @override
  String get endTime => 'End Time';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailAddresses => 'Email Addresses';

  @override
  String get errorParsinLink => 'Parsing Link failed';

  @override
  String errorCreatingPin(Object error) {
    return 'An error occured creating pin $error';
  }

  @override
  String errorLoadingAttachments(Object error) {
    return 'Error loading attachments: $error';
  }

  @override
  String errorLoadingAvatar(Object error) {
    return 'Error loading avatar: $error';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'Error loading profile: $error';
  }

  @override
  String errorLoadingUsers(Object error) {
    return 'Error loading users: $error';
  }

  @override
  String errorLoadingTasks(Object error) {
    return 'Error loading tasks: $error';
  }

  @override
  String errorLoadingSpace(Object error) {
    return 'Error loading space: $error';
  }

  @override
  String errorLoadingRelatedChats(Object error) {
    return 'Error loading related chats: $error';
  }

  @override
  String errorLoadingPin(Object error) {
    return 'Error loading pin: $error';
  }

  @override
  String errorLoadingEventDueTo(Object error) {
    return 'Error loading event due to: $error';
  }

  @override
  String errorLoadingImage(Object error) {
    return 'Error loading image: $error';
  }

  @override
  String errorLoadingRsvpStatus(Object error) {
    return 'Error loading rsvp status: $error';
  }

  @override
  String errorLoadingEmailAddresses(Object error) {
    return 'Error loading email addresses: $error';
  }

  @override
  String errorLoadingMembersCount(Object error) {
    return 'Error loading members count: $error';
  }

  @override
  String errorLoadingTileDueTo(Object error) {
    return 'Error loading tile due to: $error';
  }

  @override
  String errorLoadingMember(Object error, Object memberId) {
    return 'Error loading member: $memberId $error';
  }

  @override
  String errorSendingAttachment(Object error) {
    return 'Error sending attachment: $error';
  }

  @override
  String get eventCreate => 'Create event';

  @override
  String get eventEdit => 'Edit event';

  @override
  String get eventRemove => 'Remove event';

  @override
  String get eventReport => 'Report event';

  @override
  String get eventUpdate => 'Update event';

  @override
  String get eventShare => 'Share event';

  @override
  String failedToAdd(Object error, Object something) {
    return 'Failed to add $something: $error';
  }

  @override
  String failedToChangePin(Object error) {
    return 'Failed to change pin: $error';
  }

  @override
  String failedToChangePowerLevel(Object error) {
    return 'Failed to change permission level: $error';
  }

  @override
  String failedToChangeNotificationMode(Object error) {
    return 'Failed to change notification mode: $error';
  }

  @override
  String failedToChangePushNotificationSettings(Object error) {
    return 'Failed to change push notification settings: $error';
  }

  @override
  String failedToToggleSettingOf(Object error, Object module) {
    return 'Failed to toggle setting of $module: $error';
  }

  @override
  String failedToEditSpace(Object error) {
    return 'Failed to edit space: $error';
  }

  @override
  String failedToAssignSelf(Object error) {
    return 'Failed to assign self: $error';
  }

  @override
  String failedToUnassignSelf(Object error) {
    return 'Failed to unassign self: $error';
  }

  @override
  String failedToSend(Object error) {
    return 'Failed to send: $error';
  }

  @override
  String failedToCreateChat(Object error) {
    return 'Failed to create chat:  $error';
  }

  @override
  String failedToCreateTaskList(Object error) {
    return 'Failed to create task list:  $error';
  }

  @override
  String failedToConfirmToken(Object error) {
    return 'Failed to confirm token: $error';
  }

  @override
  String failedToSubmitEmail(Object error) {
    return 'Failed to submit email: $error';
  }

  @override
  String get failedToDecryptMessage => 'Failed to decrypt message. Re-request session keys';

  @override
  String failedToDeleteAttachment(Object error) {
    return 'Failed to delete attachment due to: $error';
  }

  @override
  String get failedToDetectMimeType => 'Failed to detect mime type';

  @override
  String failedToLeaveRoom(Object error) {
    return 'Failed to leave Chat: $error';
  }

  @override
  String failedToLoadSpace(Object error) {
    return 'Failed to load space: $error';
  }

  @override
  String failedToLoadEvent(Object error) {
    return 'Failed to load event: $error';
  }

  @override
  String failedToLoadInviteCodes(Object error) {
    return 'Failed to load invite codes: $error';
  }

  @override
  String failedToLoadPushTargets(Object error) {
    return 'Failed to load push targets: $error';
  }

  @override
  String failedToLoadEventsDueTo(Object error) {
    return 'Failed to load events due to: $error';
  }

  @override
  String failedToLoadChatsDueTo(Object error) {
    return 'Failed to load chats due to: $error';
  }

  @override
  String failedToShareRoom(Object error) {
    return 'Failed to share this Chat: $error';
  }

  @override
  String get forgotYourPassword => 'Forgot your password?';

  @override
  String get editInviteCode => 'Edit Invite Code';

  @override
  String get createInviteCode => 'Create Invite Code';

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
    return 'Saving code failed: $error';
  }

  @override
  String createInviteCodeFailed(Object error) {
    return 'Creating code failed: $error';
  }

  @override
  String deleteInviteCodeFailed(Object error) {
    return 'Deleting code failed: $error';
  }

  @override
  String get loadingChat => 'Loading chat…';

  @override
  String get loadingCommentsList => 'Loading comments list';

  @override
  String get loadingPin => 'Loading pin';

  @override
  String get loadingRoom => 'Loading Chat';

  @override
  String get loadingRsvpStatus => 'Loading rsvp status';

  @override
  String get loadingTargets => 'Loading targets';

  @override
  String get loadingOtherChats => 'Loading other chats';

  @override
  String get loadingFirstSync => 'Loading first sync';

  @override
  String get loadingImage => 'Loading image';

  @override
  String get loadingVideo => 'Loading video';

  @override
  String loadingEventsFailed(Object error) {
    return 'Loading events failed: $error';
  }

  @override
  String loadingTasksFailed(Object error) {
    return 'Loading tasks failed: $error';
  }

  @override
  String loadingSpacesFailed(Object error) {
    return 'Loading spaces failed: $error';
  }

  @override
  String loadingRoomFailed(Object error) {
    return 'Loading Chat failed: $error';
  }

  @override
  String loadingMembersCountFailed(Object error) {
    return 'Loading members count failed: $error';
  }

  @override
  String get longPressToActivate => 'long press to activate';

  @override
  String get pinCreatedSuccessfully => 'Pin created successfully';

  @override
  String get pleaseSelectValidEndTime => 'Please select valid end time';

  @override
  String get pleaseSelectValidEndDate => 'Please select valid end date';

  @override
  String powerLevelSubmitted(Object module) {
    return 'Permissionlevel update for $module submitted';
  }

  @override
  String get optionalParentSpace => 'Optional Parent Space';

  @override
  String redeeming(Object token) {
    return 'Redeeming $token';
  }

  @override
  String get encryptedDMChat => 'Encrypted DM Chat';

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
  String get regularSpaceOrChat => 'Regular Space or Chat';

  @override
  String get encryptedSpaceOrChat => 'Encrypted Space or Chat';

  @override
  String get encryptedChatInfo => 'All messages in this chat are end-to-end encrypted. No one outside of this chat, not even Acter or any Matrix Server routing the message, can read them.';

  @override
  String get removeThisPin => 'Remove this Pin';

  @override
  String get removeThisPost => 'Remove this post';

  @override
  String get removingContent => 'Removing content';

  @override
  String get removingAttachment => 'Removing attachment';

  @override
  String get reportThis => 'Report this';

  @override
  String get reportThisPin => 'Report this Pin';

  @override
  String reportSendingFailedDueTo(Object error) {
    return 'Report sending failed due to some: $error';
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
  String get sharedSuccessfully => 'Shared successfully';

  @override
  String get changedPushNotificationSettingsSuccessfully => 'Changed push notification settings successfully';

  @override
  String get startDateRequired => 'Start date required!';

  @override
  String get startTimeRequired => 'Start time required!';

  @override
  String get endDateRequired => 'End date required!';

  @override
  String get endTimeRequired => 'End time required!';

  @override
  String get searchUser => 'search user';

  @override
  String seeAllMyEvents(Object count) {
    return 'See all my $count events';
  }

  @override
  String get selectSpace => 'Select Space';

  @override
  String get selectChat => 'Select Chat';

  @override
  String get selectCustomDate => 'Select specific date';

  @override
  String get selectPicture => 'Select Picture';

  @override
  String get selectVideo => 'Select Video';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get sendDM => 'Send DM';

  @override
  String get showMore => 'show more';

  @override
  String get showLess => 'show less';

  @override
  String get joinSpace => 'Join Space';

  @override
  String get joinExistingSpace => 'Join Existing Space';

  @override
  String get mySpaces => 'My Spaces';

  @override
  String get startDate => 'Start Date';

  @override
  String get startTime => 'Start Time';

  @override
  String get startGroupDM => 'Start Group DM';

  @override
  String get moreSubspaces => 'More Subspaces';

  @override
  String get myTasks => 'My Tasks';

  @override
  String updatingDueFailed(Object error) {
    return 'Updating due failed: $error';
  }

  @override
  String get unlinkRoom => 'Unlink Chat';

  @override
  String changeThePowerFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'from $memberStatus $currentPowerLevel to';
  }

  @override
  String get createOrJoinSpaceDescription => 'Create or join a space, to start organizing and collaborating!';

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
  String get logOutConformationDescription1 => 'Attention: ';

  @override
  String get logOutConformationDescription2 => 'Logging out removes the local data, including encryption keys. If this is your last signed-in device you might no be able to decrypt any previous content.';

  @override
  String get logOutConformationDescription3 => ' Are you sure you want to log out?';

  @override
  String membersCount(Object count) {
    return '$count Members';
  }

  @override
  String get renderSyncingTitle => 'Syncing with your homeserver';

  @override
  String get renderSyncingSubTitle => 'This might take a while if you have a large account';

  @override
  String errorSyncing(Object error) {
    return 'Error syncing: $error';
  }

  @override
  String get retrying => 'retrying …';

  @override
  String retryIn(Object minutes, Object seconds) {
    return 'Will retry in $minutes:$seconds';
  }

  @override
  String get invitations => 'Invitations';

  @override
  String invitingLoading(Object userId) {
    return 'Inviting $userId';
  }

  @override
  String invitingError(Object error, Object userId) {
    return 'User $userId not found or existing: $error';
  }

  @override
  String get invite => 'Invite';

  @override
  String errorUnverifiedSessions(Object error) {
    return 'Couldn’t load unverified sessions: $error';
  }

  @override
  String unverifiedSessionsTitle(Object count) {
    return 'There are $count unverified sessions logged in';
  }

  @override
  String get review => 'Review';

  @override
  String get activities => 'Activities';

  @override
  String get activitiesDescription => 'All the important stuff requiring your attention can be found here';

  @override
  String get noActivityTitle => 'No Activity for you yet';

  @override
  String get noActivitySubtitle => 'Notifies you about important things such as messages, invitations or requests.';

  @override
  String get joining => 'Joining';

  @override
  String get joinedDelayed => 'Accepted invitation, confirmation takes its time though';

  @override
  String get rejecting => 'Rejecting';

  @override
  String get rejected => 'Rejected';

  @override
  String get failedToReject => 'Failed to reject';

  @override
  String reportedBugSuccessful(Object issueId) {
    return 'Reported the bug successfully! (#$issueId)';
  }

  @override
  String get thanksForReport => 'Thanks for reporting that bug!';

  @override
  String bugReportingError(Object error) {
    return 'Bug reporting error: $error';
  }

  @override
  String get bugReportTitle => 'Report a problem';

  @override
  String get bugReportDescription => 'Brief description of the issue';

  @override
  String get emptyDescription => 'Please enter description';

  @override
  String get includeUserId => 'Include my Matrix ID';

  @override
  String get includeLog => 'Include current logs';

  @override
  String get includePrevLog => 'Include logs from previous run';

  @override
  String get includeScreenshot => 'Include screenshot';

  @override
  String get includeErrorAndStackTrace => 'Include Error & Stacktrace';

  @override
  String get jumpTo => 'jump to';

  @override
  String get noMatchingPinsFound => 'no matching pins found';

  @override
  String get update => 'Update';

  @override
  String get event => 'Event';

  @override
  String get taskList => 'Task List';

  @override
  String get pin => 'Pin';

  @override
  String get poll => 'Poll';

  @override
  String get discussion => 'Discussion';

  @override
  String get fatalError => 'Fatal Error';

  @override
  String get nukeLocalData => 'Nuke local data';

  @override
  String get reportBug => 'Report bug';

  @override
  String get somethingWrong => 'Something went terribly wrong:';

  @override
  String get copyToClipboard => 'Copy to clipboard';

  @override
  String get errorCopiedToClipboard => 'Error & Stacktrace copied to clipboard';

  @override
  String get showStacktrace => 'Show Stacktrace';

  @override
  String get hideStacktrace => 'Hide Stacktrace';

  @override
  String get sharingRoom => 'Sharing this Chat…';

  @override
  String get changingSettings => 'Changing settings…';

  @override
  String changingSettingOf(Object module) {
    return 'Changing setting of $module';
  }

  @override
  String changedSettingOf(Object module) {
    return 'Changed setting of $module';
  }

  @override
  String changingPowerLevelOf(Object module) {
    return 'Changing permission level of $module';
  }

  @override
  String get assigningSelf => 'Assigning self…';

  @override
  String get unassigningSelf => 'Unassigning self…';

  @override
  String get homeTabTutorialTitle => 'Dashboard';

  @override
  String get homeTabTutorialDescription => 'Here you find your spaces and an overview of all upcoming events & pending tasks of these spaces.';

  @override
  String get updatesTabTutorialTitle => 'Updates';

  @override
  String get updatesTabTutorialDescription => 'News stream on the latest updates & calls to action from your spaces.';

  @override
  String get chatsTabTutorialTitle => 'Chats';

  @override
  String get chatsTabTutorialDescription => 'It’s the place to chat – with groups or individuals. chats can be linked to different spaces for broader collaboration.';

  @override
  String get activityTabTutorialTitle => 'Activity';

  @override
  String get activityTabTutorialDescription => 'Important information from your spaces, like invitations or requests. Additionally you will get notified by Acter about security issues';

  @override
  String get jumpToTabTutorialTitle => 'Jump To';

  @override
  String get jumpToTabTutorialDescription => 'Your search over spaces and pins, as well as quick actions and fast access to several sections';

  @override
  String get createSpaceTutorialTitle => 'Create New Space';

  @override
  String get createSpaceTutorialDescription => 'Join an existing space on our Acter server or in the Matrix universe or set up your own space.';

  @override
  String get joinSpaceTutorialTitle => 'Join Existing Space';

  @override
  String get joinSpaceTutorialDescription => 'Join an existing space on our Acter server or in the Matrix universe or set up your own space. [would just show the options & end there for now]';

  @override
  String get spaceOverviewTutorialTitle => 'Space Details';

  @override
  String get spaceOverviewTutorialDescription => 'A space is the starting point for your organizing. Create & navigate through pins (resources), tasks and events. Add chats or subspaces.';

  @override
  String get subscribedToParentMsg => 'Disable Notifications on main object to configure notification here';

  @override
  String get parentSubscribedAction => 'Notifications active through object';

  @override
  String get subscribeAction => 'Activate Notifications';

  @override
  String get unsubscribeAction => 'De-Activate Notifications';

  @override
  String get commentEmptyStateTitle => 'No comments found.';

  @override
  String get commentEmptyStateAction => 'Leave the first comment';

  @override
  String get previous => 'Previous';

  @override
  String get finish => 'Finish';

  @override
  String get saveUsernameTitle => 'Have you saved your username?';

  @override
  String get saveUsernameDescription1 => 'Please remember to note down your username. It’s your key to access your profile and all information and spaces connected to it.';

  @override
  String get saveUsernameDescription2 => 'Your username is crucial for password resets.';

  @override
  String get saveUsernameDescription3 => 'Without it, access to your profile and progress will be permanently lost.';

  @override
  String get acterUsername => 'Your Acter Username';

  @override
  String get autoSubscribeFeatureDesc => 'upon creation or interaction with objects';

  @override
  String get autoSubscribeSettingsTitle => 'Automatically subscribe ';

  @override
  String get copyToClip => 'Copy to Clipboard';

  @override
  String get wizzardContinue => 'Continue';

  @override
  String get protectPrivacyTitle => 'Protecting your privacy';

  @override
  String get protectPrivacyDescription1 => 'In Acter, keeping your account secure is important. That’s why you can use it without linking your profile to your email for added privacy and protection.';

  @override
  String get protectPrivacyDescription2 => 'But if you prefer, you can still link them together, e.g., for password recovery.';

  @override
  String get linkEmailToProfile => 'Linked Email to Profile';

  @override
  String get emailOptional => 'Email (Optional)';

  @override
  String get hintEmail => 'Enter your email address';

  @override
  String get linkingEmailAddress => 'Linking your email address';

  @override
  String get avatarAddTitle => 'Add User Avatar';

  @override
  String get avatarEmpty => 'Please select your avatar';

  @override
  String get avatarUploading => 'Uploading profile avatar';

  @override
  String avatarUploadFailed(Object error) {
    return 'Failed to upload user avatar: $error';
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
  String get unableToLoadFile => 'Unable to load file';
}
