import 'package:acter/features/home/providers/client_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class AsyncSpaceProfileDataNotifier
    extends AutoDisposeFamilyAsyncNotifier<ProfileData, Space> {
  late Stream<void> _listener;
  Future<ProfileData> _getSpaceProfileData() async {
    final space = arg;
    final profile = space.getProfile();
    OptionText displayName = await profile.getDisplayName();
    final avatar = await profile.getAvatar();
    return ProfileData(displayName.text(), avatar.data());
  }

  @override
  Future<ProfileData> build(Space arg) async {
    final client = ref.watch(clientProvider)!;
    _listener = client.subscribeStream(arg.getRoomId().toString());
    _listener.forEach((_e) async {
      state = await AsyncValue.guard(() => _getSpaceProfileData());
    });
    return _getSpaceProfileData();
  }
}

class AsyncSpaceNotifier extends AutoDisposeFamilyAsyncNotifier<Space, String> {
  late Stream<void> _listener;
  Future<Space> _getSpace() async {
    final client = ref.watch(clientProvider)!;
    return await client.getSpace(arg); // this might throw internally
  }

  @override
  Future<Space> build(String arg) async {
    final client = ref.watch(clientProvider)!;
    _listener = client.subscribeStream(arg);
    _listener.forEach((_e) async {
      state = await AsyncValue.guard(() => _getSpace());
    });
    return _getSpace();
  }
}

class AsyncMaybeSpaceNotifier
    extends AutoDisposeFamilyAsyncNotifier<Space?, String> {
  late Stream<void> _listener;
  Future<Space?> _getSpace() async {
    final client = ref.watch(clientProvider)!;
    try {
      return await client.getSpace(arg);
    } catch (e) {
      // we sneakly suggest that means we don't have access.
      return null;
    }
  }

  @override
  Future<Space?> build(String arg) async {
    final client = ref.watch(clientProvider)!;
    _listener = client.subscribeStream(arg);
    _listener.forEach((_e) async {
      state = await AsyncValue.guard(() => _getSpace());
    });
    return _getSpace();
  }
}

class AsyncSpacesNotifier extends AutoDisposeAsyncNotifier<List<Space>> {
  late Stream<void> _listener;
  Future<List<Space>> _getSpaces() async {
    final client = ref.watch(clientProvider)!;
    final spaces = await client.spaces();
    return spaces.toList(); // this might throw internally
  }

  @override
  Future<List<Space>> build() async {
    final client = ref.watch(clientProvider)!;
    _listener = client.subscribeStream('SPACES');
    _listener.forEach((_e) async {
      state = await AsyncValue.guard(() => _getSpaces());
    });
    return _getSpaces();
  }
}
