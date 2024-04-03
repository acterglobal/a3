import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat/pages/chat_select_page.dart';
import 'package:acter/features/chat/pages/room_profile_page.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const sidebarMinWidth = 750;

class ChatLayoutBuilder extends ConsumerWidget {
  final List<Widget>? children;
  const ChatLayoutBuilder({this.children, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < sidebarMinWidth) {
          // we only have space to show the deepest child:
          if (children != null) {
            return children!.last;
          } else {
            // no children, show the room list
            return const RoomsListWidget();
          }
        }

        // we have space to show more
        final List<Flexible> wrappedChildren;

        if (children != null) {
          wrappedChildren = children!.indexed.map((entry) {
            final child = entry.$2;
            if (entry.$1 == 0) {
              // the first entry gets twice the space, all following just 1
              return Flexible(
                flex: 2,
                child: child,
              );
            } else {
              return Flexible(
                child: child,
              );
            }
          }).toList();
        } else {
          // nothing else to show, show placeholder page:
          wrappedChildren = [
            const Flexible(
              flex: 2,
              child: ChatSelectPage(),
            ),
          ];
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Flexible(
              child: RoomsListWidget(),
            ),
            ...wrappedChildren,
          ],
        );
      },
    );
  }
}
