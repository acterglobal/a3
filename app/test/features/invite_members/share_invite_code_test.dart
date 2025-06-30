import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/invite_members/pages/share_invite_code.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/share/widgets/external_share_options.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../helpers/test_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testRoomId = 'test_room_id';
  const testInviteCode = 'TEST123';
  const testRoomName = 'Test Room';
  const testUserName = 'Test User';
  const testUserId = 'test_user_id';

  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    bool isFullPageMode = true,
    String roomName = testRoomName,
    String userName = testUserName,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        roomDisplayNameProvider(testRoomId).overrideWith((_) => roomName),
        accountDisplayNameProvider.overrideWith((_) => userName),
        myUserIdStrProvider.overrideWith((_) => testUserId),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: ShareInviteCode(
          roomId: testRoomId,
          inviteCode: testInviteCode,
          isFullPageMode: isFullPageMode,
        ),
      ),
    );
    await tester.pump();
  }

  group('ShareInviteCode Widget Tests', () {
    testWidgets('renders correctly with isFullPageMode true', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester);

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(ShareInviteCode));
      final lang = L10n.of(context);

      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(lang.shareInviteCode), findsOneWidget);

      // Verify message content
      expect(find.text(lang.message), findsOneWidget);

      // Verify share options
      expect(find.byType(ExternalShareOptions), findsOneWidget);

      // Verify done button
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text(lang.done), findsOneWidget);
    });

    testWidgets('renders correctly with isFullPageMode false', (WidgetTester tester) async {    
      await createWidgetUnderTest(
        tester: tester,
        isFullPageMode: false,
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(ShareInviteCode));
      final lang = L10n.of(context);

      // Verify app bar is not present
      expect(find.byType(AppBar), findsNothing);

      // Verify done button 
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text(lang.done), findsOneWidget);
    });

    testWidgets('displays correct share content', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester);

      // Verify the share content contains all required information
      final expectedQrContent = 'acter:i/acter.global/$testInviteCode?roomDisplayName=$testRoomName&userId=$testUserId&userDisplayName=$testUserName';
      
      // Find the ExternalShareOptions widget and verify its properties
      final externalShareOptions = tester.widget<ExternalShareOptions>(
        find.byType(ExternalShareOptions),
      );
      
      expect(externalShareOptions.qrContent, expectedQrContent);
    });

    testWidgets('handles missing room name gracefully', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        roomName: '',
      );

      // Verify the widget still renders without crashing
      expect(find.byType(ShareInviteCode), findsOneWidget);
      expect(find.byType(ExternalShareOptions), findsOneWidget);
    });

    testWidgets('handles missing user name gracefully', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        userName: '',
      );

      // Verify the widget still renders without crashing
      expect(find.byType(ShareInviteCode), findsOneWidget);
      expect(find.byType(ExternalShareOptions), findsOneWidget);
    });
  });
}