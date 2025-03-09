import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:flutter/material.dart';

class RoomJoinRuleItem extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String subtitle;
  final RoomJoinRule? selectedJoinRuleValue;
  final RoomJoinRule? spaceJoinRuleValue;
  final ValueChanged<RoomJoinRule?>? onChanged;
  final bool isShowRadio;

  static Key generateKey(RoomJoinRule joinRule) {
    return Key('select-joinRule-${joinRule.name}');
  }

  const RoomJoinRuleItem({
    super.key,
    required this.iconData,
    required this.title,
    required this.subtitle,
    this.selectedJoinRuleValue,
    this.spaceJoinRuleValue,
    this.onChanged,
    this.isShowRadio = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        key: spaceJoinRuleValue.map(generateKey),
        leading: Icon(iconData),
        title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        onTap:
            isShowRadio && onChanged != null
                ? spaceJoinRuleValue.map(
                  (val) => onChanged.map((cb) => () => cb(val)),
                )
                : null,
        trailing:
            !isShowRadio
                ? const Icon(Icons.keyboard_arrow_down_sharp)
                : spaceJoinRuleValue.map(
                      (val) => Radio<RoomJoinRule>(
                        value: val,
                        groupValue: selectedJoinRuleValue,
                        onChanged: onChanged.map((cb) => (value) => cb(value)),
                      ),
                    ) ??
                    const Icon(Icons.keyboard_arrow_down_sharp),
      ),
    );
  }
}
