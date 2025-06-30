import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockRoom extends Mock implements Room {}

class MockOptionString extends Mock implements OptionString {
  final String? _text;

  MockOptionString(this._text);

  @override
  String? text() => _text;
}

class MockOptionBuffer extends Mock implements OptionBuffer {}

class MockUserProfile extends Mock implements UserProfile {}

class MockRoomInvitation extends Mock implements RoomInvitation {
  final String roomId;
  final String senderId;
  final String senderDisplayNameStr;
  final String roomDisplayNameStr;

  MockRoomInvitation({
    required this.roomId,
    required this.senderId,
    required this.senderDisplayNameStr,
    required this.roomDisplayNameStr,
  });

  @override
  String roomIdStr() => roomId;

  @override
  bool isDm() => false;

  @override
  MockRoom room() {
    final mockRoom = MockRoom();

    when(() => mockRoom.isSpace()).thenReturn(true);

    when(
      () => mockRoom.displayName(),
    ).thenAnswer((_) => Future.value(MockOptionString(roomDisplayNameStr)));

    // Add room avatar mock
    when(
      () => mockRoom.avatar(null),
    ).thenAnswer((_) => Future.value(MockOptionBuffer()));
    return mockRoom;
  }

  @override
  MockUserProfile? senderProfile() {
    final mockSenderProfile = MockUserProfile();
    when(
      () => mockSenderProfile.displayName(),
    ).thenReturn(senderDisplayNameStr);
    when(() => mockSenderProfile.hasAvatar()).thenReturn(false);
    when(
      () => mockSenderProfile.getAvatar(null),
    ).thenAnswer((_) => Future.value(MockOptionBuffer()));
    return mockSenderProfile;
  }

  @override
  String senderIdStr() => senderId;
}

List<MockRoomInvitation> generateMockInvitations(int count) =>
    List.generate(count, (index) {
      final mockInvitation = MockRoomInvitation(
        roomId: 'roomId$index',
        senderId: '@senderId$index:example.org',
        senderDisplayNameStr: 'senderDisplayName$index',
        roomDisplayNameStr: 'roomDisplayName$index',
      );
      when(
        () => mockInvitation.reject(),
      ).thenAnswer((_) => Future.value(index % 2 == 0));
      when(
        () => mockInvitation.accept(),
      ).thenAnswer((_) => Future.value(index % 2 == 0));
      return mockInvitation;
    });
