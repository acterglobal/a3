import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockCommentsManager extends Mock implements CommentsManager {
  final String fakeRoomId;

  MockCommentsManager({required this.fakeRoomId});

  @override
  String roomIdStr() => fakeRoomId;
}
