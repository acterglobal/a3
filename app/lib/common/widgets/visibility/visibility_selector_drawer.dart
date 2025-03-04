import 'package:acter/common/widgets/visibility/room_visibilty_type.dart';
import 'package:acter/features/room/model/room_visibility.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';

const Key selectVisibilityDrawerKey = Key(
  'space-widgets-select-visibility-drawer',
);

Future<RoomVisibility?> selectVisibilityDrawer({
  required BuildContext context,
  Key? key = selectVisibilityDrawerKey,
  RoomVisibility? selectedVisibilityEnum,
  bool isLimitedVisibilityShow = true,
}) async {
  final selected = await showModalBottomSheet<RoomVisibility>(
    showDragHandle: true,
    enableDrag: true,
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            L10n.of(context).selectVisibility,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          RoomVisibilityType(
            isLimitedVisibilityShow: isLimitedVisibilityShow,
            selectedVisibilityEnum: selectedVisibilityEnum,
            onVisibilityChange: (value) {
              Navigator.pop(context, value);
            },
          ),
          const SizedBox(height: 20),
        ],
      );
    },
  );

  return selected;
}
