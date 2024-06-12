import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchItemProfileData = FutureProvider.autoDispose
    .family<ProfileData, PublicSearchResultItem>((ref, publicSpace) async {
  final sdk = await ref.read(sdkProvider.future);
  final size = sdk.api.newThumbSize(48, 48);
  final avatar = await publicSpace.getAvatar(size);
  return ProfileData(
    publicSpace.name() ?? publicSpace.roomIdStr(),
    avatar.data(),
  );
});
