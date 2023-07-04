import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/utils.dart';
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
  final String? server;
  final String? searchValue;

  const PublicSearchState({
    List<PublicSearchResultItem>? records,
    String? error,
    Next? nextPageKey = const Next(isStart: true),
    List<Next?>? previousPageKeys,
    this.server,
    this.searchValue,
  }) : super(records: records, error: error, nextPageKey: nextPageKey);

  @override
  PublicSearchState copyWith({
    List<PublicSearchResultItem>? records,
    dynamic error,
    dynamic nextPageKey,
    String? server,
    String? searchValue,
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
      server: server,
      searchValue: searchValue,
    );
  }
}

final searchController = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose();
    ref.read(searchValueProvider.notifier).state = null;
  });
  return controller;
});

final searchValueProvider = StateProvider<String?>((ref) => null);
final selectedServerProvider = StateProvider<String?>((ref) => null);

class PublicSearchNotifier extends StateNotifier<PublicSearchState>
    with PagedNotifierMixin<Next?, PublicSearchResultItem, PublicSearchState> {
  PublicSearchNotifier(this.ref) : super(const PublicSearchState()) {
    setup();
  }

  final Ref ref;

  void setup() {
    ref.watch(searchValueProvider.notifier).addListener((state) {
      readData();
    });
    ref.watch(selectedServerProvider.notifier).addListener((state) {
      readData();
    });
  }

  void readData() async {
    try {
      await ref.debounce(const Duration(milliseconds: 300));
      final newSearchValue = ref.read(searchValueProvider);
      final newSelectedSever = ref.read(selectedServerProvider);
      refresh(newSearchValue, newSelectedSever);
    } catch (e) {
      // we do not care.
    }
  }

  void refresh(searchValue, server) {
    final nextPageKey = Next(isStart: true);
    state = state.copyWith(
      records: null,
      nextPageKey: nextPageKey,
      searchValue: searchValue,
      server: server,
    );
    load(nextPageKey, 30);
  }

  @override
  Future<List<PublicSearchResultItem>?> load(Next? page, int limit) async {
    if (page == null) {
      return null;
    }

    final pageReq = page.next ?? '';
    final client = ref.watch(clientProvider)!;
    final searchValue = state.searchValue;
    final server = state.server;
    try {
      final res = await client.publicSpaces(searchValue, server, pageReq);
      final entries = res.chunks();
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
        searchValue: searchValue,
        server: server,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }

    return null;
  }
}

final publicSearchProvider = StateNotifierProvider.autoDispose<
    PublicSearchNotifier, PagedState<Next?, PublicSearchResultItem>>((ref) {
  return PublicSearchNotifier(ref);
});

class JoinSpacePage extends ConsumerStatefulWidget {
  const JoinSpacePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _JoinSpacePageState();
}

class _JoinSpacePageState extends ConsumerState<JoinSpacePage> {
  @override
  Widget build(BuildContext context) {
    final widthCount = (MediaQuery.of(context).size.width ~/ 600).toInt();
    final searchValue = ref.watch(searchValueProvider);
    final _searchTextCtrl = ref.watch(searchController);
    const int minCount = 2;
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
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              title: Text('Join space'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchTextCtrl,
                        autofocus: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Atlas.magnifying_glass_thin,
                            color: Colors.white,
                          ),
                          labelText: 'search space',
                        ),
                        onChanged: (String value) async {
                          ref.read(searchValueProvider.notifier).state = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: DropdownMenu<String>(
                        initialSelection:
                            ref.read(selectedServerProvider.notifier).state,
                        label: const Text('Server'),
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(
                            label: 'Acter',
                            value: 'acter.global',
                          ),
                          DropdownMenuEntry(
                            label: 'Matrix.org',
                            value: 'matrix.org',
                          ),
                        ],
                        onSelected: (String? typus) {
                          if (typus != null) {
                            ref.read(selectedServerProvider.notifier).state =
                                typus;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            RiverPagedBuilder<Next?, PublicSearchResultItem>.autoDispose(
              firstPageKey: const Next(isStart: true),
              provider: publicSearchProvider,
              itemBuilder: (context, item, index) => Card(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: ActerAvatar(
                        mode: DisplayMode.Space,
                        uniqueId: item.roomIdStr(),
                        displayName: item.name(),
                      ),
                      title: Text(item.name() ?? 'no display name'),
                      subtitle: Text('${item.numJoinedMembers()} Members'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        top: 2,
                        bottom: 2,
                      ),
                      child: Text('${item.topic()}'),
                    ),
                  ],
                ),
              ),
              pagedBuilder: (controller, builder) => PagedSliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 800,
                  childAspectRatio: 3,
                ),
                pagingController: controller,
                builderDelegate: builder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
