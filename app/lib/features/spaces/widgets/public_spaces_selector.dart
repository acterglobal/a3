import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

typedef OnSelectedFn = void Function(
  PublicSearchResultItem spaceSearchResult,
  String? searchServerName,
  SpaceItem? spaceInfo,
);

typedef OnSelectedMatchFn = void Function({
  String? roomId,
  String? alias,
  required List<String> servers,
});

typedef OnSelectedInnerFn = void Function(
  PublicSearchResultItem spaceSearchResult,
  SpaceItem? spaceInfo,
);

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

final serverTypeAheadController =
    Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  final typeNotifier = ref.read(serverTypeAheadProvider.notifier);
  controller.addListener(() {
    typeNotifier.state = controller.text;
  });
  ref.onDispose(() {
    controller.dispose();
    typeNotifier.state = null;
  });
  return controller;
});

final searchController = Provider.autoDispose<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() {
    controller.dispose();
    ref.read(searchValueProvider.notifier).state = null;
  });
  return controller;
});

final searchValueProvider = StateProvider<String?>((ref) => null);
final serverTypeAheadProvider = StateProvider<String?>((ref) => null);
final selectedServerProvider = StateProvider<String?>((ref) => null);

class PublicSearchNotifier extends StateNotifier<PublicSearchState>
    with PagedNotifierMixin<Next?, PublicSearchResultItem, PublicSearchState> {
  PublicSearchNotifier(this.ref) : super(const PublicSearchState()) {
    setup();
  }

  final Ref ref;

  void setup() {
    ref.read(searchValueProvider.notifier).addListener((state) {
      readData();
    });
    ref.read(selectedServerProvider.notifier).addListener((state) {
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
    const nextPageKey = Next(isStart: true);
    state = state.copyWith(
      records: [],
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
    final client = ref.read(clientProvider)!;
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

class PublicSpaceItem extends ConsumerWidget {
  final PublicSearchResultItem space;
  final OnSelectedInnerFn onSelected;

  const PublicSpaceItem({
    super.key,
    required this.space,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceId = space.roomIdStr();
    final withInfo = ref.watch(maybeSpaceInfoProvider(spaceId));

    return Card(
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
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: ListTile(
                onTap: () => onSelected(
                  space,
                  withInfo.valueOrNull,
                ),
                leading: withInfo.when(
                  data: (data) => data != null
                      ? ActerAvatar(
                          mode: DisplayMode.Space,
                          avatarInfo: AvatarInfo(
                            uniqueId: spaceId,
                            displayName: data.spaceProfileData.displayName,
                            avatar: data.spaceProfileData.getAvatarImage(),
                          ),
                        )
                      : fallbackAvatar(),
                  error: (e, a) {
                    debugPrint('loading failed: $e');
                    return ActerAvatar(
                      mode: DisplayMode.Space,
                      avatarInfo: AvatarInfo(
                        uniqueId: spaceId,
                        displayName: spaceId,
                      ),
                    );
                  },
                  loading: fallbackAvatar,
                ),
                title: Text(
                  space.name() ?? 'no display name',
                  style: Theme.of(context).textTheme.labelLarge,
                  softWrap: false,
                ),
                subtitle: Text(
                  '${space.numJoinedMembers()} Members',
                  style: Theme.of(context).textTheme.labelSmall,
                  softWrap: false,
                ),
                trailing: withInfo.when(
                  data: (data) => data != null
                      ? const Chip(label: Text('member'))
                      : space.joinRuleStr() == 'Public'
                          ? OutlinedButton(
                              onPressed: () => onSelected(
                                space,
                                withInfo.valueOrNull,
                              ),
                              child: const Text('join'),
                            )
                          : OutlinedButton(
                              onPressed: () => onSelected(
                                space,
                                withInfo.valueOrNull,
                              ),
                              child: const Text('request to join'),
                            ),
                  error: (e, s) => Text(
                    '$e',
                    softWrap: true,
                  ),
                  loading: () => const Text('loading'),
                ),
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                '${space.topic()}',
                style: Theme.of(context).textTheme.labelMedium,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ActerAvatar fallbackAvatar() {
    return ActerAvatar(
      mode: DisplayMode.Space,
      avatarInfo: AvatarInfo(
        uniqueId: space.roomIdStr(),
        displayName: space.name(),
      ),
    );
  }
}

class PublicSpaceSelector extends ConsumerWidget {
  final Widget? title;
  final bool autofocus;
  final OnSelectedFn onSelected;
  final OnSelectedMatchFn? onSelectedMatch;
  final bool canMatchAlias;
  final bool canMatchId;

  const PublicSpaceSelector({
    super.key,
    this.title,
    this.autofocus = false,
    required this.onSelected,
    this.onSelectedMatch,
    this.canMatchAlias = false,
    this.canMatchId = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchTextCtrl = ref.watch(searchController);
    final searchValueNotifier = ref.watch(searchValueProvider.notifier);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: title ?? const Text('Join space'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: searchTextCtrl,
                    autofocus: autofocus,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Atlas.magnifying_glass_thin,
                        color: Colors.white,
                      ),
                      labelText: 'search space',
                    ),
                    onChanged: (String value) {
                      searchValueNotifier.state = value;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Consumer(builder: serverTypeBuilder),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Consumer(
              builder: (context, ref, child) {
                final searchVal = ref.watch(searchValueProvider);
                if (onSelectedMatch != null &&
                    searchVal != null &&
                    searchVal.isNotEmpty) {
                  final aliased =
                      RegExp(r'https://matrix.to/#/(?<alias>#.+):(?<server>.+)')
                          .firstMatch(searchVal);
                  if (canMatchAlias && aliased != null) {
                    final alias = aliased.namedGroup('alias')!;
                    final server = aliased.namedGroup('server')!;
                    return Card(
                      child: ListTile(
                        onTap: () =>
                            onSelectedMatch!(alias: alias, servers: [server]),
                        title: Text(alias),
                        subtitle: Text('on $server'),
                        trailing: OutlinedButton.icon(
                          onPressed: () =>
                              onSelectedMatch!(alias: alias, servers: [server]),
                          icon: const Icon(Atlas.entrance_thin),
                          label: const Text('Try to join'),
                        ),
                      ),
                    );
                  }

                  final id = RegExp(
                    r'https://matrix.to/#/(?<id>![^?]+)(\?via=(?<server_name>[^&]+))?(&via=(?<server_name2>[^&]+))?(&via=(?<server_name3>[^&]+))?',
                  ).firstMatch(searchVal);
                  if (canMatchId && id != null) {
                    final targetId = id.namedGroup('id')!;
                    final List<String> servers = [
                      id.namedGroup('server_name') ?? '',
                      id.namedGroup('server_name2') ?? '',
                      id.namedGroup('server_name3') ?? '',
                    ].where((e) => e.isNotEmpty).toList();
                    return Card(
                      child: ListTile(
                        onTap: () => onSelectedMatch!(
                          roomId: targetId,
                          servers: servers,
                        ),
                        title: Text(targetId),
                        subtitle: servers.isNotEmpty
                            ? Text('via ${servers.join(', ')}')
                            : null,
                        trailing: OutlinedButton.icon(
                          onPressed: () => onSelectedMatch!(
                            roomId: targetId,
                            servers: servers,
                          ),
                          icon: const Icon(Atlas.entrance_thin),
                          label: const Text('Try to join'),
                        ),
                      ),
                    );
                  }
                }

                return const SizedBox(height: 0);
              },
            ),
          ),
        ),
        RiverPagedBuilder<Next?, PublicSearchResultItem>.autoDispose(
          firstPageKey: const Next(isStart: true),
          provider: publicSearchProvider,
          itemBuilder: (context, item, index) => PublicSpaceItem(
            space: item,
            onSelected: (item, info) =>
                onSelected(item, ref.read(selectedServerProvider), info),
          ),
          pagedBuilder: (controller, builder) => PagedSliverList(
            pagingController: controller,
            builderDelegate: builder,
          ),
        ),
      ],
    );
  }

  Widget serverTypeBuilder(BuildContext context, WidgetRef ref, Widget? child) {
    final selectedServer = ref.watch(selectedServerProvider);

    final controller = ref.watch(serverTypeAheadController);
    final val = ref.watch(serverTypeAheadProvider);
    final List<DropdownMenuEntry<String>> menuItems = [
      ...defaultServers.map(
        (e) => DropdownMenuEntry(
          label: e.name ?? e.value,
          value: e.value,
        ),
      ),
    ];
    if (val != null && val.isNotEmpty) {
      menuItems.add(
        DropdownMenuEntry(
          leadingIcon: const Icon(Atlas.plus_circle_thin),
          label: val,
          value: val,
        ),
      );
    }

    return DropdownMenu<String>(
      controller: controller,
      initialSelection: selectedServer,
      label: const Text('Server'),
      dropdownMenuEntries: menuItems,
      onSelected: (String? typus) {
        if (typus != null) {
          final notifier = ref.read(selectedServerProvider.notifier);
          notifier.state = typus;
        }
      },
    );
  }
}
