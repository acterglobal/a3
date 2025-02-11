import 'dart:ui';

import 'package:acter/features/chat_ng/widgets/message_actions_widget.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_selector.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// message actions on chat message
void messageActions({
  required BuildContext context,
  required Widget messageWidget,
  required bool isMe,
  required bool canRedact,
  required RoomEventItem item,
  required String messageId,
  required String roomId,
}) async {
  // trigger vibration haptic
  await HapticFeedback.heavyImpact();
  if (!context.mounted) return;

  final RenderBox? messageBox = context.findRenderObject() as RenderBox?;
  if (messageBox == null) return;

  final messageSize = messageBox.size;
  final messagePosition = messageBox.localToGlobal(Offset.zero);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          _BlurOverlay(
            animation: animation,
            child: const SizedBox.shrink(),
          ),
          Positioned(
            left: messagePosition.dx,
            top: 0,
            width: messageSize.width,
            height: MediaQuery.sizeOf(context).height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Reaction Row
                _AnimatedActionsContainer(
                  animation: animation,
                  tagId: messageId,
                  child: ReactionSelector(
                    isMe: isMe,
                    messageId: '$messageId-reactions',
                    roomId: roomId,
                  ),
                ),
                // Message
                Center(child: messageWidget),
                // Message actions
                _AnimatedActionsContainer(
                  animation: animation,
                  tagId: '$messageId-actions',
                  child: MessageActionsWidget(
                    isMe: isMe,
                    canRedact: canRedact,
                    item: item,
                    messageId: messageId,
                    roomId: roomId,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _BlurOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _BlurOverlay({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 8 * animation.value,
              sigmaY: 8 * animation.value,
            ),
            child: Container(
              color: Colors.black.withOpacity(0.1 * animation.value),
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
}

class _AnimatedActionsContainer extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final String tagId;

  const _AnimatedActionsContainer({
    required this.animation,
    required this.child,
    required this.tagId,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tagId,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: Curves.easeOut.transform(animation.value),
              child: child,
            );
          },
          child: child,
        ),
      ),
    );
  }
}
