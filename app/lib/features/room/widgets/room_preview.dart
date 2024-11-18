import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RoomPreviewWidget extends ConsumerWidget {
  final String roomId;
  final bool autoForward;
  final List<String> viaServers;

  const RoomPreviewWidget({
    super.key,
    required this.roomId,
    this.viaServers = const [],
    this.autoForward = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (roomIdOrAlias: roomId, serverNames: viaServers);
    if (autoForward) {
      ref.listen(roomOrPreviewProvider(query), (old, next) async {
        final room = next.valueOrNull?.room;
        if (room != null && context.mounted) {
          // room found we have been tasked to forward;
          if (room.isSpace()) {
            goToSpace(context, room.roomIdStr());
          } else {
            goToChat(context, room.roomIdStr());
          }
        }
      });
    }

    return ref.watch(roomOrPreviewProvider(query)).when(
          data: (res) {
            final room = res.room;
            final preview = res.preview;
            if (room != null) {
              return renderRoom(context, ref, room);
            } else if (preview != null) {
              return renderPreview(context, ref, preview);
            } else {
              return renderError(
                ref,
                query,
                "Room preview couldn't be loaded",
                null,
              );
            }
          },
          error: (error, stack) => renderError(ref, query, error, stack),
          loading: () => renderLoading(),
        );
  }

  Widget renderError(
    WidgetRef ref,
    RoomPreviewQuery query,
    Object error,
    StackTrace? stack,
  ) =>
      ActerInlineErrorButton(
        error: error,
        stack: stack,
        onRetryTap: () {
          ref.invalidate(roomOrPreviewProvider(query));
          ref.invalidate(roomPreviewProvider(query));
        },
      );

  Widget renderPreview(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) {
    final roomTitle = preview.name() ?? preview.roomIdStr();
    return Column(
      children: [
        const Bone.circle(size: 50),
        const SizedBox(height: 10),
        Text(roomTitle),
      ],
    );
  }

  Widget renderRoom(BuildContext context, WidgetRef ref, Room room) =>
      renderLoading();

  Widget renderLoading() => const Skeletonizer(
        child: Column(
          children: [
            Bone.circle(size: 50),
            SizedBox(height: 10),
            Text(' room name '),
          ],
        ),
      );
}
