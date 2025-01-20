import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::room::join');

Future<T> _ensureLoadedWithinTime<T>(
  Future<T?> Function() callback, {
  int delayMs = 300,
  int attempts = 20,
}) async {
  int remaining = attempts;
  while (remaining > 0) {
    remaining -= 1;
    final res = await callback();
    if (res != null) {
      return res;
    }
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  throw 'Loading timed out';
}

Future<String?> joinRoom(
  BuildContext context,
  WidgetRef ref,
  String displayMsg,
  String roomIdOrAlias,
  String? server,
  Function(String)? forward,
) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: displayMsg);
  final client = await ref.read(alwaysClientProvider.future);
  try {
    final newRoom = await client.joinRoom(roomIdOrAlias, server);
    final roomId = newRoom.roomIdStr();
    final isSpace = newRoom.isSpace();
    // ensure we re-evaluate the room data on our end. This is necessary
    // if we knew of the room prior (e.g. we had left it), but hadn’t joined
    // this should properly re-evaluate all possible readers
    ref.invalidate(maybeRoomProvider(roomId));
    if (isSpace) {
      ref.invalidate(spaceProvider(roomId));
      await _ensureLoadedWithinTime(
        () async => await ref.read(maybeSpaceProvider(roomId).future),
      );
    } else {
      ref.invalidate(chatProvider(roomId));
    }
    await _ensureLoadedWithinTime(
      () async => await ref.read(chatProvider(roomId).future),
    );
    EasyLoading.dismiss();
    if (forward != null) forward(roomId);
    return roomId;
  } catch (e, s) {
    _log.severe('Failed to join room', e, s);
    EasyLoading.showError(
      lang.joiningFailed(e),
      duration: const Duration(seconds: 3),
    );
    return null;
  }
}
