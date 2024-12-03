import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockRoom with Mock implements Room {}

class MockAsyncMaybeRoomNotifier extends FamilyAsyncNotifier<Room?, String>
    with Mock
    implements AsyncMaybeRoomNotifier {
  final Map<String, Room> items;

  MockAsyncMaybeRoomNotifier({this.items = const {}});

  @override
  Future<Room?> build(arg) async => items[arg];
}
