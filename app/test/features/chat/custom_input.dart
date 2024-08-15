import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
        // CURRENTLY FAILS
      },
      skip: true,
    );
  });
}
