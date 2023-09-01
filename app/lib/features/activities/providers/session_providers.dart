import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show DeviceRecord;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(clientProvider);
    if (client == null) {
      throw 'Client is not logged in';
    }
    final manager = client.sessionManager();
    final sessions = (await manager.allSessions()).toList();
    return sessions
        .where((sess) => sess.deviceId() != client.deviceId()) // exclude me
        .toList();
  },
);
