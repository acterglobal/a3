import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

typedef NotificationConfiguration = ({bool encrypted, bool oneToOne});

class AsyncNotificationSettingNotifier
    extends AutoDisposeAsyncNotifier<NotificationSettings> {
  late Stream<void> _listener;

  @override
  Future<NotificationSettings> build() async {
    final client = ref.watch(alwaysClientProvider);
    final settings = await client.notificationSettings();
    _listener = settings.changesStream(); // stay up to date
    _listener.forEach((e) async {
      state = AsyncValue.data(settings);
    });
    return settings;
  }
}

final notificationSettingsProvider = AsyncNotifierProvider.autoDispose<
    AsyncNotificationSettingNotifier, NotificationSettings>(
  () => AsyncNotificationSettingNotifier(),
);

final currentNotificationModeProvider = FutureProvider.autoDispose
    .family<String, NotificationConfiguration>((ref, config) async {
  final settings = await ref.watch(notificationSettingsProvider.future);
  return await settings.defaultNotificationMode(
    config.encrypted,
    config.oneToOne,
  );
});
