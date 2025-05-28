import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/invite_members/pages/share_invite_code.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/share/widgets/external_share_options.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';

import '../../helpers/test_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareInviteCode Widget Tests', () {
    const testRoomId = 'test_room_id';
    const testInviteCode = 'TEST123';
    const testRoomName = 'Test Room';
    const testUserName = 'Test User';
    const testUserId = 'test_user_id';

    testWidgets('renders correctly with isFullPageMode true', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider(testRoomId).overrideWith((_) => testRoomName),
          accountDisplayNameProvider.overrideWith((_) => testUserName),
          myUserIdStrProvider.overrideWith((_) => testUserId),
        ],
        child: const ShareInviteCode(
          roomId: testRoomId,
          inviteCode: testInviteCode,
          isFullPageMode: true,
        ),
      );

      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Share Invite Code'), findsOneWidget);

      // Verify message content
      expect(find.text('Message'), findsOneWidget);

      // Verify share options
      expect(find.byType(ExternalShareOptions), findsOneWidget);

      // Verify done button
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('renders correctly with isFullPageMode false', (WidgetTester tester) async {    
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider(testRoomId).overrideWith((_) => testRoomName),
          accountDisplayNameProvider.overrideWith((_) => testUserName),
          myUserIdStrProvider.overrideWith((_) => testUserId),
        ],
        child: ShareInviteCode(
          roomId: testRoomId,
          inviteCode: testInviteCode,
          isFullPageMode: false,
        ),
      );

      // Verify app bar is not present
      expect(find.byType(AppBar), findsNothing);

      // Verify done button 
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('displays correct share content', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider(testRoomId).overrideWith((_) => testRoomName),
          accountDisplayNameProvider.overrideWith((_) => testUserName),
          myUserIdStrProvider.overrideWith((_) => testUserId),
        ],
        child: const ShareInviteCode(
          roomId: testRoomId,
          inviteCode: testInviteCode,
        ),
      );

      // Verify the share content contains all required information
      final expectedQrContent = 'acter:i/acter.global/$testInviteCode?roomDisplayName=$testRoomName&userId=$testUserId&userDisplayName=$testUserName';
      
      // Find the ExternalShareOptions widget and verify its properties
      final externalShareOptions = tester.widget<ExternalShareOptions>(
        find.byType(ExternalShareOptions),
      );
      
      expect(externalShareOptions.qrContent, expectedQrContent);
    });

    testWidgets('handles missing room name gracefully', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider(testRoomId).overrideWith((_) => ''),
          accountDisplayNameProvider.overrideWith((_) => testUserName),
          myUserIdStrProvider.overrideWith((_) => testUserId),
        ],
        child: const ShareInviteCode(
          roomId: testRoomId,
          inviteCode: testInviteCode,
        ),
      );

      // Verify the widget still renders without crashing
      expect(find.byType(ShareInviteCode), findsOneWidget);
      expect(find.byType(ExternalShareOptions), findsOneWidget);
    });

    testWidgets('handles missing user name gracefully', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider(testRoomId).overrideWith((_) => testRoomName),
          accountDisplayNameProvider.overrideWith((_) => ''),
          myUserIdStrProvider.overrideWith((_) => testUserId),
        ],
        child: const ShareInviteCode(
          roomId: testRoomId,
          inviteCode: testInviteCode,
        ),
      );

      // Verify the widget still renders without crashing
      expect(find.byType(ShareInviteCode), findsOneWidget);
      expect(find.byType(ExternalShareOptions), findsOneWidget);
    });
  });
}