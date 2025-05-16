import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/display_name_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_room/app_bar_widget.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/convo_showcase_data.dart';
import 'package:acter/features/chat_ui_showcase/mocks/showcase/data/general_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../helpers/test_util.dart';

void main() {
  group('ChatRoomAppBarWidget', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required MockChatItem mockChatItem,
      VoidCallback? onProfileTap,
      bool isRoomEncrypted = true,
      bool isLoading = false,
      bool isError = false,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          isDirectChatProvider(mockChatItem.roomId).overrideWith(
            (ref) => Future.value(mockChatItem.mockConvo.mockIsDm),
          ),
          isRoomEncryptedProvider(
            mockChatItem.roomId,
          ).overrideWith((ref) => Future.value(isRoomEncrypted)),
          membersIdsProvider(mockChatItem.roomId).overrideWith((ref) {
            if (isError) {
              return Future.error('Error');
            }
            if (isLoading) {
              return Future.delayed(
                const Duration(milliseconds: 100),
                () => mockChatItem.mockRoom.mockActiveMembersIds ?? [],
              );
            }
            return Future.value(
              mockChatItem.mockRoom.mockActiveMembersIds ?? [],
            );
          }),
        ],
        child: ChatRoomAppBarWidget(
          roomId: mockChatItem.roomId,
          onProfileTap: onProfileTap,
        ),
      );
      // Wait for the async providers to load
      await tester.pump();
      if (isLoading) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('renders correctly for direct message', (
      WidgetTester tester,
    ) async {
      final emilysRoom = emilyDmMutedBookmarkedRoom1('@emily:acter.global');
      await createWidgetUnderTest(tester: tester, mockChatItem: emilysRoom);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(RoomAvatar), findsOneWidget);
      expect(find.byType(DisplayNameWidget), findsOneWidget);

      final memberCount = emilysRoom.mockRoom.mockActiveMembersIds?.length ?? 0;

      expect(
        find.text('$memberCount Members'),
        findsNothing,
      ); // Should not show for DM
    });

    testWidgets('renders correctly for group DM', (WidgetTester tester) async {
      final groupDmRoom = groupDmWithMichaelKumarpalsinhBenRoom5(
        '@group:acter.global',
      );
      await createWidgetUnderTest(tester: tester, mockChatItem: groupDmRoom);

      // Wait for the widget to build and update
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(RoomAvatar), findsOneWidget);
      expect(find.byType(DisplayNameWidget), findsOneWidget);

      final memberCount =
          groupDmRoom.mockRoom.mockActiveMembersIds?.length ?? 0;
      // For DMs (including group DMs), we should not show the members count
      expect(find.text('$memberCount Members'), findsNothing);
    });

    testWidgets('renders correctly for group chat', (
      WidgetTester tester,
    ) async {
      final productTeamRoom = productTeamMutedWithSingleTypingUserRoom2(
        '@emily:acter.global',
      );
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: productTeamRoom,
      );

      // Wait for the widget to build and update
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(RoomAvatar), findsOneWidget);
      expect(find.byType(DisplayNameWidget), findsOneWidget);

      final memberCount =
          productTeamRoom.mockRoom.mockActiveMembersIds?.length ?? 0;
      expect(find.text('$memberCount Members'), findsOneWidget);
    });

    testWidgets('shows encryption warning when room is not encrypted', (
      WidgetTester tester,
    ) async {
      final emilysRoom = emilyDmMutedBookmarkedRoom1('@emily:acter.global');
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: emilysRoom,
        isRoomEncrypted: false,
      );

      expect(
        find.byIcon(PhosphorIcons.shieldWarning(PhosphorIconsStyle.regular)),
        findsOneWidget,
      );
    });

    testWidgets('calls onProfileTap when title or avatar is tapped', (
      WidgetTester tester,
    ) async {
      var profileTapped = false;
      final emilysRoom = emilyDmMutedBookmarkedRoom1('@emily:acter.global');
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: emilysRoom,
        onProfileTap: () {
          profileTapped = true;
        },
      );

      await tester.tap(find.byType(DisplayNameWidget));
      expect(profileTapped, isTrue);

      profileTapped = false;
      await tester.tap(find.byType(RoomAvatar));
      expect(profileTapped, isTrue);
    });

    testWidgets('shows loading state for members count', (
      WidgetTester tester,
    ) async {
      final productTeamRoom = productTeamMutedWithSingleTypingUserRoom2(
        '@emily:acter.global',
      );
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: productTeamRoom,
        isLoading: true,
      );

      // Initial state should show loading
      expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsOneWidget);

      // Wait for the async provider to load
      await tester.pump(const Duration(milliseconds: 110));
      await tester.pumpAndSettle();

      // After loading, should show actual count
      expect(
        find.text(
          '${productTeamRoom.mockRoom.mockActiveMembersIds?.length} Members',
        ),
        findsOneWidget,
      );
      expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsNothing);
    });

    testWidgets('shows error state for members count', (
      WidgetTester tester,
    ) async {
      final productTeamRoom = productTeamMutedWithSingleTypingUserRoom2(
        '@emily:acter.global',
      );
      await createWidgetUnderTest(
        tester: tester,
        mockChatItem: productTeamRoom,
        isError: true,
      );

      // Wait for the widget to build and update
      await tester.pumpAndSettle();

      expect(find.text('Error loading members count: Error'), findsOneWidget);
    });
  });
}
