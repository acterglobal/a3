import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::notifify::linux');

Future<LinuxNotificationDetails?> genLinuxDetails(
    NotificationItem notification) async {
  return const LinuxNotificationDetails(
    category: LinuxNotificationCategory.imReceived,
  );
}
