import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/acter_notifify.dart';
import 'package:acter_notifify/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:windows_notification/notification_message.dart';
import 'package:windows_notification/windows_notification.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::notifify::windows');

// Create an instance of Windows Notification with your application name
// application id must be null in packaged mode
late WindowsNotification _winNotifyPlugin;

void initializeWindowsNotifications(
    {String? applicationId, HandleMessageTap? handleMessageTap}) {
  _winNotifyPlugin = WindowsNotification(applicationId: applicationId);
  if (handleMessageTap != null) {
    _winNotifyPlugin
        .initNotificationCallBack((NotificationCallBackDetails details) {
      if (details.eventType == EventType.onActivate) {
        handleMessageTap(details.message.payload);
      }
    });
  }
}

Future<void> showWindowsNotification(
  NotificationItem notification,
) async {
  String? filePath;

  final (title, body) = genTitleAndBody(notification);
  if (notification.hasImage()) {
    final tempDir = await getTemporaryDirectory();
    filePath = await notification.imagePath(tempDir.path);
    _log.info('attachment at $filePath');
  }
  // create new NotificationMessage instance with id, title, body, and images
  NotificationMessage message = NotificationMessage.fromPluginTemplate(
    "test1",
    title,
    body ?? '',
    largeImage: filePath,
    image: filePath,
    group: notification.threadId(),
    // we could deep-link here.
    // launch: notification.targetUrl(),
    payload: {
      'payload': notification.targetUrl(), // this is the target url
    },
  );

  // show notification
  _winNotifyPlugin.showNotificationPluginTemplate(message);
}

Future<void> windowsClearNotificationsCache(String roomId) async {
  return await _winNotifyPlugin.removeNotificationGroup(roomId);
}
