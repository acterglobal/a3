import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/room/actions/show_room_preview.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ReferenceDetailsItem extends StatelessWidget {
  final RefDetails refDetails;
  final bool showDialogOnTap;

  const ReferenceDetailsItem({
    super.key,
    required this.refDetails,
    this.showDialogOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    final refTitle = refDetails.title() ?? L10n.of(context).unknown;
    final refType = refDetails.typeStr();
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        leading: Icon(getIconByType(refType), size: 25),
        title: Text(refTitle),
        subtitle: Text(refType),
        onTap: showDialogOnTap
            ? () {
                final roomId = refDetails.roomIdStr();
                if (roomId == null) {
                  EasyLoading.showError(
                    L10n.of(context).noObjectAccess(refType, 'missing'),
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
                      ReferenceDetailsItem(
                        refDetails: refDetails, // showing this again
                        showDialogOnTap: false, // but do not open more modals
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
            : null,
      ),
    );
  }

  IconData getIconByType(String refType) {
    final defaultIcon = PhosphorIconsThin.tagChevron;
    switch (refType) {
      case 'pin':
        return Atlas.pin;
      case 'calendar-event':
        return Atlas.calendar;
      case 'task-list':
        return Atlas.list;
      default:
        return defaultIcon;
    }
  }
}
