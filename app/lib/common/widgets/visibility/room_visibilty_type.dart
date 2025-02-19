import 'package:acter/common/widgets/visibility/room_visibility_item.dart';
import 'package:acter/features/room/model/room_visibility.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomVisibilityType extends ConsumerWidget {
  final RoomVisibility? selectedVisibilityEnum;
  final ValueChanged<RoomVisibility?>? onVisibilityChange;
  final bool isLimitedVisibilityShow;
  final bool canChange;

  const RoomVisibilityType({
    super.key,
    this.onVisibilityChange,
    this.selectedVisibilityEnum,
    this.canChange = true,
    this.isLimitedVisibilityShow = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          RoomVisibilityItem(
            iconData: Icons.language,
            title: lang.public,
            subtitle: lang.publicVisibilitySubtitle,
            selectedVisibilityValue: selectedVisibilityEnum,
            spaceVisibilityValue: RoomVisibility.Public,
            onChanged: canChange ? onVisibilityChange : null,
          ),
          const SizedBox(height: 10),
          RoomVisibilityItem(
            iconData: Icons.lock,
            title: lang.private,
            subtitle: lang.privateVisibilitySubtitle,
            selectedVisibilityValue: selectedVisibilityEnum,
            spaceVisibilityValue: RoomVisibility.Private,
            onChanged: canChange ? onVisibilityChange : null,
          ),
          const SizedBox(height: 10),
          if (isLimitedVisibilityShow)
            RoomVisibilityItem(
              iconData: Atlas.users,
              title: lang.limited,
              subtitle: lang.limitedVisibilitySubtitle,
              selectedVisibilityValue: selectedVisibilityEnum,
              spaceVisibilityValue: RoomVisibility.SpaceVisible,
              onChanged: canChange ? onVisibilityChange : null,
            ),
        ],
      ),
    );
  }
}
