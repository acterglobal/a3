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
  String? fallbackRoomDisplayName,
  String? senderId,
  List<String> serverNames = const [],
}) =>
    showModalBottomSheet(
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
        child: RoomPreviewWidget(
          roomId: roomIdOrAlias,
          headerInfo: headerInfo,
          senderId: senderId,
          fallbackRoomDisplayName: fallbackRoomDisplayName,
          viaServers: serverNames,
          onForward: (inner, ref, room) async {
            if (context.canPop()) {
              context.pop(); // close the modal
            }
            if (onForward != null) {
              return await onForward(context, ref, room);
            }
            // room found we have been tasked to forward;
            if (room.isSpace()) {
              goToSpace(context, room.roomIdStr());
            } else {
              goToChat(context, room.roomIdStr());
            }
          },
        ),
      ),
    );
