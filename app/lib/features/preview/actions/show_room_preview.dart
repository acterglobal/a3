import 'dart:async';

import 'package:acter/features/preview/types.dart';
import 'package:acter/features/preview/widgets/room_preview.dart';
import 'package:acter/router/utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showRoomPreview({
  required BuildContext context,
  required String roomIdOrAlias,
  Widget? headerInfo,
  OnForward? onForward,
  List<String> serverNames = const [],
}) async {
  await showModalBottomSheet(
    context: context,
    isDismissible: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        topLeft: Radius.circular(20),
      ),
    ),
    builder: (context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (headerInfo != null) headerInfo,
          RoomPreviewWidget(
            roomId: roomIdOrAlias,
            viaServers: serverNames,
            autoForward: true,
            onForward: (room) async {
              if (context.canPop()) {
                context.pop(); // close the modal
              }
              if (onForward != null) {
                return await onForward(room);
              }
              // room found we have been tasked to forward;
              if (room.isSpace()) {
                goToSpace(context, room.roomIdStr());
              } else {
                goToChat(context, room.roomIdStr());
              }
            },
          ),
        ],
      ),
    ),
  );
}
