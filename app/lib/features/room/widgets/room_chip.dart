import 'package:acter/common/extensions/record_helpers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/common/toolkit/widgets/acter_inline_chip.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/preview/actions/show_room_preview.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

const double defaultAvatarSize = 14.0;

class RoomChip extends ConsumerStatefulWidget {
  final String roomId;
  final Uri? uri;

  const RoomChip({super.key, required this.roomId, this.uri});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RoomChipState();
}

class _RoomChipState extends ConsumerState<RoomChip> {
  late RoomPreviewQuery query;

  @override
  void initState() {
    super.initState();
    query = updateQuery();
  }

  @override
  void didUpdateWidget(RoomChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri || widget.roomId != oldWidget.roomId) {
      setState(() {
        query = updateQuery();
      }); // refresh after
    }
  }

  RoomPreviewQuery updateQuery() {
    return (
      roomIdOrAlias: widget.roomId,
      serverNames: AllHashed(widget.uri?.queryParametersAll['via'] ?? []),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foundRoom = ref.watch(maybeRoomProvider(widget.roomId)).valueOrNull;
    if (foundRoom != null) {
      return buildForRoom(context);
    }

    return ref
        .watch(roomPreviewProvider(query))
        .when(
          data: (p) => buildPreview(context),
          error: (error, stack) => renderError(context, error, stack),
          loading: () => loading(context),
        );
  }

  Widget loading(BuildContext context) => ActerInlineChip(
    tooltip: widget.roomId,
    text: widget.roomId,
    leading: Bone.circle(
      size:
          Theme.of(context).textTheme.bodySmall?.fontSize ?? defaultAvatarSize,
    ),
  );
  Widget renderError(BuildContext context, Object error, StackTrace stack) =>
      ActerInlineChip(
        leading: Bone.circle(
          size:
              Theme.of(context).textTheme.bodySmall?.fontSize ??
              defaultAvatarSize,
        ),
        text: widget.roomId,
        tooltip: widget.roomId,
        onTap: () async {
          ActerErrorDialog.show(
            context: context,
            error: error,
            stack: stack,
            onRetryTap: () {
              ref.invalidate(maybeRoomProvider(widget.roomId));
              ref.invalidate(roomPreviewProvider(query));
              Navigator.pop(context);
            },
            includeBugReportButton: true,
          );
        },
      );
  Widget buildForRoom(BuildContext context) {
    final displayName =
        ref.watch(roomDisplayNameProvider(widget.roomId)).valueOrNull ??
        L10n.of(context).unknown;
    final avatarInfo = ref.watch(roomAvatarInfoProvider(widget.roomId));
    final avatarSize =
        Theme.of(context).textTheme.bodySmall?.fontSize ?? defaultAvatarSize;
    return ActerInlineChip(
      tooltip: displayName,
      onTap: () async {
        await navigateToRoomOrAskToJoin(context, ref, widget.roomId);
      },
      text: displayName,
      leading: ActerAvatar(
        options: AvatarOptions(avatarInfo, size: avatarSize),
      ),
    );
  }

  Widget buildPreview(BuildContext context) {
    final roomPreview = ref.watch(roomPreviewProvider(query));
    final displayName =
        roomPreview.valueOrNull?.name() ?? L10n.of(context).unknown;
    final avatarInfo = ref.watch(roomPreviewAvatarInfo(query));
    final avatarSize =
        Theme.of(context).textTheme.bodySmall?.fontSize ?? defaultAvatarSize;
    return ActerInlineChip(
      leading: ActerAvatar(
        options: AvatarOptions(avatarInfo, size: avatarSize),
      ),
      text: displayName,
      tooltip: displayName,
      onTap: () async {
        await showRoomPreview(
          context: context,
          roomIdOrAlias: query.roomIdOrAlias,
          serverNames: query.serverNames.items,
        );
      },
    );
  }
}
