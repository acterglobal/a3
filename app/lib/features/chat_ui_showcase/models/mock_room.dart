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
  final Future<OptionString> mockDisplayName;

  MockRoom({required this.mockRoomId, required this.mockDisplayName});

  @override
  String roomIdStr() => mockRoomId;

  @override
  Future<OptionString> displayName() => mockDisplayName;
}
