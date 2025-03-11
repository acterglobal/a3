import 'package:acter/features/settings/providers/notifiers/app_settings_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userAppSettingsProvider = AsyncNotifierProvider.autoDispose<
  UserAppSettingsNotifier,
  ActerUserAppSettings
>(() => UserAppSettingsNotifier());
