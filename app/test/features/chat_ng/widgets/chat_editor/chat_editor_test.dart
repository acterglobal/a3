import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/features/chat_ng/models/chat_editor_state.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_editor_notifier.dart';
import 'package:acter/features/chat_ng/widgets/chat_editor/chat_editor.dart';
import 'package:acter/features/chat_ng/widgets/chat_editor/chat_editor_actions_preview.dart';
import 'package:acter/features/chat_ng/widgets/message_actions_widget.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_a3sdk.dart';
import '../../../../helpers/mock_client_provider.dart';
import '../../../../helpers/test_util.dart';
import '../../../comments/mock_data/mock_message_content.dart';
import '../../diff_applier_test.dart' show MockTimelineItem;
import '../../messages/chat_message_test.dart';

class MockChatEditorNotifier extends AutoDisposeNotifier<ChatEditorState>
    with Mock
    implements ChatEditorNotifier {
  @override
  ChatEditorState build() =>
      ChatEditorState(selectedMsgItem: null, actionType: MessageAction.none);
}

void main() {
  group('Chat editor reply/edit preview tests', () {
    final mockMsgContent = MockMsgContent(bodyText: 'Test Content Message');
    final mockHtmlMsgContent = MockMsgContent(
      bodyText: '## Title\n**Test Content Message**',
      mockFormattedBody:
          '<h2>Title</h2><p><strong>Test Content Message</strong></p>',
    );
    final mockEventItem = MockTimelineEventItem(
      mockSender: 'user-1',
      mockMsgContent: mockMsgContent,
      mockMsgType: 'm.text',
    );
    final roomMsg1 = MockTimelineItem(
      id: 'test-messageId-1',
      mockEventItem: mockEventItem,
    );
    final mockEventItem2 = MockTimelineEventItem(
      mockSender: 'user-1',
      mockMsgContent: mockHtmlMsgContent,
      mockMsgType: 'm.text',
    );
    final roomMsg2 = MockTimelineItem(
      id: 'formatted-message-id',
      mockEventItem: mockEventItem2,
    );

    final overrides = [
      sdkProvider.overrideWith((ref) => MockActerSdk()),
      clientProvider.overrideWith(
        () => MockClientNotifier(client: MockClient()),
      ),
      chatProvider.overrideWith(() => MockAsyncConvoNotifier()),
      chatComposerDraftProvider.overrideWith((ref, roomId) => null),
      renderableChatMessagesProvider.overrideWith(
        (ref, roomId) => ['test-messageId-1', 'formatted-message-id'],
      ),
      chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
        final uniqueId = roomMsgId.uniqueId;
        return switch (uniqueId) {
          'test-messageId-1' => roomMsg1,
          'formatted-message-id' => roomMsg2,
          _ => null,
        };
      }),
    ];
    testWidgets('verify chat editor correctly sets reply preview', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: overrides,
        child: Column(
          children: [
            MessageActionsWidget(
              isMe: false,
              canRedact: false,
              item: mockEventItem,
              messageId: 'test-messageId-1',
              roomId: 'test-roomId-1',
            ),
            ChatEditor(roomId: 'test-roomId-1'),
          ],
        ),
      );

      // initial state
      final element = tester.element(find.byType(ChatEditor));
      final container = ProviderScope.containerOf(element);
      final initialState = container.read(chatEditorStateProvider);
      expect(initialState.actionType, equals(MessageAction.none));
      expect(initialState.selectedMsgItem, isNull);
      expect(find.byType(ChatEditorActionsPreview), findsNothing);

      // Tap reply
      await tester.tap(find.text('Reply'));
      await tester.pump(Durations.medium2);

      expect(find.text('Reply'), findsOneWidget);

      // Verify state after reply action
      final updatedState = container.read(chatEditorStateProvider);
      expect(updatedState.actionType, equals(MessageAction.reply));
      expect(updatedState.selectedMsgItem, equals(mockEventItem));

      await tester.pump(Durations.medium2);

      // Verify preview appears with correct item
      expect(find.byType(ChatEditorActionsPreview), findsOneWidget);
      final previewWidget = tester.widget<ChatEditorActionsPreview>(
        find.byType(ChatEditorActionsPreview),
      );
      expect(previewWidget.msgItem, equals(mockEventItem));
      await tester.pump(Duration(seconds: 2));
    });
  });
}
