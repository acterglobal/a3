import 'dart:ui';

import 'package:acter/features/chat_ng/globals.dart';
import 'package:acter/common/toolkit/widgets/acter_selection_area.dart';
import 'package:acter/features/chat_ng/widgets/message_actions_widget.dart';
import 'package:acter/features/chat_ng/widgets/reactions/reaction_selector.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// message actions on chat message
void messageActions({
  required BuildContext context,
  required Widget messageWidget,
  required bool isMe,
  required bool canRedact,
  required TimelineEventItem item,
  required String messageId,
  required String roomId,
}) async {
  // trigger vibration haptic
  await HapticFeedback.heavyImpact();
  if (!context.mounted) return;

  final RenderBox? messageBox = context.findRenderObject() as RenderBox?;
  final chatRoomBox =
      chatRoomKey.currentContext?.findRenderObject() as RenderBox?;
  final chatRoomOffset = chatRoomBox?.localToGlobal(Offset.zero);
  final chatRoomSize = chatRoomBox?.size;
  final left = chatRoomOffset?.dx ?? 0;
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (messageBox == null) return;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Stack(
        children: [
          _BlurOverlay(animation: animation, child: const SizedBox.shrink()),
          Positioned(
            left: isMe ? left : left + 36,
            top: chatRoomOffset?.dy,
            width: chatRoomSize?.width,
            height: chatRoomSize?.height,
            child: SizedBox(
              width: (chatRoomSize?.width ?? screenWidth) * 0.9,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _AnimatedActionsContainer(
                    animation: animation,
                    tagId: '$messageId-reactions',
                    child: ReactionSelector(
                      isMe: isMe,
                      messageId: messageId,
                      roomId: roomId,
                    ),
                  ),
                ),
                // Message
                Center(child: ActerSelectionArea(child: messageWidget)),
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
                ],
              ),
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

  const _BlurOverlay({required this.animation, required this.child});

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
              color: Colors.black.withValues(alpha: (0.1 * animation.value)),
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
