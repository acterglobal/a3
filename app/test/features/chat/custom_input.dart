import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_chat_message.dart';
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
                canSendProvider.overrideWith((ref, roomId) => false),
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
                canSendProvider
                    .overrideWith((ref, roomId) => null), // null means loading
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
                canSendProvider.overrideWith((ref, roomId) => true),
                isRoomEncryptedProvider.overrideWith((ref, roomId) => true),
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

  group('Custom Chat Input - Edit States', () {
    final overrides = [
      canSendProvider.overrideWith((ref, roomId) => true),
      isRoomEncryptedProvider.overrideWith((ref, roomId) => true),
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

        await tester.pump();
        // not visible
        expect(find.byKey(CustomChatInput.sendBtnKey), findsNothing);
      },
    );

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

        await tester.pump();
        expect(controller.text, 'teing code');

        // lest move the cursor to fix our typos.
        controller.selection =
            TextSelection.fromPosition(const TextPosition(offset: 2));

        await tester.pump();
        await tester.enterTextWithoutReplace(find.byType(TextField), 's');
        await tester.pump();
        await tester.enterTextWithoutReplace(find.byType(TextField), 't');
        await tester.pump();
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
        expect(find.byKey(CustomChatInput.noAccessKey), findsNothing);
        expect(find.byKey(CustomChatInput.loadingKey), findsNothing);

        // not visible

        final element = tester.element(find.byType(CustomChatInput));
        final container = ProviderScope.containerOf(element);

        final TextField textField = tester.widget(find.byType(TextField));
        final controller = textField.controller!;

        await tester.enterTextWithoutReplace(
          find.byType(TextField),
          'teing code',
        );

        await tester.pump();
        expect(controller.text, 'teing code');

        // lest move the cursor to fix our typos.
        controller.selection =
            TextSelection.fromPosition(const TextPosition(offset: 2));

        await tester.pump();
        await tester.enterTextWithoutReplace(find.byType(TextField), 's');

        // now we select the one we want to reply to
        final chatInputNotifier = container.read(chatInputProvider.notifier);
        chatInputNotifier.setReplyToMessage(buildMockTextMessage());

        // without moving the cursor!
        await tester.pump();
        await tester.enterTextWithoutReplace(find.byType(TextField), 't');

        await tester.pump();
        expect(controller.text, 'testing code'); // <- cursor moved
      },
    );
  });
}
