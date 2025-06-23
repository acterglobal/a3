import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/sending_state_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quds_popup_menu/quds_popup_menu.dart';

class ReadReceiptsWidget extends ConsumerWidget {
  static const readReceiptsPopupMenuKey = Key('read_receipts_popup_menu');
  final TimelineEventItem item;
  final String roomId;
  final bool isLastMessage;
  final int showAvatarsLimit;

  const ReadReceiptsWidget._({
    super.key,
    required this.item,
    required this.roomId,
    this.showAvatarsLimit = 5,
    this.isLastMessage = false,
  });

  factory ReadReceiptsWidget.group({
    Key? key,
    required TimelineEventItem item,
    required String roomId,

    int showAvatarsLimit = 5,
  }) {
    return ReadReceiptsWidget._(
      key: key,
      item: item,
      roomId: roomId,

      showAvatarsLimit: showAvatarsLimit,
    );
  }

  factory ReadReceiptsWidget.dm({
    Key? key,
    required TimelineEventItem item,
    required String roomId,
    required bool isLastMessage,
  }) {
    return ReadReceiptsWidget._(
      key: key,
      item: item,
      roomId: roomId,
      isLastMessage: isLastMessage,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDM = ref.watch(isDirectChatProvider(roomId)).valueOrNull ?? false;

    return isDM
        ? _DmReadReceipts(item: item, roomId: roomId)
        : _GroupReadReceipts(
          item: item,
          roomId: roomId,
          showAvatarsLimit: showAvatarsLimit,
        );
  }
}

class _DmReadReceipts extends ConsumerWidget {
  const _DmReadReceipts({required this.item, required this.roomId});
  final TimelineEventItem item;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.eventId() == null) return const SizedBox.shrink();
    final sendState = item.sendState();
    if (sendState != null) {
      // we are in process of sending, the widget will take care
      return SendingStateWidget(state: sendState);
    } else {
      // tracking the latest message whether its read or not
      final msgId =
          ref.watch(renderableBubbleChatMessagesProvider(roomId)).first;
      final msg = ref.watch(
        chatRoomMessageProvider((roomId: roomId, uniqueId: msgId)),
      );
      final msgEventItem = msg?.eventItem();
      final isLatestMsgBySender =
          (msg?.uniqueId() == item.eventId()) &&
          (msgEventItem?.sender() == item.sender());

      if (isLatestMsgBySender && msgEventItem != null) {
        // if the latest message by own user is read, show the read state
        if (ref.watch(messageReadReceiptsProvider(msgEventItem)).isNotEmpty) {
          return SendingStateWidget.read();
        } else {
          // return the sent state instead
          return SendingStateWidget.sent();
        }
      } else {
        // for other previous messages by self, don't need to show tracker
        return const SizedBox.shrink();
      }
    }
  }
}

class _GroupReadReceipts extends ConsumerWidget {
  const _GroupReadReceipts({
    required this.item,
    required this.roomId,
    required this.showAvatarsLimit,
  });

  final TimelineEventItem item;
  final String roomId;
  final int showAvatarsLimit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final receipts = ref.watch(messageReadReceiptsProvider(item));
    final userIds = receipts.keys.toList();
    final timestamps = receipts.values.toList();

    return Theme(
      data: theme.copyWith(splashFactory: NoSplash.splashFactory),
      child: QudsPopupButton(
        items: _showDetails(context, userIds, timestamps),
        child: Wrap(
          spacing: -8,
          children: [
            ...List.generate(
              userIds.length <= showAvatarsLimit
                  ? userIds.length
                  : showAvatarsLimit,
              (i) => _buildUserReadAvatars(context, ref, userIds[i]),
            ),
            // overflow indicator
            if (userIds.length > showAvatarsLimit)
              CircleAvatar(
                radius: 8.5,
                child: Text(
                  '+${userIds.length - showAvatarsLimit}',
                  textScaler: const TextScaler.linear(0.6),
                  style: theme.textTheme.labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserReadAvatars(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );

    final options = AvatarOptions.DM(avatarInfo, size: 8);

    return ActerAvatar(options: options);
  }

  List<QudsPopupMenuBase> _showDetails(
    BuildContext context,
    List<String> userIds,
    List<int> timestamps,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return [
      QudsPopupMenuWidget(
        builder: (context) {
          return Container(
            key: ReadReceiptsWidget.readReceiptsPopupMenuKey,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    L10n.of(context).seenBy,
                    style: textTheme.labelLarge,
                  ),
                ),
                _ReadReceiptsList(
                  userIds: userIds,
                  timestamps: timestamps,
                  roomId: roomId,
                ),
              ],
            ),
          );
        },
      ),
    ];
  }
}

class _ReadReceiptsList extends ConsumerWidget {
  const _ReadReceiptsList({
    required this.userIds,
    required this.timestamps,
    required this.roomId,
  });
  final List<String> userIds;
  final List<int> timestamps;
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView.builder(
      shrinkWrap: true,
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final userId = userIds[index];
        final timestamp = timestamps[index];
        final member = ref.watch(
          memberAvatarInfoProvider((userId: userId, roomId: roomId)),
        );

        return ListTile(
          minTileHeight: 10,
          horizontalTitleGap: 4,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: ActerAvatar(options: AvatarOptions.DM(member, size: 8)),
          title: Text(
            member.displayName ?? userId,
            style: textTheme.labelSmall,
          ),
          trailing: Text(
            jiffyDateTimestamp(context, timestamp, showDay: true),
            style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
