import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/room/actions/show_room_preview.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';

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

  @override
  Widget build(BuildContext context) {
    final roomName = ref.watch(roomDisplayNameProvider(widget.roomId));
    if (roomName.error != null) {
      // not locally found, render preview version
      return buildPreview(context, ref);
    }
    final displayName =
        ref.watch(roomDisplayNameProvider(widget.roomId)).valueOrNull ??
            L10n.of(context).unknown;
    final avatarSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
    return Tooltip(
      message: widget.roomId,
      child: ActerInlineTextButton.icon(
        icon: ActerAvatar(
          options: AvatarOptions(
            ref.watch(roomAvatarInfoProvider(widget.roomId)),
            size: avatarSize,
          ),
        ),
        label: Text(displayName, overflow: TextOverflow.ellipsis),
        onPressed: () async {
          await navigateToRoomOrAskToJoin(context, ref, widget.roomId);
        },
      ),
    );
  }

  Widget buildPreview(BuildContext context, WidgetRef ref) {
    final query = (
      roomIdOrAlias: widget.roomId,
      serverNames: uri?.queryParametersAll['via'] ?? [],
    );
    final roomPreview = ref.watch(roomPreviewProvider(query));
    final errored = roomPreview.asError;
    if (errored != null) {
      return ActerInlineErrorButton(error: errored);
    }
    final displayName = roomPreview.valueOrNull?.name() ?? widget.roomId;
    final avatarSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14.0;
    return Tooltip(
      message: widget.roomId,
      child: ActerInlineTextButton.icon(
        icon: ActerAvatar(
          options: AvatarOptions(
            ref.watch(roomAvatarInfoProvider(widget.roomId)),
            size: avatarSize,
          ),
        ),
        label: Text(displayName, overflow: TextOverflow.ellipsis),
        onPressed: () async {
          await showRoomPreview(
            context: context,
            ref: ref,
            roomIdOrAlias: query.roomIdOrAlias,
            serverNames: query.serverNames,
          );
        },
      ),
    );
  }
}
