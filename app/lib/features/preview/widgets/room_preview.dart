import 'dart:async';

import 'package:acter/common/extensions/record_helpers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/features/preview/types.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RoomPreviewWidget extends ConsumerWidget {
  final String roomId;
  final bool autoForward;
  final OnForward onForward;
  final List<String> viaServers;

  const RoomPreviewWidget({
    super.key,
    required this.roomId,
    this.viaServers = const [],
    this.autoForward = true,
    required this.onForward,
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
        if (room != null && room.isJoined()) {
          await onForward(room);
        }
      });
    }

    final foundRoom = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    if (foundRoom != null && foundRoom.isJoined()) {
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

  Widget renderPreview(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) {
    return Column(
      children: [
        roomHeader(preview),
        roomInfo(context, preview),
        renderActions(context, ref, preview),
      ],
    );
  }

  Widget roomHeader(RoomPreview preview) => Consumer(
        builder: (context, ref, child) => ListTile(
          leading: ActerAvatar(
            options: AvatarOptions(ref.watch(roomPreviewAvatarInfo(query))),
          ),
          title: Text(
            preview.name() ?? preview.roomIdStr(),
          ),
          subtitle: Text(preview.canonicalAliasStr() ?? ''),
        ),
      );

  Widget roomInfo(BuildContext context, RoomPreview preview) {
    final description = preview.topic();
    if (description == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.of(context).about,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget renderActions(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) =>
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: renderPreviewActions(
            context,
            ref,
            preview,
          ),
        ),
      );

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

  List<Widget> renderPreviewActions(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) {
    if (preview.stateStr() == 'joined') {
      // we are already in, but for some reason this was shown
      // so hand over the action to go there
      return [
        ActerPrimaryActionButton(
          child: preview.isDirect() == true
              ? Text(L10n.of(context).goToDM)
              : Text(L10n.of(context).goToDM),
          onPressed: () {},
        ),
      ];
    }
    final joinRule = preview.joinRuleStr();
    final lang = L10n.of(context);
    final roomId = preview.roomIdStr();
    final roomName = preview.name() ?? roomId;

    return switch (joinRule.toLowerCase()) {
      'private' || 'invite' => [
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: Text(lang.youNeedBeInvitedToJoinThisRoom),
          ),
          OutlinedButton(
            onPressed: () =>
                EasyLoading.showToast(lang.youNeedBeInvitedToJoinThisRoom),
            child: Text(lang.private),
          ),
        ],
      'restricted' => [
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: Text(lang.youAreAbleToJoinThisRoom),
          ),
          ActerPrimaryActionButton(
            onPressed: () => joinRoom(
              context,
              ref,
              lang.tryingToJoin(roomName),
              roomId,
              viaServers,
            ),
            child: Text(lang.join),
          ),
        ],
      'public' => [
          Padding(
            padding: EdgeInsets.only(right: 5),
            child: Text(lang.public),
          ),
          OutlinedButton(
            onPressed: () => joinRoom(
              context,
              ref,
              lang.tryingToJoin(roomName),
              roomId,
              viaServers,
            ),
            child: Text(lang.join),
          ),
        ],
      _ => [
          Text(lang.joinRuleNotSupportedYet(joinRule)),
          Chip(
            label: Text(lang.unknown),
          ),
        ],
    };
  }
}
