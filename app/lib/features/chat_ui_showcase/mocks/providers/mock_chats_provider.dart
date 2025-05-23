import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/mock_convo.dart';
import 'package:acter/features/chat_ui_showcase/mocks/room/mock_room.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/convo_showcase_data.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/general_usecases.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/membership_usecases.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/profile_change_usecases.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/text_and_media_usecases.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final List<MockChatItem Function(String userId)> _mockChatListGenerator = [
  emilyDmMutedBookmarkedRoom1,
  productTeamMutedWithSingleTypingUserRoom2,
  engineeringTeamWithTestUpdateRoom3,
  designReviewMutedBookmarkedWithUnreadRoom4,
  groupDmWithMichaelKumarpalsinhBenRoom5,
  sarahDmWithTypingRoom6,
  projectAlphaWithMultipleTypingRoom7,
  lisaDmBookmarkedImageMessageRoom8,
  teamUpdatesBookmarkedVideoMessageRoom9,
  groupDmWithEmmaKumarpalsinhBenRoom10,
  alexDmRoom11,
  marketingTeamRoom12,
  lisaDmRoom13,
  productFeedbackGroupRoom14,
  davidDmRoom15,
  imageMessageDmRoom16,
  videoMessageDmRoom17,
  audioMessageDmRoom18,
  fileMessageDmRoom19,
  locationMessageDmRoom20,
  redactionEventRoom21,
  membershipEventjoinedRoom22,
  membershipEventLeftRoom23,
  membershipEventInvitationAcceptedRoom24,
  membershipEventInvitationRejectedRoom25,
  membershipEventInvitationRevokedRoom26,
  membershipEventKnockAcceptedRoom27,
  membershipEventKnockRetractedRoom28,
  membershipEventKnockDeniedRoom29,
  membershipEventBannedRoom30,
  membershipEventUnbannedRoom31,
  membershipEventKickedRoom32,
  membershipEventInvitedRoom33,
  membershipEventKickedAndBannedRoom34,
  membershipEventKnockedRoom35,
  profileEventDisplayNameChangedRoom36,
  profileEventDisplayNameSetRoom37,
  profileEventDisplayNameUnsetRoom38,
  profileEventAvatarChangedRoom39,
  profileEventAvatarSetRoom40,
  profileEventAvatarUnsetRoom41,
  superLongUserTypingRoom15,
];

final mockChatsProvider = Provider<List<MockChatItem>>((ref) {
  final userId = ref.watch(myUserIdStrProvider);
  return _mockChatListGenerator.map((e) => e(userId)).toList();
});

final mockChatsIdsProvider = Provider<List<String>>((ref) {
  final mockChats = ref.watch(mockChatsProvider);
  return mockChats.map((e) => e.roomId).toList();
});

final _mockChatsByNameProvider = Provider<Map<String, MockChatItem>>((ref) {
  final mockChats = ref.watch(mockChatsProvider);
  return mockChats.fold<Map<String, MockChatItem>>({}, (acc, chat) {
    acc[chat.roomId] = chat;
    return acc;
  });
});

final mockChatProvider = Provider.family<MockChatItem?, String>((ref, roomId) {
  final mockChats = ref.watch(_mockChatsByNameProvider);
  return mockChats[roomId];
});

final mockConvoProvider = Provider.family<MockConvo?, String>(
  (ref, roomId) => ref.watch(mockChatProvider(roomId))?.mockConvo,
);

final mockRoomProvider = Provider.family<MockRoom?, String>(
  (ref, roomId) => ref.watch(mockChatProvider(roomId))?.mockRoom,
);

final mockLatestMessageProvider = Provider.family<TimelineItem?, String>(
  (ref, roomId) =>
      ref.watch(mockChatProvider(roomId))?.mockConvo.latestMessage(),
);

final mockTypingUserNamesProvider = Provider.family<List<String>?, String>((
  ref,
  roomId,
) {
  final mockChat = ref.watch(mockChatProvider(roomId));
  if (mockChat == null) {
    return null;
  }
  return mockChat.typingUserNames;
});
