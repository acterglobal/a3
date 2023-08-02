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
typedef bool FilterFn(ffi.SpaceHierarchyRoomInfo element);

class SpaceHierarchyListState
    extends PagedState<Next?, ffi.SpaceHierarchyRoomInfo> {
  // We can extends [PagedState] to add custom parameters to our state

  const SpaceHierarchyListState({
    List<ffi.SpaceHierarchyRoomInfo>? records,
    String? error,
    Next? nextPageKey = const Next(isStart: true),
    List<Next?>? previousPageKeys,
  }) : super(records: records, error: error, nextPageKey: nextPageKey);

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
    return copyWith(records: records?.where(filter).toList());
  }
}

class SpaceHierarchyNotifier extends StateNotifier<SpaceHierarchyListState>
    with
        PagedNotifierMixin<Next?, ffi.SpaceHierarchyRoomInfo,
            SpaceHierarchyListState> {
  final ffi.SpaceRelations spaceRel;
  final FilterFn? filter;

  SpaceHierarchyNotifier(this.spaceRel, this.filter)
      : super(const SpaceHierarchyListState());

  @override
  Future<List<ffi.SpaceHierarchyRoomInfo>?> load(Next? page, int limit) async {
    if (page == null) {
      return null;
    }

    final pageReq = page.next ?? '';
    try {
      final res = await spaceRel.queryHierarchy(pageReq);
      var entries = (await res.rooms()).toList();
      final next = res.nextBatch();
      Next? finalPageKey;
      if (next != null) {
        // we are not at the end
        finalPageKey = Next(next: next);
      }
      if (filter != null) {
        entries = entries.where(filter!).toList();
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
