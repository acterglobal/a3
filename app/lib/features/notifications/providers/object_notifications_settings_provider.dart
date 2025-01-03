import 'package:acter/features/notifications/providers/notification_settings_providers.dart';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/notifications/types.dart';
import 'package:riverpod/riverpod.dart';

typedef PushSettingsQuery = ({String objectId, SubscriptionSubType? subType});

final pushNotificationSubscribedStatusProvider =
    FutureProvider.family<SubscriptionStatus, PushSettingsQuery>(
        (ref, query) async {
  final settings = await ref.watch(notificationSettingsProvider.future);
  final currentValue = await settings.objectPushSubscriptionStatusStr(
    query.objectId,
    query.subType.map((q) => q.asType()),
  );
  return switch (currentValue) {
    'subscribed' => SubscriptionStatus.subscribed,
    'unsubscribed' => SubscriptionStatus.unsubscribed,
    'parentSubscribed' => SubscriptionStatus.parentSubscribed,
    'parentUnubscribed' => SubscriptionStatus.parentUnsubscribed,
    _ => SubscriptionStatus.none,
  };
});
