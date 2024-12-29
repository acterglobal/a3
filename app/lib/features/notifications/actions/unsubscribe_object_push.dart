import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:acter/features/notifications/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';

Future<bool> unsubscribeObjectPush({
  required WidgetRef ref,
  required String objectId,
  SubscriptionSubType? subType,
}) async {
  final pushSettings = await ref.read(notificationSettingsProvider.future);
  return await pushSettings.unsubscribeObjectPush(
    objectId,
    subType.map((q) => q.asType()),
  );
}
