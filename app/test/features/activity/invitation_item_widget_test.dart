import 'dart:typed_data';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/invitations/widgets/invitation_item_widget.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mock_a3sdk.dart';
import '../../helpers/mock_client_provider.dart';
import '../../helpers/mock_invites.dart';
import '../../helpers/mock_room_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Account;

class MockAccount extends Mock implements Account {}

class MockRef extends Mock implements Ref {
  @override
  void invalidate(ProviderOrFamily provider) {}
}

void main() {
  late MockInvitation mockInvitation;
  late MockRoom mockRoom;
  late MockUserProfile mockSenderProfile;
  late MockOptionBuffer mockOptionBuffer;
  late MockClient mockClient;
  late MockAccount mockAccount;

  setUp(() {
    mockInvitation = MockInvitation();
    mockRoom = MockRoom();
    mockSenderProfile = MockUserProfile();
    mockOptionBuffer = MockOptionBuffer();
    mockClient = MockClient();
    mockAccount = MockAccount();

    // Setup basic mocks
    when(() => mockInvitation.room()).thenReturn(mockRoom);
    when(() => mockInvitation.roomIdStr()).thenReturn('!room:example.com');
    when(() => mockInvitation.senderIdStr()).thenReturn('@alice:example.com');
    when(() => mockInvitation.isDm()).thenReturn(false);
    when(() => mockRoom.isSpace()).thenReturn(true);
    when(
      () => mockRoom.displayName(),
    ).thenAnswer((_) => Future.value(MockOptionString('Test Room default')));

    // Add room avatar mock
    when(
      () => mockRoom.avatar(null),
    ).thenAnswer((_) => Future.value(mockOptionBuffer));

    // Add sender profile mocks
    when(() => mockInvitation.senderProfile()).thenReturn(mockSenderProfile);
    when(() => mockSenderProfile.displayName()).thenReturn('Alice DM');
    when(() => mockSenderProfile.hasAvatar()).thenReturn(false);
    when(
      () => mockSenderProfile.getAvatar(null),
    ).thenAnswer((_) => Future.value(mockOptionBuffer));
  });

  Future<void> buildTestWidget(
    WidgetTester tester, {
    AvatarInfo? avatarInfo,
  }) async {
    final builder = EasyLoading.init();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder:
            (context, child) => builder(
              context,
              Overlay(
                initialEntries: [
                  OverlayEntry(builder: (context) => Scaffold(body: child)),
                ],
              ),
            ),
        home: ProviderScope(
          overrides: [
            invitationUserProfileProvider.overrideWith((ref, invitation) async {
              return avatarInfo;
            }),
            accountProvider.overrideWith((ref) => mockAccount),
            clientProvider.overrideWith(
              () => MockClientNotifier(client: mockClient),
            ),
          ],
          child: Scaffold(
            body: InvitationItemWidget(invitation: mockInvitation),
          ),
        ),
      ),
    );
    // Add an extra pump to ensure localizations are loaded
    await tester.pumpAndSettle();
  }

  group('InvitationWidget', () {
    testWidgets('renders with default avatar info', (tester) async {
      await buildTestWidget(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.text('Test Room default'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.byType(MenuAnchor), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });
    testWidgets('renders with custom avatar info', (tester) async {
      final customAvatarInfo = AvatarInfo(
        uniqueId: '@custom:example.com',
        displayName: 'custom',
      );

      await buildTestWidget(tester, avatarInfo: customAvatarInfo);
      await tester.pumpAndSettle();

      // Look for the custom avatar info's display name
      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.textContaining('custom'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.byType(MenuAnchor), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('renders with custom avatar image', (tester) async {
      final avatarBytes = Uint8List.fromList(List.generate(10, (i) => i));
      final avatarInfo = AvatarInfo(
        uniqueId: '@alice:example.com',
        displayName: 'Alice',
        avatar: MemoryImage(avatarBytes),
      );

      await buildTestWidget(tester, avatarInfo: avatarInfo);

      await tester.pumpAndSettle();

      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.byType(MenuAnchor), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('renders Space invitation correctly', (tester) async {
      // Space is already default in setUp (mockRoom.isSpace() returns true)
      when(() => mockRoom.isSpace()).thenReturn(true);
      when(() => mockSenderProfile.displayName()).thenReturn('Space Inviter');
      when(
        () => mockRoom.displayName(),
      ).thenAnswer((_) => Future.value(MockOptionString('Test Space')));

      final avatarInfo = AvatarInfo(
        uniqueId: '@spaceinviter:example.com',
        displayName: 'Space Inviter',
      );

      await buildTestWidget(tester, avatarInfo: avatarInfo);
      await tester.pumpAndSettle();

      // Get the localized string from the context
      final context = tester.element(find.byType(InvitationItemWidget));
      final l10n = L10n.of(context);

      expect(find.text(l10n.invitationToSpace), findsOneWidget);
      expect(find.text('Space Inviter'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('renders Chat invitation correctly', (tester) async {
      // Setup for regular chat room
      when(() => mockRoom.isSpace()).thenReturn(false);
      when(() => mockSenderProfile.displayName()).thenReturn('Chat Inviter');
      when(
        () => mockRoom.displayName(),
      ).thenAnswer((_) => Future.value(MockOptionString('Test Chat')));

      final avatarInfo = AvatarInfo(
        uniqueId: '@chatinviter:example.com',
        displayName: 'Chat Inviter',
      );

      await buildTestWidget(tester, avatarInfo: avatarInfo);
      await tester.pumpAndSettle();

      // Get the localized string from the context
      final context = tester.element(find.byType(InvitationItemWidget));
      final l10n = L10n.of(context);
      expect(find.text(l10n.invitationToChat), findsOneWidget);
      expect(find.text('Chat Inviter'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('renders DM invitation with fallback to sender ID', (
      tester,
    ) async {
      // Setup for DM without profile info
      when(() => mockInvitation.isDm()).thenReturn(true);
      when(() => mockRoom.displayName()).thenAnswer(
        (_) => Future.value(MockOptionString(null)),
      ); // No room name for DM

      await buildTestWidget(tester, avatarInfo: null);
      await tester.pumpAndSettle();

      expect(find.text('Wants to start a DM with you'), findsOneWidget);
      expect(find.text('@alice:example.com'), findsOneWidget);
      expect(find.text('Start DM'), findsOneWidget);
    });

    group('Invitation Actions', () {
      // FIXME: fails due to routing failures
      // testWidgets('accepts invitation successfully', (tester) async {

      //   when(() => mockInvitation.accept()).thenAnswer((_) async => true);
      //   when(() => mockRoom.isSpace()).thenReturn(true);
      //   when(() => mockInvitation.isDm()).thenReturn(false);
      //   when(
      //     () => mockClient.waitForRoom(any(), any()),
      //   ).thenAnswer((_) async => false);

      //   await buildTestWidget(tester);
      //   await tester.pumpAndSettle();

      //   final context = tester.element(find.byType(InvitationItemWidget));

      //   // Tap accept button
      //   await tester.tap(find.text(L10n.of(context).accept));
      //   await tester.pumpAndSettle();

      //   // Verify accept was called
      //   verify(() => mockInvitation.accept()).called(1);

      //   // ensure the timers ended
      //   await tester.pump(const Duration(seconds: 4));
      // });

      testWidgets('handles accept invitation failure', (tester) async {
        when(
          () => mockInvitation.accept(),
        ).thenThrow(Exception('Accept failed'));

        await buildTestWidget(tester);
        await tester.pumpAndSettle();

        // Tap accept button
        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        // Verify error toast is shown
        expect(find.textContaining('failed'), findsOneWidget);

        // ensure the timers ended
        await tester.pump(const Duration(seconds: 4));
      });

      testWidgets('declines invitation through menu', (tester) async {
        when(() => mockInvitation.reject()).thenAnswer((_) async => true);
        final mockAccount = MockAccount();
        when(() => mockAccount.ignoreUser(any())).thenAnswer((_) async => true);

        await buildTestWidget(tester);
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(MenuAnchor));

        // Open decline menu
        await tester.tap(find.text(L10n.of(context).decline));
        await tester.pumpAndSettle();

        // Tap decline option
        await tester.tap(find.text(L10n.of(context).decline).last);
        await tester.pumpAndSettle();

        // Verify reject was called
        verify(() => mockInvitation.reject()).called(1);
        verifyNever(() => mockInvitation.accept());
        verifyNever(() => mockAccount.ignoreUser(any()));

        // ensure the timers ended
        await tester.pump(const Duration(seconds: 4));
      });

      testWidgets('declines and blocks invitation through menu', (
        tester,
      ) async {
        when(() => mockInvitation.reject()).thenAnswer((_) async => true);
        when(() => mockAccount.ignoreUser(any())).thenAnswer((_) async => true);

        await buildTestWidget(tester);
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(MenuAnchor));

        // Open decline menu
        await tester.tap(find.text(L10n.of(context).decline));
        await tester.pumpAndSettle();

        // Tap decline and block option
        await tester.tap(find.text(L10n.of(context).declineAndBlock));
        await tester.pumpAndSettle();

        // Verify reject was called
        verify(() => mockInvitation.reject()).called(1);
        verifyNever(() => mockInvitation.accept());

        // Verify block was called with correct user ID
        verify(() => mockAccount.ignoreUser('@alice:example.com')).called(1);

        // ensure the timers ended
        await tester.pump(const Duration(seconds: 4));
      });

      testWidgets('handles decline invitation failure', (tester) async {
        when(
          () => mockInvitation.reject(),
        ).thenThrow(Exception('Reject failed'));

        await buildTestWidget(tester);
        await tester.pumpAndSettle();

        // Open decline menu
        final context = tester.element(find.byType(MenuAnchor));
        await tester.tap(find.text(L10n.of(context).decline));
        await tester.pumpAndSettle();

        // Tap decline option
        await tester.tap(find.text(L10n.of(context).decline).last);
        await tester.pumpAndSettle();

        // Verify error toast is shown
        expect(find.textContaining('failed'), findsOneWidget);

        // ensure the timers ended
        await tester.pump(const Duration(seconds: 4));
      });
    });
  });
}
