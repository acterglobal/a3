import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/features/chat/pages/room_profile_page.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InChat extends ConsumerStatefulWidget {
  final Widget child;
  const InChat({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<InChat> createState() => _InChatConsumerState();
}

class _InChatConsumerState extends ConsumerState<InChat>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final showFullView = ref.watch(showFullSplitView);
    final convo = ref.watch(currentConvoProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              flex: 1,
              child: widget.child,
            ),
            Flexible(
              flex: 2,
              child: convo != null
                  ? const RoomPage()
                  : const SizedBox(
                      child: Center(
                        child: Text('Tap on any room to see full preview'),
                      ),
                    ),
            ),
            showFullView && constraints.maxWidth > 400
                ? ConstrainedBox(
                    constraints:
                        BoxConstraints.tight(const Size(400, double.infinity)),
                    child: const RoomProfilePage(),
                  )
                : const SizedBox.shrink()
          ],
        );
      },
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
