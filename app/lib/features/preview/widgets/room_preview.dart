import 'package:acter/common/extensions/record_helpers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/common/widgets/info_widget.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/preview/types.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:acter/l10n/generated/l10n.dart';

class RoomPreviewWidget extends ConsumerWidget {
  final String roomId;
  final bool autoForward;
  final OnForward onForward;
  final Widget? headerInfo;
  final List<String> viaServers;
  final String? fallbackRoomDisplayName;
  final String? senderId;

  const RoomPreviewWidget({
    super.key,
    required this.roomId,
    required this.onForward,
    this.viaServers = const [],
    this.autoForward = true,
    this.headerInfo,
    this.fallbackRoomDisplayName,
    this.senderId,
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
          await onForward(context, ref, room);
        }
      });
    }

    final foundRoom = ref.watch(maybeRoomProvider(roomId)).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (headerInfo != null) headerInfo!,
        if (foundRoom != null && foundRoom.isJoined())
          RoomCard(roomId: roomId)
        else
          ref
              .watch(roomPreviewProvider(query))
              .when(
                data:
                    (preview) => Column(
                      children: [
                        roomHeader(preview),
                        roomInfo(context, preview),
                        renderActions(context, ref, preview),
                      ],
                    ),
                error:
                    (error, stack) => renderError(context, ref, error, stack),
                loading: () => renderLoading(),
              ),
      ],
    );
  }

  Widget renderError(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace? stack,
  ) {
    final code = ErrorCode.guessFromError(error);
    return Column(
      children: [
        ListTile(
          leading: ActerAvatar(
            options: AvatarOptions(AvatarInfo(uniqueId: roomId)),
          ),
          title: Text(fallbackRoomDisplayName ?? roomId),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: switch (code) {
            // forbidden is a specific code we want to handle differently
            // by showing an information box and hand out the sender Id to
            // to contact the author
            ErrorCode.forbidden => InfoWidget(
              title: L10n.of(context).forbidden,
              leading: const Icon(Icons.warning),
              subTitle: L10n.of(context).forbiddenRoomExplainer,
            ),
            _ => ActerInlineErrorButton(
              error: error,
              stack: stack,
              textBuilder:
                  (error, errCode) => L10n.of(context).loadingFailed(error),
              onRetryTap: () {
                ref.invalidate(maybeRoomProvider(roomId));
                ref.invalidate(roomPreviewProvider(query));
              },
            ),
          },
        ),
      ],
    );
  }

  Widget roomHeader(RoomPreview preview) => Consumer(
    builder:
        (context, ref, child) => ListTile(
          leading: ActerAvatar(
            options: AvatarOptions(ref.watch(roomPreviewAvatarInfo(query))),
          ),
          title: Text(preview.name() ?? preview.roomIdStr()),
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
          Text(description, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget renderActions(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: renderPreviewActions(context, ref, preview),
    ),
  );

  Widget renderLoading() => const Skeletonizer(
    child: ListTile(
      leading: Bone.circle(size: 50),
      title: Text('preview.name()'),
      subtitle: Text('preview.canonicalAliasStr()'),
    ),
  );

  List<Widget> renderPreviewActions(
    BuildContext context,
    WidgetRef ref,
    RoomPreview preview,
  ) {
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
          onPressed:
              () => EasyLoading.showToast(lang.youNeedBeInvitedToJoinThisRoom),
          child: Text(lang.private),
        ),
      ],
      'restricted' => [
        Padding(
          padding: EdgeInsets.only(right: 5),
          child: Text(lang.youAreAbleToJoinThisRoom),
        ),
        ActerPrimaryActionButton(
          onPressed:
              () => joinRoom(
                context: context,
                ref: ref,
                roomIdOrAlias: roomId,
                serverNames: viaServers,
                roomName: roomName,
              ),
          child: Text(lang.join),
        ),
      ],
      'public' => [
        Padding(padding: EdgeInsets.only(right: 5), child: Text(lang.public)),
        OutlinedButton(
          onPressed:
              () => joinRoom(
                context: context,
                ref: ref,
                roomIdOrAlias: roomId,
                serverNames: viaServers,
                roomName: roomName,
              ),
          child: Text(lang.join),
        ),
      ],
      _ => [
        Text(lang.joinRuleNotSupportedYet(joinRule)),
        Chip(label: Text(lang.unknown)),
      ],
    };
  }
}
