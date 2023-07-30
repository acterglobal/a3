import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;

class NotificationBrief {
  final String title;
  const NotificationBrief({required this.title});

  static NotificationBrief unsupported() {
    return const NotificationBrief(title: 'not yet supported');
  }

  static NotificationBrief fromTextDesc(ffi.TextDesc? textDesc) {
    if (textDesc == null) {
      return const NotificationBrief(title: 'chat message w/o content');
    }
    String body = textDesc.body();
    String? formattedBody = textDesc.formattedBody();
    if (formattedBody != null) {
      body = simplifyBody(formattedBody);
    }
    return NotificationBrief(title: body);
  }
}
