import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:acter/features/notifications/providers/object_notifications_settings_provider.dart';
import 'package:acter/features/notifications/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';

Future<bool> subscribeObjectPush({
  required WidgetRef ref,
  required String objectId,
  SubscriptionSubType? subType,
}) async {
  final pushSettings = await ref.read(notificationSettingsProvider.future);
  final res = await pushSettings.subscribeObjectPush(
    objectId,
    subType.map((q) => q.asType()),
  );
  ref.invalidate(
    isPushNotificationSubscribedProvider(
      (objectId: objectId, subType: subType),
    ),
  );
  return res;
}
