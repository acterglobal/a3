import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockRoomId extends Mock implements RoomId {
  final String inner;

  MockRoomId(this.inner);

  @override
  String toString() => inner;
}

class MockUserId extends Mock implements UserId {
  final String inner;

  MockUserId(this.inner);

  @override
  String toString() => inner;
}

class MockEventId extends Mock implements EventId {
  final String inner;

  MockEventId(this.inner);

  @override
  String toString() => inner;
}

class MockFfiListObjRef extends Mock implements FfiListObjRef {
  final List<ObjRef> items;

  MockFfiListObjRef({this.items = const []});

  @override
  List<ObjRef> toList({bool growable = false}) => items;
}
