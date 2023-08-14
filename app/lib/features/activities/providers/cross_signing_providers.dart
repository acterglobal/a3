import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show DeviceRecord;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final allSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(clientProvider)!;
    final manager = client.verificationSessionManager();
    return (await manager.allSessions()).toList();
  },
);

final verifiedSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(clientProvider)!;
    final manager = client.verificationSessionManager();
    return (await manager.verifiedSessions()).toList();
  },
);

final unverifiedSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(clientProvider)!;
    final manager = client.verificationSessionManager();
    return (await manager.unverifiedSessions()).toList();
  },
);

final inactiveSessionsProvider = FutureProvider<List<DeviceRecord>>(
  (ref) async {
    final client = ref.watch(clientProvider)!;
    final manager = client.verificationSessionManager();
    return (await manager.inactiveSessions()).toList();
  },
);
