import 'package:acter/config/constants.dart';
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

  // candidates for always on
  deviceCalendarSync,
  mobilePushNotifications;

  static List<LabsFeature> get defaults =>
      isDevBuild || isNightly ? nightlyDefaults : releaseDefaults;

  static List<LabsFeature> get releaseDefaults => [LabsFeature.chatNG];

  static List<LabsFeature> get nightlyDefaults => [LabsFeature.chatNG];
}
