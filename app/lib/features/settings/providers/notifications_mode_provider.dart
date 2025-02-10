import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show NotificationSettings;
import 'package:riverpod/riverpod.dart';

typedef NotificationConfiguration = ({bool encrypted, bool oneToOne});

class AsyncNotificationSettingNotifier
    extends AutoDisposeAsyncNotifier<NotificationSettings> {
  late Stream<void> _listener;

  @override
  Future<NotificationSettings> build() async {
    final client = await ref.watch(alwaysClientProvider.future);
    final settings = await client.notificationSettings();
    _listener = settings.changesStream(); // stay up to date
    _listener.forEach((e) async {
      state = AsyncData(await client.notificationSettings());
    });
    return settings;
  }
}

final currentNotificationModeProvider = FutureProvider.autoDispose
    .family<String, NotificationConfiguration>((ref, config) async {
  final settings = await ref.watch(notificationSettingsProvider.future);
  return await settings.defaultNotificationMode(
    config.encrypted,
    config.oneToOne,
  );
});
