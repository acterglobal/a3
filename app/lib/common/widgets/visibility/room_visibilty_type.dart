import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/visibility/room_visibility_item.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RoomVisibilityType extends ConsumerWidget {
  final RoomVisibility? selectedVisibilityEnum;
  final ValueChanged<RoomVisibility?>? onVisibilityChange;
  final bool isLimitedVisibilityShow;

  const RoomVisibilityType({
    super.key,
    this.onVisibilityChange,
    this.selectedVisibilityEnum,
    this.isLimitedVisibilityShow = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          RoomVisibilityItem(
            iconData: Icons.language,
            title: L10n.of(context).public,
            subtitle: L10n.of(context).publicVisibilitySubtitle,
            selectedVisibilityValue: selectedVisibilityEnum,
            spaceVisibilityValue: RoomVisibility.Public,
            onChanged: onVisibilityChange,
          ),
          const SizedBox(height: 10),
          RoomVisibilityItem(
            iconData: Icons.lock,
            title: L10n.of(context).private,
            subtitle: L10n.of(context).privateVisibilitySubtitle,
            selectedVisibilityValue: selectedVisibilityEnum,
            spaceVisibilityValue: RoomVisibility.Private,
            onChanged: onVisibilityChange,
          ),
          const SizedBox(height: 10),
          if (isLimitedVisibilityShow)
            RoomVisibilityItem(
              iconData: Atlas.users,
              title: L10n.of(context).limited,
              subtitle: L10n.of(context).limitedVisibilitySubtitle,
              selectedVisibilityValue: selectedVisibilityEnum,
              spaceVisibilityValue: RoomVisibility.SpaceVisible,
              onChanged: onVisibilityChange,
            ),
        ],
      ),
    );
  }
}
