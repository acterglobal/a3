import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// FIXME: if anyone has some idea, how we can reused the same internal pager and
// filter only a single results list, rather than fetching two and building two,
// let us know!

/// Only spaces coming from this paginating spaces provider
final spaceHierarchyProvider = StateNotifierProvider.autoDispose.family<
    SpaceHierarchyNotifier,
    PagedState<Next?, ffi.SpaceHierarchyRoomInfo>,
    ffi.SpaceRelations>((ref, spaceRel) {
  return SpaceHierarchyNotifier(
    spaceRel,
    (elem) => elem.isSpace(),
  );
});

/// Only chats coming from this paginating related space hierarchy provider
final chatHierarchyProvider = StateNotifierProvider.autoDispose.family<
    SpaceHierarchyNotifier,
    PagedState<Next?, ffi.SpaceHierarchyRoomInfo>,
    ffi.SpaceRelations>((ref, spaceRel) {
  return SpaceHierarchyNotifier(
    spaceRel,
    (elem) => !elem.isSpace(),
  );
});
