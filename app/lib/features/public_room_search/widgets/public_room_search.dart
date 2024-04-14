import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/public_room_search/providers/public_search_providers.dart';
import 'package:acter/features/public_room_search/types.dart';
import 'package:acter/features/public_room_search/widgets/public_room_item.dart';
import 'package:acter/features/public_room_search/widgets/server_selection_field.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class _MaybeQuickActionWidget extends ConsumerWidget {
  final OnSelectedFn onSelected;
  final OnSelectedMatchFn? onSelectedMatch;
  final bool canMatchAlias;
  final bool canMatchId;
  const _MaybeQuickActionWidget({
    required this.onSelected,
    this.onSelectedMatch,
    this.canMatchAlias = false,
    this.canMatchId = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchVal = ref.watch(searchFilterProvider).searchTerm;
    if (onSelectedMatch != null && searchVal?.isNotEmpty == true) {
      final aliased = RegExp(r'https://matrix.to/#/(?<alias>#.+):(?<server>.+)')
          .firstMatch(searchVal!);
      if (canMatchAlias && aliased != null) {
        final alias = aliased.namedGroup('alias')!;
        final server = aliased.namedGroup('server')!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Card(
            child: ListTile(
              onTap: () => onSelectedMatch!(alias: alias, servers: [server]),
              title: Text(alias),
              subtitle: Text('${L10n.of(context).on} $server'),
              trailing: OutlinedButton.icon(
                onPressed: () =>
                    onSelectedMatch!(alias: alias, servers: [server]),
                icon: const Icon(Atlas.entrance_thin),
                label: Text(L10n.of(context).tryToJoin),
              ),
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Card(
            child: ListTile(
              onTap: () => onSelectedMatch!(
                roomId: targetId,
                servers: servers,
              ),
              title: Text(targetId),
              subtitle: servers.isNotEmpty
                  ? Text('${L10n.of(context).via} ${servers.join(', ')}')
                  : null,
              trailing: OutlinedButton.icon(
                onPressed: () => onSelectedMatch!(
                  roomId: targetId,
                  servers: servers,
                ),
                icon: const Icon(Atlas.entrance_thin),
                label: Text(L10n.of(context).tryToJoin),
              ),
            ),
          ),
        );
      }
    }

    return const SizedBox(height: 0);
  }
}

class PublicRoomSearch extends ConsumerWidget {
  final Widget? title;
  final bool autofocus;
  final OnSelectedFn onSelected;
  final OnSelectedMatchFn? onSelectedMatch;
  final bool canMatchAlias;
  final bool canMatchId;

  const PublicRoomSearch({
    super.key,
    this.title,
    this.autofocus = false,
    required this.onSelected,
    this.onSelectedMatch,
    this.canMatchAlias = false,
    this.canMatchId = false,
  });

  Widget _searchBar(BuildContext context, WidgetRef ref) {
    final searchFilterNotifier = ref.watch(searchFilterProvider.notifier);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              flex: 5,
              child: TextField(
                autofocus: autofocus,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Atlas.magnifying_glass_thin,
                    color: Colors.white,
                  ),
                  labelText: L10n.of(context).searchSpace,
                ),
                onChanged: (String value) {
                  searchFilterNotifier.updateSearchTerm(value);
                },
              ),
            ),
            _serverSelectionBuilder(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _searchResults(BuildContext context, WidgetRef ref) {
    return RiverPagedBuilder<Next?, PublicSearchResultItem>.autoDispose(
      firstPageKey: const Next(isStart: true),
      provider: publicSearchProvider,
      itemBuilder: (context, item, index) => PublicRoomItem(
        item: item,
        onSelected: (item) =>
            onSelected(item, ref.read(searchFilterProvider).server),
      ),
      pagedBuilder: (controller, builder) => PagedSliverList(
        pagingController: controller,
        builderDelegate: builder,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: title ?? Text(L10n.of(context).joinSpace),
      ),
      body: CustomScrollView(
        slivers: [
          _searchBar(context, ref),
          SliverToBoxAdapter(
            child: _MaybeQuickActionWidget(
              onSelected: onSelected,
              onSelectedMatch: onSelectedMatch,
              canMatchAlias: canMatchAlias,
              canMatchId: canMatchId,
            ),
          ),
          _searchResults(context, ref),
        ],
      ),
    );
  }

  Widget _serverSelectionBuilder(BuildContext context, WidgetRef ref) {
    String? currentSelection = ref.watch(searchFilterProvider).server;
    if (currentSelection != null) {
      final foundEntry = defaultServers
          .where(
            (element) => element.value == currentSelection,
          )
          .firstOrNull;
      if (foundEntry != null) {
        currentSelection = foundEntry.name ?? foundEntry.value;
      }
    }
    return Flexible(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.only(left: 5),
        child: ServerSelectionField(
          options: defaultServers,
          autofocus: true,
          currentSelection: currentSelection ?? 'Acter.global',
          onSelect: (newServer) => ref
              .read(searchFilterProvider.notifier)
              .updateSearchServer(newServer),
        ),
      ),
    );
  }
}
