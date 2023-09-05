import 'package:acter/features/chat/pages/chat_select_page.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const sidebarMinWidth = 750;

class ChatShell extends ConsumerWidget {
  final Widget child;
  const ChatShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentId = ref.watch(selectedChatIdProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= sidebarMinWidth) {
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
            ],
          );
        }
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
