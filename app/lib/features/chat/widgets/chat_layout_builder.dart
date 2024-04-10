import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/config.dart';
import 'package:acter/features/chat/pages/chat_select_page.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatLayoutBuilder extends ConsumerWidget {
  // (bool inSideBar) -> Widget
  final Widget Function(bool)? centerBuilder;
  // (bool inSideBar) -> Widget
  final Widget Function(bool)? expandedBuilder;
  const ChatLayoutBuilder(
      {this.centerBuilder, this.expandedBuilder, super.key,});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < sidebarMinWidth) {
          // we only have space to show the deepest child:
          if (expandedBuilder != null) {
            return expandedBuilder!(false);
          } else if (centerBuilder != null) {
            return centerBuilder!(false);
          } else {
            // no children, show the room list
            return RoomsListWidget(
              onSelected: (String roomId) => context.pushNamed(
                Routes.chatroom.name,
                pathParameters: {'roomId': roomId},
              ),
            );
          }
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: RoomsListWidget(
                onSelected: (String roomId) => context.goNamed(
                  // we switch without "push"
                  Routes.chatroom.name,
                  pathParameters: {'roomId': roomId},
                ),
              ),
            ),
            // we have a room selected
            if (centerBuilder != null)
              Flexible(
                flex: 3,
                child: centerBuilder!(true),
              ),
            // we have an expanded as well
            if (expandedBuilder != null)
              Flexible(
                flex: 2,
                child: expandedBuilder!(true),
              ),
            // Fallback if neither is in our route
            if (centerBuilder == null && expandedBuilder == null)
              const Flexible(
                flex: 2,
                child: ChatSelectPage(),
              ),
          ],
        );
      },
    );
  }
}
