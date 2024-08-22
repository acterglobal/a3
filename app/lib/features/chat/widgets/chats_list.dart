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

  const ChatsList({
    super.key,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(hasRoomFilters)) {
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
    final filteredChats = ref.watch(filteredChatsProvider);
    return filteredChats.when(
      data: (chatsIds) {
        if (chatsIds.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              heightFactor: 10,
              child: Text(L10n.of(context).noChatsFoundMatchingYourFilter),
            ),
          );
        }
        return _renderList(context, chatsIds);
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
      skipLoadingOnRefresh: true,
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
            onPressed: () => context.pushNamed(Routes.createChat.name),
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
  late GlobalKey<AnimatedListState> _listKey;
  late List<String> _currentList;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _listKey = GlobalKey<AnimatedListState>(debugLabel: 'chat rooms list');
    _currentList = List.of(widget.entries);
  }

  @override
  void didUpdateWidget(_AnimatedChatsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_listKey.currentState == null) {
      _log.fine('no state, hard reset');
      // we can ignore the diffing as we aren't live, just reset
      setState(() {
        _reset();
      });
      return;
    } else {
      refreshList();
    }
  }

  void refreshList() {
    _log.fine('refreshing');
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      _log.fine('diffing $_currentList, ${widget.entries}');
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
      _log.fine('done diffing');
    });
  }

  void _insert(int pos, String data) {
    _log.fine('insert $pos: $data');
    _currentList.insert(pos, data);
    if (_listKey.currentState != null) {
      _listKey.currentState!.insertItem(pos);
    } else {
      _log.fine('we are not');
    }
  }

  void _remove(int pos, String data) {
    _currentList.removeAt(pos);
    if (_listKey.currentState != null) {
      _listKey.currentState!.removeItem(
        pos,
        (context, animation) => _removedItemBuilder(data, context, animation),
      );
    } else {
      _log.fine('we are not');
    }
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
      onTap: () {
        final onSelected = widget.onSelected;
        if (onSelected != null) onSelected(roomId);
      },
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
    _log.fine('render $roomId');
    return ConvoCard(
      animation: animation,
      key: Key('convo-card-$roomId'),
      roomId: roomId,
      onTap: () {
        final onSelected = widget.onSelected;
        if (onSelected != null) onSelected(roomId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _log.fine('render list $_currentList');
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _currentList.length,
      itemBuilder: buildItem,
    );
  }
}
