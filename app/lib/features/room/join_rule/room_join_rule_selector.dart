import 'package:acter/features/room/join_rule/room_join_rule_type.dart';
import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';

const Key selectJoinRuleDrawerKey = Key('space-widgets-select-joinRule-drawer');

Future<RoomJoinRule?> selectJoinRuleDrawer({
  required BuildContext context,
  Key? key = selectJoinRuleDrawerKey,
  RoomJoinRule? selectedJoinRuleEnum,
  bool isLimitedJoinRuleShow = true,
}) async {
  final selected = await showModalBottomSheet<RoomJoinRule>(
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
          RoomJoinRuleType(
            isLimitedJoinRuleShow: isLimitedJoinRuleShow,
            selectedJoinRuleEnum: selectedJoinRuleEnum,
            onJoinRuleChange: (value) {
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
