import 'package:acter/features/notifications/providers/notifiers/notification_settings_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

final notificationSettingsProvider = AsyncNotifierProvider<
    AsyncNotificationSettingsNotifier,
    NotificationSettings>(() => AsyncNotificationSettingsNotifier());

final appContentNotificationSetting =
    FutureProvider.family<bool, String>((ref, appKey) async {
  final settings = await ref.watch(notificationSettingsProvider.future);
  return await settings.globalContentSetting(appKey);
});
