import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/pages/chat_select_page.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatLayoutBuilder extends ConsumerWidget {
  final Widget? centerChild;
  final Widget? expandedChild;

  const ChatLayoutBuilder({
    this.centerChild,
    this.expandedChild,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = expandedChild;
    final center = centerChild;
    final isChatNG = ref.watch(isActiveProvider(LabsFeature.chatNG));
    final roomRoute = isChatNG ? Routes.chatNGRoom.name : Routes.chatroom.name;

    if (!context.isLargeScreen) {
      // we only have space to show the deepest child:
      if (expanded != null) return expanded;
      if (center != null) return center;
      // no children, show the room list
      return Consumer(
        builder: (context, ref, child) {
          return RoomsListWidget(
            onSelected: (String roomId) => context.pushNamed(
              roomRoute,
              pathParameters: {'roomId': roomId},
            ),
          );
        },
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
                    roomRoute,
                    pathParameters: {'roomId': roomId},
                  )
                : context.pushNamed(
                    // we switch without "push"
                    roomRoute,
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
