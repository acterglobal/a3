import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/room/model/room_visibility.dart';
import 'package:flutter/material.dart';

class RoomVisibilityItem extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String subtitle;
  final RoomVisibility? selectedVisibilityValue;
  final RoomVisibility? spaceVisibilityValue;
  final ValueChanged<RoomVisibility?>? onChanged;
  final bool isShowRadio;

  static Key generateKey(RoomVisibility visibility) {
    return Key('select-visibility-${visibility.name}');
  }

  const RoomVisibilityItem({
    super.key,
    required this.iconData,
    required this.title,
    required this.subtitle,
    this.selectedVisibilityValue,
    this.spaceVisibilityValue,
    this.onChanged,
    this.isShowRadio = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        key: spaceVisibilityValue.map((val) => generateKey(val)),
        leading: Icon(iconData),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        onTap: isShowRadio && onChanged != null
            ? spaceVisibilityValue.map(
                (val) => onChanged.map((cb) => () => cb(val)),
              )
            : null,
        trailing: !isShowRadio
            ? const Icon(Icons.keyboard_arrow_down_sharp)
            : spaceVisibilityValue.map(
                  (val) => Radio<RoomVisibility>(
                    value: val,
                    groupValue: selectedVisibilityValue,
                    onChanged: onChanged.map((cb) => (value) => cb(value)),
                  ),
                ) ??
                const Icon(Icons.keyboard_arrow_down_sharp),
      ),
    );
  }
}
