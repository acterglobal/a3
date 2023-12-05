import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;

class NotificationBrief {
  final String title;
  final Routes? route;
  final bool hasFormatted;
  const NotificationBrief({
    required this.title,
    this.route,
    this.hasFormatted = false,
  });

  static NotificationBrief unsupported() {
    return const NotificationBrief(title: 'not yet supported');
  }

  static NotificationBrief fromContentDesc(
    ffi.ContentDesc? contentDesc,
    Routes? route,
  ) {
    if (contentDesc == null) {
      return NotificationBrief(title: 'chat message w/o content', route: route);
    }
    final formatted = contentDesc.formattedBody();
    if (formatted != null) {
      final body = simplifyBody(formatted);
      return NotificationBrief(
        title: body,
        route: route,
        hasFormatted: true,
      );
    } else {
      return NotificationBrief(
        title: contentDesc.body(),
        route: route,
        hasFormatted: false,
      );
    }
  }
}
