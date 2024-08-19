import 'dart:async';

import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/notifiers/chat_room_notifier.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_chat_types/src/message.dart';
import 'package:flutter_chat_types/src/messages/text_message.dart';
import 'package:flutter_chat_types/src/preview_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockChatRoomNotifier extends StateNotifier<ChatRoomState>
    with Mock
    implements ChatRoomNotifier {
  @override
  late TimelineStream timeline;

  @override
  final String roomId;

  MockChatRoomNotifier(this.roomId)
      : super(const ChatRoomState(
          hasMore: false,
          messages: [],
          loading: ChatRoomLoadingState.loaded(),
        ));

  @override
  Future<void> fetchMediaBinary(String? msgType, String eventId) {
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
  Future<void> handleDiff(RoomMessageDiff diff) {
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
  Message parseMessage(RoomMessage message) {
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
  final Map<String, AvatarInfo>? avatarInfos;
  MockRoomAvatarInfoNotifier({this.avatarInfos});

  @override
  AvatarInfo build(String arg) {
    return avatarInfos?[arg] ?? AvatarInfo(uniqueId: arg);
  }
}

class MockAsyncConvoNotifier extends FamilyAsyncNotifier<Convo?, String>
    with Mock
    implements AsyncConvoNotifier {
  @override
  FutureOr<Convo?> build(String arg) {
    return null;
  }
}

class MockAsyncLatestMsgNotifier
    extends FamilyAsyncNotifier<RoomMessage?, String>
    with Mock
    implements AsyncLatestMsgNotifier {
  @override
  FutureOr<RoomMessage?> build(String arg) {
    return null;
  }
}
