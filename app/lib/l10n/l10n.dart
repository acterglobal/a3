import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_ar.dart';
import 'l10n_da.dart';
import 'l10n_de.dart';
import 'l10n_en.dart';
import 'l10n_es.dart';
import 'l10n_fr.dart';
import 'l10n_pl.dart';
import 'l10n_sw.dart';
import 'l10n_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
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
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('da'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('pl'),
    Locale('sw'),
    Locale('ur')
  ];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @acceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept Request'**
  String get acceptRequest;

  /// No description provided for @access.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get access;

  /// No description provided for @accessAndVisibility.
  ///
  /// In en, this message translates to:
  /// **'Access & Visibility'**
  String get accessAndVisibility;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @actionName.
  ///
  /// In en, this message translates to:
  /// **'Action name'**
  String get actionName;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @activateFeatureDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate {feature}?'**
  String activateFeatureDialogTitle(Object feature);

  /// No description provided for @activateFeatureDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow anyone with permission following permissions to use {feature}'**
  String activateFeatureDialogDesc(Object feature);

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'add'**
  String get add;

  /// No description provided for @addActionWidget.
  ///
  /// In en, this message translates to:
  /// **'Add an action widget'**
  String get addActionWidget;

  /// No description provided for @addChat.
  ///
  /// In en, this message translates to:
  /// **'Add Chat'**
  String get addChat;

  /// No description provided for @addedToPusherList.
  ///
  /// In en, this message translates to:
  /// **'{email} added to pusher list'**
  String addedToPusherList(Object email);

  /// No description provided for @addedToSpacesAndChats.
  ///
  /// In en, this message translates to:
  /// **'Added to {number} spaces & chats'**
  String addedToSpacesAndChats(Object number);

  /// No description provided for @addingEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Adding email address'**
  String get addingEmailAddress;

  /// No description provided for @addSpace.
  ///
  /// In en, this message translates to:
  /// **'Add Space'**
  String get addSpace;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allMessages.
  ///
  /// In en, this message translates to:
  /// **'All Messages'**
  String get allMessages;

  /// No description provided for @allReactionsCount.
  ///
  /// In en, this message translates to:
  /// **'All {total}'**
  String allReactionsCount(Object total);

  /// No description provided for @alreadyConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Already confirmed'**
  String get alreadyConfirmed;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Help us help you'**
  String get analyticsTitle;

  /// No description provided for @analyticsDescription1.
  ///
  /// In en, this message translates to:
  /// **'By sharing crash analytics and error reports with us.'**
  String get analyticsDescription1;

  /// No description provided for @analyticsDescription2.
  ///
  /// In en, this message translates to:
  /// **'These are of course anonymized and do not contain any private information'**
  String get analyticsDescription2;

  /// No description provided for @sendCrashReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Send crash & error reports'**
  String get sendCrashReportsTitle;

  /// No description provided for @sendCrashReportsInfo.
  ///
  /// In en, this message translates to:
  /// **'Share crash tracebacks via sentry with the Acter team automatically'**
  String get sendCrashReportsInfo;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @anInviteCodeYouWantToRedeem.
  ///
  /// In en, this message translates to:
  /// **'An invite code you want to redeem'**
  String get anInviteCodeYouWantToRedeem;

  /// No description provided for @anyNumber.
  ///
  /// In en, this message translates to:
  /// **'any number'**
  String get anyNumber;

  /// No description provided for @appDefaults.
  ///
  /// In en, this message translates to:
  /// **'App Defaults'**
  String get appDefaults;

  /// No description provided for @appId.
  ///
  /// In en, this message translates to:
  /// **'AppId'**
  String get appId;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get appName;

  /// No description provided for @apps.
  ///
  /// In en, this message translates to:
  /// **'Space Features'**
  String get apps;

  /// No description provided for @areYouSureYouWantToDeleteThisMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message? This action cannot be undone.'**
  String get areYouSureYouWantToDeleteThisMessage;

  /// No description provided for @areYouSureYouWantToLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave chat? This action cannot be undone'**
  String get areYouSureYouWantToLeaveRoom;

  /// No description provided for @areYouSureYouWantToLeaveSpace.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave this space?'**
  String get areYouSureYouWantToLeaveSpace;

  /// No description provided for @areYouSureYouWantToRemoveAttachmentFromPin.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this attachment from pin?'**
  String get areYouSureYouWantToRemoveAttachmentFromPin;

  /// No description provided for @areYouSureYouWantToUnregisterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unregister this email address? This action cannot be undone.'**
  String get areYouSureYouWantToUnregisterEmailAddress;

  /// No description provided for @assignedYourself.
  ///
  /// In en, this message translates to:
  /// **'assigned yourself'**
  String get assignedYourself;

  /// No description provided for @assignmentWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Assignment withdrawn'**
  String get assignmentWithdrawn;

  /// No description provided for @aTaskMustHaveATitle.
  ///
  /// In en, this message translates to:
  /// **'A task must have a title'**
  String get aTaskMustHaveATitle;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @atThisMomentYouAreNotJoiningEvents.
  ///
  /// In en, this message translates to:
  /// **'At this moment, you are not joining any upcoming events. To find out what events are scheduled, check your spaces.'**
  String get atThisMomentYouAreNotJoiningEvents;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authenticationRequired;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @awaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get awaitingConfirmation;

  /// No description provided for @awaitingConfirmationDescription.
  ///
  /// In en, this message translates to:
  /// **'These email addresses have not yet been confirmed. Please go to your inbox and check for the confirmation link.'**
  String get awaitingConfirmationDescription;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @blockInfoText.
  ///
  /// In en, this message translates to:
  /// **'Once blocked you won’t see their messages anymore and it will block their attempt to contact you directly.'**
  String get blockInfoText;

  /// No description provided for @blockingUserFailed.
  ///
  /// In en, this message translates to:
  /// **'Blocking User failed: {error}'**
  String blockingUserFailed(Object error);

  /// No description provided for @blockingUserProgress.
  ///
  /// In en, this message translates to:
  /// **'Blocking User'**
  String get blockingUserProgress;

  /// No description provided for @blockingUserSuccess.
  ///
  /// In en, this message translates to:
  /// **'User blocked. It might takes a bit before the UI reflects this update.'**
  String get blockingUserSuccess;

  /// No description provided for @blockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {userId}'**
  String blockTitle(Object userId);

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @blockUserOptional.
  ///
  /// In en, this message translates to:
  /// **'Block User (optional)'**
  String get blockUserOptional;

  /// No description provided for @blockUserWithUsername.
  ///
  /// In en, this message translates to:
  /// **'Block user with username'**
  String get blockUserWithUsername;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get bookmarked;

  /// No description provided for @bookmarkedSpaces.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked Spaces'**
  String get bookmarkedSpaces;

  /// No description provided for @builtOnShouldersOfGiants.
  ///
  /// In en, this message translates to:
  /// **'Built on the shoulders of giants'**
  String get builtOnShouldersOfGiants;

  /// No description provided for @calendarEventsFromAllTheSpaces.
  ///
  /// In en, this message translates to:
  /// **'Calendar events from all the Spaces you are part of'**
  String get calendarEventsFromAllTheSpaces;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @calendarSyncFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar Sync'**
  String get calendarSyncFeatureTitle;

  /// No description provided for @calendarSyncFeatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync (tentative and accepted) events with device calendar (Android & iOS only)'**
  String get calendarSyncFeatureDesc;

  /// No description provided for @syncThisCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Include in Calendar Sync'**
  String get syncThisCalendarTitle;

  /// No description provided for @syncThisCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync these events in the device calendar'**
  String get syncThisCalendarDesc;

  /// No description provided for @systemLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'System Links'**
  String get systemLinksTitle;

  /// No description provided for @systemLinksExplainer.
  ///
  /// In en, this message translates to:
  /// **'What to do when a link is pressed'**
  String get systemLinksExplainer;

  /// No description provided for @systemLinksOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get systemLinksOpen;

  /// No description provided for @systemLinksCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get systemLinksCopy;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cannotEditSpaceWithNoPermissions.
  ///
  /// In en, this message translates to:
  /// **'Cannot edit space with no permissions'**
  String get cannotEditSpaceWithNoPermissions;

  /// No description provided for @changeAppLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change App Language'**
  String get changeAppLanguage;

  /// No description provided for @changePowerLevel.
  ///
  /// In en, this message translates to:
  /// **'Change Permission Level'**
  String get changePowerLevel;

  /// No description provided for @changeThePowerLevelOf.
  ///
  /// In en, this message translates to:
  /// **'Change the permission level of'**
  String get changeThePowerLevelOf;

  /// No description provided for @changeYourDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Change your display name'**
  String get changeYourDisplayName;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @chatNG.
  ///
  /// In en, this message translates to:
  /// **'Next-Generation Chat'**
  String get chatNG;

  /// No description provided for @chatNGExplainer.
  ///
  /// In en, this message translates to:
  /// **'Switch to next generation Chat. Features might not be stable'**
  String get chatNGExplainer;

  /// No description provided for @customizationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customizations'**
  String get customizationsTitle;

  /// No description provided for @chatMissingPermissionsToSend.
  ///
  /// In en, this message translates to:
  /// **'You don’t have permissions to sent messages here'**
  String get chatMissingPermissionsToSend;

  /// No description provided for @behaviorSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Behavior'**
  String get behaviorSettingsTitle;

  /// No description provided for @behaviorSettingsExplainer.
  ///
  /// In en, this message translates to:
  /// **'Configure the behavior of your App'**
  String get behaviorSettingsExplainer;

  /// No description provided for @chatSettingsAutoDownload.
  ///
  /// In en, this message translates to:
  /// **'Auto Download Media'**
  String get chatSettingsAutoDownload;

  /// No description provided for @chatSettingsAutoDownloadExplainer.
  ///
  /// In en, this message translates to:
  /// **'When to automatically download media'**
  String get chatSettingsAutoDownloadExplainer;

  /// No description provided for @chatSettingsAutoDownloadAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get chatSettingsAutoDownloadAlways;

  /// No description provided for @chatSettingsAutoDownloadWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Only when on WiFi'**
  String get chatSettingsAutoDownloadWifiOnly;

  /// No description provided for @chatSettingsAutoDownloadNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get chatSettingsAutoDownloadNever;

  /// No description provided for @settingsSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting Settings'**
  String get settingsSubmitting;

  /// No description provided for @settingsSubmittingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Settings submitted'**
  String get settingsSubmittingSuccess;

  /// No description provided for @settingsSubmittingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit: {error} '**
  String settingsSubmittingFailed(Object error);

  /// No description provided for @chatRoomCreated.
  ///
  /// In en, this message translates to:
  /// **'Chat Created'**
  String get chatRoomCreated;

  /// No description provided for @chatSendingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sent. Will retry…'**
  String get chatSendingFailed;

  /// No description provided for @chatSettingsTyping.
  ///
  /// In en, this message translates to:
  /// **'Send typing notifications'**
  String get chatSettingsTyping;

  /// No description provided for @chatSettingsTypingExplainer.
  ///
  /// In en, this message translates to:
  /// **'(soon) Inform others when you are typing'**
  String get chatSettingsTypingExplainer;

  /// No description provided for @chatSettingsReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Send read receipts'**
  String get chatSettingsReadReceipts;

  /// No description provided for @chatSettingsReadReceiptsExplainer.
  ///
  /// In en, this message translates to:
  /// **'(soon) Inform others when you read a message'**
  String get chatSettingsReadReceiptsExplainer;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @claimedTimes.
  ///
  /// In en, this message translates to:
  /// **'Claimed {count} times'**
  String claimedTimes(Object count);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearDBAndReLogin.
  ///
  /// In en, this message translates to:
  /// **'Clear DB and re-login'**
  String get clearDBAndReLogin;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @closeDialog.
  ///
  /// In en, this message translates to:
  /// **'Close Dialog'**
  String get closeDialog;

  /// No description provided for @closeSessionAndDeleteData.
  ///
  /// In en, this message translates to:
  /// **'Close this session, deleting local data'**
  String get closeSessionAndDeleteData;

  /// No description provided for @closeSpace.
  ///
  /// In en, this message translates to:
  /// **'Close Space'**
  String get closeSpace;

  /// No description provided for @closeChat.
  ///
  /// In en, this message translates to:
  /// **'Close Chat'**
  String get closeChat;

  /// No description provided for @closingRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Close this Room'**
  String get closingRoomTitle;

  /// No description provided for @closingRoomTitleDescription.
  ///
  /// In en, this message translates to:
  /// **'When closing this room, we will :\n\n - Remove everyone with a lower permission level then yours from it\n - Remove it as a child from the parent spaces (where you have the permissions to do so),\n - Set the invite rule to \'private\'\n - You will leave the room.\n\nThis can not be undone. Are you sure you want to close this?'**
  String get closingRoomTitleDescription;

  /// No description provided for @closingRoom.
  ///
  /// In en, this message translates to:
  /// **'Closing…'**
  String get closingRoom;

  /// No description provided for @closingRoomRemovingMembers.
  ///
  /// In en, this message translates to:
  /// **'Closing in process. Removing member {kicked} / {total}'**
  String closingRoomRemovingMembers(Object kicked, Object total);

  /// No description provided for @closingRoomMatrixMsg.
  ///
  /// In en, this message translates to:
  /// **'The room was closed'**
  String get closingRoomMatrixMsg;

  /// No description provided for @closingRoomRemovingFromParents.
  ///
  /// In en, this message translates to:
  /// **'Closing in process. Removing room from parent {currentParent} / {totalParents}'**
  String closingRoomRemovingFromParents(Object currentParent, Object totalParents);

  /// No description provided for @closingRoomDoneBut.
  ///
  /// In en, this message translates to:
  /// **'Closed and you’ve left. But was unable to remove {skipped} other Users and remove it as child from {skippedParents} Spaces due to lack of permission. Others might still have access to it.'**
  String closingRoomDoneBut(Object skipped, Object skippedParents);

  /// No description provided for @closingRoomDone.
  ///
  /// In en, this message translates to:
  /// **'Closed successfully.'**
  String get closingRoomDone;

  /// No description provided for @closingRoomFailed.
  ///
  /// In en, this message translates to:
  /// **'Closing failed: {error}'**
  String closingRoomFailed(Object error);

  /// No description provided for @coBudget.
  ///
  /// In en, this message translates to:
  /// **'CoBudget'**
  String get coBudget;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @codeMustBeAtLeast6CharactersLong.
  ///
  /// In en, this message translates to:
  /// **'Code must be at least 6 characters long'**
  String get codeMustBeAtLeast6CharactersLong;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @commentsListError.
  ///
  /// In en, this message translates to:
  /// **'Comments list error: {error}'**
  String commentsListError(Object error);

  /// No description provided for @commentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Comment submitted'**
  String get commentSubmitted;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @confirmationToken.
  ///
  /// In en, this message translates to:
  /// **'Confirmation Token'**
  String get confirmationToken;

  /// No description provided for @confirmedEmailAddresses.
  ///
  /// In en, this message translates to:
  /// **'Confirmed Email Addresses'**
  String get confirmedEmailAddresses;

  /// No description provided for @confirmedEmailAddressesDescription.
  ///
  /// In en, this message translates to:
  /// **'Confirmed emails addresses connected to your account:'**
  String get confirmedEmailAddressesDescription;

  /// No description provided for @confirmWithToken.
  ///
  /// In en, this message translates to:
  /// **'Confirm with Token'**
  String get confirmWithToken;

  /// No description provided for @congrats.
  ///
  /// In en, this message translates to:
  /// **'Congrats!'**
  String get congrats;

  /// No description provided for @connectedToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Connected to your account'**
  String get connectedToYourAccount;

  /// No description provided for @contentSuccessfullyRemoved.
  ///
  /// In en, this message translates to:
  /// **'Content successfully removed'**
  String get contentSuccessfullyRemoved;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @continueQuestion.
  ///
  /// In en, this message translates to:
  /// **'Continue?'**
  String get continueQuestion;

  /// No description provided for @copyUsername.
  ///
  /// In en, this message translates to:
  /// **'Copy username'**
  String get copyUsername;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyMessage;

  /// No description provided for @couldNotFetchNews.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t fetch news'**
  String get couldNotFetchNews;

  /// No description provided for @couldNotLoadAllSessions.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load all sessions'**
  String get couldNotLoadAllSessions;

  /// No description provided for @couldNotLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not load image due to {error}'**
  String couldNotLoadImage(Object error);

  /// No description provided for @countsMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} Members'**
  String countsMembers(Object count);

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createChat.
  ///
  /// In en, this message translates to:
  /// **'Create Chat'**
  String get createChat;

  /// No description provided for @createCode.
  ///
  /// In en, this message translates to:
  /// **'Create Code'**
  String get createCode;

  /// No description provided for @createDefaultChat.
  ///
  /// In en, this message translates to:
  /// **'Create default chat room, too'**
  String get createDefaultChat;

  /// No description provided for @defaultChatName.
  ///
  /// In en, this message translates to:
  /// **'{name} chat'**
  String defaultChatName(Object name);

  /// No description provided for @createDMWhenRedeeming.
  ///
  /// In en, this message translates to:
  /// **'Create DM when redeeming'**
  String get createDMWhenRedeeming;

  /// No description provided for @createEventAndBringYourCommunity.
  ///
  /// In en, this message translates to:
  /// **'Create new event and bring your community together'**
  String get createEventAndBringYourCommunity;

  /// No description provided for @createGroupChat.
  ///
  /// In en, this message translates to:
  /// **'Create Group Chat'**
  String get createGroupChat;

  /// No description provided for @createPin.
  ///
  /// In en, this message translates to:
  /// **'Create Pin'**
  String get createPin;

  /// No description provided for @createPostsAndEngageWithinSpace.
  ///
  /// In en, this message translates to:
  /// **'Create actionable posts and engage everyone within your space.'**
  String get createPostsAndEngageWithinSpace;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @createSpace.
  ///
  /// In en, this message translates to:
  /// **'Create Space'**
  String get createSpace;

  /// No description provided for @createSpaceChat.
  ///
  /// In en, this message translates to:
  /// **'Create Space Chat'**
  String get createSpaceChat;

  /// No description provided for @createSubspace.
  ///
  /// In en, this message translates to:
  /// **'Create Subspace'**
  String get createSubspace;

  /// No description provided for @createTaskList.
  ///
  /// In en, this message translates to:
  /// **'Create task list'**
  String get createTaskList;

  /// No description provided for @createAcopy.
  ///
  /// In en, this message translates to:
  /// **'Copy as new'**
  String get createAcopy;

  /// No description provided for @creatingCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Creating Calendar Event'**
  String get creatingCalendarEvent;

  /// No description provided for @creatingChat.
  ///
  /// In en, this message translates to:
  /// **'Creating Chat'**
  String get creatingChat;

  /// No description provided for @creatingCode.
  ///
  /// In en, this message translates to:
  /// **'Creating code'**
  String get creatingCode;

  /// No description provided for @creatingNewsFailed.
  ///
  /// In en, this message translates to:
  /// **'Creating update failed {error}'**
  String creatingNewsFailed(Object error);

  /// No description provided for @creatingSpace.
  ///
  /// In en, this message translates to:
  /// **'Creating Space'**
  String get creatingSpace;

  /// No description provided for @creatingSpaceFailed.
  ///
  /// In en, this message translates to:
  /// **'Creating space failed: {error}'**
  String creatingSpaceFailed(Object error);

  /// No description provided for @creatingTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Creating Task failed {error}'**
  String creatingTaskFailed(Object error);

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @customizeAppsAndTheirFeatures.
  ///
  /// In en, this message translates to:
  /// **'Customize the features needed for this space'**
  String get customizeAppsAndTheirFeatures;

  /// No description provided for @customPowerLevel.
  ///
  /// In en, this message translates to:
  /// **'Custom permission  level'**
  String get customPowerLevel;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @deactivateAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'If you proceed:\n\n - All your personal data will be removed from your homeserver, including display name and avatar \n - All your sessions will be closed immediately, no other device will be able to continue their sessions \n - You will leave all rooms, chats, spaces and DMs that you are in \n - You will not be able to reactivate your account \n - You will no longer be able to log in \n - No one will be able to reuse your username (MXID), including you: this username will remain unavailable indefinitely \n - You will be removed from the identity server, if you provided any information to be found through that (e.g. email or phone number) \n - All local data, including any encryption keys, will be permanently deleted from this device \n - Your old messages will still be visible to people who received them, just like emails you sent in the past. \n\n You will not be able to reverse any of this. This is a permanent and irrevocable action.'**
  String get deactivateAccountDescription;

  /// No description provided for @deactivateAccountPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Please provide your user password to confirm you want to deactivate your account.'**
  String get deactivateAccountPasswordTitle;

  /// No description provided for @deactivateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Careful: You are about to permanently deactivate your account'**
  String get deactivateAccountTitle;

  /// No description provided for @deactivatingFailed.
  ///
  /// In en, this message translates to:
  /// **'Deactivating failed: \n {error}'**
  String deactivatingFailed(Object error);

  /// No description provided for @deactivatingYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivating your account'**
  String get deactivatingYourAccount;

  /// No description provided for @deactivationAndRemovingFailed.
  ///
  /// In en, this message translates to:
  /// **'Deactivation and removing all local data failed'**
  String get deactivationAndRemovingFailed;

  /// No description provided for @debugInfo.
  ///
  /// In en, this message translates to:
  /// **'Debug Info'**
  String get debugInfo;

  /// No description provided for @debugLevel.
  ///
  /// In en, this message translates to:
  /// **'Debug level'**
  String get debugLevel;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @defaultModes.
  ///
  /// In en, this message translates to:
  /// **'Default Modes'**
  String get defaultModes;

  /// No description provided for @defaultNotification.
  ///
  /// In en, this message translates to:
  /// **'Default {type}'**
  String defaultNotification(Object type);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAttachment.
  ///
  /// In en, this message translates to:
  /// **'Delete attachment'**
  String get deleteAttachment;

  /// No description provided for @deleteCode.
  ///
  /// In en, this message translates to:
  /// **'Delete code'**
  String get deleteCode;

  /// No description provided for @deleteTarget.
  ///
  /// In en, this message translates to:
  /// **'Delete Target'**
  String get deleteTarget;

  /// No description provided for @deleteNewsDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete draft?'**
  String get deleteNewsDraftTitle;

  /// No description provided for @deleteNewsDraftText.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this draft? This can’t be undone.'**
  String get deleteNewsDraftText;

  /// No description provided for @deleteDraftBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get deleteDraftBtn;

  /// No description provided for @deletingPushTarget.
  ///
  /// In en, this message translates to:
  /// **'Deleting push target'**
  String get deletingPushTarget;

  /// No description provided for @deletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed: {error}'**
  String deletionFailed(Object error);

  /// No description provided for @denied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get denied;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device Id'**
  String get deviceId;

  /// No description provided for @deviceIdDigest.
  ///
  /// In en, this message translates to:
  /// **'Device Id Digest'**
  String get deviceIdDigest;

  /// No description provided for @deviceName.
  ///
  /// In en, this message translates to:
  /// **'Device Name'**
  String get deviceName;

  /// No description provided for @devicePlatformException.
  ///
  /// In en, this message translates to:
  /// **'You can’t use the DevicePlatform.device/web in this context. Incorrect platform: SettingsSection.build'**
  String get devicePlatformException;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @displayNameUpdateSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Display name update submitted'**
  String get displayNameUpdateSubmitted;

  /// No description provided for @directInviteUser.
  ///
  /// In en, this message translates to:
  /// **'Directly invite {userId}'**
  String directInviteUser(Object userId);

  /// No description provided for @dms.
  ///
  /// In en, this message translates to:
  /// **'DMs'**
  String get dms;

  /// No description provided for @doYouWantToDeleteInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to irreversibly delete the invite code? It can’t be used again after.'**
  String get doYouWantToDeleteInviteCode;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String due(Object date);

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get dueDate;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get editMessage;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editSpace.
  ///
  /// In en, this message translates to:
  /// **'Edit Space'**
  String get editSpace;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get edited;

  /// No description provided for @egGlobalMovement.
  ///
  /// In en, this message translates to:
  /// **'eg. Global Movement'**
  String get egGlobalMovement;

  /// No description provided for @emailAddressToAdd.
  ///
  /// In en, this message translates to:
  /// **'Email address to add'**
  String get emailAddressToAdd;

  /// No description provided for @emailOrPasswordSeemsNotValid.
  ///
  /// In en, this message translates to:
  /// **'Email or password seems to be not valid.'**
  String get emailOrPasswordSeemsNotValid;

  /// No description provided for @emptyEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter email'**
  String get emptyEmail;

  /// No description provided for @emptyPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter Password'**
  String get emptyPassword;

  /// No description provided for @emptyToken.
  ///
  /// In en, this message translates to:
  /// **'Please enter code'**
  String get emptyToken;

  /// No description provided for @emptyUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter Username'**
  String get emptyUsername;

  /// No description provided for @encrypted.
  ///
  /// In en, this message translates to:
  /// **'Encrypted'**
  String get encrypted;

  /// No description provided for @encryptedSpace.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Space'**
  String get encryptedSpace;

  /// No description provided for @encryptionBackupEnabled.
  ///
  /// In en, this message translates to:
  /// **'Encryption backups enabled'**
  String get encryptionBackupEnabled;

  /// No description provided for @encryptionBackupEnabledExplainer.
  ///
  /// In en, this message translates to:
  /// **'Your keys are stored in an encrypted backup on your home server'**
  String get encryptionBackupEnabledExplainer;

  /// No description provided for @encryptionBackupMissing.
  ///
  /// In en, this message translates to:
  /// **'Encryption backups missing'**
  String get encryptionBackupMissing;

  /// No description provided for @encryptionBackupMissingExplainer.
  ///
  /// In en, this message translates to:
  /// **'We recommend to use automatic encryption key backups'**
  String get encryptionBackupMissingExplainer;

  /// No description provided for @encryptionBackupProvideKey.
  ///
  /// In en, this message translates to:
  /// **'Provide Recovery Key'**
  String get encryptionBackupProvideKey;

  /// No description provided for @encryptionBackupProvideKeyExplainer.
  ///
  /// In en, this message translates to:
  /// **'We have found an automatic encryption backup'**
  String get encryptionBackupProvideKeyExplainer;

  /// No description provided for @encryptionBackupProvideKeyAction.
  ///
  /// In en, this message translates to:
  /// **'Provide Key'**
  String get encryptionBackupProvideKeyAction;

  /// No description provided for @encryptionBackupNoBackup.
  ///
  /// In en, this message translates to:
  /// **'No encryption backup found'**
  String get encryptionBackupNoBackup;

  /// No description provided for @encryptionBackupNoBackupExplainer.
  ///
  /// In en, this message translates to:
  /// **'If you lose access to your account, conversations might become unrecoverable. We recommend enabling automatic encryption backups.'**
  String get encryptionBackupNoBackupExplainer;

  /// No description provided for @encryptionBackupNoBackupAction.
  ///
  /// In en, this message translates to:
  /// **'Enable Backup'**
  String get encryptionBackupNoBackupAction;

  /// No description provided for @encryptionBackupEnabling.
  ///
  /// In en, this message translates to:
  /// **'Enabling backup'**
  String get encryptionBackupEnabling;

  /// No description provided for @encryptionBackupEnablingFailed.
  ///
  /// In en, this message translates to:
  /// **'Enabling backup failed: {error}'**
  String encryptionBackupEnablingFailed(Object error);

  /// No description provided for @encryptionBackupRecovery.
  ///
  /// In en, this message translates to:
  /// **'Your Backup Recover key'**
  String get encryptionBackupRecovery;

  /// No description provided for @encryptionBackupRecoveryExplainer.
  ///
  /// In en, this message translates to:
  /// **'Store this Backup Recovery Key securely.'**
  String get encryptionBackupRecoveryExplainer;

  /// No description provided for @encryptionBackupRecoveryCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Recovery Key copied to clipboard'**
  String get encryptionBackupRecoveryCopiedToClipboard;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing'**
  String get refreshing;

  /// No description provided for @encryptionBackupDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable your Key Backup?'**
  String get encryptionBackupDisable;

  /// No description provided for @encryptionBackupDisableExplainer.
  ///
  /// In en, this message translates to:
  /// **'Resetting the key backup will destroy it locally and on your homeserver. This can’t be undone. Are you sure you want to continue?'**
  String get encryptionBackupDisableExplainer;

  /// No description provided for @encryptionBackupDisableActionKeepIt.
  ///
  /// In en, this message translates to:
  /// **'No, keep it'**
  String get encryptionBackupDisableActionKeepIt;

  /// No description provided for @encryptionBackupDisableActionDestroyIt.
  ///
  /// In en, this message translates to:
  /// **'Yes, destroy it'**
  String get encryptionBackupDisableActionDestroyIt;

  /// No description provided for @encryptionBackupResetting.
  ///
  /// In en, this message translates to:
  /// **'Resetting Backup'**
  String get encryptionBackupResetting;

  /// No description provided for @encryptionBackupResettingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reset successful'**
  String get encryptionBackupResettingSuccess;

  /// No description provided for @encryptionBackupResettingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to disable: {error}'**
  String encryptionBackupResettingFailed(Object error);

  /// No description provided for @encryptionBackupRecover.
  ///
  /// In en, this message translates to:
  /// **'Recover Encryption Backup'**
  String get encryptionBackupRecover;

  /// No description provided for @encryptionBackupRecoverExplainer.
  ///
  /// In en, this message translates to:
  /// **'Provider you recovery key to decrypt the encryption backup'**
  String get encryptionBackupRecoverExplainer;

  /// No description provided for @encryptionBackupRecoverInputHint.
  ///
  /// In en, this message translates to:
  /// **'Recovery key'**
  String get encryptionBackupRecoverInputHint;

  /// No description provided for @encryptionBackupRecoverProvideKey.
  ///
  /// In en, this message translates to:
  /// **'Please provide the key'**
  String get encryptionBackupRecoverProvideKey;

  /// No description provided for @encryptionBackupRecoverAction.
  ///
  /// In en, this message translates to:
  /// **'Recover'**
  String get encryptionBackupRecoverAction;

  /// No description provided for @encryptionBackupRecoverRecovering.
  ///
  /// In en, this message translates to:
  /// **'Recovering'**
  String get encryptionBackupRecoverRecovering;

  /// No description provided for @encryptionBackupRecoverRecoveringSuccess.
  ///
  /// In en, this message translates to:
  /// **'Recovery successful'**
  String get encryptionBackupRecoverRecoveringSuccess;

  /// No description provided for @encryptionBackupRecoverRecoveringImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get encryptionBackupRecoverRecoveringImportFailed;

  /// No description provided for @encryptionBackupRecoverRecoveringFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to recover: {error}'**
  String encryptionBackupRecoverRecoveringFailed(Object error);

  /// No description provided for @encryptionBackupKeyBackup.
  ///
  /// In en, this message translates to:
  /// **'Key backup'**
  String get encryptionBackupKeyBackup;

  /// No description provided for @encryptionBackupKeyBackupExplainer.
  ///
  /// In en, this message translates to:
  /// **'Here you configure the Key Backup'**
  String get encryptionBackupKeyBackupExplainer;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error {error}'**
  String error(Object error);

  /// No description provided for @errorCreatingCalendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Error Creating Calendar Event: {error}'**
  String errorCreatingCalendarEvent(Object error);

  /// No description provided for @errorCreatingChat.
  ///
  /// In en, this message translates to:
  /// **'Error creating chat: {error}'**
  String errorCreatingChat(Object error);

  /// No description provided for @errorSubmittingComment.
  ///
  /// In en, this message translates to:
  /// **'Error submitting comment: {error}'**
  String errorSubmittingComment(Object error);

  /// No description provided for @errorUpdatingEvent.
  ///
  /// In en, this message translates to:
  /// **'Error updating event: {error}'**
  String errorUpdatingEvent(Object error);

  /// No description provided for @eventDescriptionsData.
  ///
  /// In en, this message translates to:
  /// **'Event descriptions data'**
  String get eventDescriptionsData;

  /// No description provided for @eventName.
  ///
  /// In en, this message translates to:
  /// **'Event Name'**
  String get eventName;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @eventTitleData.
  ///
  /// In en, this message translates to:
  /// **'Event title data'**
  String get eventTitleData;

  /// No description provided for @experimentalActerFeatures.
  ///
  /// In en, this message translates to:
  /// **'Experimental Acter features'**
  String get experimentalActerFeatures;

  /// No description provided for @failedToAcceptInvite.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept invite: {error}'**
  String failedToAcceptInvite(Object error);

  /// No description provided for @failedToRejectInvite.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject invite: {error}'**
  String failedToRejectInvite(Object error);

  /// No description provided for @missingStoragePermissions.
  ///
  /// In en, this message translates to:
  /// **'You must grant us permissions to storage to pick an Image file'**
  String get missingStoragePermissions;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'To reset your password, we will send a verification link to your email. Follow the process there and once confirmed, you can reset your password here.'**
  String get forgotPasswordDescription;

  /// No description provided for @forgotPasswordNewPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Once you’ve finished the process behind the link of the email we’ve sent you, you can set a new password here:'**
  String get forgotPasswordNewPasswordDescription;

  /// No description provided for @formatMustBe.
  ///
  /// In en, this message translates to:
  /// **'Format must be @user:server.tld'**
  String get formatMustBe;

  /// No description provided for @foundUsers.
  ///
  /// In en, this message translates to:
  /// **'Found Users'**
  String get foundUsers;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'from'**
  String get from;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @getConversationGoingToStart.
  ///
  /// In en, this message translates to:
  /// **'Get the conversation going to start organizing collaborating'**
  String get getConversationGoingToStart;

  /// No description provided for @getInTouchWithOtherChangeMakers.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with other change makers, organizers or activists and chat directly with them.'**
  String get getInTouchWithOtherChangeMakers;

  /// No description provided for @goToDM.
  ///
  /// In en, this message translates to:
  /// **'Go to DM'**
  String get goToDM;

  /// No description provided for @going.
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get going;

  /// No description provided for @haveProfile.
  ///
  /// In en, this message translates to:
  /// **'Already have a profile?'**
  String get haveProfile;

  /// No description provided for @helpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenterTitle;

  /// No description provided for @helpCenterDesc.
  ///
  /// In en, this message translates to:
  /// **'Get helpful tips about Acter'**
  String get helpCenterDesc;

  /// No description provided for @hereYouCanChangeTheSpaceDetails.
  ///
  /// In en, this message translates to:
  /// **'Here you can change the space details'**
  String get hereYouCanChangeTheSpaceDetails;

  /// No description provided for @hereYouCanSeeAllUsersYouBlocked.
  ///
  /// In en, this message translates to:
  /// **'Here you can see all users you’ve blocked.'**
  String get hereYouCanSeeAllUsersYouBlocked;

  /// No description provided for @hintMessageDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Enter the name you want others to see'**
  String get hintMessageDisplayName;

  /// No description provided for @hintMessageInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your invite code'**
  String get hintMessageInviteCode;

  /// No description provided for @hintMessagePassword.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get hintMessagePassword;

  /// No description provided for @hintMessageUsername.
  ///
  /// In en, this message translates to:
  /// **'Unique username for logging in and identification'**
  String get hintMessageUsername;

  /// No description provided for @homeServerName.
  ///
  /// In en, this message translates to:
  /// **'Home Server Name'**
  String get homeServerName;

  /// No description provided for @homeServerURL.
  ///
  /// In en, this message translates to:
  /// **'Home Server URL'**
  String get homeServerURL;

  /// No description provided for @httpProxy.
  ///
  /// In en, this message translates to:
  /// **'HTTP Proxy'**
  String get httpProxy;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @inConnectedSpaces.
  ///
  /// In en, this message translates to:
  /// **'In connected spaces, you can focus on specific actions or campaigns of your working groups and start organizing.'**
  String get inConnectedSpaces;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @invalidTokenOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid token or password'**
  String get invalidTokenOrPassword;

  /// No description provided for @invitationToChat.
  ///
  /// In en, this message translates to:
  /// **'Invited to join chat by '**
  String get invitationToChat;

  /// No description provided for @invitationToDM.
  ///
  /// In en, this message translates to:
  /// **'Wants to start a DM with you'**
  String get invitationToDM;

  /// No description provided for @invitationToSpace.
  ///
  /// In en, this message translates to:
  /// **'Invited to join space by '**
  String get invitationToSpace;

  /// No description provided for @invited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get invited;

  /// No description provided for @inviteCode.
  ///
  /// In en, this message translates to:
  /// **'Invite Code'**
  String get inviteCode;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get scanQrCode;

  /// No description provided for @shareInviteWithCode.
  ///
  /// In en, this message translates to:
  /// **'Invite {code}'**
  String shareInviteWithCode(Object code);

  /// No description provided for @inviteCodeInfo.
  ///
  /// In en, this message translates to:
  /// **'Acter is still invite-only access. In case you were not given an invite code by a specific group or initiative, use below code to check out Acter.'**
  String get inviteCodeInfo;

  /// No description provided for @irreversiblyDeactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Irreversibly deactivate this account'**
  String get irreversiblyDeactivateAccount;

  /// No description provided for @itsYou.
  ///
  /// In en, this message translates to:
  /// **'This is you'**
  String get itsYou;

  /// No description provided for @join.
  ///
  /// In en, this message translates to:
  /// **'join'**
  String get join;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @joiningFailed.
  ///
  /// In en, this message translates to:
  /// **'Joining failed: {error}'**
  String joiningFailed(Object error);

  /// No description provided for @joinActer.
  ///
  /// In en, this message translates to:
  /// **'Join Acter'**
  String get joinActer;

  /// No description provided for @joinRuleNotSupportedYet.
  ///
  /// In en, this message translates to:
  /// **'Join Rule {role} not supported yet. Sorry'**
  String joinRuleNotSupportedYet(Object role);

  /// No description provided for @kickAndBanFailed.
  ///
  /// In en, this message translates to:
  /// **'Removing & banning user failed: \n {error}'**
  String kickAndBanFailed(Object error);

  /// No description provided for @kickAndBanProgress.
  ///
  /// In en, this message translates to:
  /// **'Removing and Banning user'**
  String get kickAndBanProgress;

  /// No description provided for @kickAndBanSuccess.
  ///
  /// In en, this message translates to:
  /// **'User removed and banned'**
  String get kickAndBanSuccess;

  /// No description provided for @kickAndBanUser.
  ///
  /// In en, this message translates to:
  /// **'Remove & Ban User'**
  String get kickAndBanUser;

  /// No description provided for @kickAndBanUserDescription.
  ///
  /// In en, this message translates to:
  /// **'You are about to remove and permanently ban {userId} from {roomId}'**
  String kickAndBanUserDescription(Object roomId, Object userId);

  /// No description provided for @kickAndBanUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove & Ban User {userId}'**
  String kickAndBanUserTitle(Object userId);

  /// No description provided for @kickFailed.
  ///
  /// In en, this message translates to:
  /// **'Removing user failed: \n {error}'**
  String kickFailed(Object error);

  /// No description provided for @kickProgress.
  ///
  /// In en, this message translates to:
  /// **'Removing user'**
  String get kickProgress;

  /// No description provided for @kickSuccess.
  ///
  /// In en, this message translates to:
  /// **'User removed'**
  String get kickSuccess;

  /// No description provided for @kickUser.
  ///
  /// In en, this message translates to:
  /// **'Remove User'**
  String get kickUser;

  /// No description provided for @kickUserDescription.
  ///
  /// In en, this message translates to:
  /// **'You are about to remove {userId} from {roomId}'**
  String kickUserDescription(Object roomId, Object userId);

  /// No description provided for @kickUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove User {userId}'**
  String kickUserTitle(Object userId);

  /// No description provided for @labs.
  ///
  /// In en, this message translates to:
  /// **'Labs'**
  String get labs;

  /// No description provided for @labsAppFeatures.
  ///
  /// In en, this message translates to:
  /// **'App Features'**
  String get labsAppFeatures;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Leave Chat'**
  String get leaveRoom;

  /// No description provided for @leaveSpace.
  ///
  /// In en, this message translates to:
  /// **'Leave Space'**
  String get leaveSpace;

  /// No description provided for @leavingSpace.
  ///
  /// In en, this message translates to:
  /// **'Leaving Space'**
  String get leavingSpace;

  /// No description provided for @leavingSpaceSuccessful.
  ///
  /// In en, this message translates to:
  /// **'You’ve left the Space'**
  String get leavingSpaceSuccessful;

  /// No description provided for @leavingSpaceFailed.
  ///
  /// In en, this message translates to:
  /// **'Error leaving the space: {error}'**
  String leavingSpaceFailed(Object error);

  /// No description provided for @leavingRoom.
  ///
  /// In en, this message translates to:
  /// **'Leaving Chat'**
  String get leavingRoom;

  /// No description provided for @letsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let’s get started'**
  String get letsGetStarted;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @limitedInternConnection.
  ///
  /// In en, this message translates to:
  /// **'Limited Internet connection'**
  String get limitedInternConnection;

  /// No description provided for @link.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @linkExistingChat.
  ///
  /// In en, this message translates to:
  /// **'Link existing Chat'**
  String get linkExistingChat;

  /// No description provided for @linkExistingSpace.
  ///
  /// In en, this message translates to:
  /// **'Link existing Space'**
  String get linkExistingSpace;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @linkToChat.
  ///
  /// In en, this message translates to:
  /// **'Link to Chat'**
  String get linkToChat;

  /// No description provided for @loadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading failed: {error}'**
  String loadingFailed(Object error);

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @loginAgain.
  ///
  /// In en, this message translates to:
  /// **'Login again'**
  String get loginAgain;

  /// No description provided for @loginContinue.
  ///
  /// In en, this message translates to:
  /// **'Log in and continue organizing from where you last left off.'**
  String get loginContinue;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccess;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logOut;

  /// No description provided for @logSettings.
  ///
  /// In en, this message translates to:
  /// **'Log Settings'**
  String get logSettings;

  /// No description provided for @looksGoodAddressConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Looks good. Address confirmed.'**
  String get looksGoodAddressConfirmed;

  /// No description provided for @makeADifference.
  ///
  /// In en, this message translates to:
  /// **'Unlock your digital organizing.'**
  String get makeADifference;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @manageBudgetsCooperatively.
  ///
  /// In en, this message translates to:
  /// **'Manage budgets cooperatively'**
  String get manageBudgetsCooperatively;

  /// No description provided for @manageYourInvitationCodes.
  ///
  /// In en, this message translates to:
  /// **'Manage your invitation codes'**
  String get manageYourInvitationCodes;

  /// No description provided for @markToHideAllCurrentAndFutureContent.
  ///
  /// In en, this message translates to:
  /// **'Mark to hide all current and future content from this user and block them from contacting you'**
  String get markToHideAllCurrentAndFutureContent;

  /// No description provided for @markedAsDone.
  ///
  /// In en, this message translates to:
  /// **'marked as done'**
  String get markedAsDone;

  /// No description provided for @maybe.
  ///
  /// In en, this message translates to:
  /// **'Maybe'**
  String get maybe;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @memberDescriptionsData.
  ///
  /// In en, this message translates to:
  /// **'Member descriptions data'**
  String get memberDescriptionsData;

  /// No description provided for @memberTitleData.
  ///
  /// In en, this message translates to:
  /// **'Member title data'**
  String get memberTitleData;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @mentionsAndKeywordsOnly.
  ///
  /// In en, this message translates to:
  /// **'Mentions and Keywords only'**
  String get mentionsAndKeywordsOnly;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @messageCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Message copied to clipboard'**
  String get messageCopiedToClipboard;

  /// No description provided for @missingName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your Name'**
  String get missingName;

  /// No description provided for @mobilePushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Mobile Push Notifications'**
  String get mobilePushNotifications;

  /// No description provided for @moderator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get moderator;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @moreRooms.
  ///
  /// In en, this message translates to:
  /// **'+{count} additional rooms'**
  String moreRooms(Object count);

  /// No description provided for @muted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get muted;

  /// No description provided for @customValueMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'You need to enter the custom value as a number.'**
  String get customValueMustBeNumber;

  /// No description provided for @myDashboard.
  ///
  /// In en, this message translates to:
  /// **'My Dashboard'**
  String get myDashboard;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @nameOfTheEvent.
  ///
  /// In en, this message translates to:
  /// **'Name of the event'**
  String get nameOfTheEvent;

  /// No description provided for @needsAppRestartToTakeEffect.
  ///
  /// In en, this message translates to:
  /// **'Needs an app restart to take effect'**
  String get needsAppRestartToTakeEffect;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @newEncryptedMessage.
  ///
  /// In en, this message translates to:
  /// **'New Encrypted Message'**
  String get newEncryptedMessage;

  /// No description provided for @needYourPasswordToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Need your password to confirm'**
  String get needYourPasswordToConfirm;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @newUpdate.
  ///
  /// In en, this message translates to:
  /// **'New Update'**
  String get newUpdate;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @noChatsFound.
  ///
  /// In en, this message translates to:
  /// **'no chats found'**
  String get noChatsFound;

  /// No description provided for @noChatsFoundMatchingYourFilter.
  ///
  /// In en, this message translates to:
  /// **'No chats found matching your filters & search'**
  String get noChatsFoundMatchingYourFilter;

  /// No description provided for @noChatsFoundMatchingYourSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'No chats found matching your search term'**
  String get noChatsFoundMatchingYourSearchTerm;

  /// No description provided for @noChatsInThisSpaceYet.
  ///
  /// In en, this message translates to:
  /// **'No chats in this space yet'**
  String get noChatsInThisSpaceYet;

  /// No description provided for @noChatsStillSyncing.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing…'**
  String get noChatsStillSyncing;

  /// No description provided for @noChatsStillSyncingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We are loading your chats. On large accounts the initial loading takes a bit…'**
  String get noChatsStillSyncingSubtitle;

  /// No description provided for @noConnectedSpaces.
  ///
  /// In en, this message translates to:
  /// **'No connected spaces'**
  String get noConnectedSpaces;

  /// No description provided for @noDisplayName.
  ///
  /// In en, this message translates to:
  /// **'no display name'**
  String get noDisplayName;

  /// No description provided for @noDueDate.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get noDueDate;

  /// No description provided for @noEventsPlannedYet.
  ///
  /// In en, this message translates to:
  /// **'No events planned yet'**
  String get noEventsPlannedYet;

  /// No description provided for @noIStay.
  ///
  /// In en, this message translates to:
  /// **'No, I stay'**
  String get noIStay;

  /// No description provided for @noMembersFound.
  ///
  /// In en, this message translates to:
  /// **'No members found. How can that even be, you are here, aren’t you?'**
  String get noMembersFound;

  /// No description provided for @noOverwrite.
  ///
  /// In en, this message translates to:
  /// **'No Overwrite'**
  String get noOverwrite;

  /// No description provided for @noParticipantsGoing.
  ///
  /// In en, this message translates to:
  /// **'No participants going'**
  String get noParticipantsGoing;

  /// No description provided for @noPinsAvailableDescription.
  ///
  /// In en, this message translates to:
  /// **'Share important resources with your community such as documents or links so everyone is updated.'**
  String get noPinsAvailableDescription;

  /// No description provided for @noPinsAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No pins available yet'**
  String get noPinsAvailableYet;

  /// No description provided for @noProfile.
  ///
  /// In en, this message translates to:
  /// **'Don’t have a profile yet?'**
  String get noProfile;

  /// No description provided for @noPushServerConfigured.
  ///
  /// In en, this message translates to:
  /// **'No push server configured on build'**
  String get noPushServerConfigured;

  /// No description provided for @noPushTargetsAddedYet.
  ///
  /// In en, this message translates to:
  /// **'no push targets added yet'**
  String get noPushTargetsAddedYet;

  /// No description provided for @noSpacesFound.
  ///
  /// In en, this message translates to:
  /// **'No spaces found'**
  String get noSpacesFound;

  /// No description provided for @noUsersFoundWithSpecifiedSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'No Users found with specified search term'**
  String get noUsersFoundWithSpecifiedSearchTerm;

  /// No description provided for @notEnoughPowerLevelForInvites.
  ///
  /// In en, this message translates to:
  /// **'Not enough permission level for invites, ask administrator to change it'**
  String get notEnoughPowerLevelForInvites;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'404 - Not Found'**
  String get notFound;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notGoing.
  ///
  /// In en, this message translates to:
  /// **'Not Going'**
  String get notGoing;

  /// No description provided for @noThanks.
  ///
  /// In en, this message translates to:
  /// **'No, thanks'**
  String get noThanks;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsOverwrites.
  ///
  /// In en, this message translates to:
  /// **'Notifications Overwrites'**
  String get notificationsOverwrites;

  /// No description provided for @notificationsOverwritesDescription.
  ///
  /// In en, this message translates to:
  /// **'Overwrite your notifications configurations for this space'**
  String get notificationsOverwritesDescription;

  /// No description provided for @notificationsSettingsAndTargets.
  ///
  /// In en, this message translates to:
  /// **'Notifications settings and targets'**
  String get notificationsSettingsAndTargets;

  /// No description provided for @notificationStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Notification status submitted'**
  String get notificationStatusSubmitted;

  /// No description provided for @notificationStatusUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Notification status update failed: {error}'**
  String notificationStatusUpdateFailed(Object error);

  /// No description provided for @notificationsUnmuted.
  ///
  /// In en, this message translates to:
  /// **'Notifications unmuted'**
  String get notificationsUnmuted;

  /// No description provided for @notificationTargets.
  ///
  /// In en, this message translates to:
  /// **'Notification Targets'**
  String get notificationTargets;

  /// No description provided for @notifyAboutSpaceUpdates.
  ///
  /// In en, this message translates to:
  /// **'Notify about Space Updates immediately'**
  String get notifyAboutSpaceUpdates;

  /// No description provided for @noTopicFound.
  ///
  /// In en, this message translates to:
  /// **'No topic found'**
  String get noTopicFound;

  /// No description provided for @notVisible.
  ///
  /// In en, this message translates to:
  /// **'Not visible'**
  String get notVisible;

  /// No description provided for @notYetSupported.
  ///
  /// In en, this message translates to:
  /// **'Not yet supported'**
  String get notYetSupported;

  /// No description provided for @noWorriesWeHaveGotYouCovered.
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your email to reset your password.'**
  String get noWorriesWeHaveGotYouCovered;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get ok;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get on;

  /// No description provided for @onboardText.
  ///
  /// In en, this message translates to:
  /// **'Let’s get started by setting up your profile'**
  String get onboardText;

  /// No description provided for @onlySupportedIosAndAndroid.
  ///
  /// In en, this message translates to:
  /// **'Only supported on mobile (iOS & Android) right now'**
  String get onlySupportedIosAndAndroid;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **' or '**
  String get or;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @parentSpace.
  ///
  /// In en, this message translates to:
  /// **'Parent Space'**
  String get parentSpace;

  /// No description provided for @parentSpaces.
  ///
  /// In en, this message translates to:
  /// **'Parent Spaces'**
  String get parentSpaces;

  /// No description provided for @parentSpaceMustBeSelected.
  ///
  /// In en, this message translates to:
  /// **'Parent Space must be selected'**
  String get parentSpaceMustBeSelected;

  /// No description provided for @parents.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get parents;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Reset'**
  String get passwordResetTitle;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @peopleGoing.
  ///
  /// In en, this message translates to:
  /// **'{count} People going'**
  String peopleGoing(Object count);

  /// No description provided for @personalSettings.
  ///
  /// In en, this message translates to:
  /// **'Personal Settings'**
  String get personalSettings;

  /// No description provided for @pinName.
  ///
  /// In en, this message translates to:
  /// **'Pin Name'**
  String get pinName;

  /// No description provided for @pins.
  ///
  /// In en, this message translates to:
  /// **'Pins'**
  String get pins;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @pleaseCheckYourInbox.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox for the validation email and click the link before it expires'**
  String get pleaseCheckYourInbox;

  /// No description provided for @pleaseEnterAName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterAName;

  /// No description provided for @pleaseEnterATitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterATitle;

  /// No description provided for @pleaseEnterEventName.
  ///
  /// In en, this message translates to:
  /// **'Please enter event name'**
  String get pleaseEnterEventName;

  /// No description provided for @pleaseFirstSelectASpace.
  ///
  /// In en, this message translates to:
  /// **'Please first select a space'**
  String get pleaseFirstSelectASpace;

  /// No description provided for @errorProcessingSlide.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t process slide {slideIdx}: {error}'**
  String errorProcessingSlide(Object error, Object slideIdx);

  /// No description provided for @pleaseProvideEmailAddressToAdd.
  ///
  /// In en, this message translates to:
  /// **'Please provide the email address you’d like to add'**
  String get pleaseProvideEmailAddressToAdd;

  /// No description provided for @pleaseProvideYourUserPassword.
  ///
  /// In en, this message translates to:
  /// **'Please provide your user password to confirm you want to end that session.'**
  String get pleaseProvideYourUserPassword;

  /// No description provided for @pleaseSelectSpace.
  ///
  /// In en, this message translates to:
  /// **'Please select space'**
  String get pleaseSelectSpace;

  /// No description provided for @selectTaskList.
  ///
  /// In en, this message translates to:
  /// **'Select Task List'**
  String get selectTaskList;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// No description provided for @polls.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get polls;

  /// No description provided for @pollsAndSurveys.
  ///
  /// In en, this message translates to:
  /// **'Polls and Surveys'**
  String get pollsAndSurveys;

  /// No description provided for @postingOfTypeNotYetSupported.
  ///
  /// In en, this message translates to:
  /// **'Posting of {type} not yet supported'**
  String postingOfTypeNotYetSupported(Object type);

  /// No description provided for @postingTaskList.
  ///
  /// In en, this message translates to:
  /// **'Posting TaskList'**
  String get postingTaskList;

  /// No description provided for @postpone.
  ///
  /// In en, this message translates to:
  /// **'Postpone'**
  String get postpone;

  /// No description provided for @postponeN.
  ///
  /// In en, this message translates to:
  /// **'Postpone {days} days'**
  String postponeN(Object days);

  /// No description provided for @powerLevel.
  ///
  /// In en, this message translates to:
  /// **'Permission Level'**
  String get powerLevel;

  /// No description provided for @powerLevelUpdateSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Permission Level update submitted'**
  String get powerLevelUpdateSubmitted;

  /// No description provided for @powerLevelAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get powerLevelAdmin;

  /// No description provided for @powerLevelModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get powerLevelModerator;

  /// No description provided for @powerLevelRegular.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get powerLevelRegular;

  /// No description provided for @powerLevelNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get powerLevelNone;

  /// No description provided for @powerLevelCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get powerLevelCustom;

  /// No description provided for @powerLevelsTitle.
  ///
  /// In en, this message translates to:
  /// **'General Permission levels'**
  String get powerLevelsTitle;

  /// No description provided for @powerLevelPostEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Posting Permission Level'**
  String get powerLevelPostEventsTitle;

  /// No description provided for @powerLevelPostEventsDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimal Permission Level to post anything at all'**
  String get powerLevelPostEventsDesc;

  /// No description provided for @powerLevelKickTitle.
  ///
  /// In en, this message translates to:
  /// **'Kick Permission Level'**
  String get powerLevelKickTitle;

  /// No description provided for @powerLevelKickDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimal Permission Level to kick someone'**
  String get powerLevelKickDesc;

  /// No description provided for @powerLevelBanTitle.
  ///
  /// In en, this message translates to:
  /// **'Ban Permission Level'**
  String get powerLevelBanTitle;

  /// No description provided for @powerLevelBanDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimal Permission Level to ban someone'**
  String get powerLevelBanDesc;

  /// No description provided for @powerLevelInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Permission Level'**
  String get powerLevelInviteTitle;

  /// No description provided for @powerLevelInviteDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimal Permission Level to invite someone'**
  String get powerLevelInviteDesc;

  /// No description provided for @powerLevelRedactTitle.
  ///
  /// In en, this message translates to:
  /// **'Redact Permission Level'**
  String get powerLevelRedactTitle;

  /// No description provided for @powerLevelRedactDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimal Permission Level to redact other peoples content'**
  String get powerLevelRedactDesc;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @pushKey.
  ///
  /// In en, this message translates to:
  /// **'PushKey'**
  String get pushKey;

  /// No description provided for @pushTargetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Push target deleted'**
  String get pushTargetDeleted;

  /// No description provided for @pushTargetDetails.
  ///
  /// In en, this message translates to:
  /// **'Push Target Details'**
  String get pushTargetDetails;

  /// No description provided for @pushToThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Push to this device'**
  String get pushToThisDevice;

  /// No description provided for @quickSelect.
  ///
  /// In en, this message translates to:
  /// **'Quick select:'**
  String get quickSelect;

  /// No description provided for @rageShakeAppName.
  ///
  /// In en, this message translates to:
  /// **'Rageshake App Name'**
  String get rageShakeAppName;

  /// No description provided for @rageShakeAppNameDigest.
  ///
  /// In en, this message translates to:
  /// **'Rageshake App Name Digest'**
  String get rageShakeAppNameDigest;

  /// No description provided for @rageShakeTargetUrl.
  ///
  /// In en, this message translates to:
  /// **'Rageshake Target Url'**
  String get rageShakeTargetUrl;

  /// No description provided for @rageShakeTargetUrlDigest.
  ///
  /// In en, this message translates to:
  /// **'Rageshake Target Url Digest'**
  String get rageShakeTargetUrlDigest;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @reasonHint.
  ///
  /// In en, this message translates to:
  /// **'optional reason'**
  String get reasonHint;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @redactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Redaction sending failed: {error}'**
  String redactionFailed(Object error);

  /// No description provided for @redeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redeem;

  /// No description provided for @redeemingFailed.
  ///
  /// In en, this message translates to:
  /// **'Redeeming failed: {error}'**
  String redeemingFailed(Object error);

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed: {error}'**
  String registerFailed(Object error);

  /// No description provided for @regular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get regular;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removePin.
  ///
  /// In en, this message translates to:
  /// **'Remove Pin'**
  String get removePin;

  /// No description provided for @removeThisContent.
  ///
  /// In en, this message translates to:
  /// **'Remove this content. This can not be undone. Provide an optional reason to explain, why this was removed'**
  String get removeThisContent;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String replyTo(Object name);

  /// No description provided for @replyPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No preview available for the message you are replying to'**
  String get replyPreviewUnavailable;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reportThisEvent.
  ///
  /// In en, this message translates to:
  /// **'Report this event'**
  String get reportThisEvent;

  /// No description provided for @reportThisMessage.
  ///
  /// In en, this message translates to:
  /// **'Report this message'**
  String get reportThisMessage;

  /// No description provided for @reportMessageContent.
  ///
  /// In en, this message translates to:
  /// **'Report this message to your homeserver administrator. Please note that adminstrator wouldn’t be able to read or view any files, if chat is encrypted'**
  String get reportMessageContent;

  /// No description provided for @reportPin.
  ///
  /// In en, this message translates to:
  /// **'Report Pin'**
  String get reportPin;

  /// No description provided for @reportThisPost.
  ///
  /// In en, this message translates to:
  /// **'Report this post'**
  String get reportThisPost;

  /// No description provided for @reportPostContent.
  ///
  /// In en, this message translates to:
  /// **'Report this post to your homeserver administrator. Please note that administrator would’t be able to read or view any files in encrypted spaces.'**
  String get reportPostContent;

  /// No description provided for @reportSendingFailed.
  ///
  /// In en, this message translates to:
  /// **'Report sending failed'**
  String get reportSendingFailed;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent!'**
  String get reportSent;

  /// No description provided for @reportThisContent.
  ///
  /// In en, this message translates to:
  /// **'Report this content to your homeserver administrator. Please note that your administrator won’t be able to read or view files in encrypted spaces.'**
  String get reportThisContent;

  /// No description provided for @requestToJoin.
  ///
  /// In en, this message translates to:
  /// **'request to join'**
  String get requestToJoin;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @roomId.
  ///
  /// In en, this message translates to:
  /// **'ChatId'**
  String get roomId;

  /// No description provided for @roomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chat not found'**
  String get roomNotFound;

  /// No description provided for @roomLinkedButNotUpgraded.
  ///
  /// In en, this message translates to:
  /// **'Added. However you are not able to upgrade its join rule settings and thus not all people from this space might be able to join it.'**
  String get roomLinkedButNotUpgraded;

  /// No description provided for @rsvp.
  ///
  /// In en, this message translates to:
  /// **'RSVP'**
  String get rsvp;

  /// No description provided for @repliedToMsgFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load original message id: {id}'**
  String repliedToMsgFailed(Object id);

  /// No description provided for @sasGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get sasGotIt;

  /// When another users asks to verify this session
  ///
  /// In en, this message translates to:
  /// **'{sender} wants to verify your session'**
  String sasIncomingReqNotifContent(String sender);

  /// No description provided for @sasIncomingReqNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Request'**
  String get sasIncomingReqNotifTitle;

  /// No description provided for @sasVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified!'**
  String get sasVerified;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveFileAs.
  ///
  /// In en, this message translates to:
  /// **'Save file as'**
  String get saveFileAs;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openFile;

  /// No description provided for @shareFile.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareFile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @savingCode.
  ///
  /// In en, this message translates to:
  /// **'Saving code'**
  String get savingCode;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchTermFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Search for…'**
  String get searchTermFieldHint;

  /// No description provided for @searchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get searchChats;

  /// No description provided for @searchResultFor.
  ///
  /// In en, this message translates to:
  /// **'Search result for {text}…'**
  String searchResultFor(Object text);

  /// No description provided for @searchUsernameToStartDM.
  ///
  /// In en, this message translates to:
  /// **'Search Username to start a DM'**
  String get searchUsernameToStartDM;

  /// No description provided for @searchingFailed.
  ///
  /// In en, this message translates to:
  /// **'Searching failed {error}'**
  String searchingFailed(Object error);

  /// No description provided for @searchSpace.
  ///
  /// In en, this message translates to:
  /// **'search space'**
  String get searchSpace;

  /// No description provided for @searchSpaces.
  ///
  /// In en, this message translates to:
  /// **'Search Spaces'**
  String get searchSpaces;

  /// No description provided for @searchPublicDirectory.
  ///
  /// In en, this message translates to:
  /// **'Search Public Directory'**
  String get searchPublicDirectory;

  /// No description provided for @searchPublicDirectoryNothingFound.
  ///
  /// In en, this message translates to:
  /// **'No entry found in the public directory'**
  String get searchPublicDirectoryNothingFound;

  /// No description provided for @seeOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'see open tasks'**
  String get seeOpenTasks;

  /// No description provided for @seenBy.
  ///
  /// In en, this message translates to:
  /// **'Seen By'**
  String get seenBy;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @unselectAll.
  ///
  /// In en, this message translates to:
  /// **'Unselect all'**
  String get unselectAll;

  /// No description provided for @selectAnyRoomToSeeIt.
  ///
  /// In en, this message translates to:
  /// **'Select any Chat to see it'**
  String get selectAnyRoomToSeeIt;

  /// No description provided for @selectDue.
  ///
  /// In en, this message translates to:
  /// **'Select Due'**
  String get selectDue;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectParentSpace.
  ///
  /// In en, this message translates to:
  /// **'Select parent space'**
  String get selectParentSpace;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendingAttachment.
  ///
  /// In en, this message translates to:
  /// **'Sending Attachment'**
  String get sendingAttachment;

  /// No description provided for @sendingReport.
  ///
  /// In en, this message translates to:
  /// **'Sending Report'**
  String get sendingReport;

  /// No description provided for @sendingEmail.
  ///
  /// In en, this message translates to:
  /// **'Sending Email'**
  String get sendingEmail;

  /// No description provided for @sendingEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Sending failed: {error}'**
  String sendingEmailFailed(Object error);

  /// No description provided for @sendingRsvpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sending RSVP failed: {error}'**
  String sendingRsvpFailed(Object error);

  /// No description provided for @sentAnImage.
  ///
  /// In en, this message translates to:
  /// **'sent an image.'**
  String get sentAnImage;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessions;

  /// No description provided for @sessionTokenName.
  ///
  /// In en, this message translates to:
  /// **'Session Token Name'**
  String get sessionTokenName;

  /// No description provided for @setDebugLevel.
  ///
  /// In en, this message translates to:
  /// **'Set debug level'**
  String get setDebugLevel;

  /// No description provided for @setHttpProxy.
  ///
  /// In en, this message translates to:
  /// **'Set HTTP Proxy'**
  String get setHttpProxy;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @securityAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get securityAndPrivacy;

  /// No description provided for @settingsKeyBackUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Backup'**
  String get settingsKeyBackUpTitle;

  /// No description provided for @settingsKeyBackUpDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage the key backup'**
  String get settingsKeyBackUpDesc;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareIcal.
  ///
  /// In en, this message translates to:
  /// **'Share iCal'**
  String get shareIcal;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Sharing failed: {error}'**
  String shareFailed(Object error);

  /// No description provided for @sharedCalendarAndEvents.
  ///
  /// In en, this message translates to:
  /// **'Shared Calendar and events'**
  String get sharedCalendarAndEvents;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @slidePosting.
  ///
  /// In en, this message translates to:
  /// **'Slide posting'**
  String get slidePosting;

  /// No description provided for @slidesNotYetSupported.
  ///
  /// In en, this message translates to:
  /// **'{type} slides not yet supported'**
  String slidesNotYetSupported(Object type);

  /// No description provided for @someErrorOccurredLeavingRoom.
  ///
  /// In en, this message translates to:
  /// **'Some error occurred leaving Chat'**
  String get someErrorOccurredLeavingRoom;

  /// No description provided for @space.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get space;

  /// No description provided for @spaceConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Space Configuration'**
  String get spaceConfiguration;

  /// No description provided for @spaceConfigurationDescription.
  ///
  /// In en, this message translates to:
  /// **'Configure, who can view and how to join this space'**
  String get spaceConfigurationDescription;

  /// No description provided for @spaceName.
  ///
  /// In en, this message translates to:
  /// **'Space Name'**
  String get spaceName;

  /// No description provided for @spaceNotificationOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Space notification overwrite'**
  String get spaceNotificationOverwrite;

  /// No description provided for @spaceNotifications.
  ///
  /// In en, this message translates to:
  /// **'Space Notifications'**
  String get spaceNotifications;

  /// No description provided for @spaceOrSpaceIdMustBeProvided.
  ///
  /// In en, this message translates to:
  /// **'space or spaceId must be provided'**
  String get spaceOrSpaceIdMustBeProvided;

  /// No description provided for @spaces.
  ///
  /// In en, this message translates to:
  /// **'Spaces'**
  String get spaces;

  /// No description provided for @spacesAndChats.
  ///
  /// In en, this message translates to:
  /// **'Spaces & Chats'**
  String get spacesAndChats;

  /// No description provided for @spacesAndChatsToAddThemTo.
  ///
  /// In en, this message translates to:
  /// **'Spaces & Chats to add them to'**
  String get spacesAndChatsToAddThemTo;

  /// No description provided for @startDM.
  ///
  /// In en, this message translates to:
  /// **'Start DM'**
  String get startDM;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'state'**
  String get state;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submittingComment.
  ///
  /// In en, this message translates to:
  /// **'Submitting comment'**
  String get submittingComment;

  /// No description provided for @suggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get suggested;

  /// No description provided for @suggestedUsers.
  ///
  /// In en, this message translates to:
  /// **'Suggested Users'**
  String get suggestedUsers;

  /// No description provided for @joiningSuggested.
  ///
  /// In en, this message translates to:
  /// **'Joining suggested'**
  String get joiningSuggested;

  /// No description provided for @suggestedRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested to join'**
  String get suggestedRoomsTitle;

  /// No description provided for @suggestedRoomsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We suggest you also join the following'**
  String get suggestedRoomsSubtitle;

  /// No description provided for @addSuggested.
  ///
  /// In en, this message translates to:
  /// **'Mark as suggested'**
  String get addSuggested;

  /// No description provided for @removeSuggested.
  ///
  /// In en, this message translates to:
  /// **'Remove suggestion'**
  String get removeSuggested;

  /// No description provided for @superInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitation Codes'**
  String get superInvitations;

  /// No description provided for @superInvites.
  ///
  /// In en, this message translates to:
  /// **'Invitation Codes'**
  String get superInvites;

  /// No description provided for @superInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'{user} invites you'**
  String superInvitedBy(Object user);

  /// No description provided for @superInvitedTo.
  ///
  /// In en, this message translates to:
  /// **'To join {count} room'**
  String superInvitedTo(Object count);

  /// No description provided for @superInvitesPreviewMissing.
  ///
  /// In en, this message translates to:
  /// **'Your Server doesn’t support previewing Invite Codes. You can still try to redeem {token} though'**
  String superInvitesPreviewMissing(Object token);

  /// No description provided for @superInvitesDeleted.
  ///
  /// In en, this message translates to:
  /// **'The invite code {token} is not valid anymore.'**
  String superInvitesDeleted(Object token);

  /// No description provided for @takeAFirstStep.
  ///
  /// In en, this message translates to:
  /// **'The secure organizing app that grows with your aspirations. Providing a safe space for movements.'**
  String get takeAFirstStep;

  /// No description provided for @taskListName.
  ///
  /// In en, this message translates to:
  /// **'Task list name'**
  String get taskListName;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsText1.
  ///
  /// In en, this message translates to:
  /// **'By clicking to create profile you agree to our'**
  String get termsText1;

  /// No description provided for @theCurrentJoinRulesOfSpace.
  ///
  /// In en, this message translates to:
  /// **'The current join rules of {roomName} mean it won’t be visible for {parentSpaceName}’s members. Should we update the join rules to allow for {parentSpaceName}’s space member to see and join the {roomName}?'**
  String theCurrentJoinRulesOfSpace(Object parentSpaceName, Object roomName);

  /// No description provided for @theParentSpace.
  ///
  /// In en, this message translates to:
  /// **'the parent space'**
  String get theParentSpace;

  /// No description provided for @thereIsNothingScheduledYet.
  ///
  /// In en, this message translates to:
  /// **'There’s nothing scheduled yet'**
  String get thereIsNothingScheduledYet;

  /// No description provided for @theSelectedRooms.
  ///
  /// In en, this message translates to:
  /// **'the selected chats'**
  String get theSelectedRooms;

  /// No description provided for @theyWontBeAbleToJoinAgain.
  ///
  /// In en, this message translates to:
  /// **'They won’t be able to join again'**
  String get theyWontBeAbleToJoinAgain;

  /// No description provided for @thirdParty.
  ///
  /// In en, this message translates to:
  /// **'3rd Party'**
  String get thirdParty;

  /// No description provided for @thisApaceIsEndToEndEncrypted.
  ///
  /// In en, this message translates to:
  /// **'This space is end-to-end-encrypted'**
  String get thisApaceIsEndToEndEncrypted;

  /// No description provided for @thisApaceIsNotEndToEndEncrypted.
  ///
  /// In en, this message translates to:
  /// **'This space is not end-to-end-encrypted'**
  String get thisApaceIsNotEndToEndEncrypted;

  /// No description provided for @thisIsAMultilineDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a multiline description of the task with lengthy texts and stuff'**
  String get thisIsAMultilineDescription;

  /// No description provided for @thisIsNotAProperActerSpace.
  ///
  /// In en, this message translates to:
  /// **'This is not a proper acter space. Some features may not be available.'**
  String get thisIsNotAProperActerSpace;

  /// No description provided for @thisMessageHasBeenDeleted.
  ///
  /// In en, this message translates to:
  /// **'This message has been deleted'**
  String get thisMessageHasBeenDeleted;

  /// No description provided for @thisWillAllowThemToContactYouAgain.
  ///
  /// In en, this message translates to:
  /// **'This will allow them to contact you again'**
  String get thisWillAllowThemToContactYouAgain;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @titleTheNewTask.
  ///
  /// In en, this message translates to:
  /// **'Title the new task..'**
  String get titleTheNewTask;

  /// No description provided for @typingUser1.
  ///
  /// In en, this message translates to:
  /// **'{user} is typing…'**
  String typingUser1(Object user);

  /// No description provided for @typingUser2.
  ///
  /// In en, this message translates to:
  /// **'{user1} and {user2} are typing…'**
  String typingUser2(Object user1, Object user2);

  /// No description provided for @typingUserN.
  ///
  /// In en, this message translates to:
  /// **'{user} and {userCount} others are typing'**
  String typingUserN(Object user, Object userCount);

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @toAccess.
  ///
  /// In en, this message translates to:
  /// **'to access'**
  String get toAccess;

  /// No description provided for @needToBeMemberOf.
  ///
  /// In en, this message translates to:
  /// **'you need to be member of'**
  String get needToBeMemberOf;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @token.
  ///
  /// In en, this message translates to:
  /// **'token'**
  String get token;

  /// No description provided for @tokenAndPasswordMustBeProvided.
  ///
  /// In en, this message translates to:
  /// **'Token and password must be provided'**
  String get tokenAndPasswordMustBeProvided;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @topic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get topic;

  /// No description provided for @tryingToConfirmToken.
  ///
  /// In en, this message translates to:
  /// **'Trying to confirm token'**
  String get tryingToConfirmToken;

  /// No description provided for @tryingToJoin.
  ///
  /// In en, this message translates to:
  /// **'Joining {name}'**
  String tryingToJoin(Object name);

  /// No description provided for @tryToJoin.
  ///
  /// In en, this message translates to:
  /// **'Try to join'**
  String get tryToJoin;

  /// No description provided for @typeName.
  ///
  /// In en, this message translates to:
  /// **'Type Name'**
  String get typeName;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @unblockingUser.
  ///
  /// In en, this message translates to:
  /// **'Unblocking User'**
  String get unblockingUser;

  /// No description provided for @unblockingUserFailed.
  ///
  /// In en, this message translates to:
  /// **'Unblocking User failed: {error}'**
  String unblockingUserFailed(Object error);

  /// No description provided for @unblockingUserProgress.
  ///
  /// In en, this message translates to:
  /// **'Unblocking User'**
  String get unblockingUserProgress;

  /// No description provided for @unblockingUserSuccess.
  ///
  /// In en, this message translates to:
  /// **'User unblocked. It might takes a bit before the UI reflects this update.'**
  String get unblockingUserSuccess;

  /// No description provided for @unblockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unblock {userId}'**
  String unblockTitle(Object userId);

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @unclearJoinRule.
  ///
  /// In en, this message translates to:
  /// **'Unclear join rule {rule}'**
  String unclearJoinRule(Object rule);

  /// No description provided for @unreadMarkerFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unread Markers'**
  String get unreadMarkerFeatureTitle;

  /// No description provided for @unreadMarkerFeatureDescription.
  ///
  /// In en, this message translates to:
  /// **'Track and show which Chats have been read'**
  String get unreadMarkerFeatureDescription;

  /// No description provided for @undefined.
  ///
  /// In en, this message translates to:
  /// **'undefined'**
  String get undefined;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get unknown;

  /// No description provided for @unknownRoom.
  ///
  /// In en, this message translates to:
  /// **'Unknown Chat'**
  String get unknownRoom;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @unset.
  ///
  /// In en, this message translates to:
  /// **'unset'**
  String get unset;

  /// No description provided for @unsupportedPleaseUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Unsupported - Please upgrade!'**
  String get unsupportedPleaseUpgrade;

  /// No description provided for @unverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get unverified;

  /// No description provided for @unverifiedSessions.
  ///
  /// In en, this message translates to:
  /// **'Unverified Sessions'**
  String get unverifiedSessions;

  /// No description provided for @unverifiedSessionsDescription.
  ///
  /// In en, this message translates to:
  /// **'You have devices logged in your account that aren’t verified. This can be a security risk. Please ensure this is okay.'**
  String get unverifiedSessionsDescription;

  /// Text shown for number of unverified sessions
  ///
  /// In en, this message translates to:
  /// **'There are {count} unverified sessions logged in'**
  String unverifiedSessionsCount(int count);

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @updatePowerLevel.
  ///
  /// In en, this message translates to:
  /// **'Update Permission level'**
  String get updatePowerLevel;

  /// No description provided for @updateFeaturePowerLevelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Permission of {feature}'**
  String updateFeaturePowerLevelDialogTitle(Object feature);

  /// No description provided for @updateFeaturePowerLevelDialogFromTo.
  ///
  /// In en, this message translates to:
  /// **'from {memberStatus} ({currentPowerLevel}) to'**
  String updateFeaturePowerLevelDialogFromTo(Object currentPowerLevel, Object memberStatus);

  /// No description provided for @updateFeaturePowerLevelDialogFromDefaultTo.
  ///
  /// In en, this message translates to:
  /// **'from default to'**
  String get updateFeaturePowerLevelDialogFromDefaultTo;

  /// No description provided for @updatingDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Updating display name'**
  String get updatingDisplayName;

  /// No description provided for @updatingDue.
  ///
  /// In en, this message translates to:
  /// **'Updating due'**
  String get updatingDue;

  /// No description provided for @updatingEvent.
  ///
  /// In en, this message translates to:
  /// **'Updating Event'**
  String get updatingEvent;

  /// No description provided for @updatingPowerLevelOf.
  ///
  /// In en, this message translates to:
  /// **'Updating Permission  level of {userId}'**
  String updatingPowerLevelOf(Object userId);

  /// No description provided for @updatingProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Updating profile image'**
  String get updatingProfileImage;

  /// No description provided for @updatingRSVP.
  ///
  /// In en, this message translates to:
  /// **'Updating RSVP'**
  String get updatingRSVP;

  /// No description provided for @updatingSpace.
  ///
  /// In en, this message translates to:
  /// **'Updating Space'**
  String get updatingSpace;

  /// No description provided for @uploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload Avatar'**
  String get uploadAvatar;

  /// No description provided for @usedTimes.
  ///
  /// In en, this message translates to:
  /// **'Used {count} times'**
  String usedTimes(Object count);

  /// No description provided for @userAddedToBlockList.
  ///
  /// In en, this message translates to:
  /// **'{user} added to block list. UI might take a bit too update'**
  String userAddedToBlockList(Object user);

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @usersfoundDirectory.
  ///
  /// In en, this message translates to:
  /// **'Users found in public directory'**
  String get usersfoundDirectory;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @usernameCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Username copied to clipboard'**
  String get usernameCopiedToClipboard;

  /// No description provided for @userRemovedFromList.
  ///
  /// In en, this message translates to:
  /// **'User removed from list. UI might take a bit too update'**
  String get userRemovedFromList;

  /// No description provided for @usersYouBlocked.
  ///
  /// In en, this message translates to:
  /// **'Users you blocked'**
  String get usersYouBlocked;

  /// No description provided for @validEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get validEmail;

  /// No description provided for @verificationConclusionCompromised.
  ///
  /// In en, this message translates to:
  /// **'One of the following may be compromised:\n\n   - Your homeserver\n   - The homeserver the user you’re verifying is connected to\n   - Yours, or the other users’ internet connection\n   - Yours, or the other users’ device'**
  String get verificationConclusionCompromised;

  /// After successfully verifying another user
  ///
  /// In en, this message translates to:
  /// **'You’ve successfully verified {sender}!'**
  String verificationConclusionOkDone(String sender);

  /// No description provided for @verificationConclusionOkSelfNotice.
  ///
  /// In en, this message translates to:
  /// **'Your new session is now verified. It has access to your encrypted messages, and other users will see it as trusted.'**
  String get verificationConclusionOkSelfNotice;

  /// No description provided for @verificationEmojiNotice.
  ///
  /// In en, this message translates to:
  /// **'Compare the unique emoji, ensuring they appear in the same order.'**
  String get verificationEmojiNotice;

  /// No description provided for @verificationRequestAccept.
  ///
  /// In en, this message translates to:
  /// **'To proceed, please accept the verification request on your other device.'**
  String get verificationRequestAccept;

  /// No description provided for @verificationRequestWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {sender}…'**
  String verificationRequestWaitingFor(String sender);

  /// No description provided for @verificationSasDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'They don’t match'**
  String get verificationSasDoNotMatch;

  /// No description provided for @verificationSasMatch.
  ///
  /// In en, this message translates to:
  /// **'They match'**
  String get verificationSasMatch;

  /// No description provided for @verificationScanEmojiTitle.
  ///
  /// In en, this message translates to:
  /// **'Can’t scan'**
  String get verificationScanEmojiTitle;

  /// No description provided for @verificationScanSelfEmojiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify by comparing emoji instead'**
  String get verificationScanSelfEmojiSubtitle;

  /// No description provided for @verificationScanSelfNotice.
  ///
  /// In en, this message translates to:
  /// **'Scan the code with your other device or switch and scan with this device'**
  String get verificationScanSelfNotice;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @verifiedSessionsDescription.
  ///
  /// In en, this message translates to:
  /// **'All your devices are verified. Your account is secure.'**
  String get verifiedSessionsDescription;

  /// No description provided for @verifyOtherSession.
  ///
  /// In en, this message translates to:
  /// **'Verify other session'**
  String get verifyOtherSession;

  /// No description provided for @verifySession.
  ///
  /// In en, this message translates to:
  /// **'Verify session'**
  String get verifySession;

  /// No description provided for @verifyThisSession.
  ///
  /// In en, this message translates to:
  /// **'Verify this session'**
  String get verifyThisSession;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @via.
  ///
  /// In en, this message translates to:
  /// **'via'**
  String get via;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to '**
  String get welcomeTo;

  /// No description provided for @whatToCallThisChat.
  ///
  /// In en, this message translates to:
  /// **'What to call this chat?'**
  String get whatToCallThisChat;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @yesLeave.
  ///
  /// In en, this message translates to:
  /// **'Yes, Leave'**
  String get yesLeave;

  /// No description provided for @yesPleaseUpdate.
  ///
  /// In en, this message translates to:
  /// **'Yes, please update'**
  String get yesPleaseUpdate;

  /// No description provided for @youAreAbleToJoinThisRoom.
  ///
  /// In en, this message translates to:
  /// **'You can join this'**
  String get youAreAbleToJoinThisRoom;

  /// No description provided for @youAreAboutToBlock.
  ///
  /// In en, this message translates to:
  /// **'You are about to block {userId}'**
  String youAreAboutToBlock(Object userId);

  /// No description provided for @youAreAboutToUnblock.
  ///
  /// In en, this message translates to:
  /// **'You are about to unblock {userId}'**
  String youAreAboutToUnblock(Object userId);

  /// No description provided for @youAreBothIn.
  ///
  /// In en, this message translates to:
  /// **'you are both in '**
  String get youAreBothIn;

  /// No description provided for @youAreCurrentlyNotConnectedToAnySpaces.
  ///
  /// In en, this message translates to:
  /// **'You are currently not connected to any spaces'**
  String get youAreCurrentlyNotConnectedToAnySpaces;

  /// No description provided for @spaceShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Create or Join a space, to start organizing and collaborating!'**
  String get spaceShortDescription;

  /// No description provided for @youAreDoneWithAllYourTasks.
  ///
  /// In en, this message translates to:
  /// **'you are done with all your tasks!'**
  String get youAreDoneWithAllYourTasks;

  /// No description provided for @youAreNotAMemberOfAnySpaceYet.
  ///
  /// In en, this message translates to:
  /// **'You are not a member of any space yet'**
  String get youAreNotAMemberOfAnySpaceYet;

  /// No description provided for @youAreNotPartOfThisGroup.
  ///
  /// In en, this message translates to:
  /// **'You are not part of this group. Would you like to join?'**
  String get youAreNotPartOfThisGroup;

  /// No description provided for @youHaveNoDMsAtTheMoment.
  ///
  /// In en, this message translates to:
  /// **'You have no DMs at the moment'**
  String get youHaveNoDMsAtTheMoment;

  /// No description provided for @youHaveNoUpdates.
  ///
  /// In en, this message translates to:
  /// **'You have no updates'**
  String get youHaveNoUpdates;

  /// No description provided for @youHaveNotCreatedInviteCodes.
  ///
  /// In en, this message translates to:
  /// **'You have not yet created any invite codes'**
  String get youHaveNotCreatedInviteCodes;

  /// No description provided for @youMustSelectSpace.
  ///
  /// In en, this message translates to:
  /// **'You must select a space'**
  String get youMustSelectSpace;

  /// No description provided for @youNeedBeInvitedToJoinThisRoom.
  ///
  /// In en, this message translates to:
  /// **'You need be invited to join this Chat'**
  String get youNeedBeInvitedToJoinThisRoom;

  /// No description provided for @youNeedToEnterAComment.
  ///
  /// In en, this message translates to:
  /// **'You need to enter a comment'**
  String get youNeedToEnterAComment;

  /// No description provided for @youNeedToEnterCustomValueAsNumber.
  ///
  /// In en, this message translates to:
  /// **'You need to enter the custom value as a number.'**
  String get youNeedToEnterCustomValueAsNumber;

  /// No description provided for @youCantExceedPowerLevel.
  ///
  /// In en, this message translates to:
  /// **'You can’t exceed a permission level of {powerLevel}'**
  String youCantExceedPowerLevel(Object powerLevel);

  /// No description provided for @yourActiveDevices.
  ///
  /// In en, this message translates to:
  /// **'Your active devices'**
  String get yourActiveDevices;

  /// No description provided for @yourPassword.
  ///
  /// In en, this message translates to:
  /// **'Your Password'**
  String get yourPassword;

  /// No description provided for @yourSessionHasBeenTerminatedByServer.
  ///
  /// In en, this message translates to:
  /// **'Your session has been terminated by the server, you need to log in again'**
  String get yourSessionHasBeenTerminatedByServer;

  /// No description provided for @yourTextSlidesMustContainsSomeText.
  ///
  /// In en, this message translates to:
  /// **'Your text slide must contain some text'**
  String get yourTextSlidesMustContainsSomeText;

  /// No description provided for @yourSafeAndSecureSpace.
  ///
  /// In en, this message translates to:
  /// **'Your safe and secure space for organizing change.'**
  String get yourSafeAndSecureSpace;

  /// No description provided for @adding.
  ///
  /// In en, this message translates to:
  /// **'adding {email}'**
  String adding(Object email);

  /// No description provided for @addTextSlide.
  ///
  /// In en, this message translates to:
  /// **'Add text slide'**
  String get addTextSlide;

  /// No description provided for @addImageSlide.
  ///
  /// In en, this message translates to:
  /// **'Add image slide'**
  String get addImageSlide;

  /// No description provided for @addVideoSlide.
  ///
  /// In en, this message translates to:
  /// **'Add video slide'**
  String get addVideoSlide;

  /// No description provided for @acter.
  ///
  /// In en, this message translates to:
  /// **'Acter'**
  String get acter;

  /// No description provided for @acterApp.
  ///
  /// In en, this message translates to:
  /// **'Acter App'**
  String get acterApp;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @changingNotificationMode.
  ///
  /// In en, this message translates to:
  /// **'Changing notification mode…'**
  String get changingNotificationMode;

  /// No description provided for @createComment.
  ///
  /// In en, this message translates to:
  /// **'Create Comment'**
  String get createComment;

  /// No description provided for @createNewPin.
  ///
  /// In en, this message translates to:
  /// **'Create new Pin'**
  String get createNewPin;

  /// No description provided for @createNewSpace.
  ///
  /// In en, this message translates to:
  /// **'Create New Space'**
  String get createNewSpace;

  /// No description provided for @createNewTaskList.
  ///
  /// In en, this message translates to:
  /// **'Create new task list'**
  String get createNewTaskList;

  /// No description provided for @creatingPin.
  ///
  /// In en, this message translates to:
  /// **'Creating pin…'**
  String get creatingPin;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccount;

  /// No description provided for @deletingCode.
  ///
  /// In en, this message translates to:
  /// **'Deleting code'**
  String get deletingCode;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueSuccess.
  ///
  /// In en, this message translates to:
  /// **'Due successfully changed'**
  String get dueSuccess;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailAddresses.
  ///
  /// In en, this message translates to:
  /// **'Email Addresses'**
  String get emailAddresses;

  /// No description provided for @errorParsinLink.
  ///
  /// In en, this message translates to:
  /// **'Parsing Link failed'**
  String get errorParsinLink;

  /// No description provided for @errorCreatingPin.
  ///
  /// In en, this message translates to:
  /// **'An error occured creating pin {error}'**
  String errorCreatingPin(Object error);

  /// No description provided for @errorLoadingAttachments.
  ///
  /// In en, this message translates to:
  /// **'Error loading attachments: {error}'**
  String errorLoadingAttachments(Object error);

  /// No description provided for @errorLoadingAvatar.
  ///
  /// In en, this message translates to:
  /// **'Error loading avatar: {error}'**
  String errorLoadingAvatar(Object error);

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(Object error);

  /// No description provided for @errorLoadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error loading users: {error}'**
  String errorLoadingUsers(Object error);

  /// No description provided for @errorLoadingTasks.
  ///
  /// In en, this message translates to:
  /// **'Error loading tasks: {error}'**
  String errorLoadingTasks(Object error);

  /// No description provided for @errorLoadingSpace.
  ///
  /// In en, this message translates to:
  /// **'Error loading space: {error}'**
  String errorLoadingSpace(Object error);

  /// No description provided for @errorLoadingRelatedChats.
  ///
  /// In en, this message translates to:
  /// **'Error loading related chats: {error}'**
  String errorLoadingRelatedChats(Object error);

  /// No description provided for @errorLoadingPin.
  ///
  /// In en, this message translates to:
  /// **'Error loading pin: {error}'**
  String errorLoadingPin(Object error);

  /// No description provided for @errorLoadingEventDueTo.
  ///
  /// In en, this message translates to:
  /// **'Error loading event due to: {error}'**
  String errorLoadingEventDueTo(Object error);

  /// No description provided for @errorLoadingImage.
  ///
  /// In en, this message translates to:
  /// **'Error loading image: {error}'**
  String errorLoadingImage(Object error);

  /// No description provided for @errorLoadingRsvpStatus.
  ///
  /// In en, this message translates to:
  /// **'Error loading rsvp status: {error}'**
  String errorLoadingRsvpStatus(Object error);

  /// No description provided for @errorLoadingEmailAddresses.
  ///
  /// In en, this message translates to:
  /// **'Error loading email addresses: {error}'**
  String errorLoadingEmailAddresses(Object error);

  /// No description provided for @errorLoadingMembersCount.
  ///
  /// In en, this message translates to:
  /// **'Error loading members count: {error}'**
  String errorLoadingMembersCount(Object error);

  /// No description provided for @errorLoadingTileDueTo.
  ///
  /// In en, this message translates to:
  /// **'Error loading tile due to: {error}'**
  String errorLoadingTileDueTo(Object error);

  /// No description provided for @errorLoadingMember.
  ///
  /// In en, this message translates to:
  /// **'Error loading member: {memberId} {error}'**
  String errorLoadingMember(Object error, Object memberId);

  /// No description provided for @errorSendingAttachment.
  ///
  /// In en, this message translates to:
  /// **'Error sending attachment: {error}'**
  String errorSendingAttachment(Object error);

  /// No description provided for @eventCreate.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get eventCreate;

  /// No description provided for @eventEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get eventEdit;

  /// No description provided for @eventRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove event'**
  String get eventRemove;

  /// No description provided for @eventReport.
  ///
  /// In en, this message translates to:
  /// **'Report event'**
  String get eventReport;

  /// No description provided for @eventUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update event'**
  String get eventUpdate;

  /// No description provided for @eventShare.
  ///
  /// In en, this message translates to:
  /// **'Share event'**
  String get eventShare;

  /// No description provided for @failedToAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add {something}: {error}'**
  String failedToAdd(Object error, Object something);

  /// No description provided for @failedToChangePin.
  ///
  /// In en, this message translates to:
  /// **'Failed to change pin: {error}'**
  String failedToChangePin(Object error);

  /// No description provided for @failedToChangePowerLevel.
  ///
  /// In en, this message translates to:
  /// **'Failed to change permission level: {error}'**
  String failedToChangePowerLevel(Object error);

  /// No description provided for @failedToChangeNotificationMode.
  ///
  /// In en, this message translates to:
  /// **'Failed to change notification mode: {error}'**
  String failedToChangeNotificationMode(Object error);

  /// No description provided for @failedToChangePushNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to change push notification settings: {error}'**
  String failedToChangePushNotificationSettings(Object error);

  /// No description provided for @failedToToggleSettingOf.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle setting of {module}: {error}'**
  String failedToToggleSettingOf(Object error, Object module);

  /// No description provided for @failedToEditSpace.
  ///
  /// In en, this message translates to:
  /// **'Failed to edit space: {error}'**
  String failedToEditSpace(Object error);

  /// No description provided for @failedToAssignSelf.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign self: {error}'**
  String failedToAssignSelf(Object error);

  /// No description provided for @failedToUnassignSelf.
  ///
  /// In en, this message translates to:
  /// **'Failed to unassign self: {error}'**
  String failedToUnassignSelf(Object error);

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: {error}'**
  String failedToSend(Object error);

  /// No description provided for @failedToCreateChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to create chat:  {error}'**
  String failedToCreateChat(Object error);

  /// No description provided for @failedToCreateTaskList.
  ///
  /// In en, this message translates to:
  /// **'Failed to create task list:  {error}'**
  String failedToCreateTaskList(Object error);

  /// No description provided for @failedToConfirmToken.
  ///
  /// In en, this message translates to:
  /// **'Failed to confirm token: {error}'**
  String failedToConfirmToken(Object error);

  /// No description provided for @failedToSubmitEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit email: {error}'**
  String failedToSubmitEmail(Object error);

  /// No description provided for @failedToDecryptMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to decrypt message. Re-request session keys'**
  String get failedToDecryptMessage;

  /// No description provided for @failedToDeleteAttachment.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete attachment due to: {error}'**
  String failedToDeleteAttachment(Object error);

  /// No description provided for @failedToDetectMimeType.
  ///
  /// In en, this message translates to:
  /// **'Failed to detect mime type'**
  String get failedToDetectMimeType;

  /// No description provided for @failedToLeaveRoom.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave Chat: {error}'**
  String failedToLeaveRoom(Object error);

  /// No description provided for @failedToLoadSpace.
  ///
  /// In en, this message translates to:
  /// **'Failed to load space: {error}'**
  String failedToLoadSpace(Object error);

  /// No description provided for @failedToLoadEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to load event: {error}'**
  String failedToLoadEvent(Object error);

  /// No description provided for @failedToLoadInviteCodes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invite codes: {error}'**
  String failedToLoadInviteCodes(Object error);

  /// No description provided for @failedToLoadPushTargets.
  ///
  /// In en, this message translates to:
  /// **'Failed to load push targets: {error}'**
  String failedToLoadPushTargets(Object error);

  /// No description provided for @failedToLoadEventsDueTo.
  ///
  /// In en, this message translates to:
  /// **'Failed to load events due to: {error}'**
  String failedToLoadEventsDueTo(Object error);

  /// No description provided for @failedToLoadChatsDueTo.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chats due to: {error}'**
  String failedToLoadChatsDueTo(Object error);

  /// No description provided for @failedToShareRoom.
  ///
  /// In en, this message translates to:
  /// **'Failed to share this Chat: {error}'**
  String failedToShareRoom(Object error);

  /// No description provided for @forgotYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotYourPassword;

  /// No description provided for @editInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Edit Invite Code'**
  String get editInviteCode;

  /// No description provided for @createInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Create Invite Code'**
  String get createInviteCode;

  /// No description provided for @selectSpacesAndChats.
  ///
  /// In en, this message translates to:
  /// **'Select spaces and chats'**
  String get selectSpacesAndChats;

  /// No description provided for @autoJoinSpacesAndChatsInfo.
  ///
  /// In en, this message translates to:
  /// **'While redeeming this code, selected spaces and chats are auto join.'**
  String get autoJoinSpacesAndChatsInfo;

  /// No description provided for @createDM.
  ///
  /// In en, this message translates to:
  /// **'Create DM'**
  String get createDM;

  /// No description provided for @autoDMWhileRedeemCode.
  ///
  /// In en, this message translates to:
  /// **'While redeeming code, DM will be created\''**
  String get autoDMWhileRedeemCode;

  /// No description provided for @redeemInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Redeem Invite Code'**
  String get redeemInviteCode;

  /// No description provided for @saveInviteCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Saving code failed: {error}'**
  String saveInviteCodeFailed(Object error);

  /// No description provided for @createInviteCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Creating code failed: {error}'**
  String createInviteCodeFailed(Object error);

  /// No description provided for @deleteInviteCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Deleting code failed: {error}'**
  String deleteInviteCodeFailed(Object error);

  /// No description provided for @loadingChat.
  ///
  /// In en, this message translates to:
  /// **'Loading chat…'**
  String get loadingChat;

  /// No description provided for @loadingCommentsList.
  ///
  /// In en, this message translates to:
  /// **'Loading comments list'**
  String get loadingCommentsList;

  /// No description provided for @loadingPin.
  ///
  /// In en, this message translates to:
  /// **'Loading pin'**
  String get loadingPin;

  /// No description provided for @loadingRoom.
  ///
  /// In en, this message translates to:
  /// **'Loading Chat'**
  String get loadingRoom;

  /// No description provided for @loadingRsvpStatus.
  ///
  /// In en, this message translates to:
  /// **'Loading rsvp status'**
  String get loadingRsvpStatus;

  /// No description provided for @loadingTargets.
  ///
  /// In en, this message translates to:
  /// **'Loading targets'**
  String get loadingTargets;

  /// No description provided for @loadingOtherChats.
  ///
  /// In en, this message translates to:
  /// **'Loading other chats'**
  String get loadingOtherChats;

  /// No description provided for @loadingFirstSync.
  ///
  /// In en, this message translates to:
  /// **'Loading first sync'**
  String get loadingFirstSync;

  /// No description provided for @loadingImage.
  ///
  /// In en, this message translates to:
  /// **'Loading image'**
  String get loadingImage;

  /// No description provided for @loadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video'**
  String get loadingVideo;

  /// No description provided for @loadingEventsFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading events failed: {error}'**
  String loadingEventsFailed(Object error);

  /// No description provided for @loadingTasksFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading tasks failed: {error}'**
  String loadingTasksFailed(Object error);

  /// No description provided for @loadingSpacesFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading spaces failed: {error}'**
  String loadingSpacesFailed(Object error);

  /// No description provided for @loadingRoomFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading Chat failed: {error}'**
  String loadingRoomFailed(Object error);

  /// No description provided for @loadingMembersCountFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading members count failed: {error}'**
  String loadingMembersCountFailed(Object error);

  /// No description provided for @longPressToActivate.
  ///
  /// In en, this message translates to:
  /// **'long press to activate'**
  String get longPressToActivate;

  /// No description provided for @pinCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Pin created successfully'**
  String get pinCreatedSuccessfully;

  /// No description provided for @pleaseSelectValidEndTime.
  ///
  /// In en, this message translates to:
  /// **'Please select valid end time'**
  String get pleaseSelectValidEndTime;

  /// No description provided for @pleaseSelectValidEndDate.
  ///
  /// In en, this message translates to:
  /// **'Please select valid end date'**
  String get pleaseSelectValidEndDate;

  /// No description provided for @powerLevelSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Permissionlevel update for {module} submitted'**
  String powerLevelSubmitted(Object module);

  /// No description provided for @optionalParentSpace.
  ///
  /// In en, this message translates to:
  /// **'Optional Parent Space'**
  String get optionalParentSpace;

  /// No description provided for @redeeming.
  ///
  /// In en, this message translates to:
  /// **'Redeeming {token}'**
  String redeeming(Object token);

  /// No description provided for @encryptedDMChat.
  ///
  /// In en, this message translates to:
  /// **'Encrypted DM Chat'**
  String get encryptedDMChat;

  /// No description provided for @encryptedChatMessage.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Message locked. Tap for more'**
  String get encryptedChatMessage;

  /// No description provided for @encryptedChatMessageInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Locked Message'**
  String get encryptedChatMessageInfoTitle;

  /// No description provided for @encryptedChatMessageInfo.
  ///
  /// In en, this message translates to:
  /// **'Chat messages are end-to-end-encrypted. That means only devices connected at the time the message is sent can decrypt them. If you joined later, just logged in or used a new device, you don’t have the keys to decrypt this message yet. You can get it by verifying this session with another device of your account, by providing a encryption backup key or by verifying with another user that has access to the key.'**
  String get encryptedChatMessageInfo;

  /// No description provided for @chatMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get chatMessageDeleted;

  /// No description provided for @chatJoinedDisplayName.
  ///
  /// In en, this message translates to:
  /// **'{name} joined'**
  String chatJoinedDisplayName(Object name);

  /// No description provided for @chatJoinedUserId.
  ///
  /// In en, this message translates to:
  /// **'{userId} joined'**
  String chatJoinedUserId(Object userId);

  /// No description provided for @chatYouJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined'**
  String get chatYouJoined;

  /// No description provided for @chatYouLeft.
  ///
  /// In en, this message translates to:
  /// **'You left'**
  String get chatYouLeft;

  /// No description provided for @chatYouBanned.
  ///
  /// In en, this message translates to:
  /// **'You banned {name}'**
  String chatYouBanned(Object name);

  /// No description provided for @chatYouUnbanned.
  ///
  /// In en, this message translates to:
  /// **'You unbanned {name}'**
  String chatYouUnbanned(Object name);

  /// No description provided for @chatYouKicked.
  ///
  /// In en, this message translates to:
  /// **'You kicked {name}'**
  String chatYouKicked(Object name);

  /// No description provided for @chatYouKickedBanned.
  ///
  /// In en, this message translates to:
  /// **'You kicked and banned {name}'**
  String chatYouKickedBanned(Object name);

  /// No description provided for @chatUserLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left'**
  String chatUserLeft(Object name);

  /// No description provided for @chatUserBanned.
  ///
  /// In en, this message translates to:
  /// **'{name} banned {user}'**
  String chatUserBanned(Object name, Object user);

  /// No description provided for @chatUserUnbanned.
  ///
  /// In en, this message translates to:
  /// **'{name} unbanned {user}'**
  String chatUserUnbanned(Object name, Object user);

  /// No description provided for @chatUserKicked.
  ///
  /// In en, this message translates to:
  /// **'{name} kicked {user}'**
  String chatUserKicked(Object name, Object user);

  /// No description provided for @chatUserKickedBanned.
  ///
  /// In en, this message translates to:
  /// **'{name} kicked and banned {user}'**
  String chatUserKickedBanned(Object name, Object user);

  /// No description provided for @chatYouAcceptedInvite.
  ///
  /// In en, this message translates to:
  /// **'You accepted the invite'**
  String get chatYouAcceptedInvite;

  /// No description provided for @chatYouInvited.
  ///
  /// In en, this message translates to:
  /// **'You invited {name}'**
  String chatYouInvited(Object name);

  /// No description provided for @chatInvitedDisplayName.
  ///
  /// In en, this message translates to:
  /// **'{name} invited {invitee}'**
  String chatInvitedDisplayName(Object invitee, Object name);

  /// No description provided for @chatInvitedUserId.
  ///
  /// In en, this message translates to:
  /// **'{userId} invited {inviteeId}'**
  String chatInvitedUserId(Object inviteeId, Object userId);

  /// No description provided for @chatInvitationAcceptedDisplayName.
  ///
  /// In en, this message translates to:
  /// **'{name} accepted invitation'**
  String chatInvitationAcceptedDisplayName(Object name);

  /// No description provided for @chatInvitationAcceptedUserId.
  ///
  /// In en, this message translates to:
  /// **'{userId} accepted invitation'**
  String chatInvitationAcceptedUserId(Object userId);

  /// No description provided for @chatDisplayNameUpdate.
  ///
  /// In en, this message translates to:
  /// **'{name} updated display name from'**
  String chatDisplayNameUpdate(Object name);

  /// No description provided for @chatDisplayNameSet.
  ///
  /// In en, this message translates to:
  /// **'{name} set display name'**
  String chatDisplayNameSet(Object name);

  /// No description provided for @chatDisplayNameUnset.
  ///
  /// In en, this message translates to:
  /// **'{name} removed display name'**
  String chatDisplayNameUnset(Object name);

  /// No description provided for @chatUserAvatarChange.
  ///
  /// In en, this message translates to:
  /// **'{name} updated profile avatar'**
  String chatUserAvatarChange(Object name);

  /// No description provided for @dmChat.
  ///
  /// In en, this message translates to:
  /// **'DM Chat'**
  String get dmChat;

  /// No description provided for @regularSpaceOrChat.
  ///
  /// In en, this message translates to:
  /// **'Regular Space or Chat'**
  String get regularSpaceOrChat;

  /// No description provided for @encryptedSpaceOrChat.
  ///
  /// In en, this message translates to:
  /// **'Encrypted Space or Chat'**
  String get encryptedSpaceOrChat;

  /// No description provided for @encryptedChatInfo.
  ///
  /// In en, this message translates to:
  /// **'All messages in this chat are end-to-end encrypted. No one outside of this chat, not even Acter or any Matrix Server routing the message, can read them.'**
  String get encryptedChatInfo;

  /// No description provided for @removeThisPin.
  ///
  /// In en, this message translates to:
  /// **'Remove this Pin'**
  String get removeThisPin;

  /// No description provided for @removeThisPost.
  ///
  /// In en, this message translates to:
  /// **'Remove this post'**
  String get removeThisPost;

  /// No description provided for @removingContent.
  ///
  /// In en, this message translates to:
  /// **'Removing content'**
  String get removingContent;

  /// No description provided for @removingAttachment.
  ///
  /// In en, this message translates to:
  /// **'Removing attachment'**
  String get removingAttachment;

  /// No description provided for @reportThis.
  ///
  /// In en, this message translates to:
  /// **'Report this'**
  String get reportThis;

  /// No description provided for @reportThisPin.
  ///
  /// In en, this message translates to:
  /// **'Report this Pin'**
  String get reportThisPin;

  /// No description provided for @reportSendingFailedDueTo.
  ///
  /// In en, this message translates to:
  /// **'Report sending failed due to some: {error}'**
  String reportSendingFailedDueTo(Object error);

  /// No description provided for @resettingPassword.
  ///
  /// In en, this message translates to:
  /// **'Resetting your password'**
  String get resettingPassword;

  /// No description provided for @resettingPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Reset failed: {error}'**
  String resettingPasswordFailed(Object error);

  /// No description provided for @resettingPasswordSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Password successfully reset.'**
  String get resettingPasswordSuccessful;

  /// No description provided for @sharedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shared successfully'**
  String get sharedSuccessfully;

  /// No description provided for @changedPushNotificationSettingsSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Changed push notification settings successfully'**
  String get changedPushNotificationSettingsSuccessfully;

  /// No description provided for @startDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Start date required!'**
  String get startDateRequired;

  /// No description provided for @startTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Start time required!'**
  String get startTimeRequired;

  /// No description provided for @endDateRequired.
  ///
  /// In en, this message translates to:
  /// **'End date required!'**
  String get endDateRequired;

  /// No description provided for @endTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'End time required!'**
  String get endTimeRequired;

  /// No description provided for @searchUser.
  ///
  /// In en, this message translates to:
  /// **'search user'**
  String get searchUser;

  /// No description provided for @seeAllMyEvents.
  ///
  /// In en, this message translates to:
  /// **'See all my {count} events'**
  String seeAllMyEvents(Object count);

  /// No description provided for @selectSpace.
  ///
  /// In en, this message translates to:
  /// **'Select Space'**
  String get selectSpace;

  /// No description provided for @selectChat.
  ///
  /// In en, this message translates to:
  /// **'Select Chat'**
  String get selectChat;

  /// No description provided for @selectCustomDate.
  ///
  /// In en, this message translates to:
  /// **'Select specific date'**
  String get selectCustomDate;

  /// No description provided for @selectPicture.
  ///
  /// In en, this message translates to:
  /// **'Select Picture'**
  String get selectPicture;

  /// No description provided for @selectVideo.
  ///
  /// In en, this message translates to:
  /// **'Select Video'**
  String get selectVideo;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @sendDM.
  ///
  /// In en, this message translates to:
  /// **'Send DM'**
  String get sendDM;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'show less'**
  String get showLess;

  /// No description provided for @joinSpace.
  ///
  /// In en, this message translates to:
  /// **'Join Space'**
  String get joinSpace;

  /// No description provided for @joinExistingSpace.
  ///
  /// In en, this message translates to:
  /// **'Join Existing Space'**
  String get joinExistingSpace;

  /// No description provided for @mySpaces.
  ///
  /// In en, this message translates to:
  /// **'My Spaces'**
  String get mySpaces;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @startGroupDM.
  ///
  /// In en, this message translates to:
  /// **'Start Group DM'**
  String get startGroupDM;

  /// No description provided for @moreSubspaces.
  ///
  /// In en, this message translates to:
  /// **'More Subspaces'**
  String get moreSubspaces;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @updatingDueFailed.
  ///
  /// In en, this message translates to:
  /// **'Updating due failed: {error}'**
  String updatingDueFailed(Object error);

  /// No description provided for @unlinkRoom.
  ///
  /// In en, this message translates to:
  /// **'Unlink Chat'**
  String get unlinkRoom;

  /// No description provided for @changeThePowerFromTo.
  ///
  /// In en, this message translates to:
  /// **'from {memberStatus} {currentPowerLevel} to'**
  String changeThePowerFromTo(Object currentPowerLevel, Object memberStatus);

  /// No description provided for @createOrJoinSpaceDescription.
  ///
  /// In en, this message translates to:
  /// **'Create or join a space, to start organizing and collaborating!'**
  String get createOrJoinSpaceDescription;

  /// No description provided for @introPageDescriptionPre.
  ///
  /// In en, this message translates to:
  /// **'Acter is more than just an app.\nIt’s'**
  String get introPageDescriptionPre;

  /// No description provided for @isLinked.
  ///
  /// In en, this message translates to:
  /// **'is linked in here'**
  String get isLinked;

  /// No description provided for @canLink.
  ///
  /// In en, this message translates to:
  /// **'You can link this'**
  String get canLink;

  /// No description provided for @canLinkButNotUpgrade.
  ///
  /// In en, this message translates to:
  /// **'You can link this, but not update its join permissions'**
  String get canLinkButNotUpgrade;

  /// No description provided for @introPageDescriptionHl.
  ///
  /// In en, this message translates to:
  /// **' community of change makers.'**
  String get introPageDescriptionHl;

  /// No description provided for @introPageDescriptionPost.
  ///
  /// In en, this message translates to:
  /// **' '**
  String get introPageDescriptionPost;

  /// No description provided for @introPageDescription2ndLine.
  ///
  /// In en, this message translates to:
  /// **'Connect with fellow activists, share insights, and collaborate on creating meaningful change.'**
  String get introPageDescription2ndLine;

  /// No description provided for @logOutConformationDescription1.
  ///
  /// In en, this message translates to:
  /// **'Attention: '**
  String get logOutConformationDescription1;

  /// No description provided for @logOutConformationDescription2.
  ///
  /// In en, this message translates to:
  /// **'Logging out removes the local data, including encryption keys. If this is your last signed-in device you might no be able to decrypt any previous content.'**
  String get logOutConformationDescription2;

  /// No description provided for @logOutConformationDescription3.
  ///
  /// In en, this message translates to:
  /// **' Are you sure you want to log out?'**
  String get logOutConformationDescription3;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Members'**
  String membersCount(Object count);

  /// No description provided for @renderSyncingTitle.
  ///
  /// In en, this message translates to:
  /// **'Syncing with your homeserver'**
  String get renderSyncingTitle;

  /// No description provided for @renderSyncingSubTitle.
  ///
  /// In en, this message translates to:
  /// **'This might take a while if you have a large account'**
  String get renderSyncingSubTitle;

  /// No description provided for @errorSyncing.
  ///
  /// In en, this message translates to:
  /// **'Error syncing: {error}'**
  String errorSyncing(Object error);

  /// No description provided for @retrying.
  ///
  /// In en, this message translates to:
  /// **'retrying …'**
  String get retrying;

  /// No description provided for @retryIn.
  ///
  /// In en, this message translates to:
  /// **'Will retry in {minutes}:{seconds}'**
  String retryIn(Object minutes, Object seconds);

  /// No description provided for @invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// No description provided for @invitingLoading.
  ///
  /// In en, this message translates to:
  /// **'Inviting {userId}'**
  String invitingLoading(Object userId);

  /// No description provided for @invitingError.
  ///
  /// In en, this message translates to:
  /// **'User {userId} not found or existing: {error}'**
  String invitingError(Object error, Object userId);

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @errorUnverifiedSessions.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load unverified sessions: {error}'**
  String errorUnverifiedSessions(Object error);

  /// No description provided for @unverifiedSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'There are {count} unverified sessions logged in'**
  String unverifiedSessionsTitle(Object count);

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @activitiesDescription.
  ///
  /// In en, this message translates to:
  /// **'All the important stuff requiring your attention can be found here'**
  String get activitiesDescription;

  /// No description provided for @noActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No Activity for you yet'**
  String get noActivityTitle;

  /// No description provided for @noActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifies you about important things such as messages, invitations or requests.'**
  String get noActivitySubtitle;

  /// No description provided for @joining.
  ///
  /// In en, this message translates to:
  /// **'Joining'**
  String get joining;

  /// No description provided for @joinedDelayed.
  ///
  /// In en, this message translates to:
  /// **'Accepted invitation, confirmation takes its time though'**
  String get joinedDelayed;

  /// No description provided for @rejecting.
  ///
  /// In en, this message translates to:
  /// **'Rejecting'**
  String get rejecting;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @failedToReject.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject'**
  String get failedToReject;

  /// No description provided for @reportedBugSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Reported the bug successfully! (#{issueId})'**
  String reportedBugSuccessful(Object issueId);

  /// No description provided for @thanksForReport.
  ///
  /// In en, this message translates to:
  /// **'Thanks for reporting that bug!'**
  String get thanksForReport;

  /// No description provided for @bugReportingError.
  ///
  /// In en, this message translates to:
  /// **'Bug reporting error: {error}'**
  String bugReportingError(Object error);

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get bugReportTitle;

  /// No description provided for @bugReportDescription.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the issue'**
  String get bugReportDescription;

  /// No description provided for @emptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter description'**
  String get emptyDescription;

  /// No description provided for @includeUserId.
  ///
  /// In en, this message translates to:
  /// **'Include my Matrix ID'**
  String get includeUserId;

  /// No description provided for @includeLog.
  ///
  /// In en, this message translates to:
  /// **'Include current logs'**
  String get includeLog;

  /// No description provided for @includePrevLog.
  ///
  /// In en, this message translates to:
  /// **'Include logs from previous run'**
  String get includePrevLog;

  /// No description provided for @includeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Include screenshot'**
  String get includeScreenshot;

  /// No description provided for @includeErrorAndStackTrace.
  ///
  /// In en, this message translates to:
  /// **'Include Error & Stacktrace'**
  String get includeErrorAndStackTrace;

  /// No description provided for @jumpTo.
  ///
  /// In en, this message translates to:
  /// **'jump to'**
  String get jumpTo;

  /// No description provided for @noMatchingPinsFound.
  ///
  /// In en, this message translates to:
  /// **'no matching pins found'**
  String get noMatchingPinsFound;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @taskList.
  ///
  /// In en, this message translates to:
  /// **'Task List'**
  String get taskList;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @poll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get poll;

  /// No description provided for @discussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get discussion;

  /// No description provided for @fatalError.
  ///
  /// In en, this message translates to:
  /// **'Fatal Error'**
  String get fatalError;

  /// No description provided for @nukeLocalData.
  ///
  /// In en, this message translates to:
  /// **'Nuke local data'**
  String get nukeLocalData;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report bug'**
  String get reportBug;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went terribly wrong:'**
  String get somethingWrong;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// No description provided for @errorCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Error & Stacktrace copied to clipboard'**
  String get errorCopiedToClipboard;

  /// No description provided for @showStacktrace.
  ///
  /// In en, this message translates to:
  /// **'Show Stacktrace'**
  String get showStacktrace;

  /// No description provided for @hideStacktrace.
  ///
  /// In en, this message translates to:
  /// **'Hide Stacktrace'**
  String get hideStacktrace;

  /// No description provided for @sharingRoom.
  ///
  /// In en, this message translates to:
  /// **'Sharing this Chat…'**
  String get sharingRoom;

  /// No description provided for @changingSettings.
  ///
  /// In en, this message translates to:
  /// **'Changing settings…'**
  String get changingSettings;

  /// No description provided for @changingSettingOf.
  ///
  /// In en, this message translates to:
  /// **'Changing setting of {module}'**
  String changingSettingOf(Object module);

  /// No description provided for @changedSettingOf.
  ///
  /// In en, this message translates to:
  /// **'Changed setting of {module}'**
  String changedSettingOf(Object module);

  /// No description provided for @changingPowerLevelOf.
  ///
  /// In en, this message translates to:
  /// **'Changing permission level of {module}'**
  String changingPowerLevelOf(Object module);

  /// No description provided for @assigningSelf.
  ///
  /// In en, this message translates to:
  /// **'Assigning self…'**
  String get assigningSelf;

  /// No description provided for @unassigningSelf.
  ///
  /// In en, this message translates to:
  /// **'Unassigning self…'**
  String get unassigningSelf;

  /// No description provided for @homeTabTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get homeTabTutorialTitle;

  /// No description provided for @homeTabTutorialDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you find your spaces and an overview of all upcoming events & pending tasks of these spaces.'**
  String get homeTabTutorialDescription;

  /// No description provided for @updatesTabTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updatesTabTutorialTitle;

  /// No description provided for @updatesTabTutorialDescription.
  ///
  /// In en, this message translates to:
  /// **'News stream on the latest updates & calls to action from your spaces.'**
  String get updatesTabTutorialDescription;

  /// No description provided for @chatsTabTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTabTutorialTitle;

  /// No description provided for @chatsTabTutorialDescription.
  ///
  /// In en, this message translates to:
  /// **'It’s the place to chat – with groups or individuals. chats can be linked to different spaces for broader collaboration.'**
  String get chatsTabTutorialDescription;

  /// No description provided for @activityTabTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTabTutorialTitle;

  /// No description provided for @activityTabTutorialDescription.
  ///
  /// In en, this message translates to:
  /// **'Important information from your spaces, like invitations or requests. Additionally you will get notified by Acter about security issues'**
  String get activityTabTutorialDescription;

  /// No description provided for @jumpToTabTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Jump To'**
  String get jumpToTabTutorialTitle;

  /// No description provided for @jumpToTabTutorialDescription.
  ///
  /// In en, this message translates to:
  /// **'Your search over spaces and pins, as well as quick actions and fast access to several sections'**
  String get jumpToTabTutorialDescription;

  /// No description provided for @createSpaceTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Space'**
  String get createSpaceTutorialTitle;

  /// No description provided for @createSpaceTutorialDescription.
  ///
  /// In en, this message translates to:
  /// **'Join an existing space on our Acter server or in the Matrix universe or set up your own space.'**
  String get createSpaceTutorialDescription;

  /// No description provided for @joinSpaceTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Existing Space'**
  String get joinSpaceTutorialTitle;

  /// No description provided for @joinSpaceTutorialDescription.
  ///
  /// In en, this message translates to:
  /// **'Join an existing space on our Acter server or in the Matrix universe or set up your own space. [would just show the options & end there for now]'**
  String get joinSpaceTutorialDescription;

  /// No description provided for @spaceOverviewTutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Space Details'**
  String get spaceOverviewTutorialTitle;

  /// No description provided for @spaceOverviewTutorialDescription.
  ///
  /// In en, this message translates to:
  /// **'A space is the starting point for your organizing. Create & navigate through pins (resources), tasks and events. Add chats or subspaces.'**
  String get spaceOverviewTutorialDescription;

  /// No description provided for @subscribedToParentMsg.
  ///
  /// In en, this message translates to:
  /// **'Disable Notifications on main object to configure notification here'**
  String get subscribedToParentMsg;

  /// No description provided for @parentSubscribedAction.
  ///
  /// In en, this message translates to:
  /// **'Notifications active through object'**
  String get parentSubscribedAction;

  /// No description provided for @subscribeAction.
  ///
  /// In en, this message translates to:
  /// **'Activate Notifications'**
  String get subscribeAction;

  /// No description provided for @unsubscribeAction.
  ///
  /// In en, this message translates to:
  /// **'De-Activate Notifications'**
  String get unsubscribeAction;

  /// No description provided for @commentEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No comments found.'**
  String get commentEmptyStateTitle;

  /// No description provided for @commentEmptyStateAction.
  ///
  /// In en, this message translates to:
  /// **'Leave the first comment'**
  String get commentEmptyStateAction;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @saveUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Have you saved your username?'**
  String get saveUsernameTitle;

  /// No description provided for @saveUsernameDescription1.
  ///
  /// In en, this message translates to:
  /// **'Please remember to note down your username. It’s your key to access your profile and all information and spaces connected to it.'**
  String get saveUsernameDescription1;

  /// No description provided for @saveUsernameDescription2.
  ///
  /// In en, this message translates to:
  /// **'Your username is crucial for password resets.'**
  String get saveUsernameDescription2;

  /// No description provided for @saveUsernameDescription3.
  ///
  /// In en, this message translates to:
  /// **'Without it, access to your profile and progress will be permanently lost.'**
  String get saveUsernameDescription3;

  /// No description provided for @acterUsername.
  ///
  /// In en, this message translates to:
  /// **'Your Acter Username'**
  String get acterUsername;

  /// No description provided for @autoSubscribeFeatureDesc.
  ///
  /// In en, this message translates to:
  /// **'upon creation or interaction with objects'**
  String get autoSubscribeFeatureDesc;

  /// No description provided for @autoSubscribeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically subscribe '**
  String get autoSubscribeSettingsTitle;

  /// No description provided for @copyToClip.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClip;

  /// No description provided for @wizzardContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get wizzardContinue;

  /// No description provided for @protectPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Protecting your privacy'**
  String get protectPrivacyTitle;

  /// No description provided for @protectPrivacyDescription1.
  ///
  /// In en, this message translates to:
  /// **'In Acter, keeping your account secure is important. That’s why you can use it without linking your profile to your email for added privacy and protection.'**
  String get protectPrivacyDescription1;

  /// No description provided for @protectPrivacyDescription2.
  ///
  /// In en, this message translates to:
  /// **'But if you prefer, you can still link them together, e.g., for password recovery.'**
  String get protectPrivacyDescription2;

  /// No description provided for @linkEmailToProfile.
  ///
  /// In en, this message translates to:
  /// **'Linked Email to Profile'**
  String get linkEmailToProfile;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get hintEmail;

  /// No description provided for @linkingEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Linking your email address'**
  String get linkingEmailAddress;

  /// No description provided for @avatarAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add User Avatar'**
  String get avatarAddTitle;

  /// No description provided for @avatarEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please select your avatar'**
  String get avatarEmpty;

  /// No description provided for @avatarUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading profile avatar'**
  String get avatarUploading;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload user avatar: {error}'**
  String avatarUploadFailed(Object error);

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send email'**
  String get sendEmail;

  /// No description provided for @inviteCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Invite code copied to clipboard'**
  String get inviteCopiedToClipboard;

  /// No description provided for @updateName.
  ///
  /// In en, this message translates to:
  /// **'Updating name'**
  String get updateName;

  /// No description provided for @updateDescription.
  ///
  /// In en, this message translates to:
  /// **'Updating description'**
  String get updateDescription;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @editDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit Description'**
  String get editDescription;

  /// No description provided for @updateNameFailed.
  ///
  /// In en, this message translates to:
  /// **'Updating name failed: {error}'**
  String updateNameFailed(Object error);

  /// No description provided for @updateDescriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Updating description failed: {error}'**
  String updateDescriptionFailed(Object error);

  /// No description provided for @eventParticipants.
  ///
  /// In en, this message translates to:
  /// **'Event Participants'**
  String get eventParticipants;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents;

  /// No description provided for @spaceInviteDescription.
  ///
  /// In en, this message translates to:
  /// **'Anyone you would like to invite to this space?'**
  String get spaceInviteDescription;

  /// No description provided for @inviteSpaceMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Space Members'**
  String get inviteSpaceMembersTitle;

  /// No description provided for @inviteSpaceMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite users from selected space'**
  String get inviteSpaceMembersSubtitle;

  /// No description provided for @inviteIndividualUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite Individual Users'**
  String get inviteIndividualUsersTitle;

  /// No description provided for @inviteIndividualUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite users who are already on the Acter'**
  String get inviteIndividualUsersSubtitle;

  /// No description provided for @inviteIndividualUsersDescription.
  ///
  /// In en, this message translates to:
  /// **'Invite anyone who is part of the the Acter platform'**
  String get inviteIndividualUsersDescription;

  /// No description provided for @inviteJoinActer.
  ///
  /// In en, this message translates to:
  /// **'Invite to join Acter'**
  String get inviteJoinActer;

  /// No description provided for @inviteJoinActerDescription.
  ///
  /// In en, this message translates to:
  /// **'You can invite people to join Acter and automatically join this space with a custom registration code and share that with them'**
  String get inviteJoinActerDescription;

  /// No description provided for @generateInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Generate Invite Code'**
  String get generateInviteCode;

  /// No description provided for @pendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending Invites'**
  String get pendingInvites;

  /// No description provided for @pendingInvitesCount.
  ///
  /// In en, this message translates to:
  /// **'You have {count} pending Invites'**
  String pendingInvitesCount(Object count);

  /// No description provided for @noPendingInvitesTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending Invites found'**
  String get noPendingInvitesTitle;

  /// No description provided for @noUserFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUserFoundTitle;

  /// No description provided for @noUserFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search users with their username or display name'**
  String get noUserFoundSubtitle;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @downloadFileDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Please select where to store the file'**
  String get downloadFileDialogTitle;

  /// No description provided for @downloadFileSuccess.
  ///
  /// In en, this message translates to:
  /// **'File saved to {path}'**
  String downloadFileSuccess(Object path);

  /// No description provided for @cancelInviteLoading.
  ///
  /// In en, this message translates to:
  /// **'Canceling invitation of {userId}'**
  String cancelInviteLoading(Object userId);

  /// No description provided for @cancelInviteError.
  ///
  /// In en, this message translates to:
  /// **'User {userId} not found: {error}'**
  String cancelInviteError(Object error, Object userId);

  /// No description provided for @shareInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Share Invite Code'**
  String get shareInviteCode;

  /// No description provided for @appUnavailable.
  ///
  /// In en, this message translates to:
  /// **'App Unavailable'**
  String get appUnavailable;

  /// No description provided for @shareInviteContent.
  ///
  /// In en, this message translates to:
  /// **'{userName} would like to invite you to the {roomName}.\nPlease follow below steps to join:\n\nSTEP-1: Download the Acter App from below links https://app-redir.acter.global/\n\nSTEP-2: Use the below invitation code on the registration.\nInvitation Code : {code}\n\nThat’s it! Enjoy the new safe and secure way of organizing!'**
  String shareInviteContent(Object code, Object roomName, Object userName);

  /// No description provided for @activateInviteCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Activate code failed: {error}'**
  String activateInviteCodeFailed(Object error);

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @otherSpaces.
  ///
  /// In en, this message translates to:
  /// **'Other Spaces'**
  String get otherSpaces;

  /// No description provided for @invitingSpaceMembersLoading.
  ///
  /// In en, this message translates to:
  /// **'Inviting Space Members'**
  String get invitingSpaceMembersLoading;

  /// No description provided for @invitingSpaceMembersProgress.
  ///
  /// In en, this message translates to:
  /// **'Inviting Space Member {count} / {total}'**
  String invitingSpaceMembersProgress(Object count, Object total);

  /// No description provided for @invitingSpaceMembersError.
  ///
  /// In en, this message translates to:
  /// **'Inviting Space Members Error: {error}'**
  String invitingSpaceMembersError(Object error);

  /// No description provided for @membersInvited.
  ///
  /// In en, this message translates to:
  /// **'{count} members invited'**
  String membersInvited(Object count);

  /// No description provided for @selectVisibility.
  ///
  /// In en, this message translates to:
  /// **'Select Visibility'**
  String get selectVisibility;

  /// No description provided for @visibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibilityTitle;

  /// No description provided for @visibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select who can join this space.'**
  String get visibilitySubtitle;

  /// No description provided for @visibilityNoPermission.
  ///
  /// In en, this message translates to:
  /// **'You don’t have necessary permissions to change this space visibility'**
  String get visibilityNoPermission;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @publicVisibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anyone can find and join'**
  String get publicVisibilitySubtitle;

  /// No description provided for @privateVisibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only invited people can join'**
  String get privateVisibilitySubtitle;

  /// No description provided for @limited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get limited;

  /// No description provided for @limitedVisibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anyone in selected spaces can find and join'**
  String get limitedVisibilitySubtitle;

  /// No description provided for @visibilityAndAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility and Accessibility'**
  String get visibilityAndAccessibility;

  /// No description provided for @updatingVisibilityFailed.
  ///
  /// In en, this message translates to:
  /// **'Updating room visibility failed: {error}'**
  String updatingVisibilityFailed(Object error);

  /// No description provided for @spaceWithAccess.
  ///
  /// In en, this message translates to:
  /// **'Space with access'**
  String get spaceWithAccess;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Change your Password'**
  String get changePasswordDescription;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @emptyOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter old password'**
  String get emptyOldPassword;

  /// No description provided for @emptyNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter new password'**
  String get emptyNewPassword;

  /// No description provided for @emptyConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter confirm password'**
  String get emptyConfirmPassword;

  /// No description provided for @validateSamePassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be same'**
  String get validateSamePassword;

  /// No description provided for @changingYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Changing your password'**
  String get changingYourPassword;

  /// No description provided for @changePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Change password failed: {error}'**
  String changePasswordFailed(Object error);

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @emptyTaskList.
  ///
  /// In en, this message translates to:
  /// **'No Task list created yet'**
  String get emptyTaskList;

  /// No description provided for @addMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Add More Details'**
  String get addMoreDetails;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get taskName;

  /// No description provided for @addingTask.
  ///
  /// In en, this message translates to:
  /// **'Adding Task'**
  String get addingTask;

  /// No description provided for @countTasksCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count} Completed'**
  String countTasksCompleted(Object count);

  /// No description provided for @showCompleted.
  ///
  /// In en, this message translates to:
  /// **'Show Completed'**
  String get showCompleted;

  /// No description provided for @hideCompleted.
  ///
  /// In en, this message translates to:
  /// **'Hide Completed'**
  String get hideCompleted;

  /// No description provided for @assignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get assignment;

  /// No description provided for @noAssignment.
  ///
  /// In en, this message translates to:
  /// **'No Assignment'**
  String get noAssignment;

  /// No description provided for @assignMyself.
  ///
  /// In en, this message translates to:
  /// **'Assign Myself'**
  String get assignMyself;

  /// No description provided for @removeMyself.
  ///
  /// In en, this message translates to:
  /// **'Remove Myself'**
  String get removeMyself;

  /// No description provided for @updateTask.
  ///
  /// In en, this message translates to:
  /// **'Update Task'**
  String get updateTask;

  /// No description provided for @updatingTask.
  ///
  /// In en, this message translates to:
  /// **'Updating Task'**
  String get updatingTask;

  /// No description provided for @updatingTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Updating Task failed {error}'**
  String updatingTaskFailed(Object error);

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Title'**
  String get editTitle;

  /// No description provided for @updatingDescription.
  ///
  /// In en, this message translates to:
  /// **'Updating Description'**
  String get updatingDescription;

  /// No description provided for @errorUpdatingDescription.
  ///
  /// In en, this message translates to:
  /// **'Error updating description: {error}'**
  String errorUpdatingDescription(Object error);

  /// No description provided for @editLink.
  ///
  /// In en, this message translates to:
  /// **'Edit Link'**
  String get editLink;

  /// No description provided for @updatingLinking.
  ///
  /// In en, this message translates to:
  /// **'Updating link'**
  String get updatingLinking;

  /// No description provided for @deleteTaskList.
  ///
  /// In en, this message translates to:
  /// **'Delete Task List'**
  String get deleteTaskList;

  /// No description provided for @deleteTaskItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Task Item'**
  String get deleteTaskItem;

  /// No description provided for @reportTaskList.
  ///
  /// In en, this message translates to:
  /// **'Report Task List'**
  String get reportTaskList;

  /// No description provided for @reportTaskItem.
  ///
  /// In en, this message translates to:
  /// **'Report Task Item'**
  String get reportTaskItem;

  /// No description provided for @unconfirmedEmailsActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'You have unconfirmed E-Mail Addresses'**
  String get unconfirmedEmailsActivityTitle;

  /// No description provided for @unconfirmedEmailsActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please follow the link we’ve sent you in the email and then confirm them here'**
  String get unconfirmedEmailsActivitySubtitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @addPin.
  ///
  /// In en, this message translates to:
  /// **'Add Pin'**
  String get addPin;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add Event'**
  String get addEvent;

  /// No description provided for @linkChat.
  ///
  /// In en, this message translates to:
  /// **'Link Chat'**
  String get linkChat;

  /// No description provided for @linkSpace.
  ///
  /// In en, this message translates to:
  /// **'Link Space'**
  String get linkSpace;

  /// No description provided for @failedToUploadAvatar.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar: {error}'**
  String failedToUploadAvatar(Object error);

  /// No description provided for @noMatchingTasksListFound.
  ///
  /// In en, this message translates to:
  /// **'No matching tasks list found'**
  String get noMatchingTasksListFound;

  /// No description provided for @noTasksListAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks list available yet'**
  String get noTasksListAvailableYet;

  /// No description provided for @noTasksListAvailableDescription.
  ///
  /// In en, this message translates to:
  /// **'Share and manage important task with your community such as any TO-DO list so everyone is updated.'**
  String get noTasksListAvailableDescription;

  /// No description provided for @loadingMembersFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading members failed: {error}'**
  String loadingMembersFailed(Object error);

  /// No description provided for @ongoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get ongoing;

  /// No description provided for @noMatchingEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No matching events found'**
  String get noMatchingEventsFound;

  /// No description provided for @noEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get noEventsFound;

  /// No description provided for @noEventAvailableDescription.
  ///
  /// In en, this message translates to:
  /// **'Create new event and bring your community together.'**
  String get noEventAvailableDescription;

  /// No description provided for @myEvents.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEvents;

  /// No description provided for @eventStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get eventStarted;

  /// No description provided for @eventStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get eventStarts;

  /// No description provided for @eventEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get eventEnded;

  /// No description provided for @happeningNow.
  ///
  /// In en, this message translates to:
  /// **'Happening Now'**
  String get happeningNow;

  /// No description provided for @myUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'My Upcoming Events'**
  String get myUpcomingEvents;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @forbidden.
  ///
  /// In en, this message translates to:
  /// **'Forbidden'**
  String get forbidden;

  /// No description provided for @forbiddenRoomExplainer.
  ///
  /// In en, this message translates to:
  /// **'Access to the room has been denied. Please contact the author to be invited'**
  String get forbiddenRoomExplainer;

  /// No description provided for @accessDeniedToRoom.
  ///
  /// In en, this message translates to:
  /// **'Access to {roomId} denied'**
  String accessDeniedToRoom(Object roomId);

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get changeDate;

  /// No description provided for @deepLinkNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Link {link} not supported'**
  String deepLinkNotSupported(Object link);

  /// No description provided for @deepLinkWrongFormat.
  ///
  /// In en, this message translates to:
  /// **'Not a link. Can\'t open.'**
  String get deepLinkWrongFormat;

  /// No description provided for @updatingDate.
  ///
  /// In en, this message translates to:
  /// **'Updating Date'**
  String get updatingDate;

  /// No description provided for @pleaseEnterALink.
  ///
  /// In en, this message translates to:
  /// **'Please enter a link'**
  String get pleaseEnterALink;

  /// No description provided for @pleaseEnterAValidLink.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid link'**
  String get pleaseEnterAValidLink;

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'Add Link'**
  String get addLink;

  /// No description provided for @attachmentEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No attachments found.'**
  String get attachmentEmptyStateTitle;

  /// No description provided for @referencesEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No references found.'**
  String get referencesEmptyStateTitle;

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get text;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @pinDetails.
  ///
  /// In en, this message translates to:
  /// **'Pin Details'**
  String get pinDetails;

  /// No description provided for @inSpaceLabelInline.
  ///
  /// In en, this message translates to:
  /// **'In:'**
  String get inSpaceLabelInline;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Not supported yet, coming soon!'**
  String get comingSoon;

  /// No description provided for @colonCharacter.
  ///
  /// In en, this message translates to:
  /// **' : '**
  String get colonCharacter;

  /// No description provided for @andSeparator.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andSeparator;

  /// No description provided for @andNMore.
  ///
  /// In en, this message translates to:
  /// **', and {count} more'**
  String andNMore(Object count);

  /// No description provided for @errorLoadingSpaces.
  ///
  /// In en, this message translates to:
  /// **'Error loading spaces: {error}'**
  String errorLoadingSpaces(Object error);

  /// No description provided for @eventNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Event no longer available'**
  String get eventNoLongerAvailable;

  /// No description provided for @eventDeletedOrFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'This may due to event deletion or failed to load'**
  String get eventDeletedOrFailedToLoad;

  /// No description provided for @chatNotEncrypted.
  ///
  /// In en, this message translates to:
  /// **'This chat is not end-to-end-encrypted'**
  String get chatNotEncrypted;

  /// No description provided for @updatingIcon.
  ///
  /// In en, this message translates to:
  /// **'Updating Icon'**
  String get updatingIcon;

  /// No description provided for @selectColor.
  ///
  /// In en, this message translates to:
  /// **'Select color'**
  String get selectColor;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select icon'**
  String get selectIcon;

  /// No description provided for @createCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get createCategory;

  /// No description provided for @organize.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get organize;

  /// No description provided for @updatingCategories.
  ///
  /// In en, this message translates to:
  /// **'Updating categories'**
  String get updatingCategories;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @updatingCategoriesFailed.
  ///
  /// In en, this message translates to:
  /// **'Updating categories failed {error}'**
  String updatingCategoriesFailed(Object error);

  /// No description provided for @addingNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Adding new category'**
  String get addingNewCategory;

  /// No description provided for @addingNewCategoriesFailed.
  ///
  /// In en, this message translates to:
  /// **'Adding new category failed {error}'**
  String addingNewCategoriesFailed(Object error);

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @boost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get boost;

  /// No description provided for @boosts.
  ///
  /// In en, this message translates to:
  /// **'Boosts'**
  String get boosts;

  /// No description provided for @requiredPowerLevel.
  ///
  /// In en, this message translates to:
  /// **'Required PowerLevel'**
  String get requiredPowerLevel;

  /// No description provided for @minPowerLevelDesc.
  ///
  /// In en, this message translates to:
  /// **'Minimum power level required to post {featureName}'**
  String minPowerLevelDesc(Object featureName);

  /// No description provided for @minPowerLevelRsvp.
  ///
  /// In en, this message translates to:
  /// **'Minimum power level to RSVP to calendar events'**
  String get minPowerLevelRsvp;

  /// No description provided for @commentsOnBoost.
  ///
  /// In en, this message translates to:
  /// **'Comments on Boost'**
  String get commentsOnBoost;

  /// No description provided for @commentsOnPin.
  ///
  /// In en, this message translates to:
  /// **'Comments on Pin'**
  String get commentsOnPin;

  /// No description provided for @adminPowerLevel.
  ///
  /// In en, this message translates to:
  /// **'Admin PowerLevel'**
  String get adminPowerLevel;

  /// No description provided for @rsvpPowerLevel.
  ///
  /// In en, this message translates to:
  /// **'RSVP PowerLevel'**
  String get rsvpPowerLevel;

  /// No description provided for @taskListPowerLevel.
  ///
  /// In en, this message translates to:
  /// **'TaskList PowerLevel'**
  String get taskListPowerLevel;

  /// No description provided for @tasksPowerLevel.
  ///
  /// In en, this message translates to:
  /// **'Tasks PowerLevel'**
  String get tasksPowerLevel;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @activeApps.
  ///
  /// In en, this message translates to:
  /// **'Active Apps'**
  String get activeApps;

  /// No description provided for @postSpaceWiseBoost.
  ///
  /// In en, this message translates to:
  /// **'Post space-wide boost'**
  String get postSpaceWiseBoost;

  /// No description provided for @postSpaceWiseStories.
  ///
  /// In en, this message translates to:
  /// **'Post space-wide stories'**
  String get postSpaceWiseStories;

  /// No description provided for @pinImportantInformation.
  ///
  /// In en, this message translates to:
  /// **'Pin important information'**
  String get pinImportantInformation;

  /// No description provided for @calenderWithEvents.
  ///
  /// In en, this message translates to:
  /// **'Calender with Events'**
  String get calenderWithEvents;

  /// No description provided for @pinNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Pin no longer available'**
  String get pinNoLongerAvailable;

  /// No description provided for @inviteCodeEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No invite codes are generated yet'**
  String get inviteCodeEmptyState;

  /// No description provided for @pinDeletedOrFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'This may due to pin deletion or failed to load'**
  String get pinDeletedOrFailedToLoad;

  /// No description provided for @sharePin.
  ///
  /// In en, this message translates to:
  /// **'Share Pin'**
  String get sharePin;

  /// No description provided for @selectPin.
  ///
  /// In en, this message translates to:
  /// **'Select Pin'**
  String get selectPin;

  /// No description provided for @selectEvent.
  ///
  /// In en, this message translates to:
  /// **'Select Event'**
  String get selectEvent;

  /// No description provided for @shareTaskList.
  ///
  /// In en, this message translates to:
  /// **'Share TaskList'**
  String get shareTaskList;

  /// No description provided for @shareSpace.
  ///
  /// In en, this message translates to:
  /// **'Share Space'**
  String get shareSpace;

  /// No description provided for @shareChat.
  ///
  /// In en, this message translates to:
  /// **'Share Chat'**
  String get shareChat;

  /// No description provided for @addBoost.
  ///
  /// In en, this message translates to:
  /// **'Add Boost'**
  String get addBoost;

  /// No description provided for @addTaskList.
  ///
  /// In en, this message translates to:
  /// **'Add TaskList'**
  String get addTaskList;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @signal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get signal;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @whatsAppBusiness.
  ///
  /// In en, this message translates to:
  /// **'WA Business'**
  String get whatsAppBusiness;

  /// No description provided for @telegram.
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get telegram;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'copy'**
  String get copy;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @qr.
  ///
  /// In en, this message translates to:
  /// **'QR'**
  String get qr;

  /// No description provided for @newBoost.
  ///
  /// In en, this message translates to:
  /// **'New\nBoost'**
  String get newBoost;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add Comment'**
  String get addComment;

  /// No description provided for @references.
  ///
  /// In en, this message translates to:
  /// **'References'**
  String get references;

  /// No description provided for @removeReference.
  ///
  /// In en, this message translates to:
  /// **'Remove Reference'**
  String get removeReference;

  /// No description provided for @suggestedChats.
  ///
  /// In en, this message translates to:
  /// **'Suggested Chats'**
  String get suggestedChats;

  /// No description provided for @suggestedSpaces.
  ///
  /// In en, this message translates to:
  /// **'Suggested Spaces'**
  String get suggestedSpaces;

  /// No description provided for @removeReferenceConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this reference?'**
  String get removeReferenceConfirmation;

  /// No description provided for @noObjectAccess.
  ///
  /// In en, this message translates to:
  /// **'You are not part of {spaceName} so you can\'t access this {objectType}'**
  String noObjectAccess(Object objectType, Object spaceName);

  /// No description provided for @shareLink.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shareLink;

  /// No description provided for @shareSuperInvite.
  ///
  /// In en, this message translates to:
  /// **'Share Invitation Code'**
  String get shareSuperInvite;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @unableToLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Unable to load video'**
  String get unableToLoadVideo;

  /// No description provided for @unableToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to load image'**
  String get unableToLoadImage;

  /// No description provided for @story.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get story;

  /// No description provided for @storyInfo.
  ///
  /// In en, this message translates to:
  /// **'Everyone can see, this is from you'**
  String get storyInfo;

  /// No description provided for @boostInfo.
  ///
  /// In en, this message translates to:
  /// **'Important News. Sends a push notification to space members'**
  String get boostInfo;

  /// No description provided for @notHaveBoostStoryPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to post Boost or Story in selected space'**
  String get notHaveBoostStoryPermission;

  /// No description provided for @pleaseSelectePostType.
  ///
  /// In en, this message translates to:
  /// **'Please select post type'**
  String get pleaseSelectePostType;

  /// No description provided for @postTo.
  ///
  /// In en, this message translates to:
  /// **'Post to'**
  String get postTo;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @stories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get stories;

  /// No description provided for @addStory.
  ///
  /// In en, this message translates to:
  /// **'Add Story'**
  String get addStory;

  /// No description provided for @unableToLoadFile.
  ///
  /// In en, this message translates to:
  /// **'Unable to load file'**
  String get unableToLoadFile;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'da', 'de', 'en', 'es', 'fr', 'pl', 'sw', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return L10nAr();
    case 'da': return L10nDa();
    case 'de': return L10nDe();
    case 'en': return L10nEn();
    case 'es': return L10nEs();
    case 'fr': return L10nFr();
    case 'pl': return L10nPl();
    case 'sw': return L10nSw();
    case 'ur': return L10nUr();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
