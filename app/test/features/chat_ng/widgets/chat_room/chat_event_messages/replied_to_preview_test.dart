import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/replied_to_preview.dart';
import 'package:acter/features/chat_ng/widgets/events/replied_to_event.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter_avatar/acter_avatar.dart';
import '../../../../../helpers/test_util.dart';

void main() {
  group('RepliedToPreview Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required String roomId,
      required String messageId,
      required MockTimelineEventItem mockEventItem,
      bool isMe = false,
    }) async {
      final senderUserId = mockEventItem.sender().toString();

      await tester.pumpProviderWidget(
        overrides: [
          repliedToMsgProvider((
            roomId: roomId,
            uniqueId: messageId,
          )).overrideWith((ref) => Future.value(mockEventItem)),
          memberAvatarInfoProvider((
            userId: senderUserId,
            roomId: roomId,
          )).overrideWith(
            (ref) => AvatarInfo(
              displayName: 'Test User',
              uniqueName: 'test_user',
              uniqueId: senderUserId,
            ),
          ),
        ],
        child: RepliedToPreview(
          roomId: roomId,
          messageId: messageId,
          isMe: isMe,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('should show loading state', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          repliedToMsgProvider((
            roomId: 'room-id',
            uniqueId: 'message-id',
          )).overrideWith(
            (ref) => Future.delayed(
              const Duration(milliseconds: 100),
              () => MockTimelineEventItem(),
            ),
          ),
        ],
        child: const RepliedToPreview(
          roomId: 'room-id',
          messageId: 'message-id',
        ),
      );

      expect(find.text('Loading...'), findsNWidgets(2));

      // Pump to complete the delayed future
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
    });

    testWidgets('should show error state', (WidgetTester tester) async {
      const errorMessage = 'Failed to load message';
      await tester.pumpProviderWidget(
        overrides: [
          repliedToMsgProvider((
            roomId: 'room-id',
            uniqueId: 'message-id',
          )).overrideWith((ref) => Future.error(errorMessage)),
        ],
        child: const RepliedToPreview(
          roomId: 'room-id',
          messageId: 'message-id',
        ),
      );

      await tester.pumpAndSettle();

      final lang = L10n.of(tester.element(find.byType(RepliedToPreview)));
      expect(
        find.textContaining(lang.repliedToMsgFailed(errorMessage)),
        findsOneWidget,
      );
    });

    testWidgets('should show replied message for other user', (
      WidgetTester tester,
    ) async {
      final mockEventItem = MockTimelineEventItem();

      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room-id',
        messageId: 'message-id',
        mockEventItem: mockEventItem,
      );

      expect(find.byType(RepliedToEvent), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('should show replied message for current user', (
      WidgetTester tester,
    ) async {
      final mockEventItem = MockTimelineEventItem();

      await createWidgetUnderTest(
        tester: tester,
        roomId: 'room-id',
        messageId: 'message-id',
        mockEventItem: mockEventItem,
        isMe: true,
      );

      expect(find.byType(RepliedToEvent), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('should show sender ID when both names are null', (
      WidgetTester tester,
    ) async {
      final mockEventItem = MockTimelineEventItem();
      final senderId = mockEventItem.sender().toString();

      await tester.pumpProviderWidget(
        overrides: [
          repliedToMsgProvider((
            roomId: 'room-id',
            uniqueId: 'message-id',
          )).overrideWith((ref) => Future.value(mockEventItem)),
          memberAvatarInfoProvider((
            userId: senderId,
            roomId: 'room-id',
          )).overrideWith(
            (ref) => AvatarInfo(
              displayName: null,
              uniqueName: null,
              uniqueId: senderId,
            ),
          ),
        ],
        child: const RepliedToPreview(
          roomId: 'room-id',
          messageId: 'message-id',
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text(senderId), findsOneWidget);
    });
  });
}
