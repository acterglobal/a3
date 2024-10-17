import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/pages/chat_select_page.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef RoomListWidgetBuilder = Widget Function(RoomSelectAction);

class ChatLayoutBuilder extends StatelessWidget {
  final Widget? centerChild;
  final Widget? expandedChild;
  final RoomListWidgetBuilder? roomListWidgetBuilder;

  const ChatLayoutBuilder({
    this.centerChild,
    this.expandedChild,
    this.roomListWidgetBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final expanded = expandedChild;
    final center = centerChild;
    final rlwBuilder =
        roomListWidgetBuilder ?? (s) => RoomsListWidget(onSelected: s);
    if (!context.isLargeScreen) {
      // we only have space to show the deepest child:
      if (expanded != null) return expanded;
      if (center != null) return center;
      // no children, show the room list
      return rlwBuilder(
        (String roomId) => context.pushNamed(
          Routes.chatroom.name,
          pathParameters: {'roomId': roomId},
        ),
      );
    }

    final pushReplacementRouting = centerChild != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: rlwBuilder(
            (String roomId) => pushReplacementRouting
                ? context.pushReplacementNamed(
                    // we switch without "push"
                    Routes.chatroom.name,
                    pathParameters: {'roomId': roomId},
                  )
                : context.pushNamed(
                    // we switch without "push"
                    Routes.chatroom.name,
                    pathParameters: {'roomId': roomId},
                  ),
          ),
        ),
        // we have a room selected
        if (center != null)
          Flexible(
            flex: 3,
            child: center,
          ),
        // we have an expanded as well
        if (expanded != null)
          Flexible(
            flex: 2,
            child: expanded,
          ),
        // Fallback if neither is in our route
        if (center == null && expanded == null)
          const Flexible(
            flex: 2,
            child: ChatSelectPage(),
          ),
      ],
    );
  }
}
