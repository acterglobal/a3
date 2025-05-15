import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_ffi_list_timeline_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_item_diff.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/mock_convo.dart';
import 'package:acter/features/chat_ui_showcase/mocks/room/mock_room.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_stream.dart';

class MockChatItem {
  final String roomId;
  final MockRoom mockRoom;
  final MockConvo mockConvo;
  final List<String>? typingUserNames;

  MockChatItem({
    required this.roomId,
    required this.mockRoom,
    required this.mockConvo,
    required this.typingUserNames,
  });
}

MockChatItem Function(String userId) createMockChatItem({
  required String roomId,
  required String displayName,
  String? notificationMode,
  List<String>? activeMembersIds,
  bool? isDm,
  bool? isBookmarked,
  int? unreadNotificationCount,
  int? unreadMentions,
  int? unreadMessages,
  List<String>? typingUserNames,
  List<MockTimelineEventItem>? timelineEventItems,
  List<MockTimelineEventItem> Function(String userId)?
  timelineEventItemsBuilder,
}) {
  return (String userId) {
    final members = activeMembersIds ?? [];
    final eventItems =
        timelineEventItems ?? timelineEventItemsBuilder?.call(userId) ?? [];
    members.add(userId);
    return MockChatItem(
      roomId: roomId,
      typingUserNames: typingUserNames,
      mockRoom: MockRoom(
        mockRoomId: roomId,
        mockDisplayName: displayName,
        mockNotificationMode: notificationMode ?? 'all',
        mockActiveMembersIds: members,
      ),
      mockConvo: MockConvo(
        mockConvoId: roomId,
        mockIsDm: isDm ?? false,
        mockIsBookmarked: isBookmarked ?? false,
        mockNumUnreadNotificationCount: unreadNotificationCount ?? 0,
        mockNumUnreadMentions: unreadMentions ?? 0,
        mockNumUnreadMessages: unreadMessages ?? 0,
        mockTimelineItem: MockTimelineItem(
          mockTimelineEventItem: eventItems.lastOrNull,
        ),
        mockTimelineStream: MockTimelineStream(
          mockTimelineItemDiffs: [
            MockTimelineItemDiff(
              mockAction: 'Append',
              mockTimelineItemList: MockFfiListTimelineItem(
                timelineItems:
                    eventItems
                        .map((e) => MockTimelineItem(mockTimelineEventItem: e))
                        .toList(),
              ),
              mockIndex: 0,
              mockTimelineItem: MockTimelineItem(
                mockTimelineEventItem: eventItems.lastOrNull,
              ),
            ),
          ],
        ),
      ),
    );
  };
}
