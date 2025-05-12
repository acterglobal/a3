import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomNameContent extends Mock implements RoomNameContent {
  final String? mockChange;
  final String mockNewVal;
  final String? mockOldVal;

  MockRoomNameContent({
    this.mockChange,
    required this.mockNewVal,
    this.mockOldVal,
  });

  @override
  String? change() => mockChange ?? 'Changed';

  @override
  String newVal() => mockNewVal;

  @override
  String? oldVal() => mockOldVal ?? 'mock-old-val';
}
