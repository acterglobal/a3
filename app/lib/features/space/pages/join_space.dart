import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/main.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';

import 'dart:math';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class Next {
  final bool isStart;
  final String? next;

  const Next({this.isStart = false, this.next});
}

class PublicSearchState extends PagedState<Next?, PublicSearchResultItem> {
  // We can extends [PagedState] to add custom parameters to our state

  const PublicSearchState({
    List<PublicSearchResultItem>? records,
    String? error,
    Next? nextPageKey = const Next(isStart: true),
    List<Next?>? previousPageKeys,
  }) : super(records: records, error: error, nextPageKey: nextPageKey);

  @override
  PublicSearchState copyWith({
    List<PublicSearchResultItem>? records,
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
    return PublicSearchState(
      records: sup.records,
      error: sup.error,
      nextPageKey: sup.nextPageKey,
      previousPageKeys: sup.previousPageKeys,
    );
  }
}

class PublicSearchNotifier extends StateNotifier<PublicSearchState>
    with PagedNotifierMixin<Next?, PublicSearchResultItem, PublicSearchState> {
  PublicSearchNotifier(this.ref) : super(const PublicSearchState());

  final Ref ref;

  @override
  Future<List<PublicSearchResultItem>?> load(Next? page, int limit) async {
    if (page == null) {
      return null;
    }

    final pageReq = page.next ?? '';
    final client = ref.watch(clientProvider)!;
    final res = await client.publicSpaces(null, null, pageReq);
    final entries = res.chunks();
    final next = res.nextBatch();
    Next? finalPageKey;
    if (next != null) {
      // we are not at the end
      finalPageKey = Next(next: next);
    }
    state = state.copyWith(
      records:
          page.isStart ? [...entries] : [...(state.records ?? []), ...entries],
      nextPageKey: finalPageKey,
    );

    return null;
  }
}

final publicSearchProvider = StateNotifierProvider<PublicSearchNotifier,
    PagedState<Next?, PublicSearchResultItem>>(
  (ref) => PublicSearchNotifier(ref),
);

class JoinSpacePage extends ConsumerStatefulWidget {
  const JoinSpacePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _JoinSpacePageState();
}

class _JoinSpacePageState extends ConsumerState<JoinSpacePage> {
  @override
  Widget build(BuildContext context) {
    final widthCount = (MediaQuery.of(context).size.width ~/ 600).toInt();
    const int minCount = 2;
    return Scaffold(
      appBar: AppBar(title: Text('Join Space')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: <Color>[
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.neutral,
            ],
          ),
        ),
        child: RiverPagedBuilder<Next?, PublicSearchResultItem>(
          firstPageKey: const Next(isStart: true),
          provider: publicSearchProvider,
          itemBuilder: (context, item, index) => ListTile(
            leading: ActerAvatar(
              mode: DisplayMode.Space,
              uniqueId: item.roomIdStr(),
              displayName: item.name(),
            ),
            title: Text(item.name() ?? 'no display name'),
          ),
          pagedBuilder: (controller, builder) => PagedGridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: max(1, min(widthCount, minCount)),
              childAspectRatio: 6,
            ),
            pagingController: controller,
            builderDelegate: builder,
          ),
        ),
      ),
    );
  }
}
