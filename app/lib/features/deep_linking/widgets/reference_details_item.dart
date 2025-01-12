import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/deep_linking/util.dart';
import 'package:acter/features/deep_linking/widgets/item_preview_card.dart';
import 'package:acter/features/room/actions/show_room_preview.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';

class ReferenceDetailsItem extends StatelessWidget {
  final RefDetails refDetails;

  const ReferenceDetailsItem({
    super.key,
    required this.refDetails,
  });

  @override
  Widget build(BuildContext context) => ItemPreviewCard(
        title: refDetails.title(),
        refType: typeFromRefDetails(refDetails),
        onTap: () {
          final roomId = refDetails.roomIdStr();
          if (roomId == null) {
            EasyLoading.showError(
              L10n.of(context)
                  .noObjectAccess(refDetails.typeStr(), 'missing roomId'),
              duration: const Duration(seconds: 3),
            );
            return;
          }

          final serverNames = refDetails.viaServers().toDart();
          showRoomPreview(
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
                  title: refDetails.title(),
                  refType: typeFromRefDetails(refDetails),
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
        },
      );
}
