import 'package:acter/common/extensions/record_helpers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/preview/actions/show_room_preview.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:skeletonizer/skeletonizer.dart';

const double defaultAvatarSize = 14.0;

class RoomChip extends ConsumerStatefulWidget {
  final String roomId;
  final String? uri;

  const RoomChip({super.key, required this.roomId, this.uri});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RoomChipState();
}

class _RoomChipState extends ConsumerState<RoomChip> {
  late Uri? uri;

  @override
  void initState() {
    super.initState();
    uri = widget.uri.map((u) => Uri.tryParse(u));
  }

  RoomPreviewQuery get query => (
        roomIdOrAlias: widget.roomId,
        serverNames: AllHashed(uri?.queryParametersAll['via'] ?? []),
      );

  @override
  Widget build(BuildContext context) {
    final foundRoom = ref.watch(maybeRoomProvider(widget.roomId)).valueOrNull;
    if (foundRoom != null) {
      return Tooltip(
        message: widget.roomId,
        child: buildForRoom(context),
      );
    }

    return Tooltip(
      message: widget.roomId,
      child: ref.watch(roomPreviewProvider(query)).when(
            data: (p) => buildPreview(context),
            error: (error, stack) => renderError(context, error, stack),
            loading: () => loading(context),
          ),
    );
  }

  Widget loading(BuildContext context) => Skeletonizer(
        child: ActerInlineTextButton.icon(
          icon: Bone.circle(
            size: Theme.of(context).textTheme.bodyMedium?.fontSize ??
                defaultAvatarSize,
          ),
          label: Text(widget.roomId, overflow: TextOverflow.ellipsis),
          onPressed: () async {
            await showRoomPreview(
              context: context,
              roomIdOrAlias: query.roomIdOrAlias,
              serverNames: query.serverNames.items,
            );
          },
        ),
      );
  Widget renderError(
    BuildContext context,
    Object error,
    StackTrace stack,
  ) =>
      ActerInlineTextButton.icon(
        icon: Bone.circle(
          size: Theme.of(context).textTheme.bodyMedium?.fontSize ??
              defaultAvatarSize,
        ),
        label: Text(widget.roomId, overflow: TextOverflow.ellipsis),
        onPressed: () async {
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
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? defaultAvatarSize;
    return ActerInlineTextButton.icon(
      icon: ActerAvatar(
        options: AvatarOptions(
          avatarInfo,
          size: avatarSize,
        ),
      ),
      label: Text(displayName, overflow: TextOverflow.ellipsis),
      onPressed: () async {
        await navigateToRoomOrAskToJoin(context, ref, widget.roomId);
      },
    );
  }

  Widget buildPreview(BuildContext context) {
    final roomPreview = ref.watch(roomPreviewProvider(query));
    final displayName =
        roomPreview.valueOrNull?.name() ?? L10n.of(context).unknown;
    final avatarInfo = ref.watch(roomPreviewAvatarInfo(query));
    final avatarSize =
        Theme.of(context).textTheme.bodyMedium?.fontSize ?? defaultAvatarSize;
    return ActerInlineTextButton.icon(
      icon: ActerAvatar(
        options: AvatarOptions(
          avatarInfo,
          size: avatarSize,
        ),
      ),
      label: Text(displayName, overflow: TextOverflow.ellipsis),
      onPressed: () async {
        await showRoomPreview(
          context: context,
          roomIdOrAlias: query.roomIdOrAlias,
          serverNames: query.serverNames.items,
        );
      },
    );
  }
}
