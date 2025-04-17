import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::toolkit::animated_list_widget');

typedef ItemWidgetBuilder =
    Widget Function({
      required Animation<double> animation,
      required String roomId,
    });

class ActerAnimatedListWidget extends StatefulWidget {
  final ItemWidgetBuilder itemBuilder;
  final List<String> entries;

  const ActerAnimatedListWidget({
    super.key,
    required this.entries,
    required this.itemBuilder,
  });

  @override
  ActerAnimatedListState createState() => ActerAnimatedListState();
}

class ActerAnimatedListState extends State<ActerAnimatedListWidget> {
  late GlobalKey<AnimatedListState> _listKey;
  late List<String> _currentList;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _listKey = GlobalKey<AnimatedListState>(debugLabel: 'acter animated list');
    _currentList = List.of(widget.entries);
  }

  @override
  void didUpdateWidget(ActerAnimatedListWidget oldWidget) {
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
  ) => widget.itemBuilder(animation: animation, roomId: roomId);

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
    return widget.itemBuilder(animation: animation, roomId: roomId);
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
