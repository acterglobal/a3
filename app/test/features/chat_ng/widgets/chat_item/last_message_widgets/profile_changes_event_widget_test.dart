import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter/features/chat_ng/widgets/events/profile_changes_event_widget.dart';
import 'package:acter/features/chat_ui_showcase/mocks/convo/timeline/mock_timeline_event_item.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/profile_change_usecases.dart';
import 'package:acter/l10n/generated/l10n.dart';
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
      final senderUserId = mockEventItem.sender();
      final contentUserId =
          mockEventItem.profileContent()?.userId().toString() ?? '';

      await tester.pumpProviderWidget(
        overrides: [
          lastMessageDisplayNameProvider((
            roomId: roomId,
            userId: senderUserId,
          )).overrideWith((ref) => senderUserId),
          lastMessageDisplayNameProvider((
            roomId: roomId,
            userId: contentUserId,
          )).overrideWith((ref) => contentUserId),
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
            profileEventDisplayNameChangedRoom36(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;
        final profileContent = mockEventItemData!.profileContent();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatProfileDisplayNameYouChanged(
              profileContent!.displayNameNewVal() ?? '',
            ),
          ),
          findsOneWidget,
        );
      });
      testWidgets('Display name changed message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameChangedRoom36(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;
        final profileContent = mockEventItemData!.profileContent();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatProfileDisplayNameOtherChanged(
              profileContent!.displayNameOldVal() ?? '',
              profileContent.displayNameNewVal() ?? '',
            ),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Display name set message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameSetRoom37(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;
        final profileContent = mockEventItemData!.profileContent();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatProfileDisplayNameYouSet(
              profileContent!.displayNameNewVal() ?? '',
            ),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Display name set message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameSetRoom37(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;
        final profileContent = mockEventItemData!.profileContent();

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatProfileDisplayNameOtherSet(
              '@david:acter.global',
              profileContent!.displayNameNewVal() ?? '',
            ),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Display name removed message - Mine', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameUnsetRoom38(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(lang.chatProfileDisplayNameYouUnset),
          findsOneWidget,
        );
      });

      testWidgets('Display name removed message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventDisplayNameUnsetRoom38(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatProfileDisplayNameOtherUnset('@david:acter.global'),
          ),
          findsOneWidget,
        );
      });
    });
    group('Avatar changed message', () {
      testWidgets('Avatar changed message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            profileEventAvatarChangedRoom39(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(lang.chatProfileAvatarUrlYouChanged),
          findsOneWidget,
        );
      });

      testWidgets('Avatar changed message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventAvatarChangedRoom39(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatProfileAvatarUrlOtherChanged('@david:acter.global'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Avatar set message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            profileEventAvatarSetRoom40(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(lang.chatProfileAvatarUrlYouSet),
          findsOneWidget,
        );
      });

      testWidgets('Avatar set message - Other', (WidgetTester tester) async {
        final mockEventItemData =
            profileEventAvatarSetRoom40(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatProfileAvatarUrlOtherSet('@david:acter.global'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('Avatar removed message - Mine', (WidgetTester tester) async {
        final mockEventItemData =
            profileEventAvatarUnsetRoom41(
              '@emily:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: '@david:acter.global',
          mockEventItem: mockEventItemData!,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(lang.chatProfileAvatarUrlYouUnset),
          findsOneWidget,
        );
      });

      testWidgets('Avatar removed message - Other', (
        WidgetTester tester,
      ) async {
        final mockEventItemData =
            profileEventAvatarUnsetRoom41(
              '@david:acter.global',
            ).mockConvo.mockTimelineItem?.mockTimelineEventItem;

        await createWidgetUnderTest(
          tester: tester,
          roomId: 'room-id',
          myUserId: 'user-id',
          mockEventItem: mockEventItemData!,
        );

        final lang = L10n.of(
          tester.element(find.byType(ProfileChangesEventWidget)),
        );
        expect(
          find.textContaining(
            lang.chatProfileAvatarUrlOtherUnset('@david:acter.global'),
          ),
          findsOneWidget,
        );
      });
    });
  });
}
