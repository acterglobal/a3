import 'package:flutter_chat_types/flutter_chat_types.dart';

import 'mocks.dart';

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

// builds dummy compose draft by providing text
MockComposeDraft buildMockDraft(String text) {
  var mockComposeDraft = MockComposeDraft();
  mockComposeDraft.setPlainText(text);
  return mockComposeDraft;
}
