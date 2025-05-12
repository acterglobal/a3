import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_util.dart';

void main() {
  group('Chat Bubble Widget Tests', () {
    testWidgets('renders timestamp when provided', (tester) async {
      final timestamp = DateTime(2023, 1, 1, 12, 0, 0).millisecondsSinceEpoch;

      await tester.pumpProviderWidget(
        child: Center(
          child: ChatBubble(
            context: tester.element(find.byType(Center)),
            timestamp: timestamp,
            isFirstMessageBySender: true,
            isLastMessageBySender: true,
            child: const Text('Hello'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);

      expect(find.byType(MessageTimestampWidget), findsOneWidget);
    });

    testWidgets('renders edited indicator when isEdited is true', (
      tester,
    ) async {
      late BuildContext testContext;
      await tester.pumpProviderWidget(
        child: Center(
          child: Builder(
            builder: (context) {
              testContext = context;
              return ChatBubble(
                context: context,
                isEdited: true,
                isFirstMessageBySender: true,
                isLastMessageBySender: true,
                child: const Text('Edited message'),
              );
            },
          ),
        ),
      );

      expect(find.text(L10n.of(testContext).edited), findsOneWidget);
    });

    testWidgets(
      'renders both edited indicator and timestamp when both provided',
      (tester) async {
        final timestamp = DateTime(2023, 1, 1, 12, 0, 0).millisecondsSinceEpoch;
        late BuildContext testContext;
        await tester.pumpProviderWidget(
          child: Center(
            child: Builder(
              builder: (context) {
                testContext = context;
                return ChatBubble(
                  context: context,
                  isEdited: true,
                  timestamp: timestamp,
                  isFirstMessageBySender: true,
                  isLastMessageBySender: true,
                  child: const Text('Edited message with timestamp'),
                );
              },
            ),
          ),
        );

        expect(find.text(L10n.of(testContext).edited), findsOneWidget);

        expect(find.byType(MessageTimestampWidget), findsOneWidget);
      },
    );

    testWidgets('does not render edited indicator when isEdited is false', (
      tester,
    ) async {
      late BuildContext testContext;
      await tester.pumpProviderWidget(
        child: Center(
          child: Builder(
            builder: (context) {
              testContext = context;
              return ChatBubble(
                context: context,
                isEdited: false,
                isFirstMessageBySender: true,
                isLastMessageBySender: true,
                child: const Text('Unedited message'),
              );
            },
          ),
        ),
      );

      expect(find.text(L10n.of(testContext).edited), findsNothing);
    });

    testWidgets('renders user message with ChatBubble.me factory', (
      tester,
    ) async {
      final timestamp = DateTime(2023, 1, 1, 12, 0, 0).millisecondsSinceEpoch;
      late BuildContext testContext;

      await tester.pumpProviderWidget(
        child: Builder(
          builder: (context) {
            testContext = context;
            return ChatBubble.me(
              context: context,
              isEdited: true,
              timestamp: timestamp,
              isFirstMessageBySender: true,
              isLastMessageBySender: true,
              child: const Text('My message'),
            );
          },
        ),
      );

      expect(find.text('My message'), findsOneWidget);

      final editedText = L10n.of(testContext).edited;
      expect(find.text(editedText), findsOneWidget);
      expect(find.byType(MessageTimestampWidget), findsOneWidget);

      final row = tester.widget<Row>(find.byType(Row).first);
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.end));
    });
  });
}
