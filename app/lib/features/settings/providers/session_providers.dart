import 'package:acter/features/settings/providers/notifiers/devices_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show DeviceRecord;
import 'package:riverpod/riverpod.dart';

final allSessionsProvider =
    AsyncNotifierProvider<AsyncDevicesNotifier, List<DeviceRecord>>(
      () => AsyncDevicesNotifier(),
    );

final unknownSessionsProvider = FutureProvider<List<DeviceRecord>>((ref) async {
  final sessions = await ref.watch(allSessionsProvider.future);
  return sessions
      .where((session) => !session.isMe()) // exclude me
      .toList();
});
