import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

extension ActerNotififyActivityObjectExtension on ActivityObject {
  String parentPart() {
    final emoji = this.emoji();
    final title = switch (typeStr()) {
      'news' => 'boost',
      'story' => 'story',
      _ => this.title(),
    };
    return "$emoji $title";
  }

  String getObjectCentricTitlePart(
    String suffix,
  ) {
    final parentInfo = parentPart();
    return '$parentInfo $suffix';
  }
}

extension ActerNotififyNotificationItemExtension on NotificationItem {
  String getUserCentricTitlePart(
    String? emoji,
    String suffix,
  ) {
    final sender = this.sender();
    final username = sender.displayName() ?? sender.userId();

    String titlePart = '$username $suffix';
    if (emoji != null) titlePart = '$emoji $titlePart';
    return titlePart;
  }
}
