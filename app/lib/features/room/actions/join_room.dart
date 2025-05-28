import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::room::join');

Future<T> _ensureLoadedWithinTime<T>(
  Future<T?> Function() callback, {
  int delayMs = 300,
  int attempts = 20,
  bool throwError = false,
}) async {
  int remaining = attempts;
  while (remaining > 0) {
    remaining -= 1;
    try {
      final res = await callback();
      if (res != null) {
        return res;
      }
    } catch (e) {
      if (throwError) rethrow;
    }
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  throw 'Loading timed out';
}

Future<String?> joinRoom({
  required L10n lang,
  required WidgetRef ref,
  required String roomIdOrAlias,
  required List<String>? serverNames,
  String? displayMsg,
  String? roomName,

  /// configure to throw on error rather than return null
  bool throwOnError = false,
}) async {
  EasyLoading.show(
    status: displayMsg ?? lang.tryingToJoin(roomName ?? roomIdOrAlias),
  );
  try {
    final client = await ref.read(alwaysClientProvider.future);
    final sdk = await ref.read(sdkProvider.future);
    VecStringBuilder servers = sdk.api.newVecStringBuilder();
    if (serverNames != null) {
      for (final server in serverNames) {
        servers.add(server);
      }
    }
    final newRoom = await client.joinRoom(roomIdOrAlias, servers);
    final roomId = newRoom.roomIdStr();
    // ref.read(hasRecommendedSpaceJoinedProvider.notifier).state = true;
    final isSpace = await _ensureLoadedWithinTime(() async {
      final room = await ref.refresh(maybeRoomProvider(roomId).future);
      return room?.isJoined() == true ? room!.isSpace() : null;
    });

    if (isSpace) {
      ref.invalidate(maybeSpaceProvider(roomId));
    } else {
      ref.invalidate(chatProvider(roomId));
    }
    EasyLoading.dismiss();
    return roomId;
  } catch (e, s) {
    if (throwOnError) {
      EasyLoading.dismiss();
      rethrow;
    }
    _log.severe('Failed to join room', e, s);
    EasyLoading.showError(
      lang.joiningFailed(e),
      duration: const Duration(seconds: 3),
    );
    return null;
  }
}
