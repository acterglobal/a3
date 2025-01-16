import 'dart:ui';

import 'package:acter/features/chat_ng/widgets/reactions/reaction_selector.dart';
import 'package:flutter/material.dart';

// reaction selector action on chat message
void reactionSelectionAction({
  required BuildContext context,
  required Offset position,
  required Widget messageWidget,
  required bool isUser,
  required String roomId,
  required String messageId,
}) {
  final RenderBox box = context.findRenderObject() as RenderBox;
  final Offset position = box.localToGlobal(Offset.zero);
  final messageSize = box.size;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          _ReactionOverlay(
            animation: animation,
            child: const SizedBox.expand(),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            width: messageSize.width,
            child: messageWidget,
          ),
          Positioned(
            left: position.dx,
            top: position.dy - 60,
            child: _AnimatedReactionSelector(
              animation: animation,
              messageId: messageId,
              child: ReactionSelector(
                isUser: isUser,
                messageId: messageId,
                roomId: roomId,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _ReactionOverlay extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ReactionOverlay({
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

class _AnimatedReactionSelector extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final String messageId;

  const _AnimatedReactionSelector({
    required this.animation,
    required this.child,
    required this.messageId,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: messageId,
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
