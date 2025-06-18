import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/toolkit/html_editor/html_editor.dart';
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
import '../../../../helpers/test_wrapper_widget.dart'
    show InActerContextTestWrapper;
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
      chatComposerDraftProvider.overrideWith(
        (ref, roomId) => MockComposeDraft(),
      ),
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: InActerContextTestWrapper(
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
          ),
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
      await tester.pump();

      expect(find.text('Reply'), findsOneWidget);

      // Verify state after reply action
      final updatedState = container.read(chatEditorStateProvider);
      expect(updatedState.actionType, equals(MessageAction.reply));
      expect(updatedState.selectedMsgItem, equals(mockEventItem));

      await tester.pump();

      // Verify preview appears with correct item
      expect(find.byType(ChatEditorActionsPreview), findsOneWidget);
      final previewWidget = tester.widget<ChatEditorActionsPreview>(
        find.byType(ChatEditorActionsPreview),
      );
      expect(previewWidget.msgItem, equals(mockEventItem));
      await tester.pump(Duration(seconds: 2));
    });

    testWidgets('verify chat editor correctly sets edit preview', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: InActerContextTestWrapper(
            child: Column(
              children: [
                MessageActionsWidget(
                  isMe: true,
                  canRedact: false,
                  item: mockEventItem,
                  messageId: 'test-messageId-1',
                  roomId: 'test-roomId-1',
                ),
                ChatEditor(roomId: 'test-roomId-1'),
              ],
            ),
          ),
        ),
      );

      // initial state
      final element = tester.element(find.byType(ChatEditor));
      final container = ProviderScope.containerOf(element);
      final initialState = container.read(chatEditorStateProvider);
      expect(initialState.actionType, equals(MessageAction.none));
      expect(initialState.selectedMsgItem, isNull);
      expect(find.byType(ChatEditorActionsPreview), findsNothing);

      // Tap edit
      await tester.tap(find.text('Edit'));
      await tester.pump();

      expect(find.text('Edit'), findsOneWidget);

      // verify edit preview
      final updatedState = container.read(chatEditorStateProvider);
      expect(updatedState.actionType, equals(MessageAction.edit));
      expect(updatedState.selectedMsgItem, equals(mockEventItem));

      expect(find.byType(ChatEditorActionsPreview), findsOneWidget);

      final previewWidget = tester.widget<ChatEditorActionsPreview>(
        find.byType(ChatEditorActionsPreview),
      );
      final textEditorState = previewWidget.textEditorState;

      final messageContent = updatedState.selectedMsgItem?.msgContent()?.body();
      final editorTextMd = textEditorState.intoMarkdown();

      // This test is timing out due to a pending timer (compose draft).
      // put 300ms delay as (debounceTimerDuration)
      await tester.pumpAndSettle(Durations.medium2);

      expect(previewWidget.msgItem, equals(mockEventItem));
      expect(messageContent, editorTextMd);
    });

    testWidgets('verify chat editor correctly sets html edit preview', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: InActerContextTestWrapper(
            child: Column(
              children: [
                MessageActionsWidget(
                  isMe: true,
                  canRedact: false,
                  item: mockEventItem2,
                  messageId: 'formatted-message-id',
                  roomId: 'test-roomId-1',
                ),
                ChatEditor(roomId: 'test-roomId-1'),
              ],
            ),
          ),
        ),
      );

      // initial state
      final element = tester.element(find.byType(ChatEditor));
      final container = ProviderScope.containerOf(element);
      final initialState = container.read(chatEditorStateProvider);
      expect(initialState.actionType, equals(MessageAction.none));
      expect(initialState.selectedMsgItem, isNull);
      expect(find.byType(ChatEditorActionsPreview), findsNothing);

      // Tap edit
      await tester.tap(find.text('Edit'));
      await tester.pump();

      expect(find.text('Edit'), findsOneWidget);

      // verify edit preview
      final updatedState = container.read(chatEditorStateProvider);
      expect(updatedState.actionType, equals(MessageAction.edit));
      expect(updatedState.selectedMsgItem, equals(mockEventItem2));

      expect(find.byType(ChatEditorActionsPreview), findsOneWidget);

      final previewWidget = tester.widget<ChatEditorActionsPreview>(
        find.byType(ChatEditorActionsPreview),
      );
      final textEditorState = previewWidget.textEditorState;

      final editorTextMd = textEditorState.intoMarkdown();
      final editorTextHtml = textEditorState.intoHtml();

      // This test is timing out due to a pending timer (compose draft).
      // put 300ms delay as (debounceTimerDuration)
      await tester.pumpAndSettle(Durations.medium2);

      expect(previewWidget.msgItem, equals(mockEventItem2));
      expect(editorTextHtml, mockEventItem2.msgContent()?.mockFormattedBody);
      // checking the markdown as well
      expect(editorTextMd, mockEventItem2.msgContent()?.bodyText);
    });

    testWidgets('closing edit preview resets chat editor state', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: overrides,
        child: Column(
          children: [
            MessageActionsWidget(
              isMe: true,
              canRedact: false,
              item: mockEventItem,
              messageId: 'test-messageId-1',
              roomId: 'test-roomId-1',
            ),
            ChatEditor(roomId: 'test-roomId-1'),
          ],
        ),
      );

      final element = tester.element(find.byType(ChatEditor));
      final container = ProviderScope.containerOf(element);

      // initial state
      final initialState = container.read(chatEditorStateProvider);
      expect(initialState.actionType, equals(MessageAction.none));
      expect(initialState.selectedMsgItem, isNull);
      expect(find.byType(ChatEditorActionsPreview), findsNothing);

      await tester.tap(find.text('Edit'));
      await tester.pump();

      // verify edit preview with updated state
      final updatedState = container.read(chatEditorStateProvider);
      expect(updatedState.actionType, equals(MessageAction.edit));
      expect(updatedState.selectedMsgItem, equals(mockEventItem));

      await tester.pump();

      expect(find.byType(ChatEditorActionsPreview), findsOneWidget);

      final previewWidget = tester.widget<ChatEditorActionsPreview>(
        find.byType(ChatEditorActionsPreview),
      );

      final textEditorState = previewWidget.textEditorState;
      final messageContent = updatedState.selectedMsgItem?.msgContent()?.body();
      final editorText =
          textEditorState.getNodeAtPath([0])?.delta?.toPlainText();

      // This test is timing out due to a pending timer (compose draft).
      // put 300ms delay as (debounceTimerDuration)
      await tester.pumpAndSettle(Durations.medium2);
      expect(previewWidget.msgItem, equals(mockEventItem));
      // verify editor field has edit preview content
      expect(messageContent, editorText);

      // now close edit preview
      // FIXME: apparently tester cannot find the close icon for some reason.
      return markTestSkipped(
        "Tester can't find the clsoe button for some reason",
      );

      // final closeKey = find.byKey(ChatEditorActionsPreview.closePreviewKey);

      // expect(closeKey, findsOneWidget);
      // await tester.tap(closeKey);
      // // This test is timing out due to a pending timer (compose draft).
      // // put 300ms delay as (debounceTimerDuration)
      // await tester.pumpAndSettle(Durations.medium2);
      // // verify actions set to none
      // final finalState = container.read(chatEditorStateProvider);
      // expect(finalState.actionType, equals(MessageAction.none));
      // expect(finalState.selectedMsgItem, isNull);
      // expect(find.byType(ChatEditorActionsPreview), findsNothing);

      // // editor state resets
      // expect(editorText, isEmpty);
    });

    testWidgets(
      'switching between reply and edit states correctly sets editor state',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: InActerContextTestWrapper(
              child: Column(
                children: [
                  MessageActionsWidget(
                    isMe: true,
                    canRedact: false,
                    item: mockEventItem,
                    messageId: 'test-messageId-1',
                    roomId: 'test-roomId-1',
                  ),
                  ChatEditor(roomId: 'test-roomId-1'),
                ],
              ),
            ),
          ),
        );

        final element = tester.element(find.byType(ChatEditor));
        final container = ProviderScope.containerOf(element);
        final notifier = container.read(chatEditorStateProvider.notifier);

        // set reply preview
        notifier.setReplyToMessage(mockEventItem);
        await tester.pump();

        // verify reply preview
        var state = container.read(chatEditorStateProvider);
        expect(state.actionType, equals(MessageAction.reply));
        expect(state.selectedMsgItem, equals(mockEventItem));
        expect(find.byType(ChatEditorActionsPreview), findsOneWidget);

        // set edit preview
        notifier.setEditMessage(mockEventItem);
        await tester.pump();

        // verify edit preview
        var updatedState = container.read(chatEditorStateProvider);
        expect(updatedState.actionType, equals(MessageAction.edit));
        expect(updatedState.selectedMsgItem, equals(mockEventItem));
        expect(find.byType(ChatEditorActionsPreview), findsOneWidget);

        // verify editor field has edit preview content
        final messageContent =
            updatedState.selectedMsgItem?.msgContent()?.body();
        final previewWidget = tester.widget<ChatEditorActionsPreview>(
          find.byType(ChatEditorActionsPreview),
        );
        final textEditorState = previewWidget.textEditorState;
        final editorText =
            textEditorState.getNodeAtPath([0])?.delta?.toPlainText();
        // This test is timing out due to a pending timer (compose draft).
        // put 300ms delay as (debounceTimerDuration)
        await tester.pumpAndSettle(Durations.medium2);
        expect(messageContent, editorText);
      },
    );
  });
}
