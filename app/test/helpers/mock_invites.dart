// Mock classes
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockInvitation extends Mock implements RoomInvitation {}

class MockUserProfile extends Mock implements UserProfile {}

class MockOptionBuffer extends Mock implements OptionBuffer {}

class MockOptionString extends Mock implements OptionString {
  final String? _text;

  MockOptionString(this._text);

  @override
  String? text() => _text;
}
