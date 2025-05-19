import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quds_popup_menu/quds_popup_menu.dart';

class ReadReceiptsWidget extends ConsumerWidget {
  final TimelineEventItem item;
  final String roomId;
  final String messageId;
  final int showAvatarsLimit;

  const ReadReceiptsWidget({
    super.key,
    required this.item,
    required this.roomId,
    required this.messageId,
    this.showAvatarsLimit = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final receipts = ref.watch(messageReadReceiptsProvider(item));
    final userIds = receipts.keys.toList();
    final timestamps = receipts.values.toList();

    return QudsPopupButton(
      items: _showDetails(userIds, timestamps, use24HourFormat),
      child: Wrap(
        spacing: -8,
        children: [
          ...List.generate(
            userIds.length <= showAvatarsLimit
                ? userIds.length
                : showAvatarsLimit,
            (i) => _buildUserReadAvatars(context, ref, userIds[i]),
          ),
          if (userIds.length > showAvatarsLimit)
            CircleAvatar(
              radius: 8,
              child: Text(
                '+${userIds.length - showAvatarsLimit}',
                textScaler: const TextScaler.linear(0.6),
                style: theme.textTheme.labelSmall,
              ),
            ),
        ],
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
    List<String> userIds,
    List<int> timestamps,
    bool show24HourFormat,
  ) {
    return [
      QudsPopupMenuWidget(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          return Container(
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
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: userIds.length,
                  itemBuilder: (context, index) {
                    final userId = userIds[index];
                    final timestamp = timestamps[index];
                    return Consumer(
                      builder: (context, ref, child) {
                        final member = ref.watch(
                          memberAvatarInfoProvider((
                            userId: userId,
                            roomId: roomId,
                          )),
                        );
                        return ListTile(
                          minLeadingWidth: 0,
                          minTileHeight: 10,
                          dense: true,
                          leading: ActerAvatar(
                            options: AvatarOptions.DM(member, size: 8),
                          ),
                          title: Text(
                            member.displayName ?? userId,
                            style: textTheme.labelSmall,
                          ),
                          trailing: Text(
                            jiffyDateForReadReceipt(
                              context,
                              timestamp,
                              use24HourFormat: show24HourFormat,
                              showDay: true,
                            ),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    ];
  }
}
