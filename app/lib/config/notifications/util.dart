import 'package:acter/common/utils/utils.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:acter/router/router.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> wasRejected(String deviceId) async {
  final SharedPreferences preferences = await sharedPrefs();
  final prefKey = '$deviceId.rejected_notifications';
  return preferences.getBool(prefKey) ?? false;
}

Future<void> setRejected(String deviceId, bool value) async {
  final SharedPreferences preferences = await sharedPrefs();
  final prefKey = '$deviceId.rejected_notifications';
  preferences.setBool(prefKey, value);
}

bool isCurrentRoute(String uri) {
  final curContext = rootNavKey.currentContext;
  if (curContext == null) throw 'Root context not available';
  return curContext.read(currentRoutingLocation) == uri;
}

bool shouldReplaceCurrentRoute(String uri) {
  if (!uri.startsWith(chatRoomUriMatcher)) {
    return false;
  }
  final curContext = rootNavKey.currentContext;
  if (curContext == null) throw 'Root context not available';
  return curContext.read(currentRoutingLocation).startsWith(chatRoomUriMatcher);
}

String makeForward({
  required String roomId,
  required String deviceId,
  required String eventId,
}) {
  return '/forward?roomId=${Uri.encodeComponent(roomId)}&eventId=${Uri.encodeComponent(eventId)}&deviceId=${Uri.encodeComponent(deviceId)}';
}
