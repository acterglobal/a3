import 'package:acter/features/chat_ui_showcase/mocks/convo/mock_profile_content.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/convo_showcase_data.dart';

final profileEventDisplayNameChangedRoom36 = createMockChatItem(
  roomId: 'mock-room-36',
  displayName: 'Profile Changes',
  activeMembersIds: ['@david:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800580000,
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@david:acter.global',
        mockDisplayNameChange: 'Changed',
        mockDisplayNameOldVal: 'David Miller',
        mockDisplayNameNewVal: 'David M.',
      ),
    ),
  ],
);

final profileEventDisplayNameSetRoom37 = createMockChatItem(
  roomId: 'mock-room-37',
  displayName: 'Profile Updates',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800581000,
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@david:acter.global',
        mockDisplayNameChange: 'Set',
        mockDisplayNameNewVal: 'David Miller',
      ),
    ),
  ],
);

final profileEventDisplayNameUnsetRoom38 = createMockChatItem(
  roomId: 'mock-room-38',
  displayName: 'Profile Management',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800582000,
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@david:acter.global',
        mockDisplayNameChange: 'Unset',
      ),
    ),
  ],
);

final profileEventAvatarChangedRoom39 = createMockChatItem(
  roomId: 'mock-room-39',
  displayName: 'Avatar Updates',
  activeMembersIds: ['@david:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800583000,
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@david:acter.global',
        mockAvatarUrlChange: 'Changed',
      ),
    ),
  ],
);

final profileEventAvatarSetRoom40 = createMockChatItem(
  roomId: 'mock-room-40',
  displayName: 'Avatar Management',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800584000,
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@david:acter.global',
        mockAvatarUrlChange: 'Set',
      ),
    ),
  ],
);

final profileEventAvatarUnsetRoom41 = createMockChatItem(
  roomId: 'mock-room-41',
  displayName: 'Profile Cleanup',
  activeMembersIds: ['@emily:acter.global', '@david:acter.global'],
  timelineEventItems: [
    MockTimelineEventItem(
      mockSenderId: '@david:acter.global',
      mockOriginServerTs: 1742800585000,
      mockEventType: 'ProfileChange',
      mockProfileContent: MockProfileContent(
        mockUserId: '@david:acter.global',
        mockAvatarUrlChange: 'Unset',
      ),
    ),
  ],
);
