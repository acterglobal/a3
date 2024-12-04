import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/room_test_wrapper.dart';
import '../../helpers/utils.dart';
import '../../helpers/mock_a3sdk.dart';
import '../../helpers/test_wrapper_widget.dart';

void main() {
  group(
    'Custom Chat Input - General States',
    () {
      testWidgets(
        'No access, no show',
        (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                // Same as before
                canSendMessageProvider.overrideWith((ref, roomId) => false),
                sdkProvider.overrideWith((ref) => MockActerSdk()),
                alwaysClientProvider.overrideWith((ref) => MockClient()),
              ],
              child: const InActerContextTestWrapper(
                child: CustomChatInput(
                  roomId: 'roomId',
                ),
              ),
            ),
          );
          expect(find.byKey(CustomChatInput.noAccessKey), findsOneWidget);
        },
      );

      testWidgets(
        'Unknown Access show Loading',
        (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                // Same as before
                canSendMessageProvider.overrideWith(
                  (ref, roomId) => null,
                ), // null means loading
                sdkProvider.overrideWith((ref) => MockActerSdk()),
              ],
              child: const InActerContextTestWrapper(
                child: CustomChatInput(
                  roomId: 'roomId',
                ),
              ),
            ),
          );
          expect(find.byKey(CustomChatInput.loadingKey), findsOneWidget);
        },
      );

      testWidgets(
        'Show input',
        (tester) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                // Same as before
                canSendMessageProvider.overrideWith((ref, roomId) => true),
                isRoomEncryptedProvider.overrideWith((ref, roomId) => true),
                sdkProvider.overrideWith((ref) => MockActerSdk()),
                alwaysClientProvider.overrideWith((ref) => MockClient()),
                chatComposerDraftProvider
                    .overrideWith((ref, roomId) => MockComposeDraft()),
              ],
              child: const InActerContextTestWrapper(
                child: CustomChatInput(
                  roomId: 'roomId',
                ),
              ),
            ),
          );
          expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
          expect(find.byKey(CustomChatInput.loadingKey), findsNothing);
        },
      );
    },
  );

  group('Send button states', () {
    final overrides = [
      canSendMessageProvider.overrideWith((ref, roomId) => true),
      isRoomEncryptedProvider.overrideWith((ref, roomId) => true),
      sdkProvider.overrideWith((ref) => MockActerSdk()),
      alwaysClientProvider.overrideWith((ref) => MockClient()),
      chatProvider.overrideWith(() => MockAsyncConvoNotifier()),
      chatComposerDraftProvider
          .overrideWith((ref, roomId) => MockComposeDraft()),
    ];
    testWidgets(
      'Showing and hiding send button simple',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const InActerContextTestWrapper(
              child: CustomChatInput(
                roomId: 'roomId',
              ),
            ),
          ),
        );
        expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
        expect(find.byKey(CustomChatInput.loadingKey), findsNothing);

        // not visible
        expect(find.byKey(CustomChatInput.sendBtnKey), findsNothing);
        expect(find.byType(TextField), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'testing code');

        await tester.pump();
        // now visible
        expect(find.byKey(CustomChatInput.sendBtnKey), findsOneWidget);

        // -- reset
        final TextField textField = tester.widget(find.byType(TextField));
        textField.controller!.clear();

        // This test is timing out due to a pending timer.
        // See MultiTriggerAutocompleteState._onChangedField in:
        // acter_trigger_autocomplete.dart:279
        // put 300ms delay as (debounceTimerDuration)
        await tester.pump(Durations.medium2);
        // not visible
        expect(find.byKey(CustomChatInput.sendBtnKey), findsNothing);
      },
    );

    testWidgets(
      'Send button visibility with whitespaces and text with leading whitespaces',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const InActerContextTestWrapper(
              child: CustomChatInput(
                roomId: 'roomId',
              ),
            ),
          ),
        );

        // the send button should not be visible
        expect(find.byKey(CustomChatInput.sendBtnKey), findsNothing);

        // text with leading whitespaces
        await tester.enterText(find.byType(TextField), '   leading whitespace');
        await tester.pump(Durations.medium2);

        // The send button should be visible
        expect(find.byKey(CustomChatInput.sendBtnKey), findsOneWidget);

        // Clear the text
        final TextField textField = tester.widget(find.byType(TextField));
        textField.controller!.clear();
        await tester.pump();

        // The send button should not be visible
        expect(find.byKey(CustomChatInput.sendBtnKey), findsNothing);

        // Enter only whitespace
        await tester.enterText(find.byType(TextField), '     ');

        // This test is timing out due to a pending timer.
        // See MultiTriggerAutocompleteState._onChangedField in:
        // acter_trigger_autocomplete.dart:279
        // put 300ms delay as (debounceTimerDuration)
        await tester.pump(Durations.medium2);

        // The send button should not be visible
        expect(find.byKey(CustomChatInput.sendBtnKey), findsNothing);
      },
    );
  });

  group('Custom Chat Input - Controller states', () {
    Map<String, MockComposeDraft> roomDrafts = {
      'roomId-1': buildMockDraft(''),
      'roomId-2': buildMockDraft(''),
    };
    final overrides = [
      canSendMessageProvider.overrideWith((ref, roomId) => true),
      isRoomEncryptedProvider.overrideWith((ref, roomId) => true),
      sdkProvider.overrideWith((ref) => MockActerSdk()),
      alwaysClientProvider.overrideWith((ref) => MockClient()),
      chatProvider.overrideWith(() => MockAsyncConvoNotifier()),
      chatComposerDraftProvider
          .overrideWith((ref, roomId) => Future.value(roomDrafts[roomId])),
    ];
    testWidgets(
      'Adding text in the middle',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const InActerContextTestWrapper(
              child: CustomChatInput(
                roomId: 'roomId',
              ),
            ),
          ),
        );
        expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
        expect(find.byKey(CustomChatInput.loadingKey), findsNothing);

        // not visible
        expect(find.byKey(CustomChatInput.sendBtnKey), findsNothing);
        expect(find.byType(TextField), findsOneWidget);

        final TextField textField = tester.widget(find.byType(TextField));
        final controller = textField.controller!;

        await tester.enterTextWithoutReplace(
          find.byType(TextField),
          'teing code',
        );

        await tester.pump(Durations.medium2);
        expect(controller.text, 'teing code');

        // lest move the cursor to fix our typos.
        controller.selection =
            TextSelection.fromPosition(const TextPosition(offset: 2));

        await tester.pump();
        await tester.enterTextWithoutReplace(find.byType(TextField), 's');
        await tester.pump();
        await tester.enterTextWithoutReplace(find.byType(TextField), 't');

        // This test is timing out due to a pending timer.
        // See MultiTriggerAutocompleteState._onChangedField in:
        // acter_trigger_autocomplete.dart:279
        // put 300ms delay as (debounceTimerDuration)
        await tester.pump(Durations.medium2);
        expect(controller.text, 'testing code');
      },
    );

    testWidgets(
      'Adding text in the middle in reply',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const InActerContextTestWrapper(
              child: CustomChatInput(
                roomId: 'roomId',
              ),
            ),
          ),
        );
        // not visible
        expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
        expect(find.byKey(CustomChatInput.loadingKey), findsNothing);

        final element = tester.element(find.byType(CustomChatInput));
        final container = ProviderScope.containerOf(element);

        final TextField textField = tester.widget(find.byType(TextField));
        final controller = textField.controller!;

        await tester.enterTextWithoutReplace(
          find.byType(TextField),
          'teing code',
        );

        await tester.pump(Durations.medium2);
        expect(controller.text, 'teing code');

        // lest move the cursor to fix our typos.
        controller.selection =
            TextSelection.fromPosition(const TextPosition(offset: 2));

        await tester.pump();
        await tester.enterTextWithoutReplace(find.byType(TextField), 's');
        await tester.pump();

        // now we select the one we want to reply to
        final chatInputNotifier = container.read(chatInputProvider.notifier);
        chatInputNotifier.setReplyToMessage(buildMockTextMessage());

        // without moving the cursor!
        await tester.pump();
        await tester.enterTextWithoutReplace(find.byType(TextField), 't');

        // This test is timing out due to a pending timer.
        // See MultiTriggerAutocompleteState._onChangedField in:
        // acter_trigger_autocomplete.dart:279
        // put 300ms delay as (debounceTimerDuration)
        await tester.pump(Durations.medium2);
        expect(controller.text, 'testing code');
      },
    );

    testWidgets(
      'Edit message shows correct message state in controller',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const InActerContextTestWrapper(
              child: CustomChatInput(
                roomId: 'roomId',
              ),
            ),
          ),
        );
        // not visible
        expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
        expect(find.byKey(CustomChatInput.loadingKey), findsNothing);

        final element = tester.element(find.byType(CustomChatInput));
        final container = ProviderScope.containerOf(element);

        final TextField textField = tester.widget(find.byType(TextField));
        final controller = textField.controller!;

        // initial state should be empty
        assert(controller.text.trim().isEmpty, true);

        // now we select the one we want to edit to
        final chatInputNotifier = container.read(chatInputProvider.notifier);
        final mockMessage = buildMockTextMessage();
        chatInputNotifier.setEditMessage(mockMessage);

        await tester.pump();

        // controller text should copy over message text
        expect(controller.text, mockMessage.text);

        // This test is timing out due to a pending timer.
        // See MultiTriggerAutocompleteState._onChangedField in:
        // acter_trigger_autocomplete.dart:279
        // put 300ms delay as (debounceTimerDuration)
        await tester.pump(Durations.medium2);
      },
    );

    testWidgets(
      'Switching edit/reply stores selected message',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: const InActerContextTestWrapper(
              child: CustomChatInput(
                roomId: 'roomId',
              ),
            ),
          ),
        );
        // not visible
        expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
        expect(find.byKey(CustomChatInput.loadingKey), findsNothing);

        final element = tester.element(find.byType(CustomChatInput));
        final container = ProviderScope.containerOf(element);

        final TextField textField = tester.widget(find.byType(TextField));
        final controller = textField.controller!;

        // initial state should be empty
        assert(controller.text.trim().isEmpty, true);

        // now we select the one we want to edit to
        final chatInputNotifier = container.read(chatInputProvider.notifier);
        final mockMessage = buildMockTextMessage();
        chatInputNotifier.setEditMessage(mockMessage);

        await tester.pump();

        // read container for updated value
        final editState = container.read(chatInputProvider);
        // should match the message id selected for edit
        expect(editState.selectedMessage?.id, mockMessage.id);

        // now switch the view to reply
        chatInputNotifier.setReplyToMessage(mockMessage);

        await tester.pump();

        // read container again for updated value
        final replyState = container.read(chatInputProvider);

        // should match the message id selected for reply
        expect(replyState.selectedMessage?.id, mockMessage.id);

        // This test is timing out due to a pending timer.
        // See MultiTriggerAutocompleteState._onChangedField in:
        // acter_trigger_autocomplete.dart:279
        // put 300ms delay as (debounceTimerDuration)
        await tester.pump(Durations.medium2);
      },
    );

    testWidgets(
      'Switching to room stores previous message state of room',
      (tester) async {
        final wrapperKey = GlobalKey<RoomTestWrapperState>();

        Future<void> enterText(String text) async {
          final textField = find.byType(TextField);
          await tester.enterText(textField, text);
          // Simulate the debounce timer
          await tester.pump(Durations.medium2);
          await tester.pump(Durations.medium2);
          await tester.pump(Durations.medium2);
        }

        // verify the controller text applies compose draft
        Future<void> verifyDraft(String roomId) async {
          final element = tester.element(find.byType(CustomChatInput));
          final container = ProviderScope.containerOf(element);
          final convo = await container.read(chatProvider(roomId).future);
          // ensure draft was saved
          final textField = find.byType(TextField);
          final draft = await convo?.msgDraft().then((val) => val.draft());
          final textFieldWidget = tester.widget<TextField>(textField);
          // ensure text controller text matches draft
          expect(textFieldWidget.controller?.text, equals(draft?.plainText()));
        }

        Future<void> switchRoom(String roomId) async {
          wrapperKey.currentState!.switchRoom(roomId);
          await tester.pump();
          await tester.pumpAndSettle();

          // Verify that loading and no access indicators are not visible
          expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
          expect(find.byKey(CustomChatInput.loadingKey), findsNothing);
        }

        // build the initial widget tree
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: InActerContextTestWrapper(
              child: RoomTestWrapper(key: wrapperKey, roomId: 'roomId-1'),
            ),
          ),
        );
        // not visible
        expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
        expect(find.byKey(CustomChatInput.loadingKey), findsNothing);
        await tester.pump();

        await enterText('Hello Room 1');
        await verifyDraft('roomId-1');

        await tester.pump();

        // switch to another room
        await switchRoom('roomId-2');
        await enterText('Greetings Room 2');
        await verifyDraft('roomId-2');

        await tester.pump();

        // switch back to room
        await switchRoom('roomId-1');
        // pump to ensure controller gets draft update
        await tester.pump(Durations.short4);
        await verifyDraft('roomId-1');

        // switch to next room again
        await switchRoom('roomId-2');
        // pump to ensure controller gets draft update
        await tester.pump(Durations.short4);
        await verifyDraft('roomId-2');

        // This test is timing out due to a pending timer.
        // See MultiTriggerAutocompleteState._onChangedField in:
        // acter_trigger_autocomplete.dart:279
        // put 300ms delay as (debounceTimerDuration)
        await tester.pump(Durations.medium2);
      },
    );

    testWidgets(
        'Message Edit: focusing on textfield ensures controller doesn\'t reset ',
        (tester) async {
      // Function to verify text in TextField
      void verifyText(String expectedText) {
        final textField = find.byType(TextField);
        final textFieldWidget = tester.widget<TextField>(textField);
        expect(textFieldWidget.controller?.text, equals(expectedText));
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: const InActerContextTestWrapper(
            child: CustomChatInput(
              roomId: 'roomId',
            ),
          ),
        ),
      );
      // not visible
      expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
      expect(find.byKey(CustomChatInput.loadingKey), findsNothing);

      final element = tester.element(find.byType(CustomChatInput));
      final container = ProviderScope.containerOf(element);

      // now we select the one we want to edit to
      final chatInputNotifier = container.read(chatInputProvider.notifier);
      final mockMessage = buildMockTextMessage();
      chatInputNotifier.setEditMessage(mockMessage);
      await tester.pump();
      // Verify that the text is updated to the edited message
      verifyText(mockMessage.text);

      // Simulate focusing the input (this should preserve the text)
      final textField = find.byType(TextField);
      await tester.tap(textField);
      await tester.pump();

      // Verify that the text is still preserved after focusing
      verifyText(mockMessage.text);

      // This test is timing out due to a pending timer.
      // See MultiTriggerAutocompleteState._onChangedField in:
      // acter_trigger_autocomplete.dart:279
      // put 300ms delay as (debounceTimerDuration)
      await tester.pump(Durations.medium2);
    });
  });
}
