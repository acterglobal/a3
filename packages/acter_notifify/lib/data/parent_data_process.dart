
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

String parentPart(NotificationItemParent parent) {
  final emoji = parent.emoji();
  final title = switch (parent.objectTypeStr()) {
    'news' => "boost",
    _ => parent.title(),
  };
  return "$emoji $title";
}
