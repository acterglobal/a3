import 'package:acter/features/room/join_rule/room_join_rule_item.dart';
import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomJoinRuleType extends ConsumerWidget {
  final RoomJoinRule? selectedJoinRuleEnum;
  final ValueChanged<RoomJoinRule?>? onJoinRuleChange;
  final bool isLimitedJoinRuleShow;
  final bool canChange;

  const RoomJoinRuleType({
    super.key,
    this.onJoinRuleChange,
    this.selectedJoinRuleEnum,
    this.canChange = true,
    this.isLimitedJoinRuleShow = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          RoomJoinRuleItem(
            iconData: Icons.language,
            title: lang.public,
            subtitle: lang.publicVisibilitySubtitle,
            selectedJoinRuleValue: selectedJoinRuleEnum,
            spaceJoinRuleValue: RoomJoinRule.Public,
            onChanged: canChange ? onJoinRuleChange : null,
          ),
          const SizedBox(height: 10),
          RoomJoinRuleItem(
            iconData: Icons.lock,
            title: lang.private,
            subtitle: lang.privateVisibilitySubtitle,
            selectedJoinRuleValue: selectedJoinRuleEnum,
            spaceJoinRuleValue: RoomJoinRule.Invite,
            onChanged: canChange ? onJoinRuleChange : null,
          ),
          const SizedBox(height: 10),
          if (isLimitedJoinRuleShow)
            RoomJoinRuleItem(
              iconData: Atlas.users,
              title: lang.limited,
              subtitle: lang.limitedVisibilitySubtitle,
              selectedJoinRuleValue: selectedJoinRuleEnum,
              spaceJoinRuleValue: RoomJoinRule.Restricted,
              onChanged: canChange ? onJoinRuleChange : null,
            ),
        ],
      ),
    );
  }
}
