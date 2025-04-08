import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockOptionString extends Mock implements OptionString {
  final String? _text;

  MockOptionString(this._text);

  @override
  String? text() => _text;
}

class MockRoom extends Mock implements Room {
  final String? _mockRoomId;
  final Future<OptionString>? _mockDisplayName;

  MockRoom(this._mockRoomId, this._mockDisplayName);

  @override
  String roomIdStr() => _mockRoomId ?? 'room-id';

  @override
  Future<OptionString> displayName() =>
      _mockDisplayName ?? Future.value(MockOptionString('Room Name'));
}
