import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/util.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::notifify::darwin');

Future<DarwinNotificationDetails?> genDarwinDetails(
    NotificationItem notification) async {
  List<DarwinNotificationAttachment> attachments = [];

  // FIXME: currently failing with
  // Parsing Notification failed: PlatformException(Error 101, Unrecognized attachment file type, UNErrorDomain, null)
  if (notification.hasImage()) {
    final tempDir = await getTemporaryDirectory();
    final filePath = await notification.imagePath(tempDir.path);
    _log.info('attachment at $filePath');
    attachments.add(DarwinNotificationAttachment(filePath));
  }
  // final badgeCount = await notificationsCount();

  return DarwinNotificationDetails(
    threadIdentifier: notification.threadId(),
    categoryIdentifier: 'message',
    badgeNumber: 1, //badgeCount + 1,
    attachments: attachments,
  );
}
