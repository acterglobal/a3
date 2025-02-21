import 'dart:typed_data';

import 'package:acter/features/activities/widgets/invitation_widget.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mock_room_providers.dart';
import '../../helpers/test_util.dart';

// Mock classes
class MockInvitation extends Mock implements Invitation {}

class MockUserProfile extends Mock implements UserProfile {}

class MockOptionBuffer extends Mock implements OptionBuffer {}

class MockOptionString extends Mock implements OptionString {
  final String? _text;

  MockOptionString(this._text);

  @override
  String? text() => _text;
}

void main() {
  late MockInvitation mockInvitation;
  late MockRoom mockRoom;
  late MockUserProfile mockSenderProfile;
  late MockOptionBuffer mockOptionBuffer;

  setUp(() {
    mockInvitation = MockInvitation();
    mockRoom = MockRoom();
    mockSenderProfile = MockUserProfile();
    mockOptionBuffer = MockOptionBuffer();

    // Setup basic mocks
    when(() => mockInvitation.room()).thenReturn(mockRoom);
    when(() => mockInvitation.roomIdStr()).thenReturn('!room:example.com');
    when(() => mockInvitation.senderIdStr()).thenReturn('@alice:example.com');
    when(() => mockInvitation.isDm()).thenReturn(false);
    when(() => mockRoom.isSpace()).thenReturn(true);
    when(() => mockRoom.displayName())
        .thenAnswer((_) => Future.value(MockOptionString('Test Room default')));

    // Add room avatar mock
    when(() => mockRoom.avatar(null))
        .thenAnswer((_) => Future.value(mockOptionBuffer));

    // Add sender profile mocks
    when(() => mockInvitation.senderProfile()).thenReturn(mockSenderProfile);
    when(() => mockSenderProfile.displayName()).thenReturn('Alice DM');
    when(() => mockSenderProfile.hasAvatar()).thenReturn(false);
    when(() => mockSenderProfile.getAvatar(null))
        .thenAnswer((_) => Future.value(mockOptionBuffer));
  });

  Future<void> buildTestWidget(
    WidgetTester tester, {
    AvatarInfo? avatarInfo,
  }) async {
    return tester.pumpProviderWidget(
      overrides: [
        invitationUserProfileProvider.overrideWith((ref, invitation) async {
          return avatarInfo;
        }),
      ],
      child: InvitationWidget(invitation: mockInvitation),
    );
  }

  group('InvitationWidget', () {
    testWidgets('renders with default avatar info', (tester) async {
      await buildTestWidget(
        tester,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.text('Test Room default'), findsOneWidget);
    });
    testWidgets('renders with custom avatar info', (tester) async {
      final customAvatarInfo = AvatarInfo(
        uniqueId: '@custom:example.com',
        displayName: 'custom',
      );

      await buildTestWidget(
        tester,
        avatarInfo: customAvatarInfo,
      );
      await tester.pumpAndSettle();

      // Look for the custom avatar info's display name
      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.textContaining('custom'), findsOneWidget);
    });

    testWidgets('renders DM invitation correctly', (tester) async {
      // Setup for DM invitation
      when(() => mockInvitation.isDm()).thenReturn(true);
      when(() => mockSenderProfile.displayName()).thenReturn('Alice DM');

      final dmAvatarInfo = AvatarInfo(
        uniqueId: '@alice:example.com',
        displayName: 'Alice DM',
      );

      await buildTestWidget(
        tester,
        avatarInfo: dmAvatarInfo,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.textContaining('Alice DM'), findsOneWidget);
    });

    testWidgets('renders with custom avatar image', (tester) async {
      final avatarBytes = Uint8List.fromList(List.generate(10, (i) => i));
      final avatarInfo = AvatarInfo(
        uniqueId: '@alice:example.com',
        displayName: 'Alice',
        avatar: MemoryImage(avatarBytes),
      );

      await buildTestWidget(
        tester,
        avatarInfo: avatarInfo,
      );

      await tester.pumpAndSettle();

      expect(find.byType(ActerAvatar), findsOneWidget);
    });
  });
}
