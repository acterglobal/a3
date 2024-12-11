import 'package:acter/common/utils/constants.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';

enum LabsFeature {
  // apps in general
  notes,
  cobudget,
  polls,
  discussions,

  // specific features
  chatUnread,
  chatNG,

  // system features
  deviceCalendarSync,
  encryptionBackup,

  // candidates for always on
  comments,
  mobilePushNotifications,

  // -- not a lab anymore but needs to stay for backwards compat
  tasks,
  events,
  pins,
  showNotifications; // old name for desktop notifications

  static List<LabsFeature> get defaults =>
      isDevBuild || isNightly ? nightlyDefaults : releaseDefaults;

  static List<LabsFeature> get releaseDefaults => [
        LabsFeature.mobilePushNotifications,
        LabsFeature.deviceCalendarSync,
      ];

  static List<LabsFeature> get nightlyDefaults => [
        LabsFeature.encryptionBackup,
        LabsFeature.deviceCalendarSync,
        LabsFeature.mobilePushNotifications,
        // LabsFeature.chatNG,
      ];
}
