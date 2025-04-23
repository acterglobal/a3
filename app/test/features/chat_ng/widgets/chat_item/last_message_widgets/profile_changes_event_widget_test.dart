import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/profile_changes_event_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_data.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/mock_convo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_util.dart';

void main() {
  group('ProfileChangesEventWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required String roomId,
      required String myUserId,
      required MockTimelineEventItem mockEventItem,
    }) async {
      final senderUserId = mockEventItem.sender().toString();
      final contentUserId =
          mockEventItem.profileContent()?.userId().toString() ?? '';

      await tester.pumpProviderWidget(
        overrides: [
          lastMessageDisplayNameProvider((
            roomId: roomId,
            userId: senderUserId,
          )),
          lastMessageDisplayNameProvider((
            roomId: roomId,
            userId: contentUserId,
          )),
          myUserIdStrProvider.overrideWith((ref) => myUserId),
        ],
        child: ProfileChangesEventWidget(
          roomId: roomId,
          eventItem: mockEventItem,
        ),
      );
    }

    testWidgets('should show nothing when profile content is null', (
      WidgetTester tester,
    ) async {
      final mockEventItem = MockTimelineEventItem(mockProfileContent: null);

      await tester.pumpProviderWidget(
        child: ProfileChangesEventWidget(roomId: '', eventItem: mockEventItem),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    group('Display name changed message', () {
      testWidgets('Display name changed message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameChangedRoom36
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('You changed the display name to David M.'),
          findsOneWidget,
        );
      });
      testWidgets('Display name changed message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameChangedRoom36
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining(
            'David M. changed the display name to David Miller.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('Display name set message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameSetRoom37
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('You set the display name to David Miller.'),
          findsOneWidget,
        );
      });

      testWidgets('Display name set message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameSetRoom37
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('David Miller set the display name to david.'),
          findsOneWidget,
        );
      });

      testWidgets('Display name removed message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameUnsetRoom38
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('You unset the display name.'),
          findsOneWidget,
        );
      });

      testWidgets('Display name removed message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameUnsetRoom38
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david unset the display name.'),
          findsOneWidget,
        );
      });
    });
    group('Avatar changed message', () {
      testWidgets('Avatar changed message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            profileEventAvatarChangedRoom39
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('You changed the user avatar.'),
          findsOneWidget,
        );
      });

      testWidgets('Avatar changed message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventAvatarChangedRoom39
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david changed the user avatar.'),
          findsOneWidget,
        );
      });

      testWidgets('Avatar set message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            profileEventAvatarSetRoom40
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        expect(find.textContaining('You set the user avatar.'), findsOneWidget);
      });

      testWidgets('Avatar set message - Other', (WidgetTester tester) async {
        final mockEventItemData =
            profileEventAvatarSetRoom40
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david set the user avatar.'),
          findsOneWidget,
        );
      });

      testWidgets('Avatar removed message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            profileEventAvatarUnsetRoom41
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('You unset the user avatar.'),
          findsOneWidget,
        );
      });

      testWidgets('Avatar removed message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventAvatarUnsetRoom41
                .mockConvo
                .mockTimelineItem
                ?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        expect(
          find.textContaining('david unset the user avatar.'),
          findsOneWidget,
        );
      });
    });
  });
}
