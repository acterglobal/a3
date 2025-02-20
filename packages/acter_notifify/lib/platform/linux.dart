import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<LinuxNotificationDetails?> genLinuxDetails(
    NotificationItem notification) async {
  return const LinuxNotificationDetails(
    category: LinuxNotificationCategory.imReceived,
  );
}
