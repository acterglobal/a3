import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter/features/member/widgets/user_builder.dart';
import 'package:acter/features/tasks/providers/notifiers.dart' show AsyncTaskUserInvitationNotifier;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import '../../../helpers/mock_invites.dart' as invites;
import '../../../helpers/mock_tasks_providers.dart' as tasks;
import '../../../helpers/test_util.dart';
import '../../../helpers/mock_room_providers.dart' as room_mocks;
import '../../../helpers/mock_membership.dart' as membership;
import '../../../helpers/mock_room_providers.dart' show MockAlwaysTheSameRoomNotifier;

class MockAsyncTaskUserInvitationNotifier extends AsyncTaskUserInvitationNotifier {
  final bool isUserInvitedForTask;

  MockAsyncTaskUserInvitationNotifier(this.isUserInvitedForTask);

  @override
  Future<bool> build((Task, String) params) async => isUserInvitedForTask;
}

void main() {
  late invites.MockUserProfile mockUserProfile;
  late room_mocks.MockRoom mockRoom;
  late tasks.MockTask mockTask;

  setUp(() {
    mockTask = tasks.MockTask(
      fakeTitle: 'Test Task',
      roomId: 'test_room_id',
      eventId: 'test_event_id',
    );
    mockUserProfile = invites.MockUserProfile(
      userId: 'test_user_id',
      displayName: 'Test User',
      sharedRooms: ['room1', 'room2'],
    );
    mockRoom = room_mocks.MockRoom(
      isJoined: true,
      displayName: 'Test Room',
      myMembership: membership.MockMember(userId: 'test_user_id'),
      roomId: 'test_room_id',
      invitedMembers: [membership.MockMember(userId: 'test_user_id')],
    );
  });

  Future<void> pumpUserBuilder(
    WidgetTester tester, {
    required bool includeSharedRooms,
    required VoidCallback onTap,
    String? roomId,
    bool? includeUserJoinState,
    tasks.MockTask? task,
    bool roomExists = true,
  }) async {
    await tester.pumpProviderWidget(
      child: MaterialApp(
        localizationsDelegates: [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        locale: const Locale('en'),
        home: UserBuilder(
          userProfile: mockUserProfile,
          roomId: roomId,
          userId: mockUserProfile.userId().toString(),
          includeSharedRooms: includeSharedRooms,
          includeUserJoinState: includeUserJoinState ?? true,
          onTap: onTap,
          task: task,
        ),
      ),
      overrides: [
        maybeRoomProvider.overrideWith(() => roomExists 
          ? MockAlwaysTheSameRoomNotifier(room: mockRoom)
          : MockAlwaysTheSameRoomNotifier(room: null)
        ),
        membersIdsProvider.overrideWith((ref, roomId) => Future.value(['test_user_id'])),
        roomInvitedMembersProvider.overrideWith((ref, roomId) => Future.value([])),
        isDirectChatProvider.overrideWith((ref, roomId) => Future.value(false)),
        roomDisplayNameProvider.overrideWith((ref, roomId) async {
          if (roomId == 'room1') return 'Shared Room 1';
          if (roomId == 'room2') return 'Shared Room 2';
          if (roomId == 'room3') return 'Shared Room 3';
          if (roomId == 'room4') return 'Shared Room 4';
          if (roomId == 'room5') return 'Shared Room 5';
          if (roomId == mockRoom.roomIdStr()) return 'Test Room';
          final room = await ref.watch(maybeRoomProvider(roomId).future);
          if (room == null) return null;
          return (await room.displayName()).text();
        }),
      ],
    );
    await tester.pump();
  }

  Future<void> pumpUserStateButton(
    WidgetTester tester, {
    required bool isInvited,
    required Future<void> Function(String) onInvite,
    required Future<void> Function(String) onCancelInvite,
    bool isUserInvitedForTask = false,
    bool isJoined = false,
    tasks.MockTask? task,
  }) async {
    final testTask = tasks.MockTask(
      fakeTitle: 'Test Task',
      roomId: 'test_room_id',
      eventId: 'test_event_id',
      hasInvitations: true,
      invitedUsers: isInvited ? ['test_user_id'] : [],
      currentUserId: isUserInvitedForTask ? 'test_user_id' : null,
    );

    await tester.pumpProviderWidget(
      child: UserStateButton(
        room: mockRoom,
        task: task ?? testTask,
        userId: mockUserProfile.userId().toString(),
        onInvite: onInvite,
        onCancelInvite: onCancelInvite,
      ),
      overrides: [
        taskUserInvitationProvider.overrideWith(() => MockAsyncTaskUserInvitationNotifier(isUserInvitedForTask)),
        roomInvitedMembersProvider.overrideWith((ref, roomId) => Future.value(
          isInvited ? [membership.MockMember(userId: 'test_user_id')] : []
        )),
        membersIdsProvider.overrideWith((ref, roomId) => Future.value(
          isJoined ? ['test_user_id'] : []
        )),
        isDirectChatProvider.overrideWith((ref, roomId) => Future.value(false)),
      ],
    );
    await tester.pump();
  }

  group('UserBuilder', () {
    testWidgets('builds member', (tester) async {
      await pumpUserBuilder(
        tester,
        includeSharedRooms: false,
        onTap: () {},
      );
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('handles tap callback', (tester) async {
      bool tapped = false;
      await pumpUserBuilder(
        tester,
        includeSharedRooms: false,
        onTap: () => tapped = true,
      );
      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('shows skeletonizer when room is null', (tester) async {
      await pumpUserBuilder(
        tester,
        includeSharedRooms: false,
        onTap: () {},
        roomId: 'non_existent_room',
        roomExists: false,
      );
      expect(find.text('user'), findsOneWidget);
    });

    testWidgets('does not show trailing when includeUserJoinState is false', (tester) async {
      await pumpUserBuilder(
        tester,
        includeSharedRooms: false,
        onTap: () {},
        includeUserJoinState: false,
      );
      // Should not find any UserStateButton or Skeletonizer
      expect(find.byType(UserStateButton), findsNothing);
      expect(find.text('user'), findsNothing);
    });

    testWidgets('shows shared rooms when includeSharedRooms is true', (tester) async {
      await pumpUserBuilder(
        tester,
        includeSharedRooms: true,
        onTap: () {},
      );
      final context = tester.element(find.byType(UserBuilder));
      final lang = L10n.of(context);
      expect(find.text(lang.youAreBothIn), findsOneWidget);
    });

    testWidgets('shows shared rooms with 3 rooms', (tester) async {
      mockUserProfile = invites.MockUserProfile(
        userId: 'test_user_id',
        displayName: 'Test User',
        sharedRooms: ['room1', 'room2', 'room3'],
      );
      await pumpUserBuilder(
        tester,
        includeSharedRooms: true,
        onTap: () {},
      );
      final context = tester.element(find.byType(UserBuilder));
      final lang = L10n.of(context);
      expect(find.text(lang.youAreBothIn), findsOneWidget);
    });

    testWidgets('shows shared rooms with more than 3 rooms', (tester) async {
      mockUserProfile = invites.MockUserProfile(
        userId: 'test_user_id',
        displayName: 'Test User',
        sharedRooms: ['room1', 'room2', 'room3', 'room4', 'room5'],
      );
      await pumpUserBuilder(
        tester,
        includeSharedRooms: true,
        onTap: () {},
      );
      final context = tester.element(find.byType(UserBuilder));
      final lang = L10n.of(context);
      expect(find.text(lang.youAreBothIn), findsOneWidget);
    });

    testWidgets('does not show shared rooms when empty', (tester) async {
      mockUserProfile = invites.MockUserProfile(
        userId: 'test_user_id',
        displayName: 'Test User',
        sharedRooms: [],
      );
      await pumpUserBuilder(
        tester,
        includeSharedRooms: true,
        onTap: () {},
      );
      final context = tester.element(find.byType(UserBuilder));
      final lang = L10n.of(context);
      expect(find.text(lang.youAreBothIn), findsNothing);
    });
  });

  group('UserStateButton', () {
    testWidgets('shows invite button when user is not invited', (tester) async {
      await pumpUserStateButton(
        tester,
        isInvited: false,
        onInvite: (_) async {},
        onCancelInvite: (_) async {},
      );
      expect(find.byIcon(Atlas.paper_airplane_thin), findsOneWidget);
    });

    testWidgets('shows remove button when user is invited', (tester) async {
      await pumpUserStateButton(
        tester,
        isInvited: true,
        onInvite: (_) async {},
        onCancelInvite: (_) async {},
      );
      expect(find.text('Revoke'), findsOneWidget);
    });

    testWidgets('shows invited chip when user is invited for task', (tester) async {
      await pumpUserStateButton(
        tester,
        isInvited: false,
        isUserInvitedForTask: true,
        onInvite: (_) async {},
        onCancelInvite: (_) async {},
        task: mockTask,
      );
      expect(find.text('Invited'), findsOneWidget);
    });

    testWidgets('does not show joined chip when user is joined but task exists', (tester) async {
      await pumpUserStateButton(
        tester,
        isInvited: false,
        isJoined: true,
        onInvite: (_) async {},
        onCancelInvite: (_) async {},
        task: mockTask,
      );
      expect(find.text('Joined'), findsNothing);
      expect(find.byIcon(Atlas.paper_airplane_thin), findsOneWidget);
    });

    testWidgets('handles invite callback', (tester) async {
      var callbackCalled = false;
      await pumpUserStateButton(
        tester,
        isInvited: false,
        onInvite: (userId) async {
          callbackCalled = true;
          return;
        },
        onCancelInvite: (userId) async {},
      );
      
      // Find the first InkWell that contains the paper airplane icon
      final buttonFinder = find.ancestor(
        of: find.byIcon(Atlas.paper_airplane_thin),
        matching: find.byType(InkWell),
      ).first;
      expect(buttonFinder, findsOneWidget, reason: 'Invite button should be present');
      await tester.tap(buttonFinder);
      expect(callbackCalled, true);
    });

    testWidgets('handles cancel invite callback', (tester) async {
      bool cancelled = false;
      await pumpUserStateButton(
        tester,
        isInvited: true,
        onInvite: (_) async {},
        onCancelInvite: (_) async => cancelled = true,
      );
      await tester.tap(find.byType(InkWell).first);
      expect(cancelled, true);
    });
  });
}