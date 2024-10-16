import 'package:acter/common/extensions/options.dart';
import 'package:flutter/material.dart';

class MenuItemWidget extends StatelessWidget {
  final IconData? iconData;
  final Color? iconColor;
  final String title;
  final TextStyle? titleStyles;
  final String? subTitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool withMenu;
  final Widget? trailing;
  final Key? innerKey;
  final VisualDensity? visualDensity;

  const MenuItemWidget({
    super.key,
    this.innerKey,
    this.iconData,
    this.iconColor,
    this.trailing,
    required this.title,
    this.visualDensity,
    this.titleStyles,
    this.subTitle,
    this.onTap,
    this.enabled = true,
    this.withMenu = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: innerKey,
        onTap: onTap,
        visualDensity: visualDensity,
        leading: iconData.let(
          (data) => Icon(
            data,
            color: enabled ? iconColor : Theme.of(context).disabledColor,
          ),
        ),
        title: Text(
          title,
          style: titleStyles?.copyWith(
            color: enabled ? null : Theme.of(context).disabledColor,
          ),
        ),
        subtitle: subTitle.let(
          (t) => Text(
            t,
            style: titleStyles?.copyWith(
              color: enabled ? null : Theme.of(context).disabledColor,
            ),
          ),
        ),
        trailing: trailing ??
            (withMenu ? const Icon(Icons.keyboard_arrow_right_outlined) : null),
      ),
    );
  }
}
