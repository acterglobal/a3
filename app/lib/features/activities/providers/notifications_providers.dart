import 'package:acter/features/activities/providers/notifiers/notifications_list_notifier.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsListProvider = StateNotifierProvider.autoDispose<
    NotificationsListNotifier, PagedState<Next?, ffi.Notification>>((ref) {
  return NotificationsListNotifier(ref);
});
