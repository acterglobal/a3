import 'package:acter/common/extensions/record_helpers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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

  RoomPreviewQuery get query => (
        roomIdOrAlias: roomId,
        serverNames: AllHashed(viaServers),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (autoForward) {
      ref.listen(maybeRoomProvider(roomId), (old, next) async {
        final room = next.valueOrNull;
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

    final foundRoom = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    if (foundRoom != null) {
      return renderRoom(context, ref, foundRoom);
    }

    return ref.watch(roomPreviewProvider(query)).when(
          data: (preview) => renderPreview(context, ref, preview),
          error: (error, stack) => renderError(context, ref, error, stack),
          loading: () => renderLoading(),
        );
  }

  Widget renderError(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace? stack,
  ) =>
      ActerInlineErrorButton(
        error: error,
        stack: stack,
        textBuilder: (error, errCode) => switch (errCode) {
          ErrorCode.forbidden =>
            L10n.of(context).accessDeniedToRoom(query.roomIdOrAlias),
          _ => L10n.of(context).loadingFailed(error)
        },
        onRetryTap: () {
          ref.invalidate(maybeRoomProvider(roomId));
          ref.invalidate(roomPreviewProvider(query));
        },
      );

  Widget renderPreviewActions(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) {
    return switch (preview.stateStr()) {
      'joined' => renderGotToAction(context, ref, preview),
      _ => renderUnknownAction(context, ref, preview),
    };
  }

  Widget renderGotToAction(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) =>
      ActerPrimaryActionButton(
        child: preview.isDirect() == true
            ? Text(L10n.of(context).goToDM)
            : Text(L10n.of(context).goToDM),
        onPressed: () {},
      );
  Widget renderUnknownAction(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) {
    final joinRule = preview.joinRuleStr();
    final lang = L10n.of(context);
    final roomName = preview.name() ?? preview.roomIdStr();

    return switch (joinRule) {
      'private' || 'invite' => Tooltip(
          message: lang.youNeedBeInvitedToJoinThisRoom,
          child: Chip(
            label: Text(lang.private),
          ),
        ),
      'restricted' => Tooltip(
          message: lang.youAreAbleToJoinThisRoom,
          child: OutlinedButton(
            onPressed: () async {
              await joinRoom(
                context,
                ref,
                lang.tryingToJoin(roomName),
                roomId,
                viaServers,
                null,
              );
            },
            child: Text(lang.join),
          ),
        ),
      'public' => Tooltip(
          message: lang.youAreAbleToJoinThisRoom,
          child: OutlinedButton(
            onPressed: () async {
              await joinRoom(
                context,
                ref,
                lang.tryingToJoin(roomName),
                roomId,
                viaServers,
                null,
              );
            },
            child: Text(lang.join),
          ),
        ),
      _ => Tooltip(
          message: lang.unclearJoinRule(joinRule),
          child: Chip(
            label: Text(lang.unknown),
          ),
        ),
    };
  }

  Widget renderPreview(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) {
    final roomTitle = preview.name();
    final description = preview.topic();
    final roomId = preview.roomIdStr();
    final avatarInfo = ref.watch(roomPreviewAvatarInfo(query));
    return Column(
      children: [
        ActerAvatar(
          options: AvatarOptions(
            avatarInfo,
            size: 50,
          ),
        ),
        const SizedBox(height: 10),
        if (roomTitle != null) Text(roomTitle),
        Text(roomId),
        if (description != null) Text(description),
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
