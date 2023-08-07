import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/providers/notifiers/space_hierarchy_notifier.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paginating of not yet joined children spaces
final remoteSpaceHierarchyProvider = StateNotifierProvider.autoDispose.family<
    FilteredSpaceHierarchyNotifier,
    PagedState<Next?, ffi.SpaceHierarchyRoomInfo>,
    SpaceRelationsOverview>((ref, spaceOverview) {
  final knownChildren =
      spaceOverview.knownSubspaces.map((e) => e.getRoomIdStr());
  return FilteredSpaceHierarchyNotifier(
    ref,
    spaceOverview.rel,
    (elem) => (elem.isSpace() && !knownChildren.contains(elem.roomIdStr())),
  );
});

/// Paginating of not yet joined children chats
final remoteChatHierarchyProvider = StateNotifierProvider.autoDispose.family<
    FilteredSpaceHierarchyNotifier,
    PagedState<Next?, ffi.SpaceHierarchyRoomInfo>,
    SpaceRelationsOverview>((ref, spaceOverview) {
  final knownChildren = spaceOverview.knownChats.map((e) => e.getRoomIdStr());
  return FilteredSpaceHierarchyNotifier(
    ref,
    spaceOverview.rel,
    (elem) => (!elem.isSpace() && !knownChildren.contains(elem.roomIdStr())),
  );
});
