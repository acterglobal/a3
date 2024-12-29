import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> subscribeObjectPush({
  required WidgetRef ref,
  required String objectId,
  String? subType,
}) async {
  final pushSettings = await ref.read(notificationSettingsProvider.future);
  return await pushSettings.subscribeObjectPush(objectId, subType);
}
