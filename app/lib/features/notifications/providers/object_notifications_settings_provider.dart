import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:riverpod/riverpod.dart';

final objectIsPushNotificationSubscribedProvider =
    FutureProvider.family<bool, String>((ref, objectId) async {
  final settings = await ref.watch(notificationSettingsProvider.future);
  return (await settings.objectPushSubscriptionStatusStr(objectId, null)) ==
      'subscribed';
});
