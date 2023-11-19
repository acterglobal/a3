import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat/pages/room_profile_page.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const sidebarMinWidth = 750;

class ChatLayoutBuilder extends ConsumerWidget {
  final Widget child;
  const ChatLayoutBuilder({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentId = ref.watch(selectedChatIdProvider);
    final isExpanded = ref.watch(hasExpandedPanel);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= sidebarMinWidth) {
          // FIXME: do state change inside notifier
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            ref.read(inSideBarProvider.notifier).update((state) => true);
          });
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Flexible(
                child: RoomsListWidget(),
              ),
              Flexible(
                flex: 2,
                child: child,
              ),
              currentId != null && isExpanded
                  ? Flexible(child: RoomProfilePage(roomId: currentId))
                  : const SizedBox.shrink(),
            ],
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          ref.read(inSideBarProvider.notifier).update((state) => false);
          ref.read(hasExpandedPanel.notifier).update((state) => false);
        });
        // mobile case / not enough space
        if (currentId == null) {
          // we prefer showing the room list on the index page if there isn't enough space
          return const RoomsListWidget();
        }
        return child;
      },
    );
  }
}
