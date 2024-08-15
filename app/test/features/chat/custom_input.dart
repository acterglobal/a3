import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrapper_widget.dart';

void main() {
  group(
    'Custom Chat Input General States',
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
    },
  );
}
