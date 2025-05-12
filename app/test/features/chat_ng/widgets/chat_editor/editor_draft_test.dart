import 'package:acter/features/chat_ng/providers/notifiers/chat_editor_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_a3sdk.dart';

// editor notifier mock class
class MockChatEditorNotifier extends ChatEditorNotifier with Mock {}

void main() {
  group('Chat Editor Draft Tests', () {
    const roomId = 'test-room-id';
    const testPlainText = 'Hello, test draft';
    const testHtmlText = '<p>Hello, test draft</p>';

    test('saves and retrieves drafts correctly', () async {
      final mockConvo = MockConvo(roomId);

      // initially, draft should not exist
      final initialDraft = await mockConvo.msgDraft().then(
        (value) => value.draft(),
      );
      expect(initialDraft, isNull);

      // save a regular draft
      final result = await mockConvo.saveMsgDraft(
        testPlainText,
        testHtmlText,
        'new',
        null,
      );
      expect(result, isTrue);

      // verify draft was saved with correct values
      final savedDraft = await mockConvo.msgDraft().then(
        (value) => value.draft(),
      );
      expect(savedDraft, isNotNull);
      expect(savedDraft?.plainText(), equals(testPlainText));
      expect(savedDraft?.htmlText(), equals(testHtmlText));
      expect(savedDraft?.draftType(), equals('new'));
      expect(savedDraft?.eventId(), isNull);
    });

    test('handles edit draft type correctly', () async {
      final mockConvo = MockConvo(roomId);
      const eventId = 'test-event-id';

      // save an edit draft
      final result = await mockConvo.saveMsgDraft(
        testPlainText,
        testHtmlText,
        'edit',
        eventId,
      );
      expect(result, isTrue);

      // verify draft was saved
      final savedDraft = await mockConvo.msgDraft().then(
        (value) => value.draft(),
      );
      expect(savedDraft, isNotNull);
      expect(savedDraft?.plainText(), equals(testPlainText));
      expect(savedDraft?.htmlText(), equals(testHtmlText));
      expect(savedDraft?.draftType(), equals('edit'));
      expect(savedDraft?.eventId(), equals(eventId));
    });

    test('handles reply draft type correctly', () async {
      final mockConvo = MockConvo(roomId);
      const eventId = 'test-event-id';

      // save a reply draft
      final result = await mockConvo.saveMsgDraft(
        testPlainText,
        testHtmlText,
        'reply',
        eventId,
      );
      expect(result, isTrue);

      // verify draft was saved
      final savedDraft = await mockConvo.msgDraft().then(
        (value) => value.draft(),
      );
      expect(savedDraft, isNotNull);
      expect(savedDraft?.plainText(), equals(testPlainText));
      expect(savedDraft?.htmlText(), equals(testHtmlText));
      expect(savedDraft?.draftType(), equals('reply'));
      expect(savedDraft?.eventId(), equals(eventId));
    });
  });
}
