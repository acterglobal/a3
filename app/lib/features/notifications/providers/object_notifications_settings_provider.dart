import 'package:acter/features/notifications/providers/notification_settings_providers.dart';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/notifications/types.dart';
import 'package:riverpod/riverpod.dart';

typedef PushSettingsQuery = ({String objectId, SubscriptionSubType? subType});

final isPushNotificationSubscribedProvider =
    FutureProvider.family<SubscriptionStatus, PushSettingsQuery>(
        (ref, query) async {
  final settings = await ref.watch(notificationSettingsProvider.future);
  final currentValue = await settings.objectPushSubscriptionStatusStr(
    query.objectId,
    query.subType.map((q) => q.asType()),
  );
  return switch (currentValue) {
    'subscribed' => SubscriptionStatus.subscribed,
    'parent' => SubscriptionStatus.parent,
    _ => SubscriptionStatus.none,
  };
});

final objectIsPushNotificationSubscribedProvider =
    FutureProvider.family<SubscriptionStatus, String>(
  (ref, objectId) => ref.watch(
    isPushNotificationSubscribedProvider(
      (objectId: objectId, subType: null),
    ).future,
  ),
);
