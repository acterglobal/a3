import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/widgets/item_preview_card.dart';
import 'package:acter/features/room/actions/show_room_preview.dart';
import 'package:flutter/material.dart';

Future<void> showItemPreview({
  required BuildContext context,
  required String roomId,
  required UriParseResult uriResult,
}) async {
  final serverNames = uriResult.via;
  return showRoomPreview(
    context: context,
    roomIdOrAlias: roomId,
    serverNames: serverNames,
    headerInfo: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'To access',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        ItemPreviewCard(
          // showing the same item without the tap
          title: uriResult.preview.title,
          refType: uriResult.finalType(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'you need to be member of',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}
