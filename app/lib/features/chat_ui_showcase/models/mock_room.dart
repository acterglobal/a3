import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockOptionString extends Mock implements OptionString {
  final String? mockText;

  MockOptionString({this.mockText});

  @override
  String? text() => mockText;
}

class MockRoom extends Mock implements Room {
  final String mockRoomId;
  final String mockDisplayName;
  final String mockNotificationMode;

  MockRoom({
    required this.mockRoomId,
    required this.mockDisplayName,
    this.mockNotificationMode = 'default',
  });

  @override
  String roomIdStr() => mockRoomId;

  @override
  Future<OptionString> displayName() =>
      Future.value(MockOptionString(mockText: mockDisplayName));

  @override
  Future<String> notificationMode() => Future.value(mockNotificationMode);
}
