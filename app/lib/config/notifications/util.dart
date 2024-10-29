import 'package:acter/config/setup.dart';
import 'package:acter/router/providers/router_providers.dart';
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
  final currentUri = mainProviderContainer.read(currentRoutingLocation);
  return currentUri == uri;
}

bool shouldReplaceCurrentRoute(String uri) {
  if (!uri.startsWith(chatRoomUriMatcher)) {
    return false;
  }

  final currentUri = mainProviderContainer.read(currentRoutingLocation);
  return currentUri.startsWith(chatRoomUriMatcher);
}

String makeForward({
  required String roomId,
  required String deviceId,
  required String eventId,
}) {
  return '/forward?roomId=${Uri.encodeComponent(roomId)}&eventId=${Uri.encodeComponent(eventId)}&deviceId=${Uri.encodeComponent(deviceId)}';
}
