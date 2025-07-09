// Mock classes
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

import '../features/space/pages/space_details_page_test.dart';

class MockInvitation extends Mock implements RoomInvitation {}

class MockUserProfile extends Mock implements UserProfile {
  final String _userId;
  final String _displayName;
  final bool _hasAvatar;
  final List<String> _sharedRooms;

  MockUserProfile({
    String? userId,
    String? displayName,
    bool? hasAvatar,
    List<String>? sharedRooms,
  })  : _userId = userId ?? 'test_user_id',
        _displayName = displayName ?? 'Test User',
        _hasAvatar = hasAvatar ?? false,
        _sharedRooms = sharedRooms ?? [];

  @override
  UserId userId() {
    return MockUserId(_userId);
  }

  @override
  String displayName() {
    return _displayName;
  }

  @override
  bool hasAvatar() {
    return _hasAvatar;
  }

  @override
  Future<OptionBuffer> getAvatar([ThumbnailSize? thumbSize]) async {
    return MockOptionBuffer();
  }

  @override
  FfiListFfiString sharedRooms() {
    return MockFfiListFfiString(items: _sharedRooms);
  }

  @override
  void drop() {}
}

class MockUserId extends Mock implements UserId {
  final String _id;

  MockUserId(this._id);

  @override
  String toString() => _id;
}

class MockOptionBuffer extends Mock implements OptionBuffer {
  bool isSome() => false;

  bool isNone() => true;
}

class MockOptionString extends Mock implements OptionString {
  final String? _text;

  MockOptionString(this._text);

  @override
  String? text() => _text;
}
