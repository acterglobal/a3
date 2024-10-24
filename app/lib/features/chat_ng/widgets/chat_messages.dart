import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessages extends ConsumerWidget {
  final String roomId;
  const ChatMessages({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(renderableChatMessagesProvider(roomId));
    return _ChatMessageList(messages: messages, roomId: roomId);
  }
}

class _ChatMessageList extends ConsumerStatefulWidget {
  final List<String> messages;
  final String roomId;
  const _ChatMessageList(
      {super.key, required this.messages, required this.roomId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      __ChatMessageListState();
}

class __ChatMessageListState extends ConsumerState<_ChatMessageList> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  @override
  void initState() {
    super.initState();
    didUpdateWidget(widget);
  }

  void _calculateDiffs(List<Object> prevList) async {
    final diffResult = calculateListDiff<Object>(
      prevList,
      widget.messages,
    );

    for (final update in diffResult.getUpdates(batch: false)) {
      update.when(
        insert: (pos, count) {
          _listKey.currentState?.insertItem(pos);
        },
        remove: (pos, count) {
          final item = prevList[pos];
          _listKey.currentState?.removeItem(
            pos,
            (_, animation) => _removedMessageBuilder(item, animation),
          );
        },
        change: (pos, payload) {},
        move: (from, to) {},
      );
    }
  }

  Widget _removedMessageBuilder(Object item, Animation<double> animation) =>
      const SizedBox.shrink();

  @override
  void didUpdateWidget(_ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    _calculateDiffs(oldWidget.messages);
  }

  @override
  Widget build(BuildContext context) {
    // final animationController = useAnimationController(
    //   duration: const Duration(seconds: 2),
    // );

    // useEffect(() {
    //   animationController.forward();
    //   return null;
    // }, const []);

    // useAnimation(animationController);

    return CustomScrollView(
      reverse: true,
      slivers: [
        SliverAnimatedList(
          initialItemCount: widget.messages.length,
          // key: _listKey,
          itemBuilder: (_, index, animation) => _messageBuilder(
            ref.watch(
              chatRoomMessageProvider((widget.roomId, widget.messages[index])),
            ),
            animation,
          ),
        ),
      ],
    );
  }

  Widget _messageBuilder(RoomMessage? msg, Animation<double> animation) {
    final inner = msg?.eventItem();
    if (inner == null) {
      return const SizedBox.shrink();
    }
    return Wrap(
      children: [
        Text(inner.sender()),
        const Text(':'),
        Text(inner.msgContent()?.body() ?? 'no body'),
      ],
    );
  }
}
