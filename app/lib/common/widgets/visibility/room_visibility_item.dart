import 'package:acter/common/utils/utils.dart';
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
        key: spaceVisibilityValue.let((val) => generateKey(val)),
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
            ? spaceVisibilityValue.let(
                (val) => onChanged.let((cb) => () => cb(val)),
              )
            : null,
        trailing: !isShowRadio
            ? const Icon(Icons.keyboard_arrow_down_sharp)
            : spaceVisibilityValue.let(
                  (val) => Radio<RoomVisibility>(
                    value: val,
                    groupValue: selectedVisibilityValue,
                    onChanged: onChanged.let((cb) => (value) => cb(value)),
                  ),
                ) ??
                const Icon(Icons.keyboard_arrow_down_sharp),
      ),
    );
  }
}
