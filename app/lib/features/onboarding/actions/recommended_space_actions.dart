import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> joinRecommendedSpace(
  BuildContext context,
  PublicSearchResultItem space,
  VoidCallback callNextPage,
  WidgetRef ref,
) async {
  final lang = L10n.of(context);
  final roomId = space.roomIdStr();
  final spaceName = space.name() ?? '';

  try {
    await joinRoom(
      lang: lang,
      ref: ref,
      roomIdOrAlias: roomId,
      roomName: spaceName,
      serverNames: ['acter.global'],
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.successfullyJoined(spaceName))),
      );
    }
    callNextPage.call();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(lang.joinError)));
    }
  }
}
