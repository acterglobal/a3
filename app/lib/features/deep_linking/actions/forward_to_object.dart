import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/deep_linking/actions/show_item_preview.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::deep_linking::actions::forward_to_object');

Future<void> forwardToObject(
  BuildContext context,
  WidgetRef ref,
  UriParseResult result,
) async {
  final target = result.objectPath;
  final lang = L10n.of(context);
  if (target == null) {
    return EasyLoading.showError(
      lang.deepLinkNotSupported('missing object'),
      duration: const Duration(seconds: 3),
    );
  }
  final objectId = target.objectId;

  final roomId = result.roomId;
  if (roomId == null) {
    _log.warning('link is missing room id');
  } else {
    final room = ref.read(maybeRoomProvider(roomId));
    if (room == null || !room.isJoined()) {
      // we don't have access to that room at yet/at the moment, show the preview
      if (!context.mounted) {
        return;
      }
      return showItemPreview(
        context: context,
        roomId: roomId,
        uriResult: result,
        ref: ref,
      );
    }
  }
  if (!context.mounted) {
    return;
  }
  final _ = switch (target.objectType) {
    ObjectType.pin =>
      context.pushNamed(Routes.pin.name, pathParameters: {'pinId': objectId}),
    ObjectType.taskList => context.pushNamed(
        Routes.taskListDetails.name,
        pathParameters: {'taskListId': objectId},
      ),
    ObjectType.calendarEvent => context.pushNamed(
        Routes.calendarEvent.name,
        pathParameters: {'calendarId': objectId},
      ),
    ObjectType.boost => context.pushNamed(
        Routes.update.name,
        pathParameters: {'updateId': objectId},
      ),
    _ => EasyLoading.showError(
        lang.deepLinkNotSupported(target.objectType),
        duration: const Duration(seconds: 3),
      ),
  };
}
