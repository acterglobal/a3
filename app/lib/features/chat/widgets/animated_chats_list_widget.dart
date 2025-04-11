import 'package:acter/features/chat_ui_showcase/widgets/chat_item_widget.dart';
import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::animated_chats_list_widget');

class AnimatedChatsListWidget extends StatefulWidget {
  final Function(String)? onSelected;
  final List<String> entries;

  const AnimatedChatsListWidget({
    super.key,
    required this.entries,
    this.onSelected,
  });

  @override
  AnimatedChatsListState createState() => AnimatedChatsListState();
}

class AnimatedChatsListState extends State<AnimatedChatsListWidget> {
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
  void didUpdateWidget(AnimatedChatsListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_listKey.currentState == null) {
      _log.fine('no state, hard reset');
      // we can ignore the diffing as we aren't live, just reset
      setState(_reset);
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
    final state = _listKey.currentState;
    if (state != null) {
      state.insertItem(pos, duration: const Duration(milliseconds: 300));
    } else {
      _log.fine('we are not');
    }
  }

  void _remove(int pos, String data) {
    _currentList.removeAt(pos);
    final state = _listKey.currentState;
    if (state != null) {
      state.removeItem(
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
    return ChatItemWidget(
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
    return ChatItemWidget(
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
    return AnimatedList(
      key: _listKey,
      initialItemCount: _currentList.length,
      itemBuilder: buildItem,
    );
  }
}
