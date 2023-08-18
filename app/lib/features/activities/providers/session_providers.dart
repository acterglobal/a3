import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show DeviceRecord;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(clientProvider)!;
    final manager = client.sessionManager();
    final sessions = (await manager.allSessions()).toList();
    debugPrint('$sessions');
    return sessions;
  },
);

final verifiedSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(clientProvider)!;
    final manager = client.sessionManager();
    final sessions = (await manager.verifiedSessions()).toList();
    return sessions.where((session) {
      if (session.deviceId() == client.deviceId()) {
        return false;
      }
      return true;
    }).toList();
  },
);

final unverifiedSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(clientProvider)!;
    final manager = client.sessionManager();
    final sessions = (await manager.unverifiedSessions()).toList();
    return sessions.where((session) {
      if (session.deviceId() == client.deviceId()) {
        return false;
      }
      return true;
    }).toList();
  },
);

final inactiveSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(clientProvider)!;
    final manager = client.sessionManager();
    return (await manager.inactiveSessions()).toList();
  },
);
