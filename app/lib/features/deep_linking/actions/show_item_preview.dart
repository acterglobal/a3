import 'package:acter/features/deep_linking/actions/forward_to_object.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/widgets/item_preview_card.dart';
import 'package:acter/features/preview/actions/show_room_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showItemPreview({
  required BuildContext context,
  required WidgetRef ref,
  required String roomId,
  required UriParseResult uriResult,
}) async {
  final serverNames = uriResult.via;
  final lang = L10n.of(context);
  return showRoomPreview(
    context: context,
    roomIdOrAlias: roomId,
    serverNames: serverNames,
    onForward: (context, ref, room) async {
      forwardToObject(context, ref, uriResult);
    },
    headerInfo: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            lang.toAccess,
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
            lang.needToBeMemberOf,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}
