import 'dart:async';

import 'package:acter/common/providers/notifiers/chat_notifiers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Mocked version of Convo
class MockConvo extends Mock implements Convo {
  @override
  Future<bool> saveMsgDraft(String plainText, String? htmlText,
      String draftType, String? eventId) async {
    return true; // Default implementation returns true
  }
}

class MockComposeDraft extends Mock implements ComposeDraft {
  String _plainText = '';

  @override
  String plainText() => _plainText;

  void setPlainText(String text) {
    _plainText = text;
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

final mockClientProvider = Provider<Client>((ref) => MockClient());

final mockChatComposerDraftProvider =
    FutureProvider.family<ComposeDraft?, String>((ref, roomId) async {
  return MockComposeDraft();
});
