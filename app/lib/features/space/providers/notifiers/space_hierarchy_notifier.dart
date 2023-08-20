import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'dart:async';

class Next {
  final bool isStart;
  final String? next;

  const Next({this.isStart = false, this.next});
}

/// True or False whether this item matches the required filter;
typedef FilterFn = bool Function(ffi.SpaceHierarchyRoomInfo element);

class SpaceHierarchyListState
    extends PagedState<Next?, ffi.SpaceHierarchyRoomInfo> {
  // We can extends [PagedState] to add custom parameters to our state

  const SpaceHierarchyListState({
    List<ffi.SpaceHierarchyRoomInfo>? records,
    String? error,
    Next? nextPageKey = const Next(isStart: true),
    List<Next?>? previousPageKeys,
  }) : super(records: records, error: error, nextPageKey: nextPageKey);

  SpaceHierarchyListState filtered(FilterFn filter) {
    return copyWith(
      records: (records ?? []).where(filter).toList(),
    );
  }

  @override
  SpaceHierarchyListState copyWith({
    List<ffi.SpaceHierarchyRoomInfo>? records,
    dynamic error,
    dynamic nextPageKey,
    List<Next?>? previousPageKeys,
  }) {
    final sup = super.copyWith(
      records: records,
      error: error,
      nextPageKey: nextPageKey,
      previousPageKeys: previousPageKeys,
    );
    return SpaceHierarchyListState(
      records: sup.records,
      error: sup.error,
      nextPageKey: sup.nextPageKey,
      previousPageKeys: sup.previousPageKeys,
    );
  }

  SpaceHierarchyListState copyWithFilter(FilterFn filter) {
    return copyWith(records: (records ?? []).where(filter).toList());
  }
}

class SpaceHierarchyNotifier extends StateNotifier<SpaceHierarchyListState>
    with
        PagedNotifierMixin<Next?, ffi.SpaceHierarchyRoomInfo,
            SpaceHierarchyListState> {
  final ffi.SpaceRelations spaceRel;

  SpaceHierarchyNotifier(this.spaceRel)
      : super(const SpaceHierarchyListState());

  @override
  Future<List<ffi.SpaceHierarchyRoomInfo>?> load(Next? page, int limit) async {
    if (page == null) {
      return null;
    }

    final pageReq = page.next ?? '';
    try {
      final res = await spaceRel.queryHierarchy(pageReq);
      // the current space is also returned as part of the response
      // filter that out:
      final myId = spaceRel.roomIdStr();
      final entries =
          (await res.rooms()).where((x) => x.roomIdStr() != myId).toList();
      final next = res.nextBatch();
      Next? finalPageKey;
      if (next != null) {
        // we are not at the end
        finalPageKey = Next(next: next);
      }
      state = state.copyWith(
        records: page.isStart
            ? [...entries]
            : [...(state.records ?? []), ...entries],
        nextPageKey: finalPageKey,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }

    return null;
  }
}

// Only spaces coming from this paginating spaces provider
final fullSpaceHierarchyProvider = StateNotifierProvider.family<
    SpaceHierarchyNotifier,
    PagedState<Next?, ffi.SpaceHierarchyRoomInfo>,
    ffi.SpaceRelations>((ref, spaceRel) {
  return SpaceHierarchyNotifier(
    spaceRel,
  );
});

class FilteredSpaceHierarchyNotifier
    extends StateNotifier<SpaceHierarchyListState>
    with
        PagedNotifierMixin<Next?, ffi.SpaceHierarchyRoomInfo,
            SpaceHierarchyListState> {
  final Ref ref;
  final ffi.SpaceRelations spaceRel;
  final FilterFn filter;
  late Function listener;

  FilteredSpaceHierarchyNotifier(this.ref, this.spaceRel, this.filter)
      : super(const SpaceHierarchyListState()) {
    final notifier = ref.read(fullSpaceHierarchyProvider(spaceRel).notifier);
    listener = notifier.addListener((newState) {
      if (mounted) {
        state = newState.filtered(filter);
      }
    });
  }

  @override
  Future<List<ffi.SpaceHierarchyRoomInfo>?> load(Next? page, int limit) async {
    final notifier = ref.read(fullSpaceHierarchyProvider(spaceRel).notifier);
    return await notifier.load(page, limit);
  }
}
