import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;

class NotificationBrief {
  final String title;
  final Routes? route;
  const NotificationBrief({required this.title, this.route});

  static NotificationBrief unsupported() {
    return const NotificationBrief(title: 'not yet supported');
  }

  static NotificationBrief fromTextDesc(ffi.TextDesc? textDesc, Routes? route) {
    if (textDesc == null) {
      return NotificationBrief(title: 'chat message w/o content', route: route);
    }
    String body = textDesc.body();
    String? formattedBody = textDesc.formattedBody();
    if (formattedBody != null) {
      body = simplifyBody(formattedBody);
    }
    return NotificationBrief(title: body, route: route);
  }
}
