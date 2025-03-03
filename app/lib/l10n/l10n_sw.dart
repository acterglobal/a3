// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class L10nSw extends L10n {
  L10nSw([String locale = 'sw']) : super(locale);

  @override
  String get about => 'Kuhusu';

  @override
  String get accept => 'Kubali';

  @override
  String get acceptRequest => 'Kubali Ombi';

  @override
  String get access => 'Ufikiaji';

  @override
  String get accessAndVisibility => 'Ufikiaji na Mwonekano';

  @override
  String get account => 'Akaunti';

  @override
  String get actionName => 'Jina la Kitendo';

  @override
  String get actions => 'Kitendo';

  @override
  String activateFeatureDialogTitle(Object feature) {
    return 'Washa $feature';
  }

  @override
  String activateFeatureDialogDesc(Object feature) {
    return 'Ruhusu mtu yeyote aliye na ruhusa kufuatia ruhusa kutumia $feature';
  }

  @override
  String get add => 'Ongeza';

  @override
  String get addActionWidget => 'Ongeza wijeti ya kitendo';

  @override
  String get addChat => 'Ongeza Maongezi';

  @override
  String addedToPusherList(Object email) {
    return '$email imeongezwa kwenye orodha ya visukuma';
  }

  @override
  String addedToSpacesAndChats(Object number) {
    return 'Imeongezwa kwa nafasi na Maongezi$number';
  }

  @override
  String get addingEmailAddress => 'Inaongeza barua pepe';

  @override
  String get addSpace => 'Ongeza Nafasi';

  @override
  String get addTask => 'Ongeza Kazi';

  @override
  String get admin => 'Kiongozi';

  @override
  String get all => 'Zote';

  @override
  String get allMessages => 'Ujumbe Zote';

  @override
  String allReactionsCount(Object total) {
    return 'All $total';
  }

  @override
  String get alreadyConfirmed => 'Tayari imethibitishwa';

  @override
  String get analyticsTitle => 'Tusaidie tukusaidia';

  @override
  String get analyticsDescription1 => 'Kwa kushiriki nasi takwimu za kuacha kufanya kazi na ripoti za makosa.';

  @override
  String get analyticsDescription2 => 'Bila shaka haya hayatambuliwi na hayana taarifa zozote za faragha';

  @override
  String get sendCrashReportsTitle => 'Tuma ripoti za kuacha kufanya kazi na makosa';

  @override
  String get sendCrashReportsInfo => 'Shiriki ufuatiliaji wa ajali kupitia mtumaji na timu ya Acter kiotomatiki';

  @override
  String get and => 'ongeza';

  @override
  String get anInviteCodeYouWantToRedeem => 'Msimbo wa mwaliko unaotaka kukomboa';

  @override
  String get anyNumber => 'nambari yoyote';

  @override
  String get appDefaults => 'Ongeza chaguomsingi';

  @override
  String get appId => 'Kitambulisho cha programu';

  @override
  String get appName => 'Jina la Programu';

  @override
  String get apps => 'Vipengele vya Nafasi';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'Je, una uhakika unataka kufuta ujumbe huu? Kitendo hiki hakiwezi kutenduliwa.';

  @override
  String get areYouSureYouWantToLeaveRoom => 'Je, una uhakika unataka kuondoka kwenye maongezi? Kitendo hiki hakiwezi kutenduliwa';

  @override
  String get areYouSureYouWantToLeaveSpace => 'Je, una uhakika ungependa kuondoka kwenye nafasi hii?';

  @override
  String get areYouSureYouWantToRemoveAttachmentFromPin => 'Je, una uhakika unataka kuondoa kiambatisho hiki kwenye pini?';

  @override
  String get areYouSureYouWantToUnregisterEmailAddress => 'Je, una uhakika unataka kubatilisha usajili wa barua pepe hii? Kitendo hiki hakiwezi kutenduliwa.';

  @override
  String get assignedYourself => 'umejikabidhi';

  @override
  String get assignmentWithdrawn => 'Mgawo umeondolewa';

  @override
  String get aTaskMustHaveATitle => 'Jukumu lazima liwe na kichwa';

  @override
  String get attachments => 'faili/kiambatisho';

  @override
  String get atThisMomentYouAreNotJoiningEvents => 'Kwa sasa, haujiungi na matukio yoyote yanayokuja. Ili kujua ni matukio gani yameratibiwa, angalia nafasi zako.';

  @override
  String get authenticationRequired => 'Uthibitishaji unahitajika';

  @override
  String get avatar => 'wasifu';

  @override
  String get awaitingConfirmation => 'Inasubiri uthibitisho';

  @override
  String get awaitingConfirmationDescription => 'Barua pepe hizi bado hazijathibitishwa. Tafadhali nenda kwenye kikasha chako na uangalie kiungo cha uthibitishaji.';

  @override
  String get back => 'Nyuma';

  @override
  String get block => 'kuzuia';

  @override
  String get blockedUsers => 'Watumiaji Waliozuiwa';

  @override
  String get blockInfoText => 'Ukizuiwa hutaona tena ujumbe wao na itazuia jaribio lao la kuwasiliana nawe moja kwa moja.';

  @override
  String blockingUserFailed(Object error) {
    return 'Kuzuia Mtumiaji kumeshindwa: $error';
  }

  @override
  String get blockingUserProgress => 'Kuzuia Mtumiaji';

  @override
  String get blockingUserSuccess => 'Mtumiaji amezuiwa. Huenda ikachukua muda kabla ya UI kuonyesha sasisho hili.';

  @override
  String blockTitle(Object userId) {
    return 'Mzuie $userId';
  }

  @override
  String get blockUser => 'Zuia Mtumiaji';

  @override
  String get blockUserOptional => 'Zuia Mtumiaji (si lazima)';

  @override
  String get blockUserWithUsername => 'Zuia mtumiaji kwa kutumia jina la mtumiaji';

  @override
  String get bookmark => 'Alamisho';

  @override
  String get bookmarked => 'Alamisho';

  @override
  String get bookmarkedSpaces => 'Nafasi Zilizoalamishwa';

  @override
  String get builtOnShouldersOfGiants => 'Imejengwa kwenye mabega ya majitu';

  @override
  String get calendarEventsFromAllTheSpaces => 'Matukio ya kalenda kutoka Spaces zote unazoshiriki';

  @override
  String get calendar => 'Kalenda';

  @override
  String get calendarSyncFeatureTitle => 'Usawazishaji wa Kalenda';

  @override
  String get calendarSyncFeatureDesc => 'Sawazisha matukio (ya muda na yanayokubalika) kwa kutumia kalenda ya kifaa (Android na iOS pekee)';

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
  String get camera => 'kamera';

  @override
  String get cancel => 'Ghairi';

  @override
  String get cannotEditSpaceWithNoPermissions => 'Haiwezi kuhariri nafasi bila ruhusa';

  @override
  String get changeAppLanguage => 'Badilisha Lugha ya Programu';

  @override
  String get changePowerLevel => 'Badilisha Kiwango cha Ruhusa';

  @override
  String get changeThePowerLevelOf => 'Badilisha kiwango cha ruhusa cha';

  @override
  String get changeYourDisplayName => 'Badilisha jina lako la kuonyesha';

  @override
  String get chat => 'Maongezi';

  @override
  String get chatNG => 'Next-Generation Chat';

  @override
  String get chatNGExplainer => 'Switch to next generation Chat. Features might not be stable';

  @override
  String get customizationsTitle => 'Customizations';

  @override
  String get chatMissingPermissionsToSend => 'Huna ruhusa ya kutuma ujumbe hapa';

  @override
  String get behaviorSettingsTitle => 'Behavior';

  @override
  String get behaviorSettingsExplainer => 'Configure the behavior of your App';

  @override
  String get chatSettingsAutoDownload => 'Pakua Media Kiotomatiki';

  @override
  String get chatSettingsAutoDownloadExplainer => 'Wakati wa kupakua media kiotomatiki';

  @override
  String get chatSettingsAutoDownloadAlways => 'Daima';

  @override
  String get chatSettingsAutoDownloadWifiOnly => 'Wakati tu kwenye WiFi';

  @override
  String get chatSettingsAutoDownloadNever => 'Kamwe';

  @override
  String get settingsSubmitting => 'Inawasilisha Mipangilio';

  @override
  String get settingsSubmittingSuccess => 'Mipangilio imewasilishwa';

  @override
  String settingsSubmittingFailed(Object error) {
    return 'Imeshindwa kuwasilisha: $error ';
  }

  @override
  String get chatRoomCreated => 'Maongezi Imeundwa';

  @override
  String get chatSendingFailed => 'Imeshindwa kutuma. Itajaribu tena...';

  @override
  String get chatSettingsTyping => 'Tuma arifa za kuandika';

  @override
  String get chatSettingsTypingExplainer => '(hivi karibuni) Wajulishe wengine unapoandika';

  @override
  String get chatSettingsReadReceipts => 'Tuma risiti zilizosomwa';

  @override
  String get chatSettingsReadReceiptsExplainer => '(hivi karibuni) Wajulishe wengine unaposoma ujumbe';

  @override
  String get chats => 'Maongezi';

  @override
  String claimedTimes(Object count) {
    return 'Imedaiwa mara $count';
  }

  @override
  String get clear => 'Wazi';

  @override
  String get clearDBAndReLogin => 'Futa DB na uingie tena';

  @override
  String get close => 'Funga';

  @override
  String get closeDialog => 'Funga Kidirisha';

  @override
  String get closeSessionAndDeleteData => 'Funga kipindi hiki, ukifuta data ya ndani';

  @override
  String get closeSpace => 'Funga Nafasi';

  @override
  String get closeChat => 'Funga Maongezi';

  @override
  String get closingRoomTitle => 'Funga Chumba hiki';

  @override
  String get closingRoomTitleDescription => 'Wakati wa kufunga chumba hiki, tutafanya:\n\n - Ondoa kila mtu aliye na kiwango cha chini cha ruhusa kisha chako kutoka humo\n - Iondoe kama mtoto kutoka kwa nafasi za wazazi (ambapo una ruhusa ya kufanya hivyo),\n - Weka sheria ya mwaliko kuwa \"faragha\"\n - Utaondoka kwenye chumba.\n\nHili haliwezi kutenduliwa. Je, una uhakika unataka kuifunga hii?';

  @override
  String get closingRoom => 'Inafunga...';

  @override
  String closingRoomRemovingMembers(Object kicked, Object total) {
    return 'Kufunga kwa mchakato. Mwanachama anayempiga mateke $kicked / $total';
  }

  @override
  String get closingRoomMatrixMsg => 'Chumba kilifungwa';

  @override
  String closingRoomRemovingFromParents(Object currentParent, Object totalParents) {
    return 'Kufunga kwa mchakato. Inaondoa chumba kutoka kwa mzazi $currentParent / $totalParents';
  }

  @override
  String closingRoomDoneBut(Object skipped, Object skippedParents) {
    return 'Imefungwa na umeondoka. Lakini haikuweza kuondoa Watumiaji wengine $skipped na kuiondoa kama mtoto kutoka kwa Nafasi za $skippedParents kwa sababu ya ukosefu wa ruhusa. Wengine bado wanaweza kuifikia.';
  }

  @override
  String get closingRoomDone => 'Imefungwa kwa mafanikio.';

  @override
  String closingRoomFailed(Object error) {
    return 'Imeshindwa kufunga: $error';
  }

  @override
  String get coBudget => 'bajeti ya pamoja';

  @override
  String get code => 'alama ya siri';

  @override
  String get codeMustBeAtLeast6CharactersLong => 'Msimbo lazima uwe na urefu wa angalau vibambo 6';

  @override
  String get comment => 'Maoni';

  @override
  String get comments => 'Maoni';

  @override
  String commentsListError(Object error) {
    return 'Hitilafu ya orodha ya maoni: $error';
  }

  @override
  String get commentSubmitted => 'Maoni yamewasilishwa';

  @override
  String get community => 'Jumuiya';

  @override
  String get confirmationToken => 'Ishara ya Uthibitisho';

  @override
  String get confirmedEmailAddresses => 'Anwani za Barua pepe Zilizothibitishwa';

  @override
  String get confirmedEmailAddressesDescription => 'Anwani za barua pepe zilizothibitishwa zilizounganishwa kwenye akaunti yako:';

  @override
  String get confirmWithToken => 'Thibitisha kwa Tokeni';

  @override
  String get congrats => 'Hongera!';

  @override
  String get connectedToYourAccount => 'Imeunganishwa kwenye akaunti yako';

  @override
  String get contentSuccessfullyRemoved => 'Maudhui yamefaulu kuondolewa';

  @override
  String get continueAsGuest => 'Endelea kama mgeni';

  @override
  String get continueQuestion => 'Ungependa kuendelea?';

  @override
  String get copyUsername => 'Nakili jina la mtumiaji';

  @override
  String get copyMessage => 'Nakili';

  @override
  String get couldNotFetchNews => 'Haikuweza kuleta habari';

  @override
  String get couldNotLoadAllSessions => 'Haikuweza kupakia vipindi vyote';

  @override
  String couldNotLoadImage(Object error) {
    return 'Haikuweza kupakia picha kwa sababu ya $error';
  }

  @override
  String countsMembers(Object count) {
    return '$count Wanachama';
  }

  @override
  String get create => 'Unda';

  @override
  String get createChat => 'Unda Gumzo';

  @override
  String get createCode => 'Unda Msimbo';

  @override
  String get createDefaultChat => 'Unda chumba chaguomsingi cha gumzo, pia';

  @override
  String defaultChatName(Object name) {
    return '$name Maongezi';
  }

  @override
  String get createDMWhenRedeeming => 'Unda DM wakati wa kukomboa';

  @override
  String get createEventAndBringYourCommunity => 'Unda tukio jipya na ulete jumuiya yako pamoja';

  @override
  String get createGroupChat => 'Unda Gumzo la Kikundi';

  @override
  String get createPin => 'Unda Pini';

  @override
  String get createPostsAndEngageWithinSpace => 'Unda machapisho yanayoweza kutekelezeka na ushirikishe kila mtu katika nafasi yako.';

  @override
  String get createProfile => 'Unda Wasifu';

  @override
  String get createSpace => 'Unda Nafasi';

  @override
  String get createSpaceChat => 'Unda Maongezi la Nafasi';

  @override
  String get createSubspace => 'Unda Nafasi ndogo';

  @override
  String get createTaskList => 'Unda orodha ya kazi';

  @override
  String get createAcopy => 'Copy as new';

  @override
  String get creatingCalendarEvent => 'Kuunda Tukio la Kalenda';

  @override
  String get creatingChat => 'Kuunda Maongezi';

  @override
  String get creatingCode => 'Kuunda msimbo';

  @override
  String creatingNewsFailed(Object error) {
    return 'Imeshindwa kuunda sasisho $error';
  }

  @override
  String get creatingSpace => 'Kuunda Nafasi';

  @override
  String creatingSpaceFailed(Object error) {
    return 'Imeshindwa kuunda nafasi: $error';
  }

  @override
  String creatingTaskFailed(Object error) {
    return 'Imeshindwa kuunda Jukumu $error';
  }

  @override
  String get custom => 'Desturi';

  @override
  String get customizeAppsAndTheirFeatures => 'Geuza vipengele vinavyohitajika kwa nafasi hii kukufaa';

  @override
  String get customPowerLevel => 'Kiwango cha ruhusa maalum';

  @override
  String get dangerZone => 'Eneo la Hatari';

  @override
  String get deactivate => 'Zima';

  @override
  String get deactivateAccountDescription => 'Ukiendelea:\n\n - Data yako yote ya kibinafsi itaondolewa kutoka kwa seva yako ya nyumbani, pamoja na jina la kuonyesha na avatar \n - Vipindi vyako vyote vitafungwa mara moja, hakuna kifaa kingine kitakachoweza kuendelea na vipindi vyao \n - Utaacha vyumba vyote, soga, nafasi na ujumbe mfupi wa simu uliomo \n - Hutaweza kuwezesha akaunti yako tena \n - Hutaweza tena kuingia \n - Hakuna mtu ataweza kutumia tena jina lako la mtumiaji (MXID), pamoja na wewe: jina hili la mtumiaji halitapatikana kwa muda usiojulikana. \n - Utaondolewa kwenye seva ya utambulisho, ikiwa ulitoa taarifa yoyote ya kupatikana kupitia hiyo (k.m. barua pepe au nambari ya simu) \n - Data yote ya ndani, ikijumuisha funguo zozote za usimbaji fiche, itafutwa kabisa kutoka kwa kifaa hiki \n - Barua pepe zako za zamani bado zitaonekana kwa watu waliozipokea, kama vile barua pepe ulizotuma hapo awali. \n\n Hutaweza kubadilisha yoyote kati ya haya. Hiki ni kitendo cha kudumu na kisichoweza kubatilishwa.';

  @override
  String get deactivateAccountPasswordTitle => 'Tafadhali toa nenosiri lako la mtumiaji ili kuthibitisha kuwa unataka kuzima akaunti yako.';

  @override
  String get deactivateAccountTitle => 'Makini: Unakaribia kuzima akaunti yako kabisa';

  @override
  String deactivatingFailed(Object error) {
    return 'Imeshindwa kuzima: \n $error';
  }

  @override
  String get deactivatingYourAccount => 'Inazima akaunti yako';

  @override
  String get deactivationAndRemovingFailed => 'Imeshindwa kuzima na kuondoa data zote za ndani';

  @override
  String get debugInfo => 'Maelezo ya Utatuzi';

  @override
  String get debugLevel => 'Kiwango cha utatuzi';

  @override
  String get decline => 'Kataa';

  @override
  String get defaultModes => 'Njia Chaguomsingi';

  @override
  String defaultNotification(Object type) {
    return 'Chaguomsingi $type';
  }

  @override
  String get delete => 'Futa';

  @override
  String get deleteAttachment => 'Futa kiambatisho';

  @override
  String get deleteCode => 'Futa msimbo';

  @override
  String get deleteTarget => 'Futa Lengo';

  @override
  String get deleteNewsDraftTitle => 'Delete draft?';

  @override
  String get deleteNewsDraftText => 'Are you sure you want to delete this draft? This can’t be undone.';

  @override
  String get deleteDraftBtn => 'Delete draft';

  @override
  String get deletingPushTarget => 'Inafuta lengo la kushinikiza';

  @override
  String deletionFailed(Object error) {
    return 'Imeshindwa kufuta: $error';
  }

  @override
  String get denied => 'Imekataliwa';

  @override
  String get description => 'Maelezo';

  @override
  String get deviceId => 'Kitambulisho cha Kifaa';

  @override
  String get deviceIdDigest => 'Digest ya Kitambulisho cha Kifaa';

  @override
  String get deviceName => 'Jina la Kifaa';

  @override
  String get devicePlatformException => 'Huwezi kutumia Mfumo wa Kifaa. kifaa/wavuti katika muktadha huu. Mfumo usio sahihi: Sehemu ya Mipangilio. kujenga';

  @override
  String get displayName => 'Jina la Kuonyesha';

  @override
  String get displayNameUpdateSubmitted => 'Onyesha sasisho la jina limewasilishwa';

  @override
  String directInviteUser(Object userId) {
    return 'Alika $userId moja kwa moja';
  }

  @override
  String get dms => 'DMs';

  @override
  String get doYouWantToDeleteInviteCode => 'Je, kweli unataka kufuta msimbo wa mwaliko bila kubatilishwa? Haiwezi kutumika tena baada ya.';

  @override
  String due(Object date) {
    return 'Inastahili: $date';
  }

  @override
  String get dueDate => 'Tarehe ya mwisho';

  @override
  String get edit => 'Hariri';

  @override
  String get editDetails => 'Hariri Maelezo';

  @override
  String get editMessage => 'Hariri Ujumbe';

  @override
  String get editProfile => 'Hariri Wasifu';

  @override
  String get editSpace => 'Hariri Nafasi';

  @override
  String get edited => 'Imehaririwa';

  @override
  String get egGlobalMovement => 'km. Global Movement';

  @override
  String get emailAddressToAdd => 'Anwani ya barua pepe ya kuongeza';

  @override
  String get emailOrPasswordSeemsNotValid => 'Barua pepe au nenosiri linaonekana kuwa si sahihi.';

  @override
  String get emptyEmail => 'Tafadhali weka barua pepe';

  @override
  String get emptyPassword => 'Tafadhali weka Nenosiri';

  @override
  String get emptyToken => 'Tafadhali weka msimbo';

  @override
  String get emptyUsername => 'Tafadhali ingiza Jina la mtumiaji';

  @override
  String get encrypted => 'Imesimbwa kwa njia fiche';

  @override
  String get encryptedSpace => 'Nafasi Iliyosimbwa kwa Njia Fiche';

  @override
  String get encryptionBackupEnabled => 'Hifadhi rudufu za usimbaji fiche zimewashwa';

  @override
  String get encryptionBackupEnabledExplainer => 'Funguo zako zimehifadhiwa katika chelezo iliyosimbwa kwa njia fiche kwenye seva yako ya nyumbani';

  @override
  String get encryptionBackupMissing => 'Nakala za usimbaji fiche hazipo';

  @override
  String get encryptionBackupMissingExplainer => 'Tunapendekeza kutumia nakala rudufu za vitufe vya usimbaji fiche';

  @override
  String get encryptionBackupProvideKey => 'Toa Ufunguo wa Kuokoa';

  @override
  String get encryptionBackupProvideKeyExplainer => 'Tumepata hifadhi rudufu ya usimbaji fiche kiotomatiki';

  @override
  String get encryptionBackupProvideKeyAction => 'Toa Ufunguo';

  @override
  String get encryptionBackupNoBackup => 'Hakuna nakala rudufu ya usimbaji iliyopatikana';

  @override
  String get encryptionBackupNoBackupExplainer => 'Ukipoteza ufikiaji wa akaunti yako, mazungumzo yanaweza kuwa yasirejesheke. Tunapendekeza kuwezesha nakala rudufu za usimbaji fiche kiotomatiki.';

  @override
  String get encryptionBackupNoBackupAction => 'Washa Hifadhi Nakala';

  @override
  String get encryptionBackupEnabling => 'Inawezesha kuhifadhi';

  @override
  String encryptionBackupEnablingFailed(Object error) {
    return 'Imeshindwa kuwasha nakala rudufu: $error';
  }

  @override
  String get encryptionBackupRecovery => 'Ufunguo wako wa Urejeshaji Nakala';

  @override
  String get encryptionBackupRecoveryExplainer => 'Hifadhi Ufunguo huu wa Kurejesha Nakala kwa usalama.';

  @override
  String get encryptionBackupRecoveryCopiedToClipboard => 'Ufunguo wa Urejeshi umenakiliwa kwenye ubao wa kunakili';

  @override
  String get refreshing => 'Refreshing';

  @override
  String get encryptionBackupDisable => 'Ungependa kuzima Hifadhi Nakala ya Ufunguo wako?';

  @override
  String get encryptionBackupDisableExplainer => 'Kuweka upya hifadhi rudufu ya ufunguo kutaharibu ndani na kwenye seva yako ya nyumbani. Hili haliwezi kutenduliwa. Je, una uhakika ungependa kuendelea?';

  @override
  String get encryptionBackupDisableActionKeepIt => 'Hapana, ihifadhi';

  @override
  String get encryptionBackupDisableActionDestroyIt => 'Ndiyo, uiharibu';

  @override
  String get encryptionBackupResetting => 'Kuweka upya Hifadhi Nakala';

  @override
  String get encryptionBackupResettingSuccess => 'Imeweka upya';

  @override
  String encryptionBackupResettingFailed(Object error) {
    return 'Imeshindwa kuzima: $error';
  }

  @override
  String get encryptionBackupRecover => 'Rejesha Hifadhi Nakala ya Usimbaji';

  @override
  String get encryptionBackupRecoverExplainer => 'Mtoa huduma wako wa ufunguo wa kurejesha ili kusimbua hifadhi rudufu ya usimbaji fiche';

  @override
  String get encryptionBackupRecoverInputHint => 'Ufunguo wa kurejesha';

  @override
  String get encryptionBackupRecoverProvideKey => 'Tafadhali toa ufunguo';

  @override
  String get encryptionBackupRecoverAction => '-jipatia';

  @override
  String get encryptionBackupRecoverRecovering => 'jipatia';

  @override
  String get encryptionBackupRecoverRecoveringSuccess => 'Urejeshaji umefaulu';

  @override
  String get encryptionBackupRecoverRecoveringImportFailed => 'Imeshindwa kuleta';

  @override
  String encryptionBackupRecoverRecoveringFailed(Object error) {
    return 'Imeshindwa kurejesha: $error';
  }

  @override
  String get encryptionBackupKeyBackup => 'Chelezo muhimu';

  @override
  String get encryptionBackupKeyBackupExplainer => 'Hapa unasanidi Hifadhi Nakala ya Ufunguo';

  @override
  String error(Object error) {
    return 'Hitilafu $error';
  }

  @override
  String errorCreatingCalendarEvent(Object error) {
    return 'Hitilafu katika Kuunda Tukio la Kalenda: $error';
  }

  @override
  String errorCreatingChat(Object error) {
    return 'Hitilafu imetokea wakati wa kuunda gumzo: $error';
  }

  @override
  String errorSubmittingComment(Object error) {
    return 'Hitilafu katika kuwasilisha maoni: $error';
  }

  @override
  String errorUpdatingEvent(Object error) {
    return 'Hitilafu katika kusasisha tukio: $error';
  }

  @override
  String get eventDescriptionsData => 'Data ya maelezo ya tukio';

  @override
  String get eventName => 'Jina la Tukio';

  @override
  String get events => 'Matukio';

  @override
  String get eventTitleData => 'Data ya kichwa cha tukio';

  @override
  String get experimentalActerFeatures => 'Vipengele vya Acter wa Majaribio';

  @override
  String failedToAcceptInvite(Object error) {
    return 'Imeshindwa kukubali mwaliko: $error';
  }

  @override
  String failedToRejectInvite(Object error) {
    return 'Imeshindwa kukataa mwaliko: $error';
  }

  @override
  String get missingStoragePermissions => 'You must grant us permissions to storage to pick an Image file';

  @override
  String get file => 'Faili';

  @override
  String get forgotPassword => 'Umesahau Nenosiri?';

  @override
  String get forgotPasswordDescription => 'Ili kuweka upya nenosiri lako, tutakutumia kiungo cha uthibitishaji kwa barua pepe yako. Fuata mchakato hapo na ukishathibitishwa, unaweza kuweka upya nenosiri lako hapa.';

  @override
  String get forgotPasswordNewPasswordDescription => 'Mara tu unapomaliza mchakato nyuma ya kiungo cha barua pepe tuliyokutumia, unaweza kuweka nenosiri jipya hapa:';

  @override
  String get formatMustBe => 'Umbizo lazima liwe @user:server.tld';

  @override
  String get foundUsers => 'Watumiaji Waliopatikana';

  @override
  String get from => 'kutoka';

  @override
  String get gallery => 'from';

  @override
  String get general => 'Jumla';

  @override
  String get getConversationGoingToStart => 'Fanya mazungumzo yaanze kupanga kwa kushirikiana';

  @override
  String get getInTouchWithOtherChangeMakers => 'Wasiliana na waundaji mabadiliko wengine, waandaaji au wanaharakati na uzungumze nao moja kwa moja.';

  @override
  String get goToDM => 'Nenda kwa DM';

  @override
  String get going => 'Kwenda';

  @override
  String get haveProfile => 'Je, tayari una wasifu?';

  @override
  String get helpCenterTitle => 'Kituo cha Usaidizi';

  @override
  String get helpCenterDesc => 'Pata vidokezo muhimu kuhusu Acter';

  @override
  String get hereYouCanChangeTheSpaceDetails => 'Hapa unaweza kubadilisha maelezo ya nafasi';

  @override
  String get hereYouCanSeeAllUsersYouBlocked => 'Hapa unaweza kuona watumiaji wote uliowazuia.';

  @override
  String get hintMessageDisplayName => 'Weka jina ambalo ungependa watu wengine waone';

  @override
  String get hintMessageInviteCode => 'Weka msimbo wako wa mwaliko';

  @override
  String get hintMessagePassword => 'Angalau herufi 6';

  @override
  String get hintMessageUsername => 'Jina la mtumiaji la kipekee la kuingia na kitambulisho';

  @override
  String get homeServerName => 'Jina la Seva ya Nyumbani';

  @override
  String get homeServerURL => 'URL ya Seva ya Nyumbani';

  @override
  String get httpProxy => 'Wakala wa HTTP';

  @override
  String get image => 'Picha';

  @override
  String get inConnectedSpaces => 'Katika nafasi zilizounganishwa, unaweza kuzingatia vitendo maalum au kampeni za vikundi vyako vya kufanya kazi na kuanza kupanga.';

  @override
  String get info => 'Habari';

  @override
  String get invalidTokenOrPassword => 'Tokeni batili au nenosiri';

  @override
  String get invitationToChat => 'Umealikwa kujiunga na gumzo na ';

  @override
  String get invitationToDM => 'Anataka kuanzisha DM na wewe';

  @override
  String get invitationToSpace => 'Umealikwa kujiunga na kikundi kwa ';

  @override
  String get invited => 'Umealikwa';

  @override
  String get inviteCode => 'Msimbo wa Kualika';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String shareInviteWithCode(Object code) {
    return 'Invite $code';
  }

  @override
  String get inviteCodeInfo => 'Mwigizaji bado ana ufikiaji wa mwaliko pekee. Iwapo hukupewa msimbo wa mwaliko na kikundi au mpango maalum, tumia msimbo ulio hapa chini ili kuangalia Acter.';

  @override
  String get irreversiblyDeactivateAccount => 'Zima akaunti hii bila kutenduliwa';

  @override
  String get itsYou => 'Huyu ni wewe';

  @override
  String get join => 'Jiunge';

  @override
  String get joined => 'Imejiunga';

  @override
  String joiningFailed(Object error) {
    return 'Kujiunga kumeshindwa: $error';
  }

  @override
  String get joinActer => 'Jiunge na Muigizaji';

  @override
  String joinRuleNotSupportedYet(Object role) {
    return 'Kujiunga na Sheria $role bado haitumiki. Pole';
  }

  @override
  String kickAndBanFailed(Object error) {
    return 'Imeshindwa kuondoa na kumpiga marufuku mtumiaji: \n $error';
  }

  @override
  String get kickAndBanProgress => 'Kuondoa na kupiga marufuku mtumiaji';

  @override
  String get kickAndBanSuccess => 'Mtumiaji ameondolewa na kupigwa marufuku';

  @override
  String get kickAndBanUser => 'Ondoa na Upige Marufuku Mtumiaji';

  @override
  String kickAndBanUserDescription(Object roomId, Object userId) {
    return 'Unakaribia kumwondoa na kumpiga marufuku kabisa $userId kutoka kwa $roomId';
  }

  @override
  String kickAndBanUserTitle(Object userId) {
    return 'Ondoa na Upige Marufuku Mtumiaji $userId';
  }

  @override
  String kickFailed(Object error) {
    return 'Imeshindwa kuondoa mtumiaji: \n $error';
  }

  @override
  String get kickProgress => 'Inaondoa mtumiaji';

  @override
  String get kickSuccess => 'Mtumiaji ameondolewa';

  @override
  String get kickUser => 'Ondoa Mtumiaji';

  @override
  String kickUserDescription(Object roomId, Object userId) {
    return 'Unakaribia kumwondoa $userId kutoka $roomId';
  }

  @override
  String kickUserTitle(Object userId) {
    return 'Ondoa Mtumiaji $userId';
  }

  @override
  String get labs => 'Maabara';

  @override
  String get labsAppFeatures => 'Vipengele vya Programu';

  @override
  String get language => 'Lugha';

  @override
  String get leave => 'Toka';

  @override
  String get leaveRoom => 'Ondoka kwenye Gumzo';

  @override
  String get leaveSpace => 'Ondoka Nafasi';

  @override
  String get leavingSpace => 'Kuondoka Nafasi';

  @override
  String get leavingSpaceSuccessful => 'Umeondoka kwenye Nafasi';

  @override
  String leavingSpaceFailed(Object error) {
    return 'Hitilafu katika kuondoka kwa nafasi: $error';
  }

  @override
  String get leavingRoom => 'Kuacha Gumzo';

  @override
  String get letsGetStarted => 'Hebu tuanze';

  @override
  String get licenses => 'Leseni';

  @override
  String get limitedInternConnection => 'Muunganisho mdogo wa Mtandao';

  @override
  String get link => 'Kiungo';

  @override
  String get linkExistingChat => 'Unganisha Gumzo iliyopo';

  @override
  String get linkExistingSpace => 'Unganisha Nafasi iliyopo';

  @override
  String get links => 'Viungo';

  @override
  String get loading => 'Inapakia';

  @override
  String get linkToChat => 'Kiungo cha Maongezi';

  @override
  String loadingFailed(Object error) {
    return 'Imeshindwa kupakia: $error';
  }

  @override
  String get location => 'Mahali';

  @override
  String get logIn => 'Ingia';

  @override
  String get loginAgain => 'Ingia Tena';

  @override
  String get loginContinue => 'Ingia na uendelee kupanga kutoka mahali ulipoishia mara ya mwisho.';

  @override
  String get loginSuccess => 'Kuingia kumefaulu';

  @override
  String get logOut => 'Ondoka';

  @override
  String get logSettings => 'Mipangilio ya logi';

  @override
  String get looksGoodAddressConfirmed => 'Inaonekana vizuri. Anwani imethibitishwa.';

  @override
  String get makeADifference => 'Fungua upangaji wako wa kidijitali.';

  @override
  String get manage => 'Dhibiti';

  @override
  String get manageBudgetsCooperatively => 'Dhibiti bajeti kwa ushirikiano';

  @override
  String get manageYourInvitationCodes => 'Dhibiti misimbo yako ya mialiko';

  @override
  String get markToHideAllCurrentAndFutureContent => 'Weka alama ili kuficha maudhui yote ya sasa na ya baadaye kutoka kwa mtumiaji huyu na umzuie kuwasiliana nawe';

  @override
  String get markedAsDone => 'imetiwa alama kuwa imekamilika';

  @override
  String get maybe => 'Labda';

  @override
  String get member => 'Mwanachama';

  @override
  String get memberDescriptionsData => 'Data ya maelezo ya wanachama';

  @override
  String get memberTitleData => 'Data ya kichwa cha mwanachama';

  @override
  String get members => 'Wanachama';

  @override
  String get mentionsAndKeywordsOnly => 'Mitajo na Manenomsingi pekee';

  @override
  String get message => 'Ujumbe';

  @override
  String get messageCopiedToClipboard => 'Ujumbe umenakiliwa kwenye ubao wa kunakili';

  @override
  String get missingName => 'Tafadhali ingiza Jina lako';

  @override
  String get mobilePushNotifications => 'Arifa za Push za Simu';

  @override
  String get moderator => 'Msimamizi';

  @override
  String get more => 'Zaidi';

  @override
  String moreRooms(Object count) {
    return '+$count vyumba vya ziada';
  }

  @override
  String get muted => 'Imenyamazishwa';

  @override
  String get customValueMustBeNumber => 'Unahitaji kuingiza thamani maalum kama nambari.';

  @override
  String get myDashboard => 'Dashibodi Yangu';

  @override
  String get name => 'Jina';

  @override
  String get nameOfTheEvent => 'Jina la tukio';

  @override
  String get needsAppRestartToTakeEffect => 'Inahitaji kuanzishwa upya kwa programu ili kutekelezwa';

  @override
  String get newChat => 'Gumzo Mpya';

  @override
  String get newEncryptedMessage => 'Ujumbe Mpya Uliosimbwa';

  @override
  String get needYourPasswordToConfirm => 'Unahitaji nenosiri lako ili kuthibitisha';

  @override
  String get newMessage => 'Ujumbe mpya';

  @override
  String get newUpdate => 'Sasisho Mpya';

  @override
  String get next => 'Inayofuata';

  @override
  String get no => 'Hapana';

  @override
  String get noChatsFound => 'hakuna soga zilizopatikana';

  @override
  String get noChatsFoundMatchingYourFilter => 'Hakuna soga zilizopatikana zinazolingana na vichujio na utafutaji wako';

  @override
  String get noChatsFoundMatchingYourSearchTerm => 'Hakuna soga zilizopatikana zinazolingana na neno lako la utafutaji';

  @override
  String get noChatsInThisSpaceYet => 'Bado hakuna gumzo katika nafasi hii';

  @override
  String get noChatsStillSyncing => 'Inasawazisha...';

  @override
  String get noChatsStillSyncingSubtitle => 'Tunapakia soga zako. Kwa akaunti kubwa upakiaji wa kwanza huchukua muda kidogo ...';

  @override
  String get noConnectedSpaces => 'Hakuna nafasi zilizounganishwa';

  @override
  String get noDisplayName => 'hakuna jina la kuonyesha';

  @override
  String get noDueDate => 'Hakuna tarehe ya kukamilisha';

  @override
  String get noEventsPlannedYet => 'Bado hakuna matukio yaliyopangwa';

  @override
  String get noIStay => 'Hapana, nakaa';

  @override
  String get noMembersFound => 'Hakuna wanachama waliopatikana. Hiyo inawezaje kuwa, uko hapa, sivyo?';

  @override
  String get noOverwrite => 'Hakuna Batilisha';

  @override
  String get noParticipantsGoing => 'Hakuna washiriki wanaokwenda';

  @override
  String get noPinsAvailableDescription => 'Shiriki nyenzo muhimu na jumuiya yako kama vile hati au viungo ili kila mtu asasishwe.';

  @override
  String get noPinsAvailableYet => 'Bado hakuna pini zinazopatikana';

  @override
  String get noProfile => 'Je, bado huna wasifu?';

  @override
  String get noPushServerConfigured => 'Hakuna seva ya kusukuma iliyosanidiwa kwenye ujenzi';

  @override
  String get noPushTargetsAddedYet => 'hakuna malengo ya kushinikiza yaliyoongezwa bado';

  @override
  String get noSpacesFound => 'Hakuna nafasi zilizopatikana';

  @override
  String get noUsersFoundWithSpecifiedSearchTerm => 'Hakuna Watumiaji waliopatikana na neno maalum la utafutaji';

  @override
  String get notEnoughPowerLevelForInvites => 'Hakuna kiwango cha ruhusa cha kutosha kwa mialiko, mwombe msimamizi akibadilishe';

  @override
  String get notFound => '404 - Haikupatikana';

  @override
  String get notes => 'Vidokezo';

  @override
  String get notGoing => 'Sio Kwenda';

  @override
  String get noThanks => 'Hapana, asante';

  @override
  String get notifications => 'Arifa';

  @override
  String get notificationsOverwrites => 'Arifa Inabatilisha';

  @override
  String get notificationsOverwritesDescription => 'Batilisha usanidi wako wa arifa za nafasi hii';

  @override
  String get notificationsSettingsAndTargets => 'Mipangilio na malengo ya arifa';

  @override
  String get notificationStatusSubmitted => 'Hali ya arifa imewasilishwa';

  @override
  String notificationStatusUpdateFailed(Object error) {
    return 'Usasishaji wa hali ya arifa haukufaulu: $error';
  }

  @override
  String get notificationsUnmuted => 'Arifa zimerejeshwa';

  @override
  String get notificationTargets => 'Malengo ya Arifa';

  @override
  String get notifyAboutSpaceUpdates => 'Arifu kuhusu Masasisho ya Nafasi mara moja';

  @override
  String get noTopicFound => 'Hakuna mada iliyopatikana';

  @override
  String get notVisible => 'Haionekani';

  @override
  String get notYetSupported => 'Bado haijatumika';

  @override
  String get noWorriesWeHaveGotYouCovered => 'Hakuna wasiwasi! Weka barua pepe yako ili kuweka upya nenosiri lako.';

  @override
  String get ok => 'Sawa';

  @override
  String get okay => 'Sawa';

  @override
  String get on => 'juu';

  @override
  String get onboardText => 'Wacha tuanze kwa kusanidi wasifu wako';

  @override
  String get onlySupportedIosAndAndroid => 'Inatumika tu kwenye vifaa vya mkononi (iOS na Android) hivi sasa';

  @override
  String get optional => 'Hiari';

  @override
  String get or => ' au ';

  @override
  String get overview => 'Muhtasari';

  @override
  String get parentSpace => 'Nafasi Kuu';

  @override
  String get parentSpaces => 'Nafasi Kuu';

  @override
  String get parentSpaceMustBeSelected => 'Nafasi kuu lazima ichaguliwe';

  @override
  String get parents => 'Wazazi';

  @override
  String get password => 'Nenosiri';

  @override
  String get passwordResetTitle => 'Weka Upya Nenosiri';

  @override
  String get past => 'Zamani';

  @override
  String get pending => 'Inasubiri';

  @override
  String peopleGoing(Object count) {
    return '$count Watu wanaokwenda';
  }

  @override
  String get personalSettings => 'Mipangilio ya Kibinafsi';

  @override
  String get pinName => 'Bandika Jina';

  @override
  String get pins => 'Pini';

  @override
  String get play => 'Cheza';

  @override
  String get playbackSpeed => 'Kasi ya uchezaji';

  @override
  String get pleaseCheckYourInbox => 'Tafadhali angalia kisanduku pokezi chako kwa barua pepe ya uthibitishaji na ubofye kiungo kabla muda wake kuisha';

  @override
  String get pleaseEnterAName => 'Tafadhali weka jina';

  @override
  String get pleaseEnterATitle => 'Tafadhali weka kichwa';

  @override
  String get pleaseEnterEventName => 'Tafadhali weka jina la tukio';

  @override
  String get pleaseFirstSelectASpace => 'Tafadhali chagua kwanza nafasi';

  @override
  String errorProcessingSlide(Object error, Object slideIdx) {
    return 'We couldn’t process slide $slideIdx: $error';
  }

  @override
  String get pleaseProvideEmailAddressToAdd => 'Tafadhali toa anwani ya barua pepe ambayo ungependa kuongeza';

  @override
  String get pleaseProvideYourUserPassword => 'Tafadhali toa nenosiri lako la mtumiaji ili kuthibitisha kuwa unataka kutamatisha kipindi hicho.';

  @override
  String get pleaseSelectSpace => 'Tafadhali chagua nafasi';

  @override
  String get selectTaskList => 'Select Task List';

  @override
  String get pleaseWait => 'Tafadhali subiri…';

  @override
  String get polls => 'Kura';

  @override
  String get pollsAndSurveys => 'Kura na Tafiti';

  @override
  String postingOfTypeNotYetSupported(Object type) {
    return 'Uchapishaji wa $type bado hautumiki';
  }

  @override
  String get postingTaskList => 'Inachapisha Orodha ya Kazi';

  @override
  String get postpone => 'Ahirisha';

  @override
  String postponeN(Object days) {
    return 'Ahirisha siku $days';
  }

  @override
  String get powerLevel => 'Kiwango cha Ruhusa';

  @override
  String get powerLevelUpdateSubmitted => 'Sasisho la Kiwango cha Ruhusa limewasilishwa';

  @override
  String get powerLevelAdmin => 'Msimamizi';

  @override
  String get powerLevelModerator => 'Msimamizi';

  @override
  String get powerLevelRegular => 'Kawaida';

  @override
  String get powerLevelNone => 'Hakuna';

  @override
  String get powerLevelCustom => 'Desturi';

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
  String get preview => 'Hakiki';

  @override
  String get privacyPolicy => 'Sera ya Faragha';

  @override
  String get private => 'Privat';

  @override
  String get profile => 'Wasifu';

  @override
  String get pushKey => 'Ufunguo wa Kushinikiza';

  @override
  String get pushTargetDeleted => 'Lengo la kusukuma limefutwa';

  @override
  String get pushTargetDetails => 'Sukuma Maelezo ya Malengo';

  @override
  String get pushToThisDevice => 'Sukuma kwenye kifaa hiki';

  @override
  String get quickSelect => 'Chaguo la haraka:';

  @override
  String get rageShakeAppName => 'Jina la Programu ya Rageshake';

  @override
  String get rageShakeAppNameDigest => 'Muhtasari wa Jina la Programu ya Rageshake';

  @override
  String get rageShakeTargetUrl => 'Url inayolengwa ya Rageshake';

  @override
  String get rageShakeTargetUrlDigest => 'muhtasari wa url unaolengwa';

  @override
  String get reason => 'sababu';

  @override
  String get reasonHint => 'sababu ya hiari';

  @override
  String get reasonLabel => 'Sababu';

  @override
  String redactionFailed(Object error) {
    return 'Utumaji upya umeshindwa: $error';
  }

  @override
  String get redeem => 'Komboa';

  @override
  String redeemingFailed(Object error) {
    return 'Imeshindwa kukomboa: $error';
  }

  @override
  String get register => 'Sajili';

  @override
  String registerFailed(Object error) {
    return 'Usajili umeshindwa: $error';
  }

  @override
  String get regular => 'Kawaida';

  @override
  String get remove => 'Ondoa';

  @override
  String get removePin => 'Ondoa Pini';

  @override
  String get removeThisContent => 'Ondoa maudhui haya. Hili haliwezi kutenduliwa. Toa sababu ya hiari ya kueleza, kwa nini hii iliondolewa';

  @override
  String get reply => 'Jibu';

  @override
  String replyTo(Object name) {
    return 'Jibu kwa $name';
  }

  @override
  String get replyPreviewUnavailable => 'Hakuna onyesho la kuchungulia linalopatikana la ujumbe unaojibu';

  @override
  String get report => 'Ripoti';

  @override
  String get reportThisEvent => 'Ripoti tukio hili';

  @override
  String get reportThisMessage => 'Ripoti ujumbe huu';

  @override
  String get reportMessageContent => 'Ripoti ujumbe huu kwa msimamizi wako wa seva ya nyumbani. Tafadhali kumbuka kuwa msimamizi hataweza kusoma au kuona faili zozote, ikiwa gumzo limesimbwa kwa njia fiche';

  @override
  String get reportPin => 'Ripoti Pini';

  @override
  String get reportThisPost => 'Ripoti chapisho hili';

  @override
  String get reportPostContent => 'Ripoti chapisho hili kwa msimamizi wako wa seva ya nyumbani. Tafadhali kumbuka kuwa msimamizi hataweza kusoma au kuona faili zozote katika nafasi zilizosimbwa.';

  @override
  String get reportSendingFailed => 'Imeshindwa kutuma ripoti';

  @override
  String get reportSent => 'Ripoti imetumwa!';

  @override
  String get reportThisContent => 'Ripoti maudhui haya kwa msimamizi wako wa seva ya nyumbani. Tafadhali kumbuka kuwa msimamizi wako hataweza kusoma au kuona faili katika nafasi zilizosimbwa.';

  @override
  String get requestToJoin => 'ombi la kujiunga';

  @override
  String get reset => 'Weka upya';

  @override
  String get resetPassword => 'Weka upya Nenosiri';

  @override
  String get retry => 'Jaribu tena';

  @override
  String get roomId => 'Kitambulisho cha Gumzo';

  @override
  String get roomNotFound => 'Gumzo halijapatikana';

  @override
  String get roomLinkedButNotUpgraded => 'Added. However you are not able to upgrade its join rule settings and thus not all people from this space might be able to join it.';

  @override
  String get rsvp => 'RSVP';

  @override
  String repliedToMsgFailed(Object id) {
    return 'Failed to load original message id: $id';
  }

  @override
  String get sasGotIt => 'Nimeipata';

  @override
  String sasIncomingReqNotifContent(String sender) {
    return '$sender anataka kuthibitisha kipindi chako';
  }

  @override
  String get sasIncomingReqNotifTitle => 'Ombi la Uthibitishaji';

  @override
  String get sasVerified => 'Imethibitishwa!';

  @override
  String get save => 'Hifadhi';

  @override
  String get saveFileAs => 'Hifadhi faili kama';

  @override
  String get openFile => 'Fungua';

  @override
  String get shareFile => 'Shiriki';

  @override
  String get saveChanges => 'Hifadhi kushindwa kama';

  @override
  String get savingCode => 'Inahifadhi msimbo';

  @override
  String get search => 'Tafuta';

  @override
  String get searchTermFieldHint => 'Tafuta...';

  @override
  String get searchChats => 'Tafuta ngumzo';

  @override
  String searchResultFor(Object text) {
    return 'Matokeo ya utafutaji ya $text…';
  }

  @override
  String get searchUsernameToStartDM => 'Tafuta Jina la mtumiaji ili kuanzisha DM';

  @override
  String searchingFailed(Object error) {
    return 'Imeshindwa kutafuta$error';
  }

  @override
  String get searchSpace => 'nafasi ya utafutaji';

  @override
  String get searchSpaces => 'Tafuta Nafasi';

  @override
  String get searchPublicDirectory => 'Tafuta Orodha ya Umma';

  @override
  String get searchPublicDirectoryNothingFound => 'Hakuna ingizo lililopatikana katika saraka ya umma';

  @override
  String get seeOpenTasks => 'tazama kazi zilizo wazi';

  @override
  String get seenBy => 'Imeonekana Na';

  @override
  String get select => 'Chagua';

  @override
  String get selectAll => 'Chagua zote';

  @override
  String get unselectAll => 'Acha kuchagua zote';

  @override
  String get selectAnyRoomToSeeIt => 'Chagua Gumzo lolote ili kuiona';

  @override
  String get selectDue => 'Chagua Inastahili';

  @override
  String get selectLanguage => 'Chagua Lugha';

  @override
  String get selectParentSpace => 'Chagua nafasi ya mzazi';

  @override
  String get send => 'Tuma';

  @override
  String get sendingAttachment => 'Inatuma Kiambatisho';

  @override
  String get sendingReport => 'Inatuma Ripoti';

  @override
  String get sendingEmail => 'Kutuma Barua Pepe';

  @override
  String sendingEmailFailed(Object error) {
    return 'Imeshindwa kutuma: $error';
  }

  @override
  String sendingRsvpFailed(Object error) {
    return 'Imeshindwa kutuma RSVP: $error';
  }

  @override
  String get sentAnImage => 'alituma picha.';

  @override
  String get server => 'Seva';

  @override
  String get sessions => 'Vikao';

  @override
  String get sessionTokenName => 'Jina la Ishara ya Kikao';

  @override
  String get setDebugLevel => 'Weka kiwango cha utatuzi';

  @override
  String get setHttpProxy => 'Weka Wakala wa HTTP';

  @override
  String get settings => 'Mipangilio';

  @override
  String get securityAndPrivacy => 'Usalama na Faragha';

  @override
  String get settingsKeyBackUpTitle => 'Hifadhi Nakala muhimu';

  @override
  String get settingsKeyBackUpDesc => 'Dhibiti uhifadhi wa ufunguo';

  @override
  String get share => 'Shiriki';

  @override
  String get shareIcal => 'Shiriki iCal';

  @override
  String shareFailed(Object error) {
    return 'Imeshindwa kushiriki: $error';
  }

  @override
  String get sharedCalendarAndEvents => 'Kalenda na matukio yaliyoshirikiwa';

  @override
  String get signUp => 'Jisajili';

  @override
  String get skip => 'Ruka';

  @override
  String get slidePosting => 'Uchapishaji wa slaidi';

  @override
  String slidesNotYetSupported(Object type) {
    return '$type slaidi bado hazitumiki';
  }

  @override
  String get someErrorOccurredLeavingRoom => 'Hitilafu fulani ilitokea wakati wa kuondoka kwenye Chat';

  @override
  String get space => 'Nafasi';

  @override
  String get spaceConfiguration => 'Usanidi wa Nafasi';

  @override
  String get spaceConfigurationDescription => 'Sanidi, ni nani anayeweza kutazama na jinsi ya kujiunga na kikundi hiki';

  @override
  String get spaceName => 'Jina la Nafasi';

  @override
  String get spaceNotificationOverwrite => 'Batilisha arifa ya nafasi';

  @override
  String get spaceNotifications => 'Arifa za Nafasi';

  @override
  String get spaceOrSpaceIdMustBeProvided => 'Kitambulisho cha nafasi au nafasi lazima itolewe';

  @override
  String get spaces => 'Nafasi';

  @override
  String get spacesAndChats => 'Nafasi na Gumzo';

  @override
  String get spacesAndChatsToAddThemTo => 'Nafasi na Gumzo za kuwaongeza';

  @override
  String get startDM => 'Anzisha DM';

  @override
  String get state => 'jimbo';

  @override
  String get submit => 'Wasilisha';

  @override
  String get submittingComment => 'Kuwasilisha maoni';

  @override
  String get suggested => 'Imependekezwa';

  @override
  String get suggestedUsers => 'Watumiaji Waliopendekezwa';

  @override
  String get joiningSuggested => 'Kujiunga kunapendekezwa';

  @override
  String get suggestedRoomsTitle => 'Inapendekezwa kujiunga';

  @override
  String get suggestedRoomsSubtitle => 'Tunapendekeza pia ujiunge na wafuatao';

  @override
  String get addSuggested => 'Tia alama kama inavyopendekezwa';

  @override
  String get removeSuggested => 'Ondoa pendekezo';

  @override
  String get superInvitations => 'Misimbo ya Mwaliko';

  @override
  String get superInvites => 'Misimbo ya Mwaliko';

  @override
  String superInvitedBy(Object user) {
    return '$user anakualika';
  }

  @override
  String superInvitedTo(Object count) {
    return 'Ili kujiunga na chumba cha $count';
  }

  @override
  String superInvitesPreviewMissing(Object token) {
    return 'Seva yako haitumii uhakiki wa Misimbo ya Mwaliko. Bado unaweza kujaribu kukomboa $token ingawa';
  }

  @override
  String superInvitesDeleted(Object token) {
    return 'Msimbo wa mwaliko $token si halali tena.';
  }

  @override
  String get takeAFirstStep => 'Programu salama ya kupanga ambayo hukua kulingana na matarajio yako. Kutoa nafasi salama kwa harakati.';

  @override
  String get taskListName => 'Jina la orodha ya kazi';

  @override
  String get tasks => 'Kazi';

  @override
  String get termsOfService => 'Masharti ya Huduma';

  @override
  String get termsText1 => 'Kwa kubofya ili kuunda wasifu unakubali yetu';

  @override
  String theCurrentJoinRulesOfSpace(Object parentSpaceName, Object roomName) {
    return 'Sheria za sasa za kujiunga za $roomName zinamaanisha kwamba halitaonekana kwa wanachama wa $parentSpaceName. Je, tunapaswa kusasisha sheria za kujiunga ili kuruhusu mshiriki wa kikundi cha $parentSpaceName kuona na kujiunga na $roomName?';
  }

  @override
  String get theParentSpace => 'nafasi ya mzazi';

  @override
  String get thereIsNothingScheduledYet => 'Hakuna kilichopangwa bado';

  @override
  String get theSelectedRooms => 'mazungumzo yaliyochaguliwa';

  @override
  String get theyWontBeAbleToJoinAgain => 'Hawataweza kujiunga tena';

  @override
  String get thirdParty => 'Mtu wa tatu';

  @override
  String get thisApaceIsEndToEndEncrypted => 'Nafasi hii imesimbwa kwa njia fiche kutoka mwisho hadi mwisho';

  @override
  String get thisApaceIsNotEndToEndEncrypted => 'Nafasi hii haijasimbwa kwa njia fiche kutoka mwisho hadi mwisho';

  @override
  String get thisIsAMultilineDescription => 'Haya ni maelezo ya kazi nyingi yenye maandishi marefu na vitu';

  @override
  String get thisIsNotAProperActerSpace => 'Hii si nafasi sahihi ya Acter. Baadhi ya vipengele huenda visipatikane.';

  @override
  String get thisMessageHasBeenDeleted => 'Ujumbe huu umefutwa';

  @override
  String get thisWillAllowThemToContactYouAgain => 'Hii itamruhusu kuwasiliana nawe tena';

  @override
  String get title => 'Kichwa';

  @override
  String get titleTheNewTask => 'Ipe jukumu jipya kuu..';

  @override
  String typingUser1(Object user) {
    return '$user anaandika...';
  }

  @override
  String typingUser2(Object user1, Object user2) {
    return '$user1 na $user2 wanaandika...';
  }

  @override
  String typingUserN(Object user, Object userCount) {
    return '$user na wengine $userCount wanaandika';
  }

  @override
  String get to => 'kwa';

  @override
  String get toAccess => 'to access';

  @override
  String get needToBeMemberOf => 'you need to be member of';

  @override
  String get today => 'Leo';

  @override
  String get token => 'ishara';

  @override
  String get tokenAndPasswordMustBeProvided => 'Ishara na nenosiri lazima zitolewe';

  @override
  String get tomorrow => 'Kesho';

  @override
  String get topic => 'Mada';

  @override
  String get tryingToConfirmToken => 'Inajaribu kuthibitisha tokeni';

  @override
  String tryingToJoin(Object name) {
    return 'Inajaribu kujiunga na $name';
  }

  @override
  String get tryToJoin => 'Jaribu kujiunga';

  @override
  String get typeName => 'Andika Jina';

  @override
  String get unblock => 'Ondoa kizuizi';

  @override
  String get unblockingUser => 'Kufungua Mtumiaji';

  @override
  String unblockingUserFailed(Object error) {
    return 'Imeshindwa kumfungulia Mtumiaji: $error';
  }

  @override
  String get unblockingUserProgress => 'Kufungua Mtumiaji';

  @override
  String get unblockingUserSuccess => 'Mtumiaji amefunguliwa. Huenda ikachukua muda kabla ya UI kuonyesha sasisho hili.';

  @override
  String unblockTitle(Object userId) {
    return 'Acha kumzuia $userId';
  }

  @override
  String get unblockUser => 'Ondoa kizuizi kwa Mtumiaji';

  @override
  String unclearJoinRule(Object rule) {
    return 'Sheria ya kujiunga isiyo wazi $rule';
  }

  @override
  String get unreadMarkerFeatureTitle => 'Alama ambazo hazijasomwa';

  @override
  String get unreadMarkerFeatureDescription => 'Fuatilia na uonyeshe ni Gumzo zipi zimesomwa';

  @override
  String get undefined => 'isiyofafanuliwa';

  @override
  String get unknown => 'haijulikani';

  @override
  String get unknownRoom => 'Gumzo Isiyojulikana';

  @override
  String get unlink => 'Tenganisha';

  @override
  String get unmute => 'Rejesha sauti';

  @override
  String get unset => 'haijawekwa';

  @override
  String get unsupportedPleaseUpgrade => 'Haitumiki - Tafadhali boresha!';

  @override
  String get unverified => 'Haijathibitishwa';

  @override
  String get unverifiedSessions => 'Vipindi Visivyothibitishwa';

  @override
  String get unverifiedSessionsDescription => 'Una vifaa vilivyoingia katika akaunti yako ambavyo havijathibitishwa. Hii inaweza kuwa hatari ya usalama. Tafadhali hakikisha hii ni sawa.';

  @override
  String unverifiedSessionsCount(int count) {
    return 'There are $count unverified sessions logged in';
  }

  @override
  String get upcoming => 'Ijayo';

  @override
  String get updatePowerLevel => 'Sasisha kiwango cha Ruhusa';

  @override
  String updateFeaturePowerLevelDialogTitle(Object feature) {
    return 'Sasisha Ruhusa ya $feature';
  }

  @override
  String updateFeaturePowerLevelDialogFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'kutoka $memberStatus ($currentPowerLevel) hadi';
  }

  @override
  String get updateFeaturePowerLevelDialogFromDefaultTo => 'kutoka chaguo-msingi hadi';

  @override
  String get updatingDisplayName => 'Inasasisha jina la onyesho';

  @override
  String get updatingDue => 'Inasasisha';

  @override
  String get updatingEvent => 'Inasasisha Tukio';

  @override
  String updatingPowerLevelOf(Object userId) {
    return 'Inasasisha kiwango cha Ruhusa cha $userId';
  }

  @override
  String get updatingProfileImage => 'Inasasisha picha ya wasifu';

  @override
  String get updatingRSVP => 'Inasasisha RSVP';

  @override
  String get updatingSpace => 'Inasasisha Nafasi';

  @override
  String get uploadAvatar => 'Pakia Avatar';

  @override
  String usedTimes(Object count) {
    return 'Imetumika mara $count';
  }

  @override
  String userAddedToBlockList(Object user) {
    return '$user imeongezwa kwenye orodha ya vizuizi. UI inaweza kuchukua sasisho kidogo sana';
  }

  @override
  String get users => 'Users';

  @override
  String get usersfoundDirectory => 'Watumiaji kupatikana katika orodha ya umma';

  @override
  String get username => 'Jina la mtumiaji';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get usernameCopiedToClipboard => 'Jina la mtumiaji limenakiliwa kwenye ubao wa kunakili';

  @override
  String get userRemovedFromList => 'Mtumiaji ameondolewa kwenye orodha. UI inaweza kuchukua sasisho kidogo sana';

  @override
  String get usersYouBlocked => 'Watumiaji uliowazuia';

  @override
  String get validEmail => 'Tafadhali weka barua pepe halali';

  @override
  String get verificationConclusionCompromised => 'Mojawapo ya yafuatayo yanaweza kuathiriwa:\n\n   - Mhudumu wako wa nyumbani\n   - Seva ya nyumbani ambayo mtumiaji unayemthibitisha ameunganishwa kwake\n   - Yako, au muunganisho wa mtandao wa watumiaji wengine\n   - Yako, au kifaa cha watumiaji wengine';

  @override
  String verificationConclusionOkDone(String sender) {
    return 'Umethibitisha $sender!';
  }

  @override
  String get verificationConclusionOkSelfNotice => 'Kipindi chako kipya sasa kimethibitishwa. Ina uwezo wa kufikia ujumbe wako uliosimbwa kwa njia fiche, na watumiaji wengine wataona kuwa inaaminika.';

  @override
  String get verificationEmojiNotice => 'Linganisha emoji ya kipekee, ukihakikisha kuwa zinaonekana kwa mpangilio sawa.';

  @override
  String get verificationRequestAccept => 'Ili kuendelea, tafadhali kubali ombi la uthibitishaji kwenye kifaa chako kingine.';

  @override
  String verificationRequestWaitingFor(String sender) {
    return 'Inasubiri $sender…';
  }

  @override
  String get verificationSasDoNotMatch => 'Hazilingani';

  @override
  String get verificationSasMatch => 'Wanalingana';

  @override
  String get verificationScanEmojiTitle => 'Haiwezi kuchanganua';

  @override
  String get verificationScanSelfEmojiSubtitle => 'Thibitisha kwa kulinganisha emoji badala yake';

  @override
  String get verificationScanSelfNotice => 'Changanua msimbo kwa kifaa chako kingine au ubadilishe na uchanganue kwa kifaa hiki';

  @override
  String get verified => 'Imethibitishwa';

  @override
  String get verifiedSessionsDescription => 'Vifaa vyako vyote vimethibitishwa. Akaunti yako iko salama.';

  @override
  String get verifyOtherSession => 'Thibitisha kipindi kingine';

  @override
  String get verifySession => 'Thibitisha kipindi';

  @override
  String get verifyThisSession => 'Thibitisha kipindi hiki';

  @override
  String get version => 'Toleo';

  @override
  String get via => 'kupitia';

  @override
  String get video => 'Video';

  @override
  String get welcomeBack => 'Karibu tena';

  @override
  String get welcomeTo => 'Karibu kwa ';

  @override
  String get whatToCallThisChat => 'Nini cha kuiita gumzo hili?';

  @override
  String get yes => 'Ndiyo';

  @override
  String get yesLeave => 'Ndiyo, Ondoka';

  @override
  String get yesPleaseUpdate => 'Ndiyo, tafadhali sasisha';

  @override
  String get youAreAbleToJoinThisRoom => 'Unaweza kujiunga na Gumzo hili';

  @override
  String youAreAboutToBlock(Object userId) {
    return 'Unakaribia kumzuia $userId';
  }

  @override
  String youAreAboutToUnblock(Object userId) {
    return 'Unakaribia kumfungulia $userId';
  }

  @override
  String get youAreBothIn => 'you are both in ';

  @override
  String get youAreCurrentlyNotConnectedToAnySpaces => 'Kwa sasa hujaunganishwa kwenye nafasi zozote';

  @override
  String get spaceShortDescription => 'nafasi, kuanza kupanga na kushirikiana!';

  @override
  String get youAreDoneWithAllYourTasks => 'umemaliza kazi zako zote!';

  @override
  String get youAreNotAMemberOfAnySpaceYet => 'Bado wewe si mwanachama wa kikundi chochote';

  @override
  String get youAreNotPartOfThisGroup => 'Wewe si sehemu ya kikundi hiki. Je, ungependa kujiunga?';

  @override
  String get youHaveNoDMsAtTheMoment => 'Huna DM kwa sasa';

  @override
  String get youHaveNoUpdates => 'Huna masasisho';

  @override
  String get youHaveNotCreatedInviteCodes => 'Bado hujaunda misimbo yoyote ya mwaliko';

  @override
  String get youMustSelectSpace => 'Lazima uchague nafasi';

  @override
  String get youNeedBeInvitedToJoinThisRoom => 'Unahitaji kualikwa kujiunga na Gumzo hili';

  @override
  String get youNeedToEnterAComment => 'Unahitaji kuingiza maoni';

  @override
  String get youNeedToEnterCustomValueAsNumber => 'Unahitaji kuingiza thamani maalum kama nambari.';

  @override
  String youCantExceedPowerLevel(Object powerLevel) {
    return 'Huwezi kuzidi kiwango cha ruhusa cha $powerLevel';
  }

  @override
  String get yourActiveDevices => 'Vifaa vyako vinavyotumika';

  @override
  String get yourPassword => 'Nenosiri lako';

  @override
  String get yourSessionHasBeenTerminatedByServer => 'Kipindi chako kimekatishwa na seva, unahitaji kuingia tena';

  @override
  String get yourTextSlidesMustContainsSomeText => 'Slaidi yako ya maandishi lazima iwe na maandishi';

  @override
  String get yourSafeAndSecureSpace => 'Nafasi yako salama na salama ya kupanga mabadiliko.';

  @override
  String adding(Object email) {
    return 'inaongeza $email';
  }

  @override
  String get addTextSlide => 'Ongeza slaidi ya maandishi';

  @override
  String get addImageSlide => 'Ongeza slaidi ya picha';

  @override
  String get addVideoSlide => 'Ongeza slaidi ya video';

  @override
  String get acter => 'Acter';

  @override
  String get acterApp => 'Programu ya Acter';

  @override
  String get activate => 'Washa';

  @override
  String get changingNotificationMode => 'Inabadilisha hali ya arifa…';

  @override
  String get createComment => 'Unda Maoni';

  @override
  String get createNewPin => 'Unda Pini mpya';

  @override
  String get createNewSpace => 'Unda Nafasi Mpya';

  @override
  String get createNewTaskList => 'Unda orodha mpya ya kazi';

  @override
  String get creatingPin => 'Inaunda pini…';

  @override
  String get deactivateAccount => 'Zima Akaunti';

  @override
  String get deletingCode => 'Inafuta msimbo';

  @override
  String get dueToday => 'Inadaiwa leo';

  @override
  String get dueTomorrow => 'Inadaiwa kesho';

  @override
  String get dueSuccess => 'Malipo yamefaulu kubadilishwa';

  @override
  String get endDate => 'Tarehe ya Mwisho';

  @override
  String get endTime => 'Wakati wa Mwisho';

  @override
  String get emailAddress => 'Anwani ya Barua Pepe';

  @override
  String get emailAddresses => 'Anwani za Barua Pepe';

  @override
  String get errorParsinLink => 'Parsing Link failed';

  @override
  String errorCreatingPin(Object error) {
    return 'Hitilafu imetokea wakati wa kuunda pini $error';
  }

  @override
  String errorLoadingAttachments(Object error) {
    return 'Hitilafu katika kupakia viambatisho: $error';
  }

  @override
  String errorLoadingAvatar(Object error) {
    return 'Hitilafu katika kupakia avatar: $error';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'Hitilafu katika kupakia wasifu: $error';
  }

  @override
  String errorLoadingUsers(Object error) {
    return 'Hitilafu katika kupakia watumiaji: $error';
  }

  @override
  String errorLoadingTasks(Object error) {
    return 'Hitilafu katika kupakia kazi: $error';
  }

  @override
  String errorLoadingSpace(Object error) {
    return 'Hitilafu katika kupakia nafasi: $error';
  }

  @override
  String errorLoadingRelatedChats(Object error) {
    return 'Hitilafu katika kupakia maongezi zinazohusiana: $error';
  }

  @override
  String errorLoadingPin(Object error) {
    return 'Hitilafu katika kupakia pini: $error';
  }

  @override
  String errorLoadingEventDueTo(Object error) {
    return 'Hitilafu katika kupakia tukio kwa sababu ya: $error';
  }

  @override
  String errorLoadingImage(Object error) {
    return 'Hitilafu katika kupakia picha: $error';
  }

  @override
  String errorLoadingRsvpStatus(Object error) {
    return 'Hitilafu katika kupakia hali ya rsvp: $error';
  }

  @override
  String errorLoadingEmailAddresses(Object error) {
    return 'Hitilafu katika kupakia anwani za barua pepe: $error';
  }

  @override
  String errorLoadingMembersCount(Object error) {
    return 'Hitilafu katika kupakia idadi ya wanachama: $error';
  }

  @override
  String errorLoadingTileDueTo(Object error) {
    return 'Hitilafu ya kupakia kigae kwa sababu ya: $error';
  }

  @override
  String errorLoadingMember(Object error, Object memberId) {
    return 'Hitilafu katika kupakia mwanachama: $memberId $error';
  }

  @override
  String errorSendingAttachment(Object error) {
    return 'Hitilafu katika kutuma kiambatisho: $error';
  }

  @override
  String get eventCreate => 'Unda tukio';

  @override
  String get eventEdit => 'Hariri tukio';

  @override
  String get eventRemove => 'Ondoa tukio';

  @override
  String get eventReport => 'Ripoti tukio';

  @override
  String get eventUpdate => 'Sasisha tukio';

  @override
  String get eventShare => 'Shiriki tukio';

  @override
  String failedToAdd(Object error, Object something) {
    return 'Imeshindwa kuongeza $something: $error';
  }

  @override
  String failedToChangePin(Object error) {
    return 'Imeshindwa kubadilisha pin: $error';
  }

  @override
  String failedToChangePowerLevel(Object error) {
    return 'Imeshindwa kubadilisha kiwango cha ruhusa: $error';
  }

  @override
  String failedToChangeNotificationMode(Object error) {
    return 'Imeshindwa kubadilisha hali ya arifa: $error';
  }

  @override
  String failedToChangePushNotificationSettings(Object error) {
    return 'Imeshindwa kubadilisha mipangilio ya arifa kutoka kwa programu: $error';
  }

  @override
  String failedToToggleSettingOf(Object error, Object module) {
    return 'Imeshindwa kugeuza mpangilio wa $module: $error';
  }

  @override
  String failedToEditSpace(Object error) {
    return 'Imeshindwa kuhariri nafasi: $error';
  }

  @override
  String failedToAssignSelf(Object error) {
    return 'Imeshindwa kujikabidhi: $error';
  }

  @override
  String failedToUnassignSelf(Object error) {
    return 'Imeshindwa kujiondoa: $error';
  }

  @override
  String failedToSend(Object error) {
    return 'Imeshindwa kutuma: $error';
  }

  @override
  String failedToCreateChat(Object error) {
    return 'Imeshindwa kuunda gumzo: $error';
  }

  @override
  String failedToCreateTaskList(Object error) {
    return 'Imeshindwa kuunda orodha ya kazi: $error';
  }

  @override
  String failedToConfirmToken(Object error) {
    return 'Imeshindwa kuthibitisha tokeni: $error';
  }

  @override
  String failedToSubmitEmail(Object error) {
    return 'Imeshindwa kuwasilisha barua pepe: $error';
  }

  @override
  String get failedToDecryptMessage => 'Imeshindwa kusimbua ujumbe. Omba tena funguo za kipindi';

  @override
  String failedToDeleteAttachment(Object error) {
    return 'Imeshindwa kufuta kiambatisho kwa sababu ya: $error';
  }

  @override
  String get failedToDetectMimeType => 'Imeshindwa kugundua aina ya mime';

  @override
  String failedToLeaveRoom(Object error) {
    return 'Imeshindwa kuondoka kwenye Chat: $error';
  }

  @override
  String failedToLoadSpace(Object error) {
    return 'Imeshindwa kupakia nafasi: $error';
  }

  @override
  String failedToLoadEvent(Object error) {
    return 'Imeshindwa kupakia tukio: $error';
  }

  @override
  String failedToLoadInviteCodes(Object error) {
    return 'Imeshindwa kupakia misimbo ya mwaliko: $error';
  }

  @override
  String failedToLoadPushTargets(Object error) {
    return 'Imeshindwa kupakia malengo ya kusukuma: $error';
  }

  @override
  String failedToLoadEventsDueTo(Object error) {
    return 'Imeshindwa kupakia matukio kwa sababu ya: $error';
  }

  @override
  String failedToLoadChatsDueTo(Object error) {
    return 'Imeshindwa kupakia gumzo kwa sababu ya: $error';
  }

  @override
  String failedToShareRoom(Object error) {
    return 'Imeshindwa kushiriki Maongezi hili: $error';
  }

  @override
  String get forgotYourPassword => 'Je, umesahau nenosiri lako?';

  @override
  String get editInviteCode => 'Hariri Msimbo wa Mwaliko';

  @override
  String get createInviteCode => 'Unda Msimbo wa Mwaliko';

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
    return 'Imeshindwa kuhifadhi nambari: $error';
  }

  @override
  String createInviteCodeFailed(Object error) {
    return 'Imeshindwa kuunda nambari: $error';
  }

  @override
  String deleteInviteCodeFailed(Object error) {
    return 'Imeshindwa kufuta msimbo: $error';
  }

  @override
  String get loadingChat => 'Inapakia gumzo…';

  @override
  String get loadingCommentsList => 'Inapakia orodha ya maoni';

  @override
  String get loadingPin => 'Inapakia pini';

  @override
  String get loadingRoom => 'Inapakia Maongezi';

  @override
  String get loadingRsvpStatus => 'Inapakia hali ya rsvp';

  @override
  String get loadingTargets => 'Inapakia malengo';

  @override
  String get loadingOtherChats => 'Inapakia Maongezi zingine';

  @override
  String get loadingFirstSync => 'Inapakia usawazishaji wa kwanza';

  @override
  String get loadingImage => 'Inapakia picha';

  @override
  String get loadingVideo => 'Inapakia video';

  @override
  String loadingEventsFailed(Object error) {
    return 'Imeshindwa kupakia matukio: $error';
  }

  @override
  String loadingTasksFailed(Object error) {
    return 'Imeshindwa kupakia majukumu: $error';
  }

  @override
  String loadingSpacesFailed(Object error) {
    return 'Imeshindwa kupakia nafasi: $error';
  }

  @override
  String loadingRoomFailed(Object error) {
    return 'Imeshindwa kupakia Gumzo: $error';
  }

  @override
  String loadingMembersCountFailed(Object error) {
    return 'Imeshindwa kupakia idadi ya wanachama: $error';
  }

  @override
  String get longPressToActivate => 'bonyeza kwa muda mrefu ili kuamilisha';

  @override
  String get pinCreatedSuccessfully => 'Pini imeundwa';

  @override
  String get pleaseSelectValidEndTime => 'Tafadhali chagua wakati sahihi wa mwisho';

  @override
  String get pleaseSelectValidEndDate => 'Tafadhali chagua tarehe sahihi ya mwisho';

  @override
  String powerLevelSubmitted(Object module) {
    return 'Sasisho la kiwango cha ruhusa cha $module limewasilishwa';
  }

  @override
  String get optionalParentSpace => 'Nafasi ya Mzazi ya Hiari';

  @override
  String redeeming(Object token) {
    return 'Inakomboa $token';
  }

  @override
  String get encryptedDMChat => 'Gumzo la DM Lililosimbwa kwa njia fiche';

  @override
  String get encryptedChatMessage => 'Ujumbe Uliosimbwa umefungwa. Gonga kwa zaidi';

  @override
  String get encryptedChatMessageInfoTitle => 'Ujumbe Umefungwa';

  @override
  String get encryptedChatMessageInfo => 'Ujumbe wa gumzo umesimbwa kwa njia fiche kutoka mwisho hadi mwisho. Hiyo ina maana kwamba ni vifaa vilivyounganishwa tu wakati ujumbe unatumwa vinaweza kusimbua. Ikiwa ulijiunga baadaye, umeingia tu au umetumia kifaa kipya, bado huna funguo za kusimbua ujumbe huu. Unaweza kuipata kwa kuthibitisha kipindi hiki kwa kifaa kingine cha akaunti yako, kwa kutoa ufunguo mbadala wa usimbaji fiche au kwa kuthibitisha na mtumiaji mwingine ambaye ana uwezo wa kufikia ufunguo.';

  @override
  String get chatMessageDeleted => 'Ujumbe umefutwa';

  @override
  String chatJoinedDisplayName(Object name) {
    return '$name alijiunga';
  }

  @override
  String chatJoinedUserId(Object userId) {
    return '$userId amejiunga';
  }

  @override
  String get chatYouJoined => 'Ulijiunga';

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
  String get chatYouAcceptedInvite => 'Ulikubali mwaliko';

  @override
  String chatYouInvited(Object name) {
    return 'Umealika';
  }

  @override
  String chatInvitedDisplayName(Object invitee, Object name) {
    return '$name amealikwa';
  }

  @override
  String chatInvitedUserId(Object inviteeId, Object userId) {
    return '$userId amealikwa';
  }

  @override
  String chatInvitationAcceptedDisplayName(Object name) {
    return '$name amekubali mwaliko';
  }

  @override
  String chatInvitationAcceptedUserId(Object userId) {
    return '$userId amekubali mwaliko';
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
  String get dmChat => 'Maongezi ya DM';

  @override
  String get regularSpaceOrChat => 'Nafasi ya Kawaida au Maongezi';

  @override
  String get encryptedSpaceOrChat => 'Nafasi Iliyosimbwa kwa Njia Fiche au Maongezi';

  @override
  String get encryptedChatInfo => 'Barua pepe zote kwenye gumzo hili zimesimbwa kwa njia fiche kutoka mwanzo hadi mwisho. Hakuna mtu aliye nje ya gumzo hili, hata Acter au Seva ya Matrix inayoelekeza ujumbe, anayeweza kuzisoma.';

  @override
  String get removeThisPin => 'Ondoa Pini hii';

  @override
  String get removeThisPost => 'Ondoa chapisho hili';

  @override
  String get removingContent => 'Kuondoa maudhui';

  @override
  String get removingAttachment => 'Inaondoa kiambatisho';

  @override
  String get reportThis => 'Ripoti hii';

  @override
  String get reportThisPin => 'Ripoti Pini hii';

  @override
  String reportSendingFailedDueTo(Object error) {
    return 'Utumaji wa ripoti umeshindwa kwa sababu ya baadhi ya: $error';
  }

  @override
  String get resettingPassword => 'Kuweka upya nenosiri lako';

  @override
  String resettingPasswordFailed(Object error) {
    return 'Imeshindwa kuweka upya: $error';
  }

  @override
  String get resettingPasswordSuccessful => 'Nenosiri limewekwa upya.';

  @override
  String get sharedSuccessfully => 'Imeshirikiwa kwa mafanikio';

  @override
  String get changedPushNotificationSettingsSuccessfully => 'Umebadilisha mipangilio ya arifa zinazotumwa na programu hata wakati huitumii';

  @override
  String get startDateRequired => 'Tarehe ya kuanza inahitajika!';

  @override
  String get startTimeRequired => 'Muda wa kuanza unahitajika!';

  @override
  String get endDateRequired => 'Tarehe ya mwisho inahitajika!';

  @override
  String get endTimeRequired => 'Muda wa mwisho unahitajika!';

  @override
  String get searchUser => 'tafuta mtumiaji';

  @override
  String seeAllMyEvents(Object count) {
    return 'Tazama matukio yangu yote ya $count';
  }

  @override
  String get selectSpace => 'Chagua Nafasi';

  @override
  String get selectChat => 'Chagua Gumzo';

  @override
  String get selectCustomDate => 'Chagua tarehe mahususi';

  @override
  String get selectPicture => 'Chagua Picha';

  @override
  String get selectVideo => 'Chagua Video';

  @override
  String get selectDate => 'Chagua tarehe';

  @override
  String get selectTime => 'Chagua wakati';

  @override
  String get sendDM => 'Tuma DM';

  @override
  String get showMore => 'onyesha zaidi';

  @override
  String get showLess => 'onyesha kidogo';

  @override
  String get joinSpace => 'Jiunge na Nafasi';

  @override
  String get joinExistingSpace => 'Jiunge na Nafasi Iliyopo';

  @override
  String get mySpaces => 'Nafasi Zangu';

  @override
  String get startDate => 'Tarehe ya Kuanza';

  @override
  String get startTime => 'Wakati wa Kuanza';

  @override
  String get startGroupDM => 'Anzisha Kikundi DM';

  @override
  String get moreSubspaces => 'Nafasi ndogo zaidi';

  @override
  String get myTasks => 'Kazi Zangu';

  @override
  String updatingDueFailed(Object error) {
    return 'Imeshindwa kusasisha malipo: $error';
  }

  @override
  String get unlinkRoom => 'Tenganisha Maongezi';

  @override
  String changeThePowerFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'kutoka $memberStatus $currentPowerLevel hadi';
  }

  @override
  String get createOrJoinSpaceDescription => 'Unda au ujiunge na kikundi, ili kuanza kupanga na kushirikiana!';

  @override
  String get introPageDescriptionPre => 'Acter ni zaidi ya programu tu. \nNi';

  @override
  String get isLinked => 'is linked in here';

  @override
  String get canLink => 'You can link this';

  @override
  String get canLinkButNotUpgrade => 'You can link this, but not update its join permissions';

  @override
  String get introPageDescriptionHl => ' .jumuiya ya waleta mabadiliko.';

  @override
  String get introPageDescriptionPost => ' . ';

  @override
  String get introPageDescription2ndLine => 'Ungana na wanaharakati wenzako, shiriki maarifa, na ushirikiane katika kuleta mabadiliko ya maana.';

  @override
  String get logOutConformationDescription1 => 'Tahadhari: ';

  @override
  String get logOutConformationDescription2 => 'Kuondoka nje huondoa data ya ndani, ikiwa ni pamoja na funguo za usimbaji fiche. Ikiwa hiki ndicho kifaa chako cha mwisho ulichoingia katika akaunti huenda usiweze kusimbua maudhui yoyote ya awali.';

  @override
  String get logOutConformationDescription3 => ' Je, una uhakika unataka kutoka?';

  @override
  String membersCount(Object count) {
    return '$count Wanachama';
  }

  @override
  String get renderSyncingTitle => 'Inasawazisha na seva yako ya nyumbani';

  @override
  String get renderSyncingSubTitle => 'Hii inaweza kuchukua muda ikiwa una akaunti kubwa';

  @override
  String errorSyncing(Object error) {
    return 'Hitilafu ya kusawazisha: $error';
  }

  @override
  String get retrying => 'inajaribu tena…';

  @override
  String retryIn(Object minutes, Object seconds) {
    return 'Itajaribu tena baada ya $minutes:$seconds';
  }

  @override
  String get invitations => 'Mialiko';

  @override
  String invitingLoading(Object userId) {
    return 'Inaalika $userId';
  }

  @override
  String invitingError(Object error, Object userId) {
    return 'Mtumiaji $userId hajapatikana au yuko: $error';
  }

  @override
  String get invite => 'Alika';

  @override
  String errorUnverifiedSessions(Object error) {
    return 'Haikuweza kupakia vipindi ambavyo havijathibitishwa: $error';
  }

  @override
  String unverifiedSessionsTitle(Object count) {
    return 'Kuna vipindi $count ambavyo havijathibitishwa vimeingia';
  }

  @override
  String get review => 'Kagua';

  @override
  String get activities => 'Shughuli';

  @override
  String get activitiesDescription => 'Mambo yote muhimu yanayohitaji umakini wako yanaweza kupatikana hapa';

  @override
  String get noActivityTitle => 'Bado hakuna Shughuli kwa ajili yako';

  @override
  String get noActivitySubtitle => 'Hukuarifu kuhusu mambo muhimu kama vile ujumbe, mialiko au maombi.';

  @override
  String get joining => 'Kujiunga';

  @override
  String get joinedDelayed => 'Mwaliko uliokubaliwa, uthibitisho huchukua muda wake ingawa';

  @override
  String get rejecting => 'Kukataa';

  @override
  String get rejected => 'Imekataliwa';

  @override
  String get failedToReject => 'Imeshindwa kukataa';

  @override
  String reportedBugSuccessful(Object issueId) {
    return 'Imeripoti hitilafu! (#$issueId)';
  }

  @override
  String get thanksForReport => 'Asante kwa kuripoti hitilafu hiyo!';

  @override
  String bugReportingError(Object error) {
    return 'Hitilafu ya kuripoti hitilafu: $error';
  }

  @override
  String get bugReportTitle => 'Ripoti tatizo';

  @override
  String get bugReportDescription => 'Maelezo mafupi ya suala hilo';

  @override
  String get emptyDescription => 'Tafadhali weka maelezo';

  @override
  String get includeUserId => 'Jumuisha Kitambulisho changu cha Matrix';

  @override
  String get includeLog => 'Jumuisha kumbukumbu za sasa';

  @override
  String get includePrevLog => 'Jumuisha kumbukumbu kutoka kwa uendeshaji uliopita';

  @override
  String get includeScreenshot => 'Jumuisha picha ya skrini';

  @override
  String get includeErrorAndStackTrace => 'Jumuisha Hitilafu na Stacktrace';

  @override
  String get jumpTo => 'kuruka kwa';

  @override
  String get noMatchingPinsFound => 'hakuna pini zinazolingana zilizopatikana';

  @override
  String get update => 'Sasisha';

  @override
  String get event => 'Tukio';

  @override
  String get taskList => 'Orodha ya Kazi';

  @override
  String get pin => 'Pini';

  @override
  String get poll => 'Kura ya maoni';

  @override
  String get discussion => 'Majadiliano';

  @override
  String get fatalError => 'Hitilafu mbaya';

  @override
  String get nukeLocalData => 'Nuke data ya ndani';

  @override
  String get reportBug => 'Ripoti hitilafu';

  @override
  String get somethingWrong => 'Hitilafu fulani imetokea:';

  @override
  String get copyToClipboard => 'Nakili kwenye ubao wa kunakili';

  @override
  String get errorCopiedToClipboard => 'Hitilafu na Stacktrace imenakiliwa kwenye ubao wa kunakili';

  @override
  String get showStacktrace => 'Onyesha Stacktrace';

  @override
  String get hideStacktrace => 'Ficha Stacktrace';

  @override
  String get sharingRoom => 'Inashiriki Maongezi haya…';

  @override
  String get changingSettings => 'Inabadilisha mipangilio…';

  @override
  String changingSettingOf(Object module) {
    return 'Inabadilisha mpangilio wa $module';
  }

  @override
  String changedSettingOf(Object module) {
    return 'Umebadilisha mpangilio wa $module';
  }

  @override
  String changingPowerLevelOf(Object module) {
    return 'Kubadilisha kiwango cha ruhusa cha $module';
  }

  @override
  String get assigningSelf => 'Kujikabidhi…';

  @override
  String get unassigningSelf => 'Inajiondoa…';

  @override
  String get homeTabTutorialTitle => 'Dashibodi';

  @override
  String get homeTabTutorialDescription => 'Hapa unapata nafasi zako na muhtasari wa matukio yote yajayo na majukumu yanayosubiri ya nafasi hizi.';

  @override
  String get updatesTabTutorialTitle => 'Sasisho';

  @override
  String get updatesTabTutorialDescription => 'Tiririsha habari kuhusu masasisho na simu za kuchukua hatua kutoka kwa nafasi zako.';

  @override
  String get chatsTabTutorialTitle => 'Maongezi';

  @override
  String get chatsTabTutorialDescription => 'Ni mahali pa kupiga gumzo - na vikundi au watu binafsi. soga zinaweza kuunganishwa kwa nafasi tofauti kwa ushirikiano mpana.';

  @override
  String get activityTabTutorialTitle => 'Shughuli';

  @override
  String get activityTabTutorialDescription => 'Taarifa muhimu kutoka kwa nafasi zako, kama vile mialiko au maombi. Zaidi ya hayo utaarifiwa na Acter kuhusu masuala ya usalama';

  @override
  String get jumpToTabTutorialTitle => 'Rukia Kwa';

  @override
  String get jumpToTabTutorialDescription => 'Utafutaji wako juu ya nafasi na pini, pamoja na vitendo vya haraka na ufikiaji wa haraka wa sehemu kadhaa';

  @override
  String get createSpaceTutorialTitle => 'Unda Nafasi Mpya';

  @override
  String get createSpaceTutorialDescription => 'Jiunge na nafasi iliyopo kwenye seva yetu ya Acter au katika ulimwengu wa Matrix au usanidi nafasi yako mwenyewe.';

  @override
  String get joinSpaceTutorialTitle => 'Jiunge na Nafasi Iliyopo';

  @override
  String get joinSpaceTutorialDescription => 'Jiunge na nafasi iliyopo kwenye seva yetu ya Acter au katika ulimwengu wa Matrix au usanidi nafasi yako mwenyewe. [ingeonyesha tu chaguzi na kuishia hapo kwa sasa]';

  @override
  String get spaceOverviewTutorialTitle => 'Maelezo ya Nafasi';

  @override
  String get spaceOverviewTutorialDescription => 'Nafasi ni mahali pa kuanzia kwa upangaji wako. Unda na uvinjari pini (nyenzo), kazi na matukio. Ongeza gumzo au nafasi ndogo.';

  @override
  String get subscribedToParentMsg => 'Disable Notifications on main object to configure notification here';

  @override
  String get parentSubscribedAction => 'Notifications active through object';

  @override
  String get subscribeAction => 'Activate Notifications';

  @override
  String get unsubscribeAction => 'De-Activate Notifications';

  @override
  String get commentEmptyStateTitle => 'Hakuna maoni yaliyopatikana.';

  @override
  String get commentEmptyStateAction => 'Acha maoni ya kwanza';

  @override
  String get previous => 'Iliyotangulia';

  @override
  String get finish => 'Maliza';

  @override
  String get saveUsernameTitle => 'Je, umehifadhi jina lako la mtumiaji?';

  @override
  String get saveUsernameDescription1 => 'Tafadhali kumbuka kuandika jina lako la mtumiaji. Ni ufunguo wako kufikia wasifu wako na taarifa zote na nafasi zilizounganishwa kwayo.';

  @override
  String get saveUsernameDescription2 => 'Jina lako la mtumiaji ni muhimu kwa kuweka upya nenosiri.';

  @override
  String get saveUsernameDescription3 => 'Bila hivyo, ufikiaji wa wasifu wako na maendeleo yatapotea kabisa.';

  @override
  String get acterUsername => 'Jina lako la Mtumiaji wa Acter';

  @override
  String get autoSubscribeFeatureDesc => 'upon creation or interaction with objects';

  @override
  String get autoSubscribeSettingsTitle => 'Automatically subscribe ';

  @override
  String get copyToClip => 'Nakili kwenye Ubao wa kunakili';

  @override
  String get wizzardContinue => 'Endelea';

  @override
  String get protectPrivacyTitle => 'Kulinda faragha yako';

  @override
  String get protectPrivacyDescription1 => 'Katika Acter, kuweka akaunti yako salama ni muhimu. Ndiyo maana unaweza kuitumia bila kuunganisha wasifu wako kwenye barua pepe yako kwa ajili ya faragha na ulinzi ulioongezwa.';

  @override
  String get protectPrivacyDescription2 => 'Lakini ukipenda, bado unaweza kuziunganisha pamoja, kwa mfano, kwa kurejesha nenosiri.';

  @override
  String get linkEmailToProfile => 'Barua pepe Iliyounganishwa kwa Wasifu';

  @override
  String get emailOptional => 'Barua pepe (Si lazima)';

  @override
  String get hintEmail => 'Weka barua pepe yako';

  @override
  String get linkingEmailAddress => 'Kuunganisha barua pepe yako';

  @override
  String get avatarAddTitle => 'Ongeza Avatar ya Mtumiaji';

  @override
  String get avatarEmpty => 'Tafadhali chagua avatar yako';

  @override
  String get avatarUploading => 'Inapakia avatar ya wasifu';

  @override
  String avatarUploadFailed(Object error) {
    return 'Imeshindwa kupakia ishara ya mtumiaji: $error';
  }

  @override
  String get sendEmail => 'Tuma barua pepe';

  @override
  String get inviteCopiedToClipboard => 'Msimbo wa mwaliko umenakiliwa kwenye ubao wa kunakili';

  @override
  String get updateName => 'Inasasisha jina';

  @override
  String get updateDescription => 'Inasasisha maelezo';

  @override
  String get editName => 'Hariri Jina';

  @override
  String get editDescription => 'Hariri Maelezo';

  @override
  String updateNameFailed(Object error) {
    return 'Imeshindwa kusasisha jina: $error';
  }

  @override
  String updateDescriptionFailed(Object error) {
    return 'Imeshindwa kusasisha maelezo: $error';
  }

  @override
  String get eventParticipants => 'Washiriki wa Tukio';

  @override
  String get upcomingEvents => 'Matukio Yajayo';

  @override
  String get spaceInviteDescription => 'Je, ungependa kualika kwenye kikundi hiki?';

  @override
  String get inviteSpaceMembersTitle => 'Alika Wanachama wa Nafasi';

  @override
  String get inviteSpaceMembersSubtitle => 'Alika watumiaji kutoka nafasi uliyochagua';

  @override
  String get inviteIndividualUsersTitle => 'Alika Watumiaji Binafsi';

  @override
  String get inviteIndividualUsersSubtitle => 'Alika watumiaji ambao tayari wako kwenye Acter';

  @override
  String get inviteIndividualUsersDescription => 'Alika mtu yeyote ambaye ni sehemu ya jukwaa la Acter';

  @override
  String get inviteJoinActer => 'Alika kujiunga na Acter';

  @override
  String get inviteJoinActerDescription => 'Unaweza kuwaalika watu wajiunge na Acter na wajiunge kiotomatiki kwenye kikundi hiki ukitumia msimbo maalum wa usajili na ushiriki nao';

  @override
  String get generateInviteCode => 'Tengeneza Msimbo wa Mwaliko';

  @override
  String get pendingInvites => 'Mialiko Inasubiri';

  @override
  String pendingInvitesCount(Object count) {
    return 'You have $count pending Invites';
  }

  @override
  String get noPendingInvitesTitle => 'Hakuna Mialiko ambayo haijashughulikiwa kupatikana';

  @override
  String get noUserFoundTitle => 'Hakuna watumiaji waliopatikana';

  @override
  String get noUserFoundSubtitle => 'Tafuta watumiaji na jina lao la mtumiaji au jina la kuonyesha';

  @override
  String get done => 'kufanyika';

  @override
  String get downloadFileDialogTitle => 'Tafadhali chagua mahali pa kuhifadhi faili';

  @override
  String downloadFileSuccess(Object path) {
    return 'Faili imehifadhiwa kwenye $path';
  }

  @override
  String cancelInviteLoading(Object userId) {
    return 'Inaghairi mwaliko wa $userId';
  }

  @override
  String cancelInviteError(Object error, Object userId) {
    return 'Mtumiaji $userId hajapatikana: $error';
  }

  @override
  String get shareInviteCode => 'Shiriki Nambari ya Mwaliko';

  @override
  String get appUnavailable => 'Programu Haipatikani';

  @override
  String shareInviteContent(Object code, Object roomName, Object userName) {
    return '$userName angependa kukualika kwenye $roomName.\nTafadhali fuata hatua zifuatazo ili kujiunga:\n\nHATUA YA 1: Pakua Programu ya Mwigizaji kutoka kwa viungo vilivyo hapa chini https://app-redir.acter.global/\n\nHATUA YA 2: Tumia msimbo wa mwaliko ulio hapa chini kwenye usajili.\nNambari ya Mwaliko : $code\n\nNi hayo tu! Furahia njia mpya salama na salama ya kupanga!';
  }

  @override
  String activateInviteCodeFailed(Object error) {
    return 'Imeshindwa kuwezesha msimbo: $error';
  }

  @override
  String get revoke => 'Batilisha';

  @override
  String get otherSpaces => 'Nafasi Zingine';

  @override
  String get invitingSpaceMembersLoading => 'Kuwaalika Wanachama wa Nafasi';

  @override
  String invitingSpaceMembersProgress(Object count, Object total) {
    return 'Inaalika Mwanachama wa Nafasi $count / $total';
  }

  @override
  String invitingSpaceMembersError(Object error) {
    return 'Hitilafu ya Kualika Wanachama wa Nafasi: $error';
  }

  @override
  String membersInvited(Object count) {
    return 'Wanachama $count wamealikwa';
  }

  @override
  String get selectVisibility => 'Chagua Mwonekano';

  @override
  String get visibilityTitle => 'Mwonekano';

  @override
  String get visibilitySubtitle => 'Chagua ni nani anayeweza kujiunga na kikundi hiki.';

  @override
  String get visibilityNoPermission => 'Huna ruhusa zinazohitajika kubadilisha mwonekano huu wa nafasi';

  @override
  String get public => 'Hadharani';

  @override
  String get publicVisibilitySubtitle => 'Mtu yeyote anaweza kupata na kujiunga';

  @override
  String get privateVisibilitySubtitle => 'Ni watu walioalikwa pekee wanaoweza kujiunga';

  @override
  String get limited => 'Kikomo';

  @override
  String get limitedVisibilitySubtitle => 'Mtu yeyote katika nafasi ulizochagua anaweza kupata na kujiunga';

  @override
  String get visibilityAndAccessibility => 'Mwonekano na Ufikivu';

  @override
  String updatingVisibilityFailed(Object error) {
    return 'Imeshindwa kusasisha mwonekano wa chumba: $error';
  }

  @override
  String get spaceWithAccess => 'Nafasi yenye ufikiaji';

  @override
  String get changePassword => 'Badilisha Nenosiri';

  @override
  String get changePasswordDescription => 'Badilisha Nenosiri lako';

  @override
  String get oldPassword => 'Nenosiri la zamani';

  @override
  String get newPassword => 'Nenosiri Mpya';

  @override
  String get confirmPassword => 'Thibitisha Nenosiri';

  @override
  String get emptyOldPassword => 'Tafadhali weka nenosiri la zamani';

  @override
  String get emptyNewPassword => 'Tafadhali weka nenosiri jipya';

  @override
  String get emptyConfirmPassword => 'Tafadhali ingiza nenosiri la kuthibitisha';

  @override
  String get validateSamePassword => 'Nenosiri lazima liwe sawa';

  @override
  String get changingYourPassword => 'Kubadilisha nenosiri lako';

  @override
  String changePasswordFailed(Object error) {
    return 'Imeshindwa kubadilisha nenosiri: $error';
  }

  @override
  String get passwordChangedSuccessfully => 'Nenosiri limebadilishwa';

  @override
  String get emptyTaskList => 'Bado hakuna orodha ya Majukumu iliyoundwa';

  @override
  String get addMoreDetails => 'Ongeza Maelezo Zaidi';

  @override
  String get taskName => 'Jina la kazi';

  @override
  String get addingTask => 'Kuongeza Kazi';

  @override
  String countTasksCompleted(Object count) {
    return '$count Imekamilika';
  }

  @override
  String get showCompleted => 'Onyesho Limekamilika';

  @override
  String get hideCompleted => 'Ficha Imekamilika';

  @override
  String get assignment => 'Mgawo';

  @override
  String get noAssignment => 'Hakuna mgawo';

  @override
  String get assignMyself => 'Nikabidhi Mwenyewe';

  @override
  String get removeMyself => 'Niondoe';

  @override
  String get updateTask => 'Sasisha Kazi';

  @override
  String get updatingTask => 'Kusasisha Jukumu';

  @override
  String updatingTaskFailed(Object error) {
    return 'Kusasisha Jukumu kumeshindwa$error';
  }

  @override
  String get editTitle => 'Badilisha Kichwa';

  @override
  String get updatingDescription => 'Inasasisha Maelezo';

  @override
  String errorUpdatingDescription(Object error) {
    return 'Hitilafu imetokea wakati wa kusasisha maelezo: $error';
  }

  @override
  String get editLink => 'Badilisha Kiungo';

  @override
  String get updatingLinking => 'Inasasisha kiungo';

  @override
  String get deleteTaskList => 'Futa Orodha ya Kazi';

  @override
  String get deleteTaskItem => 'Futa Kipengee cha Kazi';

  @override
  String get reportTaskList => 'Ripoti Orodha ya Kazi';

  @override
  String get reportTaskItem => 'Ripoti Jukumu';

  @override
  String get unconfirmedEmailsActivityTitle => 'Una Anwani za Barua Pepe ambazo hazijathibitishwa';

  @override
  String get unconfirmedEmailsActivitySubtitle => 'Tafadhali fuata kiungo ambacho tumekutumia kwenye barua pepe kisha uyathibitishe hapa';

  @override
  String get seeAll => 'Tazama zote';

  @override
  String get addPin => 'Ongeza Pini';

  @override
  String get addEvent => 'Ongeza Tukio';

  @override
  String get linkChat => 'Unganisha Gumzo';

  @override
  String get linkSpace => 'Unganisha Nafasi';

  @override
  String failedToUploadAvatar(Object error) {
    return 'Imeshindwa kupakia avatar: $error';
  }

  @override
  String get noMatchingTasksListFound => 'Hakuna orodha ya kazi zinazolingana iliyopatikana';

  @override
  String get noTasksListAvailableYet => 'Bado hakuna orodha ya majukumu inayopatikana';

  @override
  String get noTasksListAvailableDescription => 'Shiriki na udhibiti kazi muhimu na jumuiya yako kama vile orodha yoyote ya MAMBO YA KUFANYA ili kila mtu asasishwe.';

  @override
  String loadingMembersFailed(Object error) {
    return 'Imeshindwa kupakia washiriki: $error';
  }

  @override
  String get ongoing => 'Inaendelea';

  @override
  String get noMatchingEventsFound => 'Hakuna matukio yanayolingana yaliyopatikana';

  @override
  String get noEventsFound => 'Hakuna matukio yaliyopatikana';

  @override
  String get noEventAvailableDescription => 'Unda tukio jipya na ulete jumuiya yako pamoja.';

  @override
  String get myEvents => 'Matukio Yangu';

  @override
  String get eventStarted => 'Imeanza';

  @override
  String get eventStarts => 'Huanza';

  @override
  String get eventEnded => 'Imeisha';

  @override
  String get happeningNow => 'Inatokea Sasa';

  @override
  String get myUpcomingEvents => 'Matukio Yangu Yajayo';

  @override
  String get live => 'moja kwa moja';

  @override
  String get forbidden => 'Forbidden';

  @override
  String get forbiddenRoomExplainer => 'Access to the room has been denied. Please contact the author to be invited';

  @override
  String accessDeniedToRoom(Object roomId) {
    return 'Access to $roomId denied';
  }

  @override
  String get changeDate => 'Badilisha Tarehe';

  @override
  String deepLinkNotSupported(Object link) {
    return 'Link $link not supported';
  }

  @override
  String get deepLinkWrongFormat => 'Not a link. Can\'t open.';

  @override
  String get updatingDate => 'Inasasisha Tarehe';

  @override
  String get pleaseEnterALink => 'Tafadhali weka kiungo';

  @override
  String get pleaseEnterAValidLink => 'Tafadhali weka kiungo halali';

  @override
  String get addLink => 'Ongeza Kiungo';

  @override
  String get attachmentEmptyStateTitle => 'Hakuna viambatisho vilivyopatikana.';

  @override
  String get referencesEmptyStateTitle => 'No references found.';

  @override
  String get text => 'Maandishi';

  @override
  String get audio => 'Sauti';

  @override
  String get pinDetails => 'Maelezo ya pini';

  @override
  String get inSpaceLabelInline => 'Katika:';

  @override
  String get comingSoon => 'Bado haitumiki, inakuja hivi karibuni!';

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
    return 'Hitilafu katika kupakia nafasi: $error';
  }

  @override
  String get eventNoLongerAvailable => 'Tukio halipatikani tena';

  @override
  String get eventDeletedOrFailedToLoad => 'Hii inaweza kutokana na kufutwa kwa tukio au kushindwa kupakiwa';

  @override
  String get chatNotEncrypted => 'Maongezi haya hayajasimbwa kwa njia fiche kutoka mwisho hadi mwisho';

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
  String get action => 'Kitendo';

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
