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
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Account, Room, UserProfile, OptionBuffer, OptionString, ThumbnailSize;

class MockAccount extends Mock implements Account {
  @override
  Future<bool> ignoreUser(String userId) async => true;
}

class MockRef extends Mock implements Ref {
  @override
  void invalidate(ProviderOrFamily provider) {}
}

class TestInvitation extends MockInvitation {
  final Room _room;
  final String _roomId;
  final String _senderId;
  final bool _isDm;
  final UserProfile _senderProfile;
  final bool _shouldFailAccept;
  final bool _shouldFailReject;

  TestInvitation({
    required Room room,
    String? roomId,
    String? senderId,
    bool? isDm,
    required UserProfile senderProfile,
    bool? shouldFailAccept,
    bool? shouldFailReject,
  })  : _room = room,
        _roomId = roomId ?? '!room:example.com',
        _senderId = senderId ?? '@alice:example.com',
        _isDm = isDm ?? false,
        _senderProfile = senderProfile,
        _shouldFailAccept = shouldFailAccept ?? false,
        _shouldFailReject = shouldFailReject ?? false;

  @override
  Room room() => _room;

  @override
  String roomIdStr() => _roomId;

  @override
  String senderIdStr() => _senderId;

  @override
  bool isDm() => _isDm;

  @override
  UserProfile senderProfile() => _senderProfile;

  @override
  Future<bool> accept() async {
    if (_shouldFailAccept) {
      throw Exception('Accept failed');
    }
    return true;
  }

  @override
  Future<bool> reject() async {
    if (_shouldFailReject) {
      throw Exception('Reject failed');
    }
    return true;
  }
}

class TestRoom extends MockRoom {
  final bool _isSpace;
  final String _displayName;
  final bool _hasAvatar;
  final OptionBuffer? _avatar;

  TestRoom({
    bool? isSpace,
    String? displayName,
    bool? hasAvatar,
    OptionBuffer? avatar,
  })  : _isSpace = isSpace ?? true,
        _displayName = displayName ?? 'Test Room default',
        _hasAvatar = hasAvatar ?? false,
        _avatar = avatar;

  @override
  bool isSpace() => _isSpace;

  @override
  Future<OptionString> displayName() async => MockOptionString(_displayName);

  @override
  bool hasAvatar() => _hasAvatar;

  @override
  Future<OptionBuffer> avatar([ThumbnailSize? size]) async => _avatar ?? MockOptionBuffer();
}

class TestUserProfile extends MockUserProfile {
  final String _displayName;
  final bool _hasAvatar;
  final OptionBuffer? _avatar;

  TestUserProfile({
    String? displayName,
    bool? hasAvatar,
    OptionBuffer? avatar,
  })  : _displayName = displayName ?? 'Test User',
        _hasAvatar = hasAvatar ?? false,
        _avatar = avatar;

  @override
  String displayName() => _displayName;

  @override
  bool hasAvatar() => _hasAvatar;

  @override
  Future<OptionBuffer> getAvatar([ThumbnailSize? size]) async => _avatar ?? MockOptionBuffer();
}

void main() {
  late TestInvitation testInvitation;
  late TestRoom testRoom;
  late TestUserProfile testSenderProfile;
  late MockClient mockClient;
  late MockAccount mockAccount;

  setUpAll(() {
    registerFallbackValue(MockOptionString(''));
    registerFallbackValue(MockOptionBuffer());
  });

  setUp(() {
    testSenderProfile = TestUserProfile();
    testRoom = TestRoom();
    testInvitation = TestInvitation(
      room: testRoom,
      senderProfile: testSenderProfile,
    );
    mockClient = MockClient();
    mockAccount = MockAccount();
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
        builder: (context, child) => builder(
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
            body: InvitationItemWidget(invitation: testInvitation),
          ),
        ),
      ),
    );
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
      testRoom = TestRoom(
        isSpace: true,
        displayName: 'Test Space',
      );
      testSenderProfile = TestUserProfile(
        displayName: 'Space Inviter',
      );
      testInvitation = TestInvitation(
        room: testRoom,
        senderProfile: testSenderProfile,
      );

      final avatarInfo = AvatarInfo(
        uniqueId: '@spaceinviter:example.com',
        displayName: 'Space Inviter',
      );

      await buildTestWidget(tester, avatarInfo: avatarInfo);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(InvitationItemWidget));
      final l10n = L10n.of(context);

      expect(find.text(l10n.invitationToSpace), findsOneWidget);
      expect(find.text('Space Inviter'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('renders Chat invitation correctly', (tester) async {
      testRoom = TestRoom(
        isSpace: false,
        displayName: 'Test Chat',
      );
      testSenderProfile = TestUserProfile(
        displayName: 'Chat Inviter',
      );
      testInvitation = TestInvitation(
        room: testRoom,
        senderProfile: testSenderProfile,
      );

      final avatarInfo = AvatarInfo(
        uniqueId: '@chatinviter:example.com',
        displayName: 'Chat Inviter',
      );

      await buildTestWidget(tester, avatarInfo: avatarInfo);
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(InvitationItemWidget));
      final l10n = L10n.of(context);
      expect(find.text(l10n.invitationToChat), findsOneWidget);
      expect(find.text('Chat Inviter'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
    });

    testWidgets('renders DM invitation with fallback to sender ID', (tester) async {
      testRoom = TestRoom(
        displayName: '',
      );
      testInvitation = TestInvitation(
        room: testRoom,
        senderProfile: testSenderProfile,
        isDm: true,
      );

      await buildTestWidget(tester, avatarInfo: null);
      await tester.pumpAndSettle();

      expect(find.text('Wants to start a DM with you'), findsOneWidget);
      expect(find.text('@alice:example.com'), findsOneWidget);
      expect(find.text('Start DM'), findsOneWidget);
    });

    group('Invitation Actions', () {
      testWidgets('handles accept invitation failure', (tester) async {
        testInvitation = TestInvitation(
          room: testRoom,
          senderProfile: testSenderProfile,
          shouldFailAccept: true,
        );

        await buildTestWidget(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Accept'));
        await tester.pumpAndSettle();

        expect(find.textContaining('failed'), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
      });

      testWidgets('declines invitation through menu', (tester) async {
        await buildTestWidget(tester);
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(MenuAnchor));

        await tester.tap(find.text(L10n.of(context).decline));
        await tester.pumpAndSettle();

        await tester.tap(find.text(L10n.of(context).decline).last);
        await tester.pumpAndSettle();

        await tester.pump(const Duration(seconds: 4));
      });

      testWidgets('declines and blocks invitation through menu', (tester) async {
        await buildTestWidget(tester);
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(MenuAnchor));

        await tester.tap(find.text(L10n.of(context).decline));
        await tester.pumpAndSettle();

        await tester.tap(find.text(L10n.of(context).declineAndBlock));
        await tester.pumpAndSettle();

        await tester.pump(const Duration(seconds: 4));
      });

      testWidgets('handles decline invitation failure', (tester) async {
        testInvitation = TestInvitation(
          room: testRoom,
          senderProfile: testSenderProfile,
          shouldFailReject: true,
        );

        await buildTestWidget(tester);
        await tester.pumpAndSettle();

        final context = tester.element(find.byType(MenuAnchor));
        await tester.tap(find.text(L10n.of(context).decline));
        await tester.pumpAndSettle();

        await tester.tap(find.text(L10n.of(context).decline).last);
        await tester.pumpAndSettle();

        expect(find.textContaining('failed'), findsOneWidget);
        await tester.pump(const Duration(seconds: 4));
      });
    });
  });
}
