import 'package:flutter_chat_types/flutter_chat_types.dart';

import 'mock_a3sdk.dart';

int id = 0;

/// builds dummy text message
TextMessage buildMockTextMessage() {
  id += 1;
  return TextMessage(
    author: User(id: '$id-user'),
    id: '$id-msg',
    text: 'text of $id',
  );
}

MockComposeDraft buildMockDraft(String text) {
  var mockComposeDraft = MockComposeDraft();
  mockComposeDraft.setPlainText(text);
  return mockComposeDraft;
}
