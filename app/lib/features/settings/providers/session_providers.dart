import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show DeviceRecord;
import 'package:riverpod/riverpod.dart';

final allSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(alwaysClientProvider);
    final manager = client.sessionManager();
    return (await manager.allSessions()).toList();
  },
);

final unknownSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final sessions = await ref.watch(allSessionsProvider.future);
    return sessions
        .where((session) => !session.isMe()) // exclude me
        .toList();
  },
);
