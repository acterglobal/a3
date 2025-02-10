import 'dart:async';

import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

import 'package:mocktail/mocktail.dart';

/// Mocked version of ActerSdk
class MockActerSdk extends Mock implements ActerSdk {}

/// Mocked version of Acter Client
class MockClient extends Mock implements Client {
  @override
  Stream<bool> subscribeRoomStream(String topic) {
    return Stream.value(true); // Return a dummy stream
  }

  @override
  Stream<bool> subscribeModelStream(String topic) {
    return Stream.value(true); // Return a dummy stream
  }

  @override
  Future<Convo> convoWithRetry(String roomId, [int attempt = 0]) async {
    return MockConvo(roomId);
  }
}

/// Mocked version of OptionComposeDraft
class MockOptionComposeDraft extends Mock implements OptionComposeDraft {
  final MockComposeDraft? _draft;

  MockOptionComposeDraft(this._draft);

  @override
  ComposeDraft? draft() => _draft;
}

/// Mocked version of Convo
class MockConvo extends Mock implements Convo {
  static final Map<String, MockComposeDraft> _drafts = {};
  final String roomId;
  MockConvo(this.roomId);

  @override
  Future<OptionComposeDraft> msgDraft() async {
    return MockOptionComposeDraft(_drafts[roomId]);
  }

  @override
  String getRoomIdStr() => roomId;

  @override
  Future<bool> saveMsgDraft(
    String plainText,
    String? htmlText,
    String draftType,
    String? eventId,
  ) async {
    _drafts[roomId] = MockComposeDraft()
      ..setPlainText(plainText)
      ..setHtmlText(htmlText)
      ..setDraftType(draftType)
      ..setEventId(eventId);
    return true;
  }
}

class MockComposeDraft extends Mock implements ComposeDraft {
  String _plainText = '';
  String? _htmlText;
  String _draftType = 'new';
  String? _eventId;

  @override
  String plainText() => _plainText;

  @override
  String? htmlText() => _htmlText;

  @override
  String draftType() => _draftType;

  @override
  String? eventId() => _eventId;

  void setPlainText(String text) {
    _plainText = text;
  }

  void setHtmlText(String? text) {
    _htmlText = text;
  }

  void setDraftType(String type) {
    _draftType = type;
  }

  void setEventId(String? id) {
    _eventId = id;
  }
}

/// Mocked version of chat Provider
class MockAsyncConvoNotifier extends AsyncConvoNotifier {
  @override
  FutureOr<Convo> build(String roomId) async {
    final client = await ref.watch(alwaysClientProvider.future);
    return await client.convoWithRetry(roomId, 0);
  }
}

//
//  --- Calendar --
//
class MockOptionRsvpStatus extends Mock implements OptionRsvpStatus {
  final RsvpStatus? inner;
  MockOptionRsvpStatus(this.inner);

  @override
  RsvpStatus? status() => inner;

  @override
  String? statusStr() => inner?.toString();
}

class MockCalendarEvent extends Mock implements CalendarEvent {
  final RsvpStatus? rsvpStatus;

  MockCalendarEvent({required this.rsvpStatus});

  @override
  Future<MockOptionRsvpStatus> respondedByMe() async =>
      MockOptionRsvpStatus(rsvpStatus);
}

class MockEventId extends Mock implements EventId {
  final String id;

  MockEventId({required this.id});

  @override
  String toString() => id;
}

class MockTextMessageContent extends Mock implements TextMessageContent {
  final String textBody;
  final String? htmlBody;

  MockTextMessageContent({required this.textBody, this.htmlBody});

  @override
  String body() => textBody;
}

class MockUtcDateTime extends Mock implements UtcDateTime {
  final int millis;

  MockUtcDateTime({required this.millis});

  @override
  int timestampMillis() => millis;
}

const hourInMilliSeconds = 3600000;

List<MockCalendarEvent> generateMockCalendarEvents({
  int count = 1,
  String? roomId,
  RsvpStatus? rsvpStatus,
}) =>
    List.generate(count, (idx) {
      final eventA = MockCalendarEvent(rsvpStatus: rsvpStatus);
      when(eventA.title).thenReturn('Event $idx');
      when(eventA.eventId).thenReturn(MockEventId(id: '$roomId-event-$idx-id'));
      when(eventA.description)
          .thenReturn(MockTextMessageContent(textBody: 'event $idx body'));
      final millisecondsBase = DateTime.now().millisecondsSinceEpoch +
          (idx * 2 * hourInMilliSeconds); // put it 2 * idx hours from now

      when(eventA.utcStart)
          .thenReturn(MockUtcDateTime(millis: millisecondsBase));
      when(eventA.utcEnd).thenReturn(
        MockUtcDateTime(millis: millisecondsBase + hourInMilliSeconds),
        // event takes one hour
      );
      if (roomId != null) {
        when(eventA.roomIdStr).thenReturn(roomId);
      }
      return eventA;
    });
