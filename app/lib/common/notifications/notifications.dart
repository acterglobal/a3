import 'package:acter/common/notifications/desktop.dart' as desktop;
import 'package:acter/common/notifications/mobile.dart' as mobile;

Future<void> initializeNotifications() async {
  mobile.initializeNotifications();
  await desktop.initializeNotifications();
}

Future<void> requestNotificationsPermissions() async {
  mobile.requestNotificationsPermissions();
  await desktop.requestNotificationsPermissions();
}

Future<void> setupNotificationsListeners() async {
  mobile.setupNotificationsListeners();
}

Future<void> notify() async {
  mobile.notify();
  await desktop.notify();
}
