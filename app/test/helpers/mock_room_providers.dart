import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mockito/mockito.dart';

class MockAsyncMaybeRoomNotifier extends FamilyAsyncNotifier<Room?, String>
    with Mock
    implements AsyncMaybeRoomNotifier {
  @override
  Future<Room?> build(arg) async {
    return null;
  }
}
