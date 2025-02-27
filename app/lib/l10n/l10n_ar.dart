// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class L10nAr extends L10n {
  L10nAr([String locale = 'ar']) : super(locale);

  @override
  String get about => 'نبذة عن';

  @override
  String get accept => 'اقبل';

  @override
  String get acceptRequest => 'قبول الطلب';

  @override
  String get access => 'الوصول';

  @override
  String get accessAndVisibility => 'الوصول ووضوح الرؤية';

  @override
  String get account => 'الحساب';

  @override
  String get actionName => 'اسم العملية';

  @override
  String get actions => 'الإجراءات';

  @override
  String activateFeatureDialogTitle(Object feature) {
    return 'Activate $feature?';
  }

  @override
  String activateFeatureDialogDesc(Object feature) {
    return 'Allow anyone with permission following permissions to use $feature';
  }

  @override
  String get add => 'إضافة';

  @override
  String get addActionWidget => 'إضافة أداة إجراء';

  @override
  String get addChat => 'إضافة محادثة';

  @override
  String addedToPusherList(Object email) {
    return '$email تمت إضافته إلى قائمة pusher';
  }

  @override
  String addedToSpacesAndChats(Object number) {
    return 'تمت الإضافة إلى $number فضاءات و محادثات';
  }

  @override
  String get addingEmailAddress => 'إضافة عنوان البريد الإلكتروني';

  @override
  String get addSpace => 'إضافة فضاء';

  @override
  String get addTask => 'إضافة مهمة';

  @override
  String get admin => 'المشرف';

  @override
  String get all => 'الكُلّ';

  @override
  String get allMessages => 'جميع الرسائل';

  @override
  String allReactionsCount(Object total) {
    return 'All $total';
  }

  @override
  String get alreadyConfirmed => 'تم التأكيد سابقاً';

  @override
  String get analyticsTitle => 'ساعدنا على مساعدتك';

  @override
  String get analyticsDescription1 => 'من خلال مشاركة بيانات الأعطال وتقارير الأخطاء معنا.';

  @override
  String get analyticsDescription2 => 'هذه بالطبع مجهولة المصدر ولا تحتوي على أي معلومات خاصة';

  @override
  String get sendCrashReportsTitle => 'إرسال تقارير الأعطال والأخطاء';

  @override
  String get sendCrashReportsInfo => 'شارك تعقّب الأعطال تلقائياً عبر نظام Sentry مع فريق Acter';

  @override
  String get and => 'و';

  @override
  String get anInviteCodeYouWantToRedeem => 'رمز دعوة تريد استخدامه';

  @override
  String get anyNumber => 'أيّ رقم';

  @override
  String get appDefaults => 'الإعدادات الافتراضية للتطبيق';

  @override
  String get appId => 'AppId';

  @override
  String get appName => 'إسم التطبيق';

  @override
  String get apps => 'خصائص الفضاء';

  @override
  String get areYouSureYouWantToDeleteThisMessage => 'هل أنت متأكد من رغبتك في حذف هذه الرسالة؟ لا يمكن التراجع عن هذه الخطوة.';

  @override
  String get areYouSureYouWantToLeaveRoom => 'هل أنت متأكد من رغبتك في مغادرة المحادثة؟ لا يمكن التراجع عن هذه الخطوة';

  @override
  String get areYouSureYouWantToLeaveSpace => 'هل أنت متأكد من رغبتك في مغادرة هذا الفضاء؟';

  @override
  String get areYouSureYouWantToRemoveAttachmentFromPin => 'هل أنت متأكد من رغبتك في إزالة هذا المرفق من الدّبوس؟';

  @override
  String get areYouSureYouWantToUnregisterEmailAddress => 'هل أنت متأكد من رغبتك في إلغاء تسجيل هذا البريد الإلكتروني؟ لا يمكن إبطال هذا الإجراء.';

  @override
  String get assignedYourself => 'تم تعيين نفسك';

  @override
  String get assignmentWithdrawn => 'تم سحب التعيين';

  @override
  String get aTaskMustHaveATitle => 'يجب أن تحتوي المهمة على تسمية';

  @override
  String get attachments => 'المرفقات';

  @override
  String get atThisMomentYouAreNotJoiningEvents => 'في هذه المرحلة، أنت لم تنضم إلى أيّ فعاليات قادمة. لمعرفة الفعاليات المبرمجة، قم بتفقد الفضاءات الخاصة بك.';

  @override
  String get authenticationRequired => 'يلزم التحقق من الهوية';

  @override
  String get avatar => 'الصورة الرمزية';

  @override
  String get awaitingConfirmation => 'في إنتظار التأكيد';

  @override
  String get awaitingConfirmationDescription => 'لم يتم تأكيد هذه العناوين الإلكترونية بعد. يرجى الذهاب إلى بريدك الخاص والتحقق من رابط التأكيد.';

  @override
  String get back => 'Back';

  @override
  String get block => 'حظر';

  @override
  String get blockedUsers => 'المستخدمين المحظورين';

  @override
  String get blockInfoText => 'بمجرد الحظر، لن ترى رسائلهم بعد الآن وسوف تمنع محاولتهم الاتصال بك مباشرةً.';

  @override
  String blockingUserFailed(Object error) {
    return 'فشل حظر المستخدم: $error';
  }

  @override
  String get blockingUserProgress => 'حظر المستخدم';

  @override
  String get blockingUserSuccess => 'تم حظر المستخدم. قد يستغرق الأمر بعض الوقت قبل أن تُظهر واجهة المستخدم هذا التحديث.';

  @override
  String blockTitle(Object userId) {
    return 'حظر $userId';
  }

  @override
  String get blockUser => 'حظر المستخدم';

  @override
  String get blockUserOptional => 'حظر المستخدم (اختياري)';

  @override
  String get blockUserWithUsername => 'حظر المستخدم بواسطة إسم المستخدم';

  @override
  String get bookmark => 'إشارة مرجعية';

  @override
  String get bookmarked => 'تم وضع إشارة مرجعية';

  @override
  String get bookmarkedSpaces => 'الفضاءات التي عليها إشارات مرجعية';

  @override
  String get builtOnShouldersOfGiants => 'تأسست على أكتاف العمالقة';

  @override
  String get calendarEventsFromAllTheSpaces => 'رزنامة الفعاليات في جميع الفضاءات التي تنتمي إليها';

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
  String get camera => 'كاميرا';

  @override
  String get cancel => 'إلغاء';

  @override
  String get cannotEditSpaceWithNoPermissions => 'لا يمكن تعديل الفضاء بدون أذونات';

  @override
  String get changeAppLanguage => 'تغيير لغة التطبيق';

  @override
  String get changePowerLevel => 'تغيير درجة الإذن';

  @override
  String get changeThePowerLevelOf => 'تغيير درجة الإذن لـ';

  @override
  String get changeYourDisplayName => 'تغيير إسمك المعروض';

  @override
  String get chat => 'المحادثة';

  @override
  String get chatNG => 'Next-Generation Chat';

  @override
  String get chatNGExplainer => 'Switch to next generation Chat. Features might not be stable';

  @override
  String get customizationsTitle => 'Customizations';

  @override
  String get chatMissingPermissionsToSend => 'ليس لديك أذونات لإرسال الرسائل هنا';

  @override
  String get behaviorSettingsTitle => 'Behavior';

  @override
  String get behaviorSettingsExplainer => 'Configure the behavior of your App';

  @override
  String get chatSettingsAutoDownload => 'تحميل الميديا تلقائياً';

  @override
  String get chatSettingsAutoDownloadExplainer => 'متى يتم تحميل الميديا تلقائياً';

  @override
  String get chatSettingsAutoDownloadAlways => 'دائماً';

  @override
  String get chatSettingsAutoDownloadWifiOnly => 'فقط عند الاتصال بشبكة WiFi';

  @override
  String get chatSettingsAutoDownloadNever => 'أبداً';

  @override
  String get settingsSubmitting => 'إرسال الإعدادات';

  @override
  String get settingsSubmittingSuccess => 'تم إرسال الإعدادات';

  @override
  String settingsSubmittingFailed(Object error) {
    return 'تعذر في الإرسال: $error ';
  }

  @override
  String get chatRoomCreated => 'تم إنشاء المحادثة';

  @override
  String get chatSendingFailed => 'تعذر في الإرسال. ستتم إعادة المحاولة ...';

  @override
  String get chatSettingsTyping => 'إرسال إشعارات الكتابة';

  @override
  String get chatSettingsTypingExplainer => '(قريبًا) إعلام الآخرين عند الكتابة';

  @override
  String get chatSettingsReadReceipts => 'إرسال استلامات القراءة';

  @override
  String get chatSettingsReadReceiptsExplainer => '(قريبًا) إبلاغ الآخرين عند قراءة رسالة ما';

  @override
  String get chats => 'المحادثات';

  @override
  String claimedTimes(Object count) {
    return 'تمت المطالبة $count مرّات';
  }

  @override
  String get clear => 'مسح';

  @override
  String get clearDBAndReLogin => 'مسح قاعدة البيانات وإعادة تسجيل الدخول';

  @override
  String get close => 'غلق';

  @override
  String get closeDialog => 'غلق الحوار';

  @override
  String get closeSessionAndDeleteData => 'إغلاق هذه الدورة وحذف البيانات المحلية';

  @override
  String get closeSpace => 'إغلاق الفضاء';

  @override
  String get closeChat => 'إغلاق المحادثة';

  @override
  String get closingRoomTitle => 'أغلق هذه الغرفة';

  @override
  String get closingRoomTitleDescription => 'عند إغلاق هذه الغرفة، سنقوم بما يلي :\n\n - طرد كل من لديه مستوى إذن أقل من الإذن الذي لديك \n - إزالتها كفرع من الفضاءات الأم (حيث لديك الأذونات للقيام بذلك),\n - ضبط قاعدة الدعوة إلى \"خاص\'\n - سوف تغادر الغرفة.\n\nلا يمكن التراجع فيه. هل أنت متأكد من أنك تريد الإغلاق؟';

  @override
  String get closingRoom => 'جاري الغلق';

  @override
  String closingRoomRemovingMembers(Object kicked, Object total) {
    return 'الإغلاق قيد التنفيذ. طرد عضو $kicked / $total';
  }

  @override
  String get closingRoomMatrixMsg => 'تم إغلاق الغرفة';

  @override
  String closingRoomRemovingFromParents(Object currentParent, Object totalParents) {
    return 'الإغلاق قيد التنفيذ. إزالة الغرفة من الغرفة الأم $currentParent / $totalParents';
  }

  @override
  String closingRoomDoneBut(Object skipped, Object skippedParents) {
    return 'تم الإغلاق وتمّت مغادرتك. ولكن لم تتمكن من إزالة $skipped المستخدمين الآخرين وإزالتها كفرع من $skippedParents الفضاءات بسبب عدم وجود إذن. قد لا يزال بإمكان الآخرين الوصول إليها.';
  }

  @override
  String get closingRoomDone => 'تم الغلق بنجاح.';

  @override
  String closingRoomFailed(Object error) {
    return 'الإغلاق فشل: $error';
  }

  @override
  String get coBudget => 'CoBudget';

  @override
  String get code => 'الرمز';

  @override
  String get codeMustBeAtLeast6CharactersLong => 'يجب أن يتكون الرمز من 6 أحرف على الأقل';

  @override
  String get comment => 'تعليق';

  @override
  String get comments => 'التعليقات';

  @override
  String commentsListError(Object error) {
    return 'خطأ في قائمة التعليقات: $error';
  }

  @override
  String get commentSubmitted => 'تم إيداع التعليق';

  @override
  String get community => 'المجتمع';

  @override
  String get confirmationToken => 'توكن التأكيد';

  @override
  String get confirmedEmailAddresses => 'عناوين البريد الإلكتروني المؤكَّدة';

  @override
  String get confirmedEmailAddressesDescription => 'عناوين البريد الإلكتروني المؤكّدة المرتبطة بحسابك:';

  @override
  String get confirmWithToken => 'التأكيد باستخدام التوكن';

  @override
  String get congrats => 'تهانينا!';

  @override
  String get connectedToYourAccount => 'مرتبط بحسابك';

  @override
  String get contentSuccessfullyRemoved => 'تمت إزالة المحتوى بنجاح';

  @override
  String get continueAsGuest => 'الاستمرار كزائر';

  @override
  String get continueQuestion => 'مواصلة؟';

  @override
  String get copyUsername => 'نسخ اسم المستخدم';

  @override
  String get copyMessage => 'نسخ';

  @override
  String get couldNotFetchNews => 'تعذّر جلب الأخبار';

  @override
  String get couldNotLoadAllSessions => 'تعذّر تشغيل جميع الدورات';

  @override
  String couldNotLoadImage(Object error) {
    return 'تعذر الوصول إلى الصورة بسبب $error';
  }

  @override
  String countsMembers(Object count) {
    return '$count الأعضاء';
  }

  @override
  String get create => 'إنشاء';

  @override
  String get createChat => 'إنشاء محادثة';

  @override
  String get createCode => 'إنشاء رمز';

  @override
  String get createDefaultChat => 'إنشاء غرفة محادثة افتراضية كذلك';

  @override
  String defaultChatName(Object name) {
    return '$name المحادثة';
  }

  @override
  String get createDMWhenRedeeming => 'إنشاء دي ام (DM) عند الاسترداد';

  @override
  String get createEventAndBringYourCommunity => 'إنشاء حدث جديد وجمع أعضاء مجتمعك معًا';

  @override
  String get createGroupChat => 'إنشاء مجموعة محادثة';

  @override
  String get createPin => 'إنشاء دبوس';

  @override
  String get createPostsAndEngageWithinSpace => 'إنشاء منشورات قابلة للتنفيذ وإشراك الجميع في فضائك.';

  @override
  String get createProfile => 'إنشاء ملف التعريف';

  @override
  String get createSpace => 'إنشاء فضاء';

  @override
  String get createSpaceChat => 'إنشاء فضاء للمحادثة';

  @override
  String get createSubspace => 'إنشاء فضاء فرعي';

  @override
  String get createTaskList => 'إنشاء قائمة مهام';

  @override
  String get createAcopy => 'Copy as new';

  @override
  String get creatingCalendarEvent => 'إنشاء جدول فعاليات';

  @override
  String get creatingChat => 'إنشاء محادثة';

  @override
  String get creatingCode => 'إنشاء رمز';

  @override
  String creatingNewsFailed(Object error) {
    return 'Creating update failed $error';
  }

  @override
  String get creatingSpace => 'إنشاء فضاء';

  @override
  String creatingSpaceFailed(Object error) {
    return 'فشل في إنشاء الفضاء: $error';
  }

  @override
  String creatingTaskFailed(Object error) {
    return 'فشل في إنشاء مهمة $error';
  }

  @override
  String get custom => 'خصِّص';

  @override
  String get customizeAppsAndTheirFeatures => 'تخصيص الخصائص اللازمة لهذا الفضاء';

  @override
  String get customPowerLevel => 'مستوى الإذن الخاص';

  @override
  String get dangerZone => 'منطقة خطرة';

  @override
  String get deactivate => 'إلغاء التفعيل';

  @override
  String get deactivateAccountDescription => 'إذا قمت بالاستمرار:\n\n - ستتم إزالة جميع بياناتك الشخصية من السيرفر المنزلي الخاص بك، بما في ذلك اسم العرض والصورة الرمزية \n - سيتم إغلاق جميع الدورات الخاصة بك على الفور، ولن يتمكن أي جهاز آخر من مواصلة دوراته \n - ستغادر جميع الغرف والمحادثات والفضاءات و دي ام (DMs) التي أنت فيها \n - لن تتمكن من إعادة تفعيل حسابك \n - لن تتمكن من تسجيل الدخول بعد الآن \n - لن يتمكن أحد من إعادة استعمال اسم المستخدم الخاص بك (MXID)، بما في ذلك أنت: سيظل اسم المستخدم هذا غير متاح إلى أجل غير مسمى \n - ستتم إزالتك من سيرفر الهوية، إذا قدمت أي معلومات يمكن العثور عليها من خلال ذلك (مثل البريد الإلكتروني أو رقم الهاتف) \n - سيتم حذف جميع البيانات المحلية، بما في ذلك أي مفاتيح تشفير، بشكل دائم من هذا الجهاز \n - ستظل رسائلك القديمة مرئية للأشخاص الذين تلقوها، تمامًا مثل رسائل البريد الإلكتروني التي أرسلتها في الماضي. \n\n لن تتمكن من التراجع عن هذا الخيار. هذا إجراء دائم ولا رجعة فيه.';

  @override
  String get deactivateAccountPasswordTitle => 'يرجى تقديم كلمة مرور المستخدم الخاصة بك لتأكيد رغبتك في إغلاق حسابك.';

  @override
  String get deactivateAccountTitle => 'انتبه: أنت على وشك إيقاف حسابك بشكل دائم';

  @override
  String deactivatingFailed(Object error) {
    return 'فشل في إلغاء التفعيل: \n $error';
  }

  @override
  String get deactivatingYourAccount => 'إلغاء تفعيل حسابك';

  @override
  String get deactivationAndRemovingFailed => 'فشل التعطيل وإزالة جميع البيانات المحلية';

  @override
  String get debugInfo => 'معلومات التصحيح';

  @override
  String get debugLevel => 'مستوى التصحيح';

  @override
  String get decline => 'رفض';

  @override
  String get defaultModes => 'الإعدادات التلقائية';

  @override
  String defaultNotification(Object type) {
    return 'تلقائي$type';
  }

  @override
  String get delete => 'حذف';

  @override
  String get deleteAttachment => 'حذف المرفق';

  @override
  String get deleteCode => 'حذف الرمز';

  @override
  String get deleteTarget => 'حذف الهدف';

  @override
  String get deleteNewsDraftTitle => 'Delete draft?';

  @override
  String get deleteNewsDraftText => 'Are you sure you want to delete this draft? This can’t be undone.';

  @override
  String get deleteDraftBtn => 'Delete draft';

  @override
  String get deletingPushTarget => 'حذف دفع الهدف';

  @override
  String deletionFailed(Object error) {
    return 'فشلت عملية الحذف: $error';
  }

  @override
  String get denied => 'تم النفي';

  @override
  String get description => 'الوصف';

  @override
  String get deviceId => 'معرّف الجهاز';

  @override
  String get deviceIdDigest => 'خلاصة معرّف الجهاز';

  @override
  String get deviceName => 'اسم الجهاز';

  @override
  String get devicePlatformException => 'لا يمكنك استخدام DevicePlatform.device/web في هذا السياق. المنصة غير صحيحة: SettingsSection.build';

  @override
  String get displayName => 'اسم العرض';

  @override
  String get displayNameUpdateSubmitted => 'تم إرسال تحديث لإسم العرض';

  @override
  String directInviteUser(Object userId) {
    return 'قم بدعوة مباشرة لـ $userId';
  }

  @override
  String get dms => 'دي ام (DMs)';

  @override
  String get doYouWantToDeleteInviteCode => 'هل تريد حقًا حذف رمز الدعوة بلا رجعة؟ لا يمكن استخدامه مرة أخرى بعد ذلك.';

  @override
  String due(Object date) {
    return 'الأجل: $date';
  }

  @override
  String get dueDate => 'تاريخ الأجل';

  @override
  String get edit => 'تعديل';

  @override
  String get editDetails => 'تعديل التفاصيل';

  @override
  String get editMessage => 'تعديل الرسالة';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get editSpace => 'تعديل الفضاء';

  @override
  String get edited => 'تم تعديلها';

  @override
  String get egGlobalMovement => 'على سبيل المثال. الحركة العالمية';

  @override
  String get emailAddressToAdd => 'عنوان البريد الإلكتروني المراد إضافته';

  @override
  String get emailOrPasswordSeemsNotValid => 'يبدو أن البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get emptyEmail => 'الرجاء إدخال البريد الإلكتروني';

  @override
  String get emptyPassword => 'الرجاء إدخال كلمة المرور';

  @override
  String get emptyToken => 'الرجاء إدخال الرمز';

  @override
  String get emptyUsername => 'الرجاء إدخال اسم المستخدم';

  @override
  String get encrypted => 'مشفرة';

  @override
  String get encryptedSpace => 'فضاء مشفر';

  @override
  String get encryptionBackupEnabled => 'تم تفعيل النسخ الاحتياطية المشفرة';

  @override
  String get encryptionBackupEnabledExplainer => 'يتم تخزين مفاتيحك في نسخة احتياطية مشفرة على السيرفر المنزلي الخاص بك';

  @override
  String get encryptionBackupMissing => 'النسخ الاحتياطية للتشفير مفقودة';

  @override
  String get encryptionBackupMissingExplainer => 'نوصي باستخدام النسخ الاحتياطية لمفتاح التشفير التلقائي';

  @override
  String get encryptionBackupProvideKey => 'وفر مفتاح الاسترجاع';

  @override
  String get encryptionBackupProvideKeyExplainer => 'لقد وجدنا نسخة احتياطية للتشفير التلقائي';

  @override
  String get encryptionBackupProvideKeyAction => 'توفير مفتاح';

  @override
  String get encryptionBackupNoBackup => 'لم يتم العثور على نسخة احتياطية للتشفير';

  @override
  String get encryptionBackupNoBackupExplainer => 'إذا فقدت إمكانية الوصول إلى حسابك، فقد تصبح المحادثات غير قابلة للاسترجاع. لذا نوصي بتمكين النسخ الاحتياطية التلقائية للتشفير.';

  @override
  String get encryptionBackupNoBackupAction => 'تفعيل النسخ الاحتياطي';

  @override
  String get encryptionBackupEnabling => 'تمكين النسخ الاحتياطي';

  @override
  String encryptionBackupEnablingFailed(Object error) {
    return 'فشل في تفعيل النسخ الاحتياطي: $error';
  }

  @override
  String get encryptionBackupRecovery => 'مفتاح استرجاع النسخ الاحتياطي الخاص بك';

  @override
  String get encryptionBackupRecoveryExplainer => 'قم بإيداع مفتاح استرداد النسخة الاحتياطية بطريقة آمنة.';

  @override
  String get encryptionBackupRecoveryCopiedToClipboard => 'نسخ مفتاح الاسترجاع في الحافظة';

  @override
  String get refreshing => 'Refreshing';

  @override
  String get encryptionBackupDisable => 'تعطيل مفتاح النسخ الاحتياطي؟';

  @override
  String get encryptionBackupDisableExplainer => 'ستؤدي إعادة تعيين النسخة الاحتياطية للمفتاح إلى تدميره محليًا وعلى السيرفر المنزلي. لا يمكن التراجع عن ذلك. هل أنت متأكد من رغبتك في المتابعة؟';

  @override
  String get encryptionBackupDisableActionKeepIt => 'لا، احتفظ بها';

  @override
  String get encryptionBackupDisableActionDestroyIt => 'نعم، أتلفه';

  @override
  String get encryptionBackupResetting => 'إعادة ضبط النسخ الاحتياطي';

  @override
  String get encryptionBackupResettingSuccess => 'تمت إعادة الضبط بنجاح';

  @override
  String encryptionBackupResettingFailed(Object error) {
    return 'فشل في التعطيل: $error';
  }

  @override
  String get encryptionBackupRecover => 'استرجاع النسخة الاحتياطية للتشفير';

  @override
  String get encryptionBackupRecoverExplainer => 'توفير مفتاح استرجاع لفك تشفير النسخة الاحتياطية للتشفير';

  @override
  String get encryptionBackupRecoverInputHint => 'مفتاح الاسترجاع';

  @override
  String get encryptionBackupRecoverProvideKey => 'يُرجى تقديم المفتاح';

  @override
  String get encryptionBackupRecoverAction => 'استرجاع';

  @override
  String get encryptionBackupRecoverRecovering => 'استرداد';

  @override
  String get encryptionBackupRecoverRecoveringSuccess => 'نجاح عملية الاسترجاع';

  @override
  String get encryptionBackupRecoverRecoveringImportFailed => 'فشلت عملية الاستيراد';

  @override
  String encryptionBackupRecoverRecoveringFailed(Object error) {
    return 'فشل في الاسترجاع: $error';
  }

  @override
  String get encryptionBackupKeyBackup => 'مفتاح النسخ الاحتياطي';

  @override
  String get encryptionBackupKeyBackupExplainer => 'هنا تقوم بتكوين مفتاح النسخ الاحتياطي';

  @override
  String error(Object error) {
    return 'خطأ $error';
  }

  @override
  String errorCreatingCalendarEvent(Object error) {
    return 'خطأ في إنشاء حدث في الرزنامة: $error';
  }

  @override
  String errorCreatingChat(Object error) {
    return 'خطأ في إنشاء المحادثة: $error';
  }

  @override
  String errorSubmittingComment(Object error) {
    return 'خطأ في إرسال التعليق: $error';
  }

  @override
  String errorUpdatingEvent(Object error) {
    return 'خطأ في تحديث الحدث: $error';
  }

  @override
  String get eventDescriptionsData => 'بيانات شرح الحدث';

  @override
  String get eventName => 'اسم الحدث';

  @override
  String get events => 'الفعاليات';

  @override
  String get eventTitleData => 'بيانات عنوان الحدث';

  @override
  String get experimentalActerFeatures => 'خصائص Acter التجريبية';

  @override
  String failedToAcceptInvite(Object error) {
    return 'فشل في قبول الدعوة: $error';
  }

  @override
  String failedToRejectInvite(Object error) {
    return 'فشل في رفض الدعوة: $error';
  }

  @override
  String get missingStoragePermissions => 'You must grant us permissions to storage to pick an Image file';

  @override
  String get file => 'ملف';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get forgotPasswordDescription => 'لإعادة تعيين كلمة المرور الخاصة بك، سنقوم بإرسال رابط التحقق إلى بريدك الإلكتروني. اتبع العملية هناك وبمجرد تأكيدها، يمكنك إعادة تهيئة كلمة المرور الخاصة بك هنا.';

  @override
  String get forgotPasswordNewPasswordDescription => 'بمجرد الانتهاء من العملية باستخدام رابط البريد الإلكتروني الذي أرسلناه لك، يمكنك تعيين كلمة مرور جديدة هنا:';

  @override
  String get formatMustBe => 'يجب أن تكون الصيغة @user:server.tld';

  @override
  String get foundUsers => 'المستخدمون الذين تم إيجادهم';

  @override
  String get from => 'من';

  @override
  String get gallery => 'معرض الصور';

  @override
  String get general => 'عام';

  @override
  String get getConversationGoingToStart => 'ابدأ المحادثة لبدء تنظيم التنسيق والتعاون';

  @override
  String get getInTouchWithOtherChangeMakers => 'تواصل مع صانعي التغيير أو المنظمين أو الناشطين الآخرين وتحدث معهم مباشرةً.';

  @override
  String get goToDM => 'الذهاب إلى دي ام (DM)';

  @override
  String get going => 'الانتقال';

  @override
  String get haveProfile => 'هل لديك ملف تعريف؟';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get helpCenterDesc => 'Get helpful tips about Acter';

  @override
  String get hereYouCanChangeTheSpaceDetails => 'هنا يمكنك تغيير تفاصيل الفضاء';

  @override
  String get hereYouCanSeeAllUsersYouBlocked => 'هنا يمكنك رؤية جميع المستخدمين الذين قمت بحظرهم.';

  @override
  String get hintMessageDisplayName => 'أدخل الاسم الذي تريد أن يراه الآخرون';

  @override
  String get hintMessageInviteCode => 'أدخل رمز الدعوة';

  @override
  String get hintMessagePassword => '6 أحرف على الأقل';

  @override
  String get hintMessageUsername => 'اسم مستخدم موحّد لتسجيل الدخول وتحديد الهوية';

  @override
  String get homeServerName => 'اسم السيرفر المنزلي';

  @override
  String get homeServerURL => 'رابط السيرفر المنزلي';

  @override
  String get httpProxy => 'بروكسي HTTP';

  @override
  String get image => 'صورة';

  @override
  String get inConnectedSpaces => 'في الفضاءات المتصلة، يمكنك التركيز على إجراءات أو حملات محددة لمجموعات العمل الخاصة بك والبدء في التنظيم.';

  @override
  String get info => 'معلومات';

  @override
  String get invalidTokenOrPassword => 'التوكن(token) أو كلمة المرور غير صحيحة';

  @override
  String get invitationToChat => 'تمت دعوتك للانضمام إلى المحادثة عن طريق ';

  @override
  String get invitationToDM => 'يريد بدء دي ام DM معك';

  @override
  String get invitationToSpace => 'تمت دعوتك للانضمام إلى المحادثة عن طريق ';

  @override
  String get invited => 'دعا';

  @override
  String get inviteCode => 'رمز الدعوة';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String shareInviteWithCode(Object code) {
    return 'Invite $code';
  }

  @override
  String get inviteCodeInfo => 'لا يزال الوصول إلى Acter متاحاً للمدعوين فقط. في حالة عدم حصولك على رمز دعوة من قبل مجموعة أو مبادرة معينة، استخدم الرمز أدناه للتحقق من Acter.';

  @override
  String get irreversiblyDeactivateAccount => 'إلغاء تفعيل هذا الحساب بلا رجعة';

  @override
  String get itsYou => 'هذا أنت';

  @override
  String get join => 'انضم';

  @override
  String get joined => 'إنضم';

  @override
  String joiningFailed(Object error) {
    return 'Joining failed: $error';
  }

  @override
  String get joinActer => 'انضم إلىActer';

  @override
  String joinRuleNotSupportedYet(Object role) {
    return 'قانون الانضمام $role غير مدعوم حتى الآن. عذرًا';
  }

  @override
  String kickAndBanFailed(Object error) {
    return 'فشل إزالة وحظر المستخدم: \n $error';
  }

  @override
  String get kickAndBanProgress => 'إزالة وحظر المستخدم';

  @override
  String get kickAndBanSuccess => 'تمت إزالة المستخدم وحظره';

  @override
  String get kickAndBanUser => 'إزالة وحظر المستخدم';

  @override
  String kickAndBanUserDescription(Object roomId, Object userId) {
    return 'أنت على وشك إزالة $userId من $roomId وحظره نهائيًا';
  }

  @override
  String kickAndBanUserTitle(Object userId) {
    return 'إزالة وحظر المستخدم $userId';
  }

  @override
  String kickFailed(Object error) {
    return 'فشل في إزالة المستخدم: \n $error';
  }

  @override
  String get kickProgress => 'إزالة المستخدم';

  @override
  String get kickSuccess => 'تمت إزالة المستخدم';

  @override
  String get kickUser => 'حذف مستخدم';

  @override
  String kickUserDescription(Object roomId, Object userId) {
    return 'أنت على وشك إزالة $userId من $roomId';
  }

  @override
  String kickUserTitle(Object userId) {
    return 'إزالة المستخدم $userId';
  }

  @override
  String get labs => 'المختبرات';

  @override
  String get labsAppFeatures => 'خصائص التطبيق';

  @override
  String get language => 'اللغة';

  @override
  String get leave => 'غادر';

  @override
  String get leaveRoom => 'مغادرة المحادثة';

  @override
  String get leaveSpace => 'ترك الفضاء';

  @override
  String get leavingSpace => 'مغادرة الفضاء';

  @override
  String get leavingSpaceSuccessful => 'لقد غادرت الفضاء';

  @override
  String leavingSpaceFailed(Object error) {
    return 'خطأ في مغادرة الفضاء: $error';
  }

  @override
  String get leavingRoom => 'مغادرة المحادثة';

  @override
  String get letsGetStarted => 'هيا بنا نبدأ';

  @override
  String get licenses => 'التراخيص';

  @override
  String get limitedInternConnection => 'الاتصال بالإنترنت محدود';

  @override
  String get link => 'الرابط';

  @override
  String get linkExistingChat => 'ربط المحادثة القائمة';

  @override
  String get linkExistingSpace => 'ربط الفضاء الموجود';

  @override
  String get links => 'الروابط';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get linkToChat => 'ربط بالمحادثة';

  @override
  String loadingFailed(Object error) {
    return 'فشل التحميل: $error';
  }

  @override
  String get location => 'الموقع';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get loginAgain => 'تسجيل الدخول مجدداً';

  @override
  String get loginContinue => 'سجّل الدخول وتابع التنظيم أين توقفت آخر مرة.';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get logSettings => 'إعدادات التسجيل';

  @override
  String get looksGoodAddressConfirmed => 'يبدو جيد. تم تأكيد العنوان.';

  @override
  String get makeADifference => 'افتح تنظيمك الرقمي.';

  @override
  String get manage => 'إدارة';

  @override
  String get manageBudgetsCooperatively => 'إدارة الميزانيات بشكل جماعي';

  @override
  String get manageYourInvitationCodes => 'إدارة رموز الدعوات الخاصة بك';

  @override
  String get markToHideAllCurrentAndFutureContent => 'وضع علامة لإخفاء كل المحتوى الحالي والمستقبلي من هذا المستخدم وحظره من الاتصال بك';

  @override
  String get markedAsDone => 'تم وضع علامة تم إنجازه';

  @override
  String get maybe => 'ربما';

  @override
  String get member => 'عضو';

  @override
  String get memberDescriptionsData => 'بيانات وصف العضو';

  @override
  String get memberTitleData => 'بيانات عنوان العضو';

  @override
  String get members => 'الأعضاء';

  @override
  String get mentionsAndKeywordsOnly => 'الإشارات والكلمات المفتاحية فقط';

  @override
  String get message => 'رسالة';

  @override
  String get messageCopiedToClipboard => 'تم نسخ الرسالة إلى الحافظة';

  @override
  String get missingName => 'الرجاء إدخال اسمك';

  @override
  String get mobilePushNotifications => 'الإشعارات المدفوعة عبر الهاتف المحمول';

  @override
  String get moderator => 'المشرف';

  @override
  String get more => 'المزيد';

  @override
  String moreRooms(Object count) {
    return '+$count غرف إضافية';
  }

  @override
  String get muted => 'مكتوم';

  @override
  String get customValueMustBeNumber => 'You need to enter the custom value as a number.';

  @override
  String get myDashboard => 'لوحة المتابعة الخاصة بي';

  @override
  String get name => 'الاسم';

  @override
  String get nameOfTheEvent => 'اسم الفعالية';

  @override
  String get needsAppRestartToTakeEffect => 'يحتاج إلى إعادة تشغيل التطبيق ليصبح ساري المفعول';

  @override
  String get newChat => 'محادثة جديدة';

  @override
  String get newEncryptedMessage => 'رسالة جديدة مشفرة';

  @override
  String get needYourPasswordToConfirm => 'تحتاج إلى كلمة المرور الخاصة بك للتأكيد';

  @override
  String get newMessage => 'رسالة جديدة';

  @override
  String get newUpdate => 'تحديث جديد';

  @override
  String get next => 'التالي';

  @override
  String get no => 'لا';

  @override
  String get noChatsFound => 'لم يتم العثور على أي محادثات';

  @override
  String get noChatsFoundMatchingYourFilter => 'لم يتم العثور على محادثات تطابق تصنيفاتك وبحثك';

  @override
  String get noChatsFoundMatchingYourSearchTerm => 'لم يتم العثور على محادثات مطابقة لمصطلح البحث';

  @override
  String get noChatsInThisSpaceYet => 'لا توجد محادثات في هذه المساحة بعد';

  @override
  String get noChatsStillSyncing => 'جاري المزامنة...';

  @override
  String get noChatsStillSyncingSubtitle => 'نحن نقوم بتحميل محادثاتك. في الحسابات الكبيرة يستغرق التحميل الأولي بعض الوقت ...';

  @override
  String get noConnectedSpaces => 'لا توجد فضاءات متصلة';

  @override
  String get noDisplayName => 'لا يوجد اسم عرض';

  @override
  String get noDueDate => 'لا يوجد تاريخ محدد';

  @override
  String get noEventsPlannedYet => 'لم يتم التخطيط لأي فعاليات بعد';

  @override
  String get noIStay => 'لا، سأبقى';

  @override
  String get noMembersFound => 'لم يتم العثور على أعضاء. هل يعقل هذا، أنت موجود، أليس كذلك؟';

  @override
  String get noOverwrite => 'عدم الكتابة فوق';

  @override
  String get noParticipantsGoing => 'لا يوجد مشاركين راحلين';

  @override
  String get noPinsAvailableDescription => 'شارك الموارد المهمة مع مجتمعك مثل المستندات أو الروابط حتى يكون الجميع على اطلاع على آخر المستجدات.';

  @override
  String get noPinsAvailableYet => 'لا توجد دبابيس متوفرة بعد';

  @override
  String get noProfile => 'ليس لديك ملف شخصي بعد؟';

  @override
  String get noPushServerConfigured => 'لا يوجد سيرفر دفع مهيأ على التصميم';

  @override
  String get noPushTargetsAddedYet => 'لم تتم إضافة أي دفع أهداف بعد';

  @override
  String get noSpacesFound => 'لم يتم العثور على أي فضاءت';

  @override
  String get noUsersFoundWithSpecifiedSearchTerm => 'لم يتم العثور على مستخدمين مع مصطلح البحث المحدد';

  @override
  String get notEnoughPowerLevelForInvites => 'مستوى الصلاحية غير كافٍ للدعوات، اطلب من المشرف تغييره';

  @override
  String get notFound => '404 - Not Found';

  @override
  String get notes => 'الملاحظات';

  @override
  String get notGoing => 'عدم المغادرة';

  @override
  String get noThanks => 'لا، شكراً';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationsOverwrites => 'إلغاء الإشعارات';

  @override
  String get notificationsOverwritesDescription => 'قم بالكتابة فوق تهيئة الإشعارات الخاصة بك لهذا الفضاء';

  @override
  String get notificationsSettingsAndTargets => 'إعدادات الإشعارات والأهداف';

  @override
  String get notificationStatusSubmitted => 'حالة الإشعار تم إرسالها';

  @override
  String notificationStatusUpdateFailed(Object error) {
    return 'فشل في تحديث حالة الإشعار: $error';
  }

  @override
  String get notificationsUnmuted => 'تم إلغاء كتم الإشعارات';

  @override
  String get notificationTargets => 'أهداف الإشعارات';

  @override
  String get notifyAboutSpaceUpdates => 'الإشعار بتحديثات الفضاء فورًا';

  @override
  String get noTopicFound => 'لم يتم العثور على أي موضوع';

  @override
  String get notVisible => 'غير ظاهرة';

  @override
  String get notYetSupported => 'غير مدعوم بعد';

  @override
  String get noWorriesWeHaveGotYouCovered => 'لا تقلق! أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور الخاصة بك.';

  @override
  String get ok => 'موافق';

  @override
  String get okay => 'موافق';

  @override
  String get on => 'على';

  @override
  String get onboardText => 'دعونا نبدأ بإعداد ملفك الشخصي';

  @override
  String get onlySupportedIosAndAndroid => 'مدعوم فقط على الهاتف المحمول (iOS وAndroid) في الوقت الحالي';

  @override
  String get optional => 'اختياري';

  @override
  String get or => ' أو ';

  @override
  String get overview => 'لمحة عامة';

  @override
  String get parentSpace => 'الفضاء الأم';

  @override
  String get parentSpaces => 'الفضاءات الأم';

  @override
  String get parentSpaceMustBeSelected => 'يجب تحديد الفضاء الأم';

  @override
  String get parents => 'الأم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get passwordResetTitle => 'إعادة ضبط كلمة المرور';

  @override
  String get past => 'السابق';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String peopleGoing(Object count) {
    return '$count أشخاص مغادرون';
  }

  @override
  String get personalSettings => 'الإعدادات الخاصة';

  @override
  String get pinName => 'دبس الاسم';

  @override
  String get pins => 'الدبابيس';

  @override
  String get play => 'شغل';

  @override
  String get playbackSpeed => 'سرعة إعادة التشغيل';

  @override
  String get pleaseCheckYourInbox => 'يُرجى تفقد صندوق الوارد الخاص بك للحصول على رسالة التحقق من البريد الإلكتروني والنقر على الرابط قبل انتهاء صلاحيته';

  @override
  String get pleaseEnterAName => 'الرجاء إدخال اسم';

  @override
  String get pleaseEnterATitle => 'الرجاء إدخال عنوان';

  @override
  String get pleaseEnterEventName => 'يُرجى إدخال اسم الحدث';

  @override
  String get pleaseFirstSelectASpace => 'يرجى أولاً اختيار فضاء';

  @override
  String errorProcessingSlide(Object error, Object slideIdx) {
    return 'We couldn’t process slide $slideIdx: $error';
  }

  @override
  String get pleaseProvideEmailAddressToAdd => 'يرجى إدخال عنوان البريد الإلكتروني الذي ترغب في إضافته';

  @override
  String get pleaseProvideYourUserPassword => 'يرجى تقديم كلمة مرور المستخدم الخاصة بك لتأكيد رغبتك في إنهاء تلك الدورة.';

  @override
  String get pleaseSelectSpace => 'الرجاء اختيار فضاء';

  @override
  String get selectTaskList => 'Select Task List';

  @override
  String get pleaseWait => 'الرجاء الانتظار…';

  @override
  String get polls => 'الاستطلاعات';

  @override
  String get pollsAndSurveys => 'استبيانات واستطلاعات الرأي';

  @override
  String postingOfTypeNotYetSupported(Object type) {
    return 'نشر $type غير مدعوم بعد';
  }

  @override
  String get postingTaskList => 'نشر قائمة المهام';

  @override
  String get postpone => 'تأجيل';

  @override
  String postponeN(Object days) {
    return 'تأجيل $days أيام';
  }

  @override
  String get powerLevel => 'مستوى الإذن';

  @override
  String get powerLevelUpdateSubmitted => 'تم تقديم تحديث مستوى الإذن';

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
  String get preview => 'لمحة عامة';

  @override
  String get privacyPolicy => 'اتفاقية الخصوصية';

  @override
  String get private => 'خاص';

  @override
  String get profile => 'ملف التعريف';

  @override
  String get pushKey => 'مفتاح الضغط';

  @override
  String get pushTargetDeleted => 'تم حذف الهدف المدفوع';

  @override
  String get pushTargetDetails => 'تفاصيل الهدف المدفوع';

  @override
  String get pushToThisDevice => 'الدفع إلى هذا الجهاز';

  @override
  String get quickSelect => 'اختيار سريع:';

  @override
  String get rageShakeAppName => 'اسم التطبيق Rageshake';

  @override
  String get rageShakeAppNameDigest => 'خلاصة اسم تطبيق Rageshake';

  @override
  String get rageShakeTargetUrl => 'رابط الهدف Rageshake';

  @override
  String get rageShakeTargetUrlDigest => 'خلاصة عنوان الهدف Rageshake';

  @override
  String get reason => 'السبب';

  @override
  String get reasonHint => 'سبب اختياري';

  @override
  String get reasonLabel => 'السبب';

  @override
  String redactionFailed(Object error) {
    return 'فشلت عملية إعادة الإرسال بسبب بعض';
  }

  @override
  String get redeem => 'استرداد';

  @override
  String redeemingFailed(Object error) {
    return 'فشل الاسترداد: $error';
  }

  @override
  String get register => 'التسجيل';

  @override
  String registerFailed(Object error) {
    return 'Registration failed: $error';
  }

  @override
  String get regular => 'منتظم';

  @override
  String get remove => 'إزالة';

  @override
  String get removePin => 'إزالة الدبوس';

  @override
  String get removeThisContent => 'قم بإزالة هذا المحتوى. لا يمكن التراجع عن ذلك. اذكر سببًا اختياريًا لشرح سبب إزالة هذا المحتوى';

  @override
  String get reply => 'ردّ';

  @override
  String replyTo(Object name) {
    return 'الردّ على $name';
  }

  @override
  String get replyPreviewUnavailable => 'لا توجد معاينة متاحة للرسالة التي تقوم بالرد عليها';

  @override
  String get report => 'تقرير';

  @override
  String get reportThisEvent => 'الإبلاغ عن هذا الحدث';

  @override
  String get reportThisMessage => 'الإبلاغ عن هذه الرسالة';

  @override
  String get reportMessageContent => 'أبلغ مشرف الخادم المنزلي بهذه الرسالة. يرجى ملاحظة أن المشرف لن يتمكن من قراءة أو عرض أي ملفات، إذا كانت المحادثة مشفرة';

  @override
  String get reportPin => 'الإبلاغ عن الدبوس';

  @override
  String get reportThisPost => 'الإبلاغ عن هذا المنشور';

  @override
  String get reportPostContent => 'قم بالإبلاغ عن هذا المنشور إلى مشرف السيرفر المنزلي. يرجى ملاحظة أن المشرف لن يتمكن من قراءة أو عرض أي ملفات في الفضاءات المشفرة.';

  @override
  String get reportSendingFailed => 'فشل إرسال التقرير';

  @override
  String get reportSent => 'تم إرسال التقرير!';

  @override
  String get reportThisContent => 'أبلغ مشرف السيرفر المنزلي الخاص بك عن هذا المحتوى. يرجى ملاحظة أن المشرف لن يكون قادراً على قراءة أو عرض الملفات في الفضاءات المشفرة.';

  @override
  String get requestToJoin => 'طلب الانضمام';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String get resetPassword => 'إعادة ضبط كلمة المرور';

  @override
  String get retry => 'أعد المحاولة';

  @override
  String get roomId => 'معرف المحادثة';

  @override
  String get roomNotFound => 'لم يتم العثور على المحادثة';

  @override
  String get roomLinkedButNotUpgraded => 'Added. However you are not able to upgrade its join rule settings and thus not all people from this space might be able to join it.';

  @override
  String get rsvp => 'RSVP';

  @override
  String repliedToMsgFailed(Object id) {
    return 'Failed to load original message id: $id';
  }

  @override
  String get sasGotIt => 'فهمت';

  @override
  String sasIncomingReqNotifContent(String sender) {
    return '$sender يريد التحقق من دورتك';
  }

  @override
  String get sasIncomingReqNotifTitle => 'طلب التحقق';

  @override
  String get sasVerified => 'تم التحقق!';

  @override
  String get save => 'حفظ';

  @override
  String get saveFileAs => 'Save file as';

  @override
  String get openFile => 'Open';

  @override
  String get shareFile => 'Share';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get savingCode => 'رمز الحفظ';

  @override
  String get search => 'بحث';

  @override
  String get searchTermFieldHint => 'البحث عن...';

  @override
  String get searchChats => 'بحث عن المحادثات';

  @override
  String searchResultFor(Object text) {
    return 'نتيجة البحث عن $text…';
  }

  @override
  String get searchUsernameToStartDM => 'البحث عن اسم المستخدم لبدء دي ام (DM)';

  @override
  String searchingFailed(Object error) {
    return 'فشل البحث $error';
  }

  @override
  String get searchSpace => 'البحث عن فضاء';

  @override
  String get searchSpaces => 'البحث عن الفضاءات';

  @override
  String get searchPublicDirectory => 'البحث في الدليل العام';

  @override
  String get searchPublicDirectoryNothingFound => 'لم يتم العثور على أي بيانات في الدليل العام';

  @override
  String get seeOpenTasks => 'انظر المهام المفتوحة';

  @override
  String get seenBy => 'تمت مشاهدته من قبل';

  @override
  String get select => 'اختر';

  @override
  String get selectAll => 'اختيار الكل';

  @override
  String get unselectAll => 'إلغاء اختيار الكل';

  @override
  String get selectAnyRoomToSeeIt => 'حدد أي محادثة لرؤيتها';

  @override
  String get selectDue => 'اختر تاريخ الاستحقاق';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get selectParentSpace => 'اختر الفضاء الأم';

  @override
  String get send => 'أرسل';

  @override
  String get sendingAttachment => 'إرسال المرفق';

  @override
  String get sendingReport => 'إرسال التقرير';

  @override
  String get sendingEmail => 'إرسال بريد إلكتروني';

  @override
  String sendingEmailFailed(Object error) {
    return 'فشل الإرسال: $error';
  }

  @override
  String sendingRsvpFailed(Object error) {
    return 'Sending RSVP failed: $error';
  }

  @override
  String get sentAnImage => 'تم إرسال صورة.';

  @override
  String get server => 'السيرفر';

  @override
  String get sessions => 'الدورات';

  @override
  String get sessionTokenName => 'اسم توكن (Token) الدورة';

  @override
  String get setDebugLevel => 'ضبط مستوى التصحيح';

  @override
  String get setHttpProxy => 'ضبط بروكسي HTTP';

  @override
  String get settings => 'الإعدادات';

  @override
  String get securityAndPrivacy => 'الأمن والخصوصية';

  @override
  String get settingsKeyBackUpTitle => 'مفتاح النسخ الاحتياطي';

  @override
  String get settingsKeyBackUpDesc => 'إدارة النسخة الاحتياطية';

  @override
  String get share => 'شارك';

  @override
  String get shareIcal => 'مشاركة iCal';

  @override
  String shareFailed(Object error) {
    return 'المشاركة فشلت: $error';
  }

  @override
  String get sharedCalendarAndEvents => 'الرزنامة والفعاليات المفتوحة';

  @override
  String get signUp => 'التسجيل';

  @override
  String get skip => 'تجاوز';

  @override
  String get slidePosting => 'نشر الشرائح';

  @override
  String slidesNotYetSupported(Object type) {
    return '$type الشرائح غير مدعومة بعد';
  }

  @override
  String get someErrorOccurredLeavingRoom => 'حدث خطأ ما أثناء مغادرة المحادثة';

  @override
  String get space => 'فضاء';

  @override
  String get spaceConfiguration => 'تهيئة الفضاء';

  @override
  String get spaceConfigurationDescription => 'قم بتهيئة من يمكنه الاطلاع على هذا الفضاء وكيفية الانضمام إليه';

  @override
  String get spaceName => 'اسم الفضاء';

  @override
  String get spaceNotificationOverwrite => 'استبدال إشعار الفضاء';

  @override
  String get spaceNotifications => 'إشعارات الفضاء';

  @override
  String get spaceOrSpaceIdMustBeProvided => 'يجب توفير فضاء أو معرف فضاء (spaceId)';

  @override
  String get spaces => 'الفضاءات';

  @override
  String get spacesAndChats => 'الفضاءات و المحادثات';

  @override
  String get spacesAndChatsToAddThemTo => 'الفضاءات والمحادثات المراد إضافتها إلي';

  @override
  String get startDM => 'ابدأ دي ام DM';

  @override
  String get state => 'الحالة';

  @override
  String get submit => 'إرسال';

  @override
  String get submittingComment => 'إرسال التعليق';

  @override
  String get suggested => 'مقترحة';

  @override
  String get suggestedUsers => 'المستخدمين المقترحين';

  @override
  String get joiningSuggested => 'اقتراح الانضمام';

  @override
  String get suggestedRoomsTitle => 'مقترح للانضمام';

  @override
  String get suggestedRoomsSubtitle => 'نقترح عليك أيضاً الانضمام إلى';

  @override
  String get addSuggested => 'تم تحديده كمقترح';

  @override
  String get removeSuggested => 'حذف الاقتراح';

  @override
  String get superInvitations => 'دعوات مميزة';

  @override
  String get superInvites => 'رموز الدعوة';

  @override
  String superInvitedBy(Object user) {
    return '$user يدعوك';
  }

  @override
  String superInvitedTo(Object count) {
    return 'للانضمام إلى غرفة $count';
  }

  @override
  String superInvitesPreviewMissing(Object token) {
    return 'السيرفر الخاص بك لا يدعم معاينة رموز الدعوة. لا يزال بإمكانك محاولة استرداد $token رغم ذلك';
  }

  @override
  String superInvitesDeleted(Object token) {
    return 'رمز الدعوة $token لم يعد صالحاً بعد الآن.';
  }

  @override
  String get takeAFirstStep => 'التطبيق الآمن للتنظيم الذي يتطور مع تطلعاتك. توفير فضاء آمن للحركات.';

  @override
  String get taskListName => 'اسم قائمة المهام';

  @override
  String get tasks => 'المهام';

  @override
  String get termsOfService => 'بنود الخدمة';

  @override
  String get termsText1 => 'بالنقر على إنشاء ملف شخصي فإنك توافق على';

  @override
  String theCurrentJoinRulesOfSpace(Object parentSpaceName, Object roomName) {
    return 'قواعد الانضمام الحالية ل $roomName يعني أنه لن يكون مرئيًا لأعضاء $parentSpaceName’.هل يجب علينا تحديث قواعد الانضمام للسماح لأعضاء $parentSpaceName برؤية أعضاء $roomName والانضمام إليها؟';
  }

  @override
  String get theParentSpace => 'الفضاء الأم';

  @override
  String get thereIsNothingScheduledYet => 'لا يوجد شيء مجدول حتى الآن';

  @override
  String get theSelectedRooms => 'المحادثات المختارة';

  @override
  String get theyWontBeAbleToJoinAgain => 'لن يتمكنوا من الانضمام مرة أخرى';

  @override
  String get thirdParty => 'طرف ثالث';

  @override
  String get thisApaceIsEndToEndEncrypted => 'هذا الفضاء مشفر من البداية إلى النهاية';

  @override
  String get thisApaceIsNotEndToEndEncrypted => 'هذا الفضاء ليس مشفرًا من طرف إلى طرف';

  @override
  String get thisIsAMultilineDescription => 'هذا شرح للمهمة في عدة أسطر مع نصوص مطولة وأشياء أخرى';

  @override
  String get thisIsNotAProperActerSpace => 'هذه ليس فضاءً مناسباً acter. قد لا تتوفر بعض الميزات.';

  @override
  String get thisMessageHasBeenDeleted => 'تم مسح هذه الرسالة';

  @override
  String get thisWillAllowThemToContactYouAgain => 'سيسمح لهم ذلك بالتواصل معك مرة أخرى';

  @override
  String get title => 'العنوان';

  @override
  String get titleTheNewTask => 'عنوان المهمة الجديدة..';

  @override
  String typingUser1(Object user) {
    return '$user يقوم بالكتابة...';
  }

  @override
  String typingUser2(Object user1, Object user2) {
    return '$user1 و $user2 يكتبان...';
  }

  @override
  String typingUserN(Object user, Object userCount) {
    return '$user و $userCount آخرين يكتبون';
  }

  @override
  String get to => 'إلى';

  @override
  String get toAccess => 'to access';

  @override
  String get needToBeMemberOf => 'you need to be member of';

  @override
  String get today => 'اليوم';

  @override
  String get token => 'توكن (token)';

  @override
  String get tokenAndPasswordMustBeProvided => 'يجب توفير التوكن (Token) وكلمة المرور';

  @override
  String get tomorrow => 'غداً';

  @override
  String get topic => 'الموضوع';

  @override
  String get tryingToConfirmToken => 'محاولة تأكيد التوكن (token)';

  @override
  String tryingToJoin(Object name) {
    return 'يحاول الانضمام $name';
  }

  @override
  String get tryToJoin => 'حاول الانضمام';

  @override
  String get typeName => 'اكتب الاسم';

  @override
  String get unblock => 'إلغاء الحظر';

  @override
  String get unblockingUser => 'إلغاء حظر المستخدم';

  @override
  String unblockingUserFailed(Object error) {
    return 'فشل إلغاء حظر المستخدم: $error';
  }

  @override
  String get unblockingUserProgress => 'إلغاء حظر المستخدم';

  @override
  String get unblockingUserSuccess => 'تم إلغاء حظر المستخدم. قد يستغرق الأمر بعض الوقت قبل أن يظهر هذا التحديث على واجهة المستخدم.';

  @override
  String unblockTitle(Object userId) {
    return 'إلغاء حظر $userId';
  }

  @override
  String get unblockUser => 'إلغاء حظر مستخدم';

  @override
  String unclearJoinRule(Object rule) {
    return 'قواعد الانضمام غير واضحة $rule';
  }

  @override
  String get unreadMarkerFeatureTitle => 'العلامات غير المقروءة';

  @override
  String get unreadMarkerFeatureDescription => 'تتبع وإظهار المحادثات التي تمت قراءتها';

  @override
  String get undefined => 'غير محدد';

  @override
  String get unknown => 'مجهول';

  @override
  String get unknownRoom => 'محادثة غير معروفة';

  @override
  String get unlink => 'فك الربط';

  @override
  String get unmute => 'إلغاء الكتم';

  @override
  String get unset => 'إلغاء الضبط';

  @override
  String get unsupportedPleaseUpgrade => 'غير مدعوم - يرجى التحديث!';

  @override
  String get unverified => 'لم يتم التحقق';

  @override
  String get unverifiedSessions => 'دورات لم يتم التحقق منها';

  @override
  String get unverifiedSessionsDescription => 'لديك أجهزة مسجلة في حسابك لم يتم التحقق منها. قد يشكل ذلك خطراً أمنياً. يرجى التأكد من أن هذا الأمر مقبول.';

  @override
  String unverifiedSessionsCount(int count) {
    return 'There are $count unverified sessions logged in';
  }

  @override
  String get upcoming => 'القادم';

  @override
  String get updatePowerLevel => 'تحديث مستوى الإذن';

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
  String get updatingDisplayName => 'تحديث اسم العرض';

  @override
  String get updatingDue => 'التحديث المستحق';

  @override
  String get updatingEvent => 'تحديث الفعالية';

  @override
  String updatingPowerLevelOf(Object userId) {
    return 'تحديث مستوى الإذن ل $userId';
  }

  @override
  String get updatingProfileImage => 'تحديث صورة ملف التعريف';

  @override
  String get updatingRSVP => 'تحديث RSVP';

  @override
  String get updatingSpace => 'تحديث الفضاء';

  @override
  String get uploadAvatar => 'تحميل الصورة الرمزية';

  @override
  String usedTimes(Object count) {
    return 'استُخدمت $count مرات';
  }

  @override
  String userAddedToBlockList(Object user) {
    return 'تمت إضافة $user إلى قائمة الحظر. قد يستغرق تحديث واجهة المستخدم بعض الوقت';
  }

  @override
  String get users => 'Users';

  @override
  String get usersfoundDirectory => 'مستخدمون تم العثور عليهم في الدليل العام';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get usernameCopiedToClipboard => 'تم نسخ اسم المستخدم إلى الحافظة';

  @override
  String get userRemovedFromList => 'تمت إزالة المستخدم من القائمة. قد يستغرق تحديث واجهة المستخدم بعض الوقت';

  @override
  String get usersYouBlocked => 'المستخدمون الذين قمت بحظرهم';

  @override
  String get validEmail => 'الرجاء إدخال بريد إلكتروني صحيح';

  @override
  String get verificationConclusionCompromised => 'قد يتعرض واحد مما يلي للاختراق:\n\n   - السيرفر المنزلي\n   - السيرفر المنزلي الذي يتصل به المستخدم الذي تقوم بالتحقق منه\n   - اتصالك أنت، أو اتصال المستخدمين الآخرين بالإنترنت\n   - جهازك أو جهاز المستخدمين الآخرين';

  @override
  String verificationConclusionOkDone(String sender) {
    return 'لقد نجحت في التحقق من $sender!';
  }

  @override
  String get verificationConclusionOkSelfNotice => 'تم التحقق من دورتك الجديدة الآن. لديها حق الوصول إلى رسائلك المشفرة، وسيرى المستخدمون الآخرون أنها موثوقة.';

  @override
  String get verificationEmojiNotice => 'قارن بين الرموز التعبيرية المميزة، وتأكد من ظهورها بالترتيب نفسه.';

  @override
  String get verificationRequestAccept => 'للمواصلة، يُرجى قبول طلب التحقق من جهازك الآخر.';

  @override
  String verificationRequestWaitingFor(String sender) {
    return 'في انتظار $sender…';
  }

  @override
  String get verificationSasDoNotMatch => 'لا تتطابق';

  @override
  String get verificationSasMatch => 'تتطابق';

  @override
  String get verificationScanEmojiTitle => 'لا يمكن المسح الضوئي';

  @override
  String get verificationScanSelfEmojiSubtitle => 'تحقق من خلال مقارنة الرموز التعبيرية عوضاً عن ذلك';

  @override
  String get verificationScanSelfNotice => 'امسح الرمز باستخدام جهازك الآخر أو قم بالتبديل والمسح باستخدام هذا الجهاز';

  @override
  String get verified => 'تم التحقق';

  @override
  String get verifiedSessionsDescription => 'تم التحقق من جميع أجهزتك. حسابك آمن.';

  @override
  String get verifyOtherSession => 'التحقق من دورة أخرى';

  @override
  String get verifySession => 'التحقق من الدورة';

  @override
  String get verifyThisSession => 'تحقق من هذه الدورة';

  @override
  String get version => 'الإصدار';

  @override
  String get via => 'عن طريق';

  @override
  String get video => 'فيديو';

  @override
  String get welcomeBack => 'أهلاً بعودتك';

  @override
  String get welcomeTo => 'مرحباً بك في ';

  @override
  String get whatToCallThisChat => 'ماذا نسمي هذه المحادثة؟';

  @override
  String get yes => 'نعم';

  @override
  String get yesLeave => 'نعم، مغادرة';

  @override
  String get yesPleaseUpdate => 'نعم، الرجاء التحديث';

  @override
  String get youAreAbleToJoinThisRoom => 'يمكنك الانضمام إلى هذه المحادثة';

  @override
  String youAreAboutToBlock(Object userId) {
    return 'أنت على وشك حظر $userId';
  }

  @override
  String youAreAboutToUnblock(Object userId) {
    return 'أنت على وشك إلغاء حظر $userId';
  }

  @override
  String get youAreBothIn => 'you are both in ';

  @override
  String get youAreCurrentlyNotConnectedToAnySpaces => 'أنت غير متصل حالياً بأي فضاءات';

  @override
  String get spaceShortDescription => 'فضاء، لبدء التنسيق، والتعاون!';

  @override
  String get youAreDoneWithAllYourTasks => 'لقد أنجزت جميع مهامك!';

  @override
  String get youAreNotAMemberOfAnySpaceYet => 'أنت لست عضوًا في أي فضاء بعد';

  @override
  String get youAreNotPartOfThisGroup => 'أنت لست جزءًا من هذه المجموعة. هل ترغب في الانضمام؟';

  @override
  String get youHaveNoDMsAtTheMoment => 'ليس لديك أي رسائل مباشرة (DMs )في الوقت الحالي';

  @override
  String get youHaveNoUpdates => 'ليس لديك تحديثات';

  @override
  String get youHaveNotCreatedInviteCodes => 'لم تقم بعد بإنشاء أي رموز دعوة';

  @override
  String get youMustSelectSpace => 'يجب عليك اختيار فضاء';

  @override
  String get youNeedBeInvitedToJoinThisRoom => 'يجب دعوتك للانضمام إلى هذه المحادثة';

  @override
  String get youNeedToEnterAComment => 'عليك إدخال تعليق';

  @override
  String get youNeedToEnterCustomValueAsNumber => 'تحتاج إلى إدخال القيمة الخاصة كرقم.';

  @override
  String youCantExceedPowerLevel(Object powerLevel) {
    return 'لا يمكنك تجاوز مستوى الإذن $powerLevel';
  }

  @override
  String get yourActiveDevices => 'أجهزتك النشطة';

  @override
  String get yourPassword => 'كلمة المرور الخاصة بك';

  @override
  String get yourSessionHasBeenTerminatedByServer => 'لقد تم إغلاق دورتك من قبل السيرفر، تحتاج إلى تسجيل الدخول مرة أخرى';

  @override
  String get yourTextSlidesMustContainsSomeText => 'يجب أن تحتوي الشرائح النصيّة الخاصة بك على بعض النصّ';

  @override
  String get yourSafeAndSecureSpace => 'فضائك الآمن والمضمون لتنظيم حركة التغيير.';

  @override
  String adding(Object email) {
    return 'إضافة $email';
  }

  @override
  String get addTextSlide => 'أضف شريحة نصية';

  @override
  String get addImageSlide => 'أضف شريحة صورة';

  @override
  String get addVideoSlide => 'أضف شريحة فيديو';

  @override
  String get acter => 'Acter';

  @override
  String get acterApp => 'تطبيق Acter';

  @override
  String get activate => 'Activate';

  @override
  String get changingNotificationMode => 'تغيير وضع الإشعارات…';

  @override
  String get createComment => 'خلق تعليق';

  @override
  String get createNewPin => 'إنشاء دبوس جديد';

  @override
  String get createNewSpace => 'إنشاء فضاء جديد';

  @override
  String get createNewTaskList => 'إنشاء قائمة مهام جديدة';

  @override
  String get creatingPin => 'إنشاء دبوس…';

  @override
  String get deactivateAccount => 'إلغاء تفعيل الحساب';

  @override
  String get deletingCode => 'حذف الرمز';

  @override
  String get dueToday => 'الموعد المحدد اليوم';

  @override
  String get dueTomorrow => 'الموعد المحدد غداً';

  @override
  String get dueSuccess => 'تم تغيير الأجل بنجاح';

  @override
  String get endDate => 'تاريخ الانتهاء';

  @override
  String get endTime => 'نهاية الوقت';

  @override
  String get emailAddress => 'عنوان البريد الإلكتروني';

  @override
  String get emailAddresses => 'عناوين البريد الإلكتروني';

  @override
  String get errorParsinLink => 'Parsing Link failed';

  @override
  String errorCreatingPin(Object error) {
    return 'حدث خطأ في إنشاء دبوس $error';
  }

  @override
  String errorLoadingAttachments(Object error) {
    return 'خطأ في تحميل المرفقات: $error';
  }

  @override
  String errorLoadingAvatar(Object error) {
    return 'خطأ في تحميل الصورة الرمزية: $error';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'خطأ في تحميل ملف التعريف: $error';
  }

  @override
  String errorLoadingUsers(Object error) {
    return 'خطأ في تحميل المستخدمين: $error';
  }

  @override
  String errorLoadingTasks(Object error) {
    return 'خطأ في تحميل المهام: $error';
  }

  @override
  String errorLoadingSpace(Object error) {
    return 'خطأ في تحميل الفضاء: $error';
  }

  @override
  String errorLoadingRelatedChats(Object error) {
    return 'خطأ في تحميل المحادثات ذات الصلة: $error';
  }

  @override
  String errorLoadingPin(Object error) {
    return 'خطأ في تحميل الدبوس: $error';
  }

  @override
  String errorLoadingEventDueTo(Object error) {
    return 'حدث خطأ في تحميل الحدث بسبب: $error';
  }

  @override
  String errorLoadingImage(Object error) {
    return 'خطأ في تحميل الصورة $error';
  }

  @override
  String errorLoadingRsvpStatus(Object error) {
    return 'خطأ في تحميل rsvp : $error';
  }

  @override
  String errorLoadingEmailAddresses(Object error) {
    return 'خطأ في تحميل عناوين البريد الإلكتروني: $error';
  }

  @override
  String errorLoadingMembersCount(Object error) {
    return 'خطأ في تحميل عدد الأعضاء: $error';
  }

  @override
  String errorLoadingTileDueTo(Object error) {
    return 'خطأ في تحميل * بسبب: $error';
  }

  @override
  String errorLoadingMember(Object error, Object memberId) {
    return 'خطأ في تحميل العضو: $memberId $error';
  }

  @override
  String errorSendingAttachment(Object error) {
    return 'خطأ في إرسال المرفق: $error';
  }

  @override
  String get eventCreate => 'إنشاء حدث';

  @override
  String get eventEdit => 'تعديل حدث';

  @override
  String get eventRemove => 'إزالة حدث';

  @override
  String get eventReport => 'إبلاغ عن حدث';

  @override
  String get eventUpdate => 'تحديث الفعالية';

  @override
  String get eventShare => 'مشاركة الفعالية';

  @override
  String failedToAdd(Object error, Object something) {
    return 'فشل في الإضافة: $error';
  }

  @override
  String failedToChangePin(Object error) {
    return 'Failed to change pin: $error';
  }

  @override
  String failedToChangePowerLevel(Object error) {
    return 'فشل في تغيير مستوى الإذن: $error';
  }

  @override
  String failedToChangeNotificationMode(Object error) {
    return 'فشل في تغيير وضع الإشعار: $error';
  }

  @override
  String failedToChangePushNotificationSettings(Object error) {
    return 'فشل في تغيير إعدادات الإشعارات المدفوعة: $error';
  }

  @override
  String failedToToggleSettingOf(Object error, Object module) {
    return 'فشل في تبديل إعداد $module: $error';
  }

  @override
  String failedToEditSpace(Object error) {
    return 'تعذر تعديل الفضاء: $error';
  }

  @override
  String failedToAssignSelf(Object error) {
    return 'إخفاق في التعيين الذاتي: $error';
  }

  @override
  String failedToUnassignSelf(Object error) {
    return 'إخفاق في إلغاء التعيين الذاتي: $error';
  }

  @override
  String failedToSend(Object error) {
    return 'فشل الإرسال: $error';
  }

  @override
  String failedToCreateChat(Object error) {
    return 'إخفاق في إنشاء محادثة:  $error';
  }

  @override
  String failedToCreateTaskList(Object error) {
    return 'فشل في إنشاء قائمة المهام: $error';
  }

  @override
  String failedToConfirmToken(Object error) {
    return 'فشل في تأكيد التوكن (token): $error';
  }

  @override
  String failedToSubmitEmail(Object error) {
    return 'فشل في إرسال البريد الإلكتروني: $error';
  }

  @override
  String get failedToDecryptMessage => 'فشل فك تشفير الرسالة. إعادة طلب مفاتيح الدورة';

  @override
  String failedToDeleteAttachment(Object error) {
    return 'فشل حذف المرفق بسبب: $error';
  }

  @override
  String get failedToDetectMimeType => 'فشل في الكشف عن نوع الرسالة';

  @override
  String failedToLeaveRoom(Object error) {
    return 'فشل في مغادرة المحادثة: $error';
  }

  @override
  String failedToLoadSpace(Object error) {
    return 'فشل في تحميل فضاء: $error';
  }

  @override
  String failedToLoadEvent(Object error) {
    return 'فشل في تحميل حدث: $error';
  }

  @override
  String failedToLoadInviteCodes(Object error) {
    return 'فشل تحميل رموز الدعوة: $error';
  }

  @override
  String failedToLoadPushTargets(Object error) {
    return 'فشل في تحميل دفع الأهداف: $error';
  }

  @override
  String failedToLoadEventsDueTo(Object error) {
    return 'فشل تحميل الفعاليات بسبب: $error';
  }

  @override
  String failedToLoadChatsDueTo(Object error) {
    return 'فشل تحميل المحادثات بسبب: $error';
  }

  @override
  String failedToShareRoom(Object error) {
    return 'فشل في مشاركة هذه المحادثة: $error';
  }

  @override
  String get forgotYourPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get editInviteCode => 'تعديل رمز الدعوة';

  @override
  String get createInviteCode => 'إنشاء رمز الدعوة';

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
    return 'فشل في حفظ الرمز: $error';
  }

  @override
  String createInviteCodeFailed(Object error) {
    return 'فشل في إنشاء الرمز: $error';
  }

  @override
  String deleteInviteCodeFailed(Object error) {
    return 'فشل في حذف الرمز: $error';
  }

  @override
  String get loadingChat => 'جارٍ تحميل المحادثة…';

  @override
  String get loadingCommentsList => 'جاري تحميل قائمة التعليقات';

  @override
  String get loadingPin => 'جارٍ تحميل الدبوس';

  @override
  String get loadingRoom => 'جارٍ تحميل المحادثة';

  @override
  String get loadingRsvpStatus => 'جاري تحميل حالة rsvp';

  @override
  String get loadingTargets => 'جارٍ تحميل الأهداف';

  @override
  String get loadingOtherChats => 'جاري تحميل المحادثات الأخرى';

  @override
  String get loadingFirstSync => 'جاري تحميل المزامنة الأولى';

  @override
  String get loadingImage => 'جارٍ تحميل الصورة';

  @override
  String get loadingVideo => 'جارٍ تحميل الفيديو';

  @override
  String loadingEventsFailed(Object error) {
    return 'فشل في تحميل الأحداث: $error';
  }

  @override
  String loadingTasksFailed(Object error) {
    return 'فشل في تحميل المهام: $error';
  }

  @override
  String loadingSpacesFailed(Object error) {
    return 'فشل في تحميل الفضاءات: $error';
  }

  @override
  String loadingRoomFailed(Object error) {
    return 'فشل في تحميل المحادثة: $error';
  }

  @override
  String loadingMembersCountFailed(Object error) {
    return 'فشل في تحميل عدد الأعضاء: $error';
  }

  @override
  String get longPressToActivate => 'اضغط لفترة مطولة للتفعيل';

  @override
  String get pinCreatedSuccessfully => 'تم إنشاء الدبوس بنجاح';

  @override
  String get pleaseSelectValidEndTime => 'يرجى تحديد وقت انتهاء الصلاحية';

  @override
  String get pleaseSelectValidEndDate => 'الرجاء تحديد تاريخ انتهاء الصلاحية';

  @override
  String powerLevelSubmitted(Object module) {
    return 'تحديث مستوى الإذن لـ $module المرسلة';
  }

  @override
  String get optionalParentSpace => 'فضاء الأم الاختياري';

  @override
  String redeeming(Object token) {
    return 'استرداد $token';
  }

  @override
  String get encryptedDMChat => 'محادثة دي ام DM المشفرة';

  @override
  String get encryptedChatMessage => 'رسالة مشفرة مقفلة انقر للمزيد';

  @override
  String get encryptedChatMessageInfoTitle => 'رسالة مقفلة';

  @override
  String get encryptedChatMessageInfo => 'رسائل المحادثات مشفرة من طرف إلى طرف. وهذا يعني أن الأجهزة المتصلة في وقت إرسال الرسالة هي الوحيدة التي يمكنها فك تشفيرها. إذا انضممت لاحقًا، أو قمت بتسجيل الدخول للتو أو استخدمت جهازًا جديدًا، فلن يكون لديك مفاتيح فك تشفير هذه الرسالة. يمكنك الحصول عليها عن طريق التحقق من هذه الدورة مع جهاز آخر من حسابك، أو عن طريق توفير مفتاح تشفير احتياطي أو عن طريق التحقق مع مستخدم آخر لديه صلاحية الوصول إلى المفتاح.';

  @override
  String get chatMessageDeleted => 'تم حذف الرسالة';

  @override
  String chatJoinedDisplayName(Object name) {
    return '$name انضم';
  }

  @override
  String chatJoinedUserId(Object userId) {
    return '$userId انضم';
  }

  @override
  String get chatYouJoined => 'انضممت';

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
  String get chatYouAcceptedInvite => 'لقد قبلت الدعوة';

  @override
  String chatYouInvited(Object name) {
    return 'لقد قمت بدعوة';
  }

  @override
  String chatInvitedDisplayName(Object invitee, Object name) {
    return '$name دعا';
  }

  @override
  String chatInvitedUserId(Object inviteeId, Object userId) {
    return '$userId دعا';
  }

  @override
  String chatInvitationAcceptedDisplayName(Object name) {
    return '$name قبل الدعوة';
  }

  @override
  String chatInvitationAcceptedUserId(Object userId) {
    return '$userId قبل الدعوة';
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
  String get dmChat => 'محادثة دي ام DM';

  @override
  String get regularSpaceOrChat => 'فضاء أو محادثة عادية';

  @override
  String get encryptedSpaceOrChat => 'فضاء أو محادثة مشفرة';

  @override
  String get encryptedChatInfo => 'جميع الرسائل في هذه المحادثة مشفرة من طرف إلى طرف. لا يمكن لأي شخص خارج هذه المحادثة، ولا حتى Acter أو أي سيرفر Matrix الذي يوجه الرسالة، قراءتها.';

  @override
  String get removeThisPin => 'أزل هذا الدبوس';

  @override
  String get removeThisPost => 'أزل هذا المنشور';

  @override
  String get removingContent => 'إزالة محتوى';

  @override
  String get removingAttachment => 'إزالة المرفق';

  @override
  String get reportThis => 'الإبلاغ عن هذا';

  @override
  String get reportThisPin => 'أبلغ عن هذا الدبوس';

  @override
  String reportSendingFailedDueTo(Object error) {
    return 'فشل إرسال التقرير بسبب بعض: $error';
  }

  @override
  String get resettingPassword => 'إعادة ضبط كلمة المرور الخاصة بك';

  @override
  String resettingPasswordFailed(Object error) {
    return 'إعادة الضبط فشلت: $error';
  }

  @override
  String get resettingPasswordSuccessful => 'تمت إعادة تعيين كلمة المرور بنجاح.';

  @override
  String get sharedSuccessfully => 'تمت المشاركة بنجاح';

  @override
  String get changedPushNotificationSettingsSuccessfully => 'تم تغيير إعدادات الإشعارات المدفوعة بنجاح';

  @override
  String get startDateRequired => 'تاريخ البدء ضروري!';

  @override
  String get startTimeRequired => 'وقت البدء ضروري!';

  @override
  String get endDateRequired => 'تاريخ الانتهاء ضروري!';

  @override
  String get endTimeRequired => 'وقت النهاية ضروري!';

  @override
  String get searchUser => 'البحث عن مستخدم';

  @override
  String seeAllMyEvents(Object count) {
    return 'شاهد $count أحداث الخاصة بي';
  }

  @override
  String get selectSpace => 'اختر فضاءً';

  @override
  String get selectChat => 'اختر المحادثة';

  @override
  String get selectCustomDate => 'اختر تاريخاً معيناً';

  @override
  String get selectPicture => 'اختر صورة';

  @override
  String get selectVideo => 'اختر فيديو';

  @override
  String get selectDate => 'اختر تاريخاً';

  @override
  String get selectTime => 'اختر توقيت';

  @override
  String get sendDM => 'أرسل دي ام (DM)';

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get showLess => 'عرض الأقل';

  @override
  String get joinSpace => 'الانضمام لفضاء';

  @override
  String get joinExistingSpace => 'انضم إلى الفضاء الموجود';

  @override
  String get mySpaces => 'فضاءاتي';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get startTime => 'موعد البدء';

  @override
  String get startGroupDM => 'ابدأ إدارة مجموعة دي ام DM';

  @override
  String get moreSubspaces => 'المزيد من الفضاءات الفرعية';

  @override
  String get myTasks => 'مهامي';

  @override
  String updatingDueFailed(Object error) {
    return 'فشل في التحديث: $error';
  }

  @override
  String get unlinkRoom => 'فك ربط المحادثة';

  @override
  String changeThePowerFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'من $memberStatus $currentPowerLevel إلى';
  }

  @override
  String get createOrJoinSpaceDescription => 'أنشئ فضاءً أو انضم إليه، لبدء التنظيم والتعاون!';

  @override
  String get introPageDescriptionPre => 'Acter أكثر من مجرد تطبيق.\nإنها';

  @override
  String get isLinked => 'is linked in here';

  @override
  String get canLink => 'You can link this';

  @override
  String get canLinkButNotUpgrade => 'You can link this, but not update its join permissions';

  @override
  String get introPageDescriptionHl => ' مجتمع صنّاع التغيير.';

  @override
  String get introPageDescriptionPost => ' ';

  @override
  String get introPageDescription2ndLine => 'تواصل مع زملائك النشطاء، وتبادل الأفكار وتعاون معهم لإحداث تغيير هادف.';

  @override
  String get logOutConformationDescription1 => 'انتبه: ';

  @override
  String get logOutConformationDescription2 => 'تسجيل الخروج يزيل البيانات المحلية، بما في ذلك مفاتيح التشفير. إذا كان هذا هو آخر جهاز قمت بتسجيل الدخول إليه، فقد لا تتمكن من فك تشفير أي محتوى سابق.';

  @override
  String get logOutConformationDescription3 => ' هل أنت متأكد من رغبتك في تسجيل الخروج؟';

  @override
  String membersCount(Object count) {
    return '$count أعضاء';
  }

  @override
  String get renderSyncingTitle => 'المزامنة مع السيرفر المنزلي';

  @override
  String get renderSyncingSubTitle => 'قد يستغرق ذلك بعض الوقت إذا كان لديك حساب كبير';

  @override
  String errorSyncing(Object error) {
    return 'خطأ في المزامنة: $error';
  }

  @override
  String get retrying => 'تتم إعادة المحاولة …';

  @override
  String retryIn(Object minutes, Object seconds) {
    return 'ستتم إعادة المحاولة في $minutes:$seconds';
  }

  @override
  String get invitations => 'الدعوات';

  @override
  String invitingLoading(Object userId) {
    return 'دعوة $userId';
  }

  @override
  String invitingError(Object error, Object userId) {
    return 'المستخدم $userId غير موجود أو غير قائم: $error';
  }

  @override
  String get invite => 'ادعُ';

  @override
  String errorUnverifiedSessions(Object error) {
    return 'تعذر تحميل الدورات التي لم يتم التأكد منها: $error';
  }

  @override
  String unverifiedSessionsTitle(Object count) {
    return 'هناك $count دورات غير مؤكدة تم تسجيل الدخول إليها';
  }

  @override
  String get review => 'مراجعة';

  @override
  String get activities => 'النشاطات';

  @override
  String get activitiesDescription => 'يمكن العثور على جميع الأشياء المهمة التي تحتاج إلى انتباهك هنا';

  @override
  String get noActivityTitle => 'لا يوجد نشاط لك بعد';

  @override
  String get noActivitySubtitle => 'تُعلمك بالأشياء المهمة مثل الرسائل أو الدعوات أو الطلبات.';

  @override
  String get joining => 'الانضمام';

  @override
  String get joinedDelayed => 'تم قبول الدعوة، لكن التأكيد يستغرق بعض الوقت';

  @override
  String get rejecting => 'رفض';

  @override
  String get rejected => 'رفض';

  @override
  String get failedToReject => 'لم ينجح الرفض';

  @override
  String reportedBugSuccessful(Object issueId) {
    return 'تم الإبلاغ عن الخلل بنجاح! (#$issueId)';
  }

  @override
  String get thanksForReport => 'شكراً للإبلاغ عن هذا الخلل!';

  @override
  String bugReportingError(Object error) {
    return 'خطأ في الإبلاغ عن الخلل: $error';
  }

  @override
  String get bugReportTitle => 'أبلغ عن مشكلة';

  @override
  String get bugReportDescription => 'وصف مختصر للمشكلة';

  @override
  String get emptyDescription => 'الرجاء إدخال الوصف';

  @override
  String get includeUserId => 'إدراج معرّف Matrix ID الخاص بي';

  @override
  String get includeLog => 'قم بإدراج السجلات الحالية';

  @override
  String get includePrevLog => 'إدراج سجلات من التشغيل السابق';

  @override
  String get includeScreenshot => 'إدراج لقطة شاشة';

  @override
  String get includeErrorAndStackTrace => 'Include Error & Stacktrace';

  @override
  String get jumpTo => 'الانتقال إلى';

  @override
  String get noMatchingPinsFound => 'لم يتم العثور على دبابيس مطابقة';

  @override
  String get update => 'تحديث';

  @override
  String get event => 'الفعالية';

  @override
  String get taskList => 'قائمة المهام';

  @override
  String get pin => 'دبوس';

  @override
  String get poll => 'استبيان';

  @override
  String get discussion => 'النقاش';

  @override
  String get fatalError => 'خطأ مهلك';

  @override
  String get nukeLocalData => 'نوك للبيانات المحلية';

  @override
  String get reportBug => 'الإبلاغ عن خلل';

  @override
  String get somethingWrong => 'حدث خطأ فادح:';

  @override
  String get copyToClipboard => 'نسخ للحافظة';

  @override
  String get errorCopiedToClipboard => 'تم نسخ الخطأ وتتبع المكدس إلى الحافظة';

  @override
  String get showStacktrace => 'عرض تعقب التكديس (Stacktrace)';

  @override
  String get hideStacktrace => 'إخفاء تتبع المكدس (Stacktrace)';

  @override
  String get sharingRoom => 'مشاركة هذه المحادثة…';

  @override
  String get changingSettings => 'تغيير الإعدادات…';

  @override
  String changingSettingOf(Object module) {
    return 'تعديل الإعدادات من $module';
  }

  @override
  String changedSettingOf(Object module) {
    return 'تم تغيير الإعدادات من $module';
  }

  @override
  String changingPowerLevelOf(Object module) {
    return 'تغيير مستوى الإذن في لـ $module';
  }

  @override
  String get assigningSelf => 'تعيين ذاتي…';

  @override
  String get unassigningSelf => 'إلغاء التعيين الذاتي…';

  @override
  String get homeTabTutorialTitle => 'لوحة المتابعة';

  @override
  String get homeTabTutorialDescription => 'هنا تجد فضاءاتك ولمحة عامة عن جميع الفعاليات القادمة والمهام المعلقة لهذه الفضاءات.';

  @override
  String get updatesTabTutorialTitle => 'التحديثات';

  @override
  String get updatesTabTutorialDescription => 'تدفق الأخبار حول آخر التحديثات والدعوات إلى المبادرة من فضاءاتك.';

  @override
  String get chatsTabTutorialTitle => 'المحادثات';

  @override
  String get chatsTabTutorialDescription => 'إنه المكان المناسب للمحادثة - مع مجموعات أو أفراد. يمكن ربط المحادثات بفضاءات مختلفة من أجل تعاون أوسع.';

  @override
  String get activityTabTutorialTitle => 'النشاط';

  @override
  String get activityTabTutorialDescription => 'معلومات مهمة من الفضاءات الخاصة بك، مثل الدعوات أو الطلبات. بالإضافة إلى ذلك سيتم إشعارك من قبل Acter بشأن مشاكل الحماية';

  @override
  String get jumpToTabTutorialTitle => 'الانتقال إلى';

  @override
  String get jumpToTabTutorialDescription => 'بحثك عبر الفضاءات والدبابيس، بالإضافة إلى الإجراءات السريعة والوصول المباشر إلى عدة أقسام';

  @override
  String get createSpaceTutorialTitle => 'إنشاء فضاء جديد';

  @override
  String get createSpaceTutorialDescription => 'انضم إلى مساحة موجودة على سيرفر Acter الخاص بنا أو في عالم Matrix أو أنشئ فضائك الخاص.';

  @override
  String get joinSpaceTutorialTitle => 'الانضمام إلى الفضاء الموجود';

  @override
  String get joinSpaceTutorialDescription => 'انضم إلى فضاء موجود على سيرفر Acter الخاص بنا أو في عالم Matrix أو أنشئ فضائك الخاص. [ستعرض الخيارات وتنتهي عند هذا الحد في الوقت الحالي]';

  @override
  String get spaceOverviewTutorialTitle => 'تفاصيل الفضاء';

  @override
  String get spaceOverviewTutorialDescription => 'الفضاء هو نقطة البداية للتنظيم الخاص بك. قم بإنشاء الدبابيس (الموارد) والمهام والفعاليات والتنقل عبرها. أضف محادثات أو فضاءات فرعية.';

  @override
  String get subscribedToParentMsg => 'Disable Notifications on main object to configure notification here';

  @override
  String get parentSubscribedAction => 'Notifications active through object';

  @override
  String get subscribeAction => 'Activate Notifications';

  @override
  String get unsubscribeAction => 'De-Activate Notifications';

  @override
  String get commentEmptyStateTitle => 'لم يتم العثور على أي تعليقات.';

  @override
  String get commentEmptyStateAction => 'اترك أول تعليق';

  @override
  String get previous => 'السابقة';

  @override
  String get finish => 'إنهاء';

  @override
  String get saveUsernameTitle => 'هل قمت بحفظ اسم المستخدم الخاص بك؟';

  @override
  String get saveUsernameDescription1 => 'يرجى تذكر تدوين اسم المستخدم الخاص بك. فهو مفتاحك للوصول إلى ملفك الشخصي وجميع المعلومات والفضاءات المرتبطة به.';

  @override
  String get saveUsernameDescription2 => 'اسم المستخدم الخاص بك مهم لإعادة ضبط كلمة المرور.';

  @override
  String get saveUsernameDescription3 => 'بدونها، سيُفقد إمكانية الوصول إلى ملفك الشخصي وتقدمك بشكل دائم.';

  @override
  String get acterUsername => 'اسم المستخدم Acter الخاص بك';

  @override
  String get autoSubscribeFeatureDesc => 'upon creation or interaction with objects';

  @override
  String get autoSubscribeSettingsTitle => 'Automatically subscribe ';

  @override
  String get copyToClip => 'نسخ إلى الحافظة';

  @override
  String get wizzardContinue => 'أكمل';

  @override
  String get protectPrivacyTitle => 'حماية خصوصيتك';

  @override
  String get protectPrivacyDescription1 => 'في Acter، من المهم الحفاظ على أمان حسابك. لهذا السبب يمكنك استخدامه دون ربط ملفك الشخصي ببريدك الإلكتروني لمزيد من الخصوصية والحماية.';

  @override
  String get protectPrivacyDescription2 => 'ولكن إذا كنت تفضل ذلك، لا يزال بإمكانك ربطهما معًا، على سبيل المثال، لاستعادة كلمة المرور.';

  @override
  String get linkEmailToProfile => 'تم ربط البريد الإلكتروني بملف التعريف';

  @override
  String get emailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get hintEmail => 'أدخل عنوان بريدك الإلكتروني';

  @override
  String get linkingEmailAddress => 'اربط عنوان بريدك الإلكتروني';

  @override
  String get avatarAddTitle => 'إضافة صورة رمزية للمستخدم';

  @override
  String get avatarEmpty => 'الرجاء اختيار الصورة الرمزية الخاصة بك';

  @override
  String get avatarUploading => 'تحميل الصورة الرمزية لملف التعريف';

  @override
  String avatarUploadFailed(Object error) {
    return 'فشل تحميل الصورة الرمزية للمستخدم: $error';
  }

  @override
  String get sendEmail => 'إرسال رسالة إلكترونية';

  @override
  String get inviteCopiedToClipboard => 'تم نسخ رمز الدعوة إلى الحافظة';

  @override
  String get updateName => 'تحديث الاسم';

  @override
  String get updateDescription => 'تحديث الوصف';

  @override
  String get editName => 'تعديل الاسم';

  @override
  String get editDescription => 'تعديل الوصف';

  @override
  String updateNameFailed(Object error) {
    return 'فشل في تحديث الاسم: $error';
  }

  @override
  String updateDescriptionFailed(Object error) {
    return 'فشل في تحديث الوصف: $error';
  }

  @override
  String get eventParticipants => 'المشاركون في الفعالية';

  @override
  String get upcomingEvents => 'الفعاليات المقبلة';

  @override
  String get spaceInviteDescription => 'هل هناك أي شخص ترغب في دعوته لهذا الفضاء؟';

  @override
  String get inviteSpaceMembersTitle => 'دعوة أعضاء الفضاء';

  @override
  String get inviteSpaceMembersSubtitle => 'دعوة المستخدمين من فضاء معين';

  @override
  String get inviteIndividualUsersTitle => 'دعوة المستخدمين الأفراد';

  @override
  String get inviteIndividualUsersSubtitle => 'قم بدعوة المستخدمين الموجودين على Acter';

  @override
  String get inviteIndividualUsersDescription => 'قم بدعوة أي شخص ينتمي إلى منصة Acter';

  @override
  String get inviteJoinActer => 'دعوة للانضمام إلى Acter';

  @override
  String get inviteJoinActerDescription => 'يمكنك دعوة الأشخاص للانضمام إلى Acter والانضمام تلقائيًا إلى هذا الفضاء برمز تسجيل مخصص ومشاركة ذلك معهم';

  @override
  String get generateInviteCode => 'إنشاء رمز الدعوة';

  @override
  String get pendingInvites => 'الدعوات المعلقة';

  @override
  String pendingInvitesCount(Object count) {
    return 'You have $count pending Invites';
  }

  @override
  String get noPendingInvitesTitle => 'لم يتم العثور على أي دعوات معلقة';

  @override
  String get noUserFoundTitle => 'لم يتم العثور على مستخدمين';

  @override
  String get noUserFoundSubtitle => 'البحث عن مستخدمين بواسطة اسم المستخدم أو اسم العرض الخاص بهم';

  @override
  String get done => 'تم';

  @override
  String get downloadFileDialogTitle => 'الرجاء تحديد مكان الاحتفاظ بالملف';

  @override
  String downloadFileSuccess(Object path) {
    return '\' تم حفظ الملف في $path';
  }

  @override
  String cancelInviteLoading(Object userId) {
    return 'إلغاء دعوة $userId';
  }

  @override
  String cancelInviteError(Object error, Object userId) {
    return 'المستخدم $userId ليس موجود: $error';
  }

  @override
  String get shareInviteCode => 'شارك رمز الدعوة';

  @override
  String get appUnavailable => 'التطبيق غير متاح';

  @override
  String shareInviteContent(Object code, Object roomName, Object userName) {
    return '$userName نود دعوتك إلى $roomName.\nيرجى اتباع الخطوات التالية للانضمام:\n\nالخطوة-1: قم بتحميل تطبيق Acter من الروابط أدناه https://app-redir.acter.global/\n\nالخطوة-2: استخدم رمز الدعوة أدناه في التسجيل.\nرمز الدعوة : $code\n\nهذا كل شيء! استمتع بالطريقة الجديدة الآمنة والمضمونة في التنسيق!';
  }

  @override
  String activateInviteCodeFailed(Object error) {
    return 'فشل في تفعيل الرمز: $error';
  }

  @override
  String get revoke => 'إلغاء';

  @override
  String get otherSpaces => 'فضاءات أخرى';

  @override
  String get invitingSpaceMembersLoading => 'دعوة أعضاء الفضاء';

  @override
  String invitingSpaceMembersProgress(Object count, Object total) {
    return 'دعوة عضو فضاء$count / $total';
  }

  @override
  String invitingSpaceMembersError(Object error) {
    return 'خطأ في دعوة أعضاء الفضاء: $error';
  }

  @override
  String membersInvited(Object count) {
    return '$count أعضاء تمت دعوتهم';
  }

  @override
  String get selectVisibility => 'حدد قابلية الظهور';

  @override
  String get visibilityTitle => 'مستوى الرؤية';

  @override
  String get visibilitySubtitle => 'اختر من يمكنه الانضمام إلى هذا الفضاء.';

  @override
  String get visibilityNoPermission => 'ليس لديك الأذونات اللازمة لتغيير إمكانية رؤية هذا الفضاء';

  @override
  String get public => 'عمومي';

  @override
  String get publicVisibilitySubtitle => 'يمكن لأي شخص أن يعثر وينضم إلى';

  @override
  String get privateVisibilitySubtitle => 'يمكن للأشخاص المدعوين فقط الانضمام';

  @override
  String get limited => 'محدودة';

  @override
  String get limitedVisibilitySubtitle => 'يمكن لأي شخص في فضاءات محددة أن يجد وينضم إلى';

  @override
  String get visibilityAndAccessibility => 'وضوح الرؤية وسهولة الوصول';

  @override
  String updatingVisibilityFailed(Object error) {
    return 'Updating room visibility failed: $error';
  }

  @override
  String get spaceWithAccess => 'فضاء مع إمكانية الدخول';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get changePasswordDescription => 'تغيير كلمة المرور الخاصة بك';

  @override
  String get oldPassword => 'كلمة المرور القديمة';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get emptyOldPassword => 'الرجاء إدخال كلمة المرور القديمة';

  @override
  String get emptyNewPassword => 'الرجاء إدخال كلمة مرور جديدة';

  @override
  String get emptyConfirmPassword => 'الرجاء تأكيد كلمة المرور';

  @override
  String get validateSamePassword => 'كلمة المرور يجب أن تكون هي نفسها';

  @override
  String get changingYourPassword => 'تغيير كلمة المرور الخاصة بك';

  @override
  String changePasswordFailed(Object error) {
    return 'فشل في تغيير كلمة المرور: $error';
  }

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get emptyTaskList => 'لم يتم إنشاء قائمة مهام بعد';

  @override
  String get addMoreDetails => 'أضف المزيد من التفاصيل';

  @override
  String get taskName => 'اسم المهمة';

  @override
  String get addingTask => 'إضافة مهمة';

  @override
  String countTasksCompleted(Object count) {
    return '$count أنجزت';
  }

  @override
  String get showCompleted => 'عرض المنجزة';

  @override
  String get hideCompleted => 'إخفاء المنجزة';

  @override
  String get assignment => 'التعيين';

  @override
  String get noAssignment => 'لا يوجد تعيينات';

  @override
  String get assignMyself => 'تكليف نفسي';

  @override
  String get removeMyself => 'إزالة نفسي';

  @override
  String get updateTask => 'تحديث المهمة';

  @override
  String get updatingTask => 'تحديث المهمة';

  @override
  String updatingTaskFailed(Object error) {
    return 'فشل في تحديث المهمة $error';
  }

  @override
  String get editTitle => 'تعديل العنوان';

  @override
  String get updatingDescription => 'تحديث الوصف';

  @override
  String errorUpdatingDescription(Object error) {
    return 'خطأ في تحديث الوصف: $error';
  }

  @override
  String get editLink => 'تعديل الرابط';

  @override
  String get updatingLinking => 'تحديث الرابط';

  @override
  String get deleteTaskList => 'حذف قائمة المهام';

  @override
  String get deleteTaskItem => 'حذف بند المهام';

  @override
  String get reportTaskList => 'إبلاغ عن قائمة المهام';

  @override
  String get reportTaskItem => 'إبلاغ عن بند المهام';

  @override
  String get unconfirmedEmailsActivityTitle => 'لديك عناوين بريد إلكتروني غير مؤكدة';

  @override
  String get unconfirmedEmailsActivitySubtitle => 'يرجى اتباع الرابط الذي أرسلناه لبريدك الإلكتروني ثم تأكيده هنا';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get addPin => 'إضافة دبوس';

  @override
  String get addEvent => 'إضافة حدث';

  @override
  String get linkChat => 'ربط المحادثة';

  @override
  String get linkSpace => 'ربط الفضاء';

  @override
  String failedToUploadAvatar(Object error) {
    return 'فشل تحميل الصورة الرمزية: $error';
  }

  @override
  String get noMatchingTasksListFound => 'لم يتم العثور على قائمة المهام المطابقة';

  @override
  String get noTasksListAvailableYet => 'لا توجد قائمة مهام متاحة بعد';

  @override
  String get noTasksListAvailableDescription => 'شارك المهام ذات الأولوية مع مجتمعك وقم بإدارتها، مثل أي قائمة مهام، حتى يتم إطلاع الجميع على آخر المستجدات.';

  @override
  String loadingMembersFailed(Object error) {
    return 'فشل في تحميل الأعضاء: $error';
  }

  @override
  String get ongoing => 'مستمر';

  @override
  String get noMatchingEventsFound => 'لم يتم العثور على أحداث مماثلة';

  @override
  String get noEventsFound => 'لم يتم العثور على أي فعاليات';

  @override
  String get noEventAvailableDescription => 'أنشئ فعالية جديدة واجلب مجتمعك معًا.';

  @override
  String get myEvents => 'الأحداث الخاصة بي';

  @override
  String get eventStarted => 'بدأت';

  @override
  String get eventStarts => 'البدء';

  @override
  String get eventEnded => 'انتهت';

  @override
  String get happeningNow => 'يحدث الآن';

  @override
  String get myUpcomingEvents => 'فعالياتي القادمة';

  @override
  String get live => 'مباشر';

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
    return 'خطأ في تحميل الفضاءات: $error';
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
