import 'package:acter/features/chat/pages/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatShell extends ConsumerWidget {
  final Widget child;
  const ChatShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            constraints.maxWidth >= 600
                ? const Flexible(
                    child: ChatPage(),
                  )
                : const SizedBox.shrink(),
            Flexible(
              flex: 2,
              child: child,
            ),
          ],
        );
      },
    );
  }
}
