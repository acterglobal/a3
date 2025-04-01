import 'dart:async';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/common/providers/notifiers/client_pref_notifier.dart';
import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/notifiers/chat_room_notifier.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_chat_types/src/message.dart';
import 'package:flutter_chat_types/src/messages/text_message.dart';
import 'package:flutter_chat_types/src/preview_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

typedef MockedRoomData = Map<String, AvatarInfo>;

class MockChatRoomNotifier extends StateNotifier<ChatRoomState>
    with Mock
    implements ChatRoomNotifier {
  @override
  late TimelineStream timeline;

  @override
  final String roomId;

  MockChatRoomNotifier(this.roomId)
    : super(
        const ChatRoomState(
          hasMore: false,
          messages: [],
          loading: ChatRoomLoadingState.loaded(),
        ),
      );

  @override
  Future<void> fetchMediaBinary(String? msgType, String eventId, String msgId) {
    // TODO: implement fetchMediaBinary
    throw UnimplementedError();
  }

  @override
  Future<void> fetchOriginalContent(String originalId, String replyId) {
    // TODO: implement fetchOriginalContent
    throw UnimplementedError();
  }

  @override
  String? getRepliedTo(Message message) {
    // TODO: implement getRepliedTo
    throw UnimplementedError();
  }

  @override
  Future<void> handleDiff(TimelineItemDiff diff) {
    // TODO: implement handleDiff
    throw UnimplementedError();
  }

  @override
  Future<void> handleEndReached() {
    // TODO: implement handleEndReached
    throw UnimplementedError();
  }

  @override
  void handlePreviewDataFetched(TextMessage message, PreviewData previewData) {
    // TODO: implement handlePreviewDataFetched
  }

  @override
  void insertMessage(int to, Message m) {
    // TODO: implement insertMessage
  }

  @override
  Future<void> loadMore({bool failOnError = false}) {
    // TODO: implement loadMore
    throw UnimplementedError();
  }

  @override
  List<Message> messagesCopy() {
    // TODO: implement messagesCopy
    throw UnimplementedError();
  }

  @override
  Message parseMessage(TimelineItem message) {
    // TODO: implement parseMessage
    throw UnimplementedError();
  }

  @override
  // TODO: implement ref
  Ref<Object?> get ref => throw UnimplementedError();

  @override
  void removeMessage(int idx) {
    // TODO: implement removeMessage
  }

  @override
  void replaceMessageAt(int index, Message m) {
    // TODO: implement replaceMessageAt
  }

  @override
  void resetMessages() {
    // TODO: implement resetMessages
  }

  @override
  void setMessages(List<Message> messages) {
    // TODO: implement setMessages
  }
}

class MockRoomAvatarInfoNotifier extends FamilyNotifier<AvatarInfo, String>
    with Mock
    implements RoomAvatarInfoNotifier {
  final MockedRoomData? avatarInfos;
  MockRoomAvatarInfoNotifier({this.avatarInfos});

  @override
  AvatarInfo build(String arg) {
    return avatarInfos?[arg] ?? AvatarInfo(uniqueId: arg);
  }
}

class MockAsyncConvoNotifier extends FamilyAsyncNotifier<Convo?, String>
    with Mock
    implements AsyncConvoNotifier {
  final Convo? retVal;

  MockAsyncConvoNotifier({this.retVal});

  @override
  FutureOr<Convo?> build(String arg) {
    return retVal;
  }
}

class MockAsyncLatestMsgNotifier
    extends FamilyAsyncNotifier<TimelineItem?, String>
    with Mock
    implements AsyncLatestMsgNotifier {
  @override
  FutureOr<TimelineItem?> build(String arg) {
    return null;
  }
}

class MockRoomListFilterNotifier extends StateNotifier<RoomListFilterState>
    with Mock
    implements RoomListFilterNotifier {
  MockRoomListFilterNotifier()
    : super(
        const RoomListFilterState(
          searchTerm: null,
          selection: FilterSelection.all,
        ),
      );
}

class MockPersistentPrefNotifier extends Notifier<FilterSelection>
    with Mock
    implements MapPrefNotifier<FilterSelection> {
  MockPersistentPrefNotifier() : super();

  @override
  FilterSelection build() {
    return FilterSelection.all;
  }

  /// Updates the value asynchronously.
  @override
  Future<void> set(FilterSelection value) async {
    state = value;
  }
}

List<Override> mockChatRoomProviders(MockedRoomData roomsData) {
  return [
    persistentRoomListFilterSelector.overrideWith(
      () => MockPersistentPrefNotifier(),
    ),
    chatIdsProvider.overrideWithValue(roomsData.keys.toList()),
    chatTypingEventProvider.overrideWith((ref, roomId) => const Stream.empty()),
    roomIsMutedProvider.overrideWith((ref, roomId) => false),
    latestMessageProvider.overrideWith(() => MockAsyncLatestMsgNotifier()),
    chatProvider.overrideWith(() => MockAsyncConvoNotifier()),
    roomDisplayNameProvider.overrideWith(
      (ref, roomId) => roomsData[roomId]?.displayName,
    ),
    chatStateProvider.overrideWith(
      (ref, roomId) => MockChatRoomNotifier(roomId),
    ),
    roomAvatarInfoProvider.overrideWith(
      () => MockRoomAvatarInfoNotifier(avatarInfos: roomsData),
    ),
  ];
}
