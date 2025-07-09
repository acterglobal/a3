import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/invite_members/widgets/direct_invite.dart';
import 'package:acter/features/member/widgets/user_builder.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import '../../helpers/test_util.dart';
import '../../helpers/mock_room_providers.dart';
import 'package:acter/features/chat_ui_showcase/mocks/room/mock_member.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUserId = '@testuser:matrix.org';
  const testRoomId = '!testroom:matrix.org';

  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    List<Member> invitedMembers = const [],
    List<String> joinedMembers = const [],
    Room? room,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        roomInvitedMembersProvider.overrideWith((ref, roomId) => invitedMembers),
        membersIdsProvider.overrideWith((ref, roomId) => joinedMembers),
        maybeRoomProvider.overrideWith(() => MockAlwaysTheSameRoomNotifier(room: room)),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: const DirectInvite(
          userId: testUserId,
          roomId: testRoomId,
        ),
      ),
    );
    await tester.pump();
  }

  group('DirectInvite Widget Tests', () {
    testWidgets('shows direct invite text for new user', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester);

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(DirectInvite));
      final lang = L10n.of(context);

      // Verify the widget shows direct invite text
      expect(find.text(lang.directInviteUser(testUserId)), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('shows user ID for invited user', (WidgetTester tester) async {
      final mockMember = MockMember(
        mockMemberId: testUserId,
        mockRoomId: testRoomId,
        mockMembershipStatusStr: 'invite',
        mockCanString: true,
      );

      await createWidgetUnderTest(
        tester: tester,
        invitedMembers: [mockMember],
      );

      // Verify the widget shows user ID
      expect(find.text(testUserId), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('shows user ID for joined user', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        joinedMembers: [testUserId],
      );

      // Verify the widget shows user ID
      expect(find.text(testUserId), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('shows UserStateButton when room is available', (WidgetTester tester) async {
      final mockRoom = MockRoom(
        isJoined: true,
        roomId: testRoomId,
      );

      await createWidgetUnderTest(
        tester: tester,
        room: mockRoom,
      );

      // Verify UserStateButton is shown
      expect(find.byType(UserStateButton), findsOneWidget);
    });

    testWidgets('shows skeletonizer when room is null', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        room: null,
      );

      // Verify Skeletonizer is shown when room is null
      expect(find.text('Loading room'), findsOneWidget);
      expect(find.byType(UserStateButton), findsNothing);
    });

    testWidgets('shows user ID when user is both invited and joined', (WidgetTester tester) async {
      final mockMember = MockMember(
        mockMemberId: testUserId,
        mockRoomId: testRoomId,
        mockMembershipStatusStr: 'invite',
        mockCanString: true,
      );

      await createWidgetUnderTest(
        tester: tester,
        invitedMembers: [mockMember],
        joinedMembers: [testUserId],
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(DirectInvite));
      final lang = L10n.of(context);

      // When user is both invited and joined, it should show the user ID, not the direct invite text
      expect(find.text(testUserId), findsOneWidget);
      expect(find.text(lang.directInviteUser(testUserId)), findsNothing);
    });
  });
}