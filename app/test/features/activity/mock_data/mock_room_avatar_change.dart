import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomAvatarContent extends Mock implements RoomAvatarContent {
  final String? mockUrlChange;
  final String? mockUrlNewVal;
  final String? mockUrlOldVal;

  MockRoomAvatarContent({
    this.mockUrlChange,
    this.mockUrlNewVal,
    this.mockUrlOldVal,
  });

  @override
  String? urlChange() => mockUrlChange ?? 'Changed';

  @override
  String? urlNewVal() => mockUrlNewVal ?? 'mock-url-new-val';

  @override
  String? urlOldVal() => mockUrlOldVal ?? 'mock-url-old-val';
}
