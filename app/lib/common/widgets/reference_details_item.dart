import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ReferenceDetailsItem extends StatelessWidget {
  final RefDetails refDetails;

  const ReferenceDetailsItem({
    super.key,
    required this.refDetails,
  });

  @override
  Widget build(BuildContext context) {
    final refTitle = refDetails.title() ?? L10n.of(context).unknown;
    final refType = refDetails.typeStr();
    final roomName = refDetails.roomDisplayName().toString();
    return Card(
      child: ListTile(
        leading: Icon(getIconByType(refType), size: 30),
        title: Text(refTitle),
        subtitle: Text(refType),
        onTap: () => EasyLoading.showError(
          L10n.of(context).noObjectAccess(refType, roomName),
          duration: const Duration(seconds: 3),
        ),
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
