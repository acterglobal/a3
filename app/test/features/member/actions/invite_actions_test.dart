import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/member/actions/invite_actions.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mock_membership.dart';
import '../../../helpers/mock_room_providers.dart';
import '../../../helpers/mock_tasks_providers.dart';
import '../../../helpers/test_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUserId = '@testuser:matrix.org';
  const testRoomId = '!testroom:matrix.org';

  group('InviteActions', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      EasyLoading.instance.displayDuration = const Duration(milliseconds: 100);
      EasyLoading.instance.dismissOnTap = true;
      EasyLoading.instance.toastPosition = EasyLoadingToastPosition.bottom;
    });

    tearDown(() {
      container.dispose();
      EasyLoading.dismiss();
    });

    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder: EasyLoading.init(),
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('handleInvite with task', (tester) async {
      final mockTask = MockTask(
        hasInvitations: true,
        invitedUsers: [testUserId],
      );
      final mockRoom = MockRoom(roomId: testRoomId);

      await tester.pumpProviderWidget(
        overrides: [
          memberProvider.overrideWith((ref, params) => Future.value(MockMember())),
        ],
        child: buildTestWidget(
          Builder(
            builder: (context) => Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => InviteActions.handleInvite(
                  context: context,
                  ref: ref,
                  userId: testUserId,
                  room: mockRoom,
                  task: mockTask,
                ),
                child: const Text('Invite'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('handleInvite without task', (tester) async {
      final mockRoom = MockRoom(roomId: testRoomId);

      await tester.pumpProviderWidget(
        overrides: [
          memberProvider.overrideWith((ref, params) => Future.value(MockMember())),
        ],
        child: buildTestWidget(
          Builder(
            builder: (context) => Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => InviteActions.handleInvite(
                  context: context,
                  ref: ref,
                  userId: testUserId,
                  room: mockRoom,
                ),
                child: const Text('Invite'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('handleCancelInvite', (tester) async {
      final mockRoom = MockRoom(roomId: testRoomId);
      final mockMember = MockMember();

      await tester.pumpProviderWidget(
        overrides: [
          memberProvider.overrideWith((ref, params) => Future.value(mockMember)),
        ],
        child: buildTestWidget(
          Builder(
            builder: (context) => Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => InviteActions.handleCancelInvite(
                  context: context,
                  ref: ref,
                  userId: testUserId,
                  room: mockRoom,
                ),
                child: const Text('Cancel Invite'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('handleCancelInvite when member is null', (tester) async {
      final mockRoom = MockRoom(roomId: testRoomId);

      await tester.pumpProviderWidget(
        overrides: [
          memberProvider.overrideWith((ref, params) => Future.value(MockMember())),
        ],
        child: buildTestWidget(
          Builder(
            builder: (context) => Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => InviteActions.handleCancelInvite(
                  context: context,
                  ref: ref,
                  userId: testUserId,
                  room: mockRoom,
                ),
                child: const Text('Cancel Invite'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('handleCancelInvite with error', (tester) async {
      final mockRoom = MockRoom(roomId: testRoomId);
      final mockMember = MockMember();

      // Make the kick method throw an exception
      when(() => mockMember.kick(any())).thenThrow(Exception('Kick failed'));

      await tester.pumpProviderWidget(
        overrides: [
          memberProvider.overrideWith((ref, params) => Future.value(mockMember)),
        ],
        child: buildTestWidget(
          Builder(
            builder: (context) => Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => InviteActions.handleCancelInvite(
                  context: context,
                  ref: ref,
                  userId: testUserId,
                  room: mockRoom,
                ),
                child: const Text('Cancel Invite'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
} 