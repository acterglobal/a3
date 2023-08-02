import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final spaceHierarchyProvider = StateNotifierProvider.autoDispose.family<
    SpaceHierarchyNotifier,
    PagedState<Next?, ffi.SpaceHierarchyRoomInfo>,
    ffi.SpaceRelations>((ref, spaceRel) {
  return SpaceHierarchyNotifier(spaceRel);
});
