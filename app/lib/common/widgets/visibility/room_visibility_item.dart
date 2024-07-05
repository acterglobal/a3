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
        leading: Icon(iconData),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        onTap: isShowRadio && spaceVisibilityValue != null && onChanged != null
            ? () => onChange(spaceVisibilityValue, context)
            : null,
        trailing: isShowRadio && spaceVisibilityValue != null
            ? Radio<RoomVisibility>(
                value: spaceVisibilityValue!,
                groupValue: selectedVisibilityValue,
                onChanged: onChanged != null
                    ? (value) => onChange(value, context)
                    : null,
              )
            : const Icon(Icons.keyboard_arrow_down_sharp),
      ),
    );
  }

  void onChange(RoomVisibility? value, BuildContext context) {
    if (onChanged != null) onChanged!(value);
  }
}
