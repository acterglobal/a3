import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/events/room_membership_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/room_message_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/profile_changes_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/general_message_event_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/text_message_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat-item::last-message-widget');

class LastMessageWidget extends ConsumerWidget {
  final String roomId;

  const LastMessageWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMessageProvider = ref.watch(latestMessageProvider(roomId));
    return lastMessageProvider.when(
      data: (timelineItem) => _renderLastMessage(context, timelineItem),
      error: (e, s) {
        _log.severe('Failed to load last message', e, s);
        return const SizedBox.shrink();
      },
      loading: () => Skeletonizer(child: Text('Loading...')),
    );
  }

  Widget _renderLastMessage(BuildContext context, TimelineItem? timelineItem) {
    final lang = L10n.of(context);
    final eventItem = timelineItem?.eventItem();
    if (eventItem == null) return const SizedBox.shrink();
    return switch (eventItem.eventType()) {
      'm.room.message' => RoomMessageEventWidget(
        roomId: roomId,
        eventItem: eventItem,
      ),
      'MembershipChange' => RoomMembershipEventWidget(
        roomId: roomId,
        eventItem: eventItem,
      ),
      'ProfileChange' => ProfileChangesEventWidget(
        roomId: roomId,
        eventItem: eventItem,
      ),
      'm.room.encrypted' => TextMessageWidget(
        roomId: roomId,
        message: lang.failedToDecryptMessage,
      ),
      'm.room.redaction' => TextMessageWidget(
        roomId: roomId,
        message: lang.thisMessageHasBeenDeleted,
      ),
      _ => GeneralMessageEventWidget(roomId: roomId, eventItem: eventItem),
    };
  }
}
