import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

String parentPart(NotificationItemParent parent) {
  final emoji = parent.emoji();
  final title = switch (parent.objectTypeStr()) {
    'news' => "boost",
    _ => parent.title(),
  };
  return "$emoji $title";
}

String getUserCentricTitlePart(
  NotificationItem item,
  String? emoji,
  String suffix,
) {
  final sender = item.sender();
  final username = sender.displayName() ?? sender.userId();

  String titlePart = '$username $suffix';
  if (emoji != null) titlePart = '$emoji $titlePart';
  return titlePart;
}

String getObjectCentricTitlePart(
  NotificationItemParent parent,
  String suffix,
) {
  final parentInfo = parentPart(parent);
  return '$parentInfo $suffix';
}
