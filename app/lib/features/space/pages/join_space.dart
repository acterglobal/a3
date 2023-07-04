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

class PublicSearchState extends PagedState<String?, PublicSearchResultItem> {
  // We can extends [PagedState] to add custom parameters to our state

  const PublicSearchState({
    List<PublicSearchResultItem>? records,
    String? error,
    String? nextPageKey,
    List<String?>? previousPageKeys,
  }) : super(records: records, error: error, nextPageKey: nextPageKey);

  @override
  PublicSearchState copyWith({
    List<PublicSearchResultItem>? records,
    dynamic error,
    dynamic nextPageKey,
    List<String?>? previousPageKeys,
  }) {
    final sup = super.copyWith(
        records: records,
        error: error,
        nextPageKey: nextPageKey,
        previousPageKeys: previousPageKeys);
    return PublicSearchState(
        records: sup.records,
        error: sup.error,
        nextPageKey: sup.nextPageKey,
        previousPageKeys: sup.previousPageKeys);
  }
}

class PublicSearchNotifier extends StateNotifier<PublicSearchState>
    with
        PagedNotifierMixin<String?, PublicSearchResultItem, PublicSearchState> {
  PublicSearchNotifier(this.ref) : super(const PublicSearchState());

  final Ref ref;

  @override
  Future<List<PublicSearchResultItem>?> load(String? page, int limit) async {
    if (page == null) {
      // nothing else to load:
      return null;
    }
    final client = ref.watch(clientProvider)!;
    final res = await client.publicSpaces(null, null, page);
    final entries = res.chunks();

    state = state.copyWith(
      records: [...(state.records ?? []), ...entries],
      nextPageKey: res.nextBatch(),
    );

    return null;
  }
}

final publicSearchProvider = StateNotifierProvider<PublicSearchNotifier,
    PagedState<String?, PublicSearchResultItem>>(
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
    return Scaffold(
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
        child: RiverPagedBuilder<String?, PublicSearchResultItem>(
          firstPageKey: '',
          provider: publicSearchProvider,
          itemBuilder: (context, item, index) => ListTile(
            leading: ActerAvatar(
              mode: DisplayMode.Space,
              uniqueId: item.roomIdStr(),
              displayName: item.name(),
            ),
            title: Text(item.name() ?? 'no display name'),
          ),
          pagedBuilder: (controller, builder) => PagedListView(
              pagingController: controller, builderDelegate: builder),
        ),
      ),
    );
  }
}
