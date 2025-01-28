import 'package:acter/features/room/providers/notifiers/room_user_settings_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final roomUserSettingsProvider = AsyncNotifierProvider.autoDispose
    .family<AsyncRoomUserSettingsNotifier, UserRoomSettings, String>(
  () => AsyncRoomUserSettingsNotifier(),
);
