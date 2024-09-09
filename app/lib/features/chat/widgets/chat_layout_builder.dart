import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/pages/chat_select_page.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatLayoutBuilder extends StatelessWidget {
  final Widget? centerChild;
  final Widget? expandedChild;

  const ChatLayoutBuilder({
    this.centerChild,
    this.expandedChild,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isLargeScreen) {
      // we only have space to show the deepest child:
      return expandedChild ??
          centerChild ??
          // no children, show the room list
          RoomsListWidget(
            onSelected: (String roomId) => context.pushNamed(
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
          child: RoomsListWidget(
            onSelected: (String roomId) => pushReplacementRouting
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
        if (centerChild != null)
          Flexible(
            flex: 3,
            child: centerChild!,
          ),
        // we have an expanded as well
        if (expandedChild != null)
          Flexible(
            flex: 2,
            child: expandedChild!,
          ),
        // Fallback if neither is in our route
        if (centerChild == null && expandedChild == null)
          const Flexible(
            flex: 2,
            child: ChatSelectPage(),
          ),
      ],
    );
  }
}
