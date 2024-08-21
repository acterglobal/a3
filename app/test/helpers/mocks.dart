import 'dart:async';

import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

import 'package:mockito/mockito.dart';

/// Mocked version of ActerSdk
class MockActerSdk extends Mock implements ActerSdk {}

/// Mocked version of Acter Client
class MockClient extends Mock implements Client {
  @override
  Stream<bool> subscribeStream(String topic) {
    return Stream.value(true); // Return a dummy stream
  }

  @override
  Future<Convo> convoWithRetry(String roomId, [int attempt = 0]) async {
    return MockConvo();
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
  MockComposeDraft? _savedDraft;

  @override
  Future<OptionComposeDraft> msgDraft() async {
    return MockOptionComposeDraft(_savedDraft);
  }

  @override
  Future<bool> saveMsgDraft(
    String plainText,
    String? htmlText,
    String draftType,
    String? eventId,
  ) async {
    _savedDraft = MockComposeDraft()
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
    final client = ref.read(alwaysClientProvider);
    return await client.convoWithRetry(roomId, 0);
  }
}
