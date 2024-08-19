import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::chats_list');

class ChatsList extends ConsumerWidget {
  final Function(String)? onSelected;

  const ChatsList({this.onSelected, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSearchFilter = ref.watch(hasRoomFilters);
    if (hasSearchFilter) {
      return _renderFiltered(context, ref);
    }
    final chats = ref.watch(chatIdsProvider);

    if (chats.isEmpty) {
      if (!ref.watch(hasFirstSyncedProvider)) {
        return _renderSyncing(context);
      }
      return _renderEmpty(context);
    }
    return _renderList(context, chats);
  }

  Widget _renderFiltered(BuildContext context, WidgetRef ref) {
    return ref.watch(filteredChatsProvider).when(
          data: (chats) {
            if (chats.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(
                  heightFactor: 10,
                  child: Text(L10n.of(context).noChatsFoundMatchingYourFilter),
                ),
              );
            }
            return _renderList(
              context,
              chats.map((e) => e.getRoomIdStr()).toList(),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              heightFactor: 10,
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, s) {
            _log.severe('Failed to filter convos', e, s);
            return SliverToBoxAdapter(
              child: Center(
                heightFactor: 10,
                child: Text(L10n.of(context).searchingFailed(e)),
              ),
            );
          },
          skipLoadingOnReload: true,
        );
  }

  Widget _renderSyncing(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        heightFactor: 1.5,
        child: EmptyState(
          title: L10n.of(context).noChatsStillSyncing,
          subtitle: L10n.of(context).noChatsStillSyncingSubtitle,
          image: 'assets/images/empty_chat.svg',
        ),
      ),
    );
  }

  Widget _renderEmpty(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        heightFactor: 1.5,
        child: EmptyState(
          title: L10n.of(context).youHaveNoDMsAtTheMoment,
          subtitle: L10n.of(context).getInTouchWithOtherChangeMakers,
          image: 'assets/images/empty_chat.svg',
          primaryButton: ActerPrimaryActionButton(
            onPressed: () async => context.pushNamed(
              Routes.createChat.name,
            ),
            child: Text(L10n.of(context).sendDM),
          ),
        ),
      ),
    );
  }

  Widget _renderList(BuildContext context, List<String> chats) {
    return _AnimatedChatsList(
      entries: chats,
      onSelected: onSelected,
    );
  }
}

class _AnimatedChatsList extends StatefulWidget {
  final Function(String)? onSelected;
  final List<String> entries;

  const _AnimatedChatsList({
    required this.entries,
    this.onSelected,
  });

  @override
  __AnimatedChatsListState createState() => __AnimatedChatsListState();
}

class __AnimatedChatsListState extends State<_AnimatedChatsList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<String> _currentList;

  @override
  void initState() {
    super.initState();
    _currentList = widget.entries;
  }

  @override
  void didUpdateWidget(_AnimatedChatsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    refreshList();
  }

  void refreshList() {
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final diffResult = calculateListDiff<String>(
        _currentList,
        widget.entries,
        detectMoves: false,
      );
      for (final update in diffResult.getUpdatesWithData()) {
        update.when(
          insert: _insert,
          remove: _remove,
          change: (pos, oldData, newData) {
            _remove(pos, oldData);
            _insert(pos, newData);
          },
          move: (from, to, item) {
            _remove(from, item);
            _insert(to, item);
          },
        );
      }
    });
  }

  void _insert(int pos, String data) {
    _currentList.insert(pos, data);
    _listKey.currentState?.insertItem(pos);
  }

  void _remove(int pos, String data) {
    _currentList.removeAt(pos);
    _listKey.currentState?.removeItem(
      pos,
      (context, animation) => _removedItemBuilder(data, context, animation),
    );
  }

  Widget _removedItemBuilder(
    String roomId,
    BuildContext context,
    Animation<double> animation,
  ) {
    return ConvoCard(
      animation: animation,
      key: Key('convo-card-$roomId-removed'),
      roomId: roomId,
      onTap: () =>
          widget.onSelected != null ? widget.onSelected!(roomId) : null,
    );
  }

  Widget buildItem(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    if (index >= _currentList.length) {
      // due to this updating with animations, we sometimes run out of the index
      // while still manipulating it. Ignore that case with just some empty boxes.
      return const SizedBox.shrink();
    }
    final roomId = _currentList[index];
    return ConvoCard(
      animation: animation,
      key: Key('convo-card-$roomId'),
      roomId: roomId,
      onTap: () =>
          widget.onSelected != null ? widget.onSelected!(roomId) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _currentList.length,
      itemBuilder: buildItem,
    );
  }
}
