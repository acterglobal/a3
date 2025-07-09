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
    final disabledColor = Theme.of(context).disabledColor;
    return Card(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        key: innerKey,
        onTap: onTap,
        visualDensity: visualDensity,
        leading: iconData.map(
          (data) => Icon(data, color: enabled ? iconColor : disabledColor),
        ),
        title: Text(
          title,
          style: titleStyles?.copyWith(color: enabled ? null : disabledColor),
        ),
        subtitle: subTitle.map(
          (t) => Text(
            t,
            style: titleStyles?.copyWith(color: enabled ? null : disabledColor),
          ),
        ),
        trailing:
            trailing ??
            (withMenu ? const Icon(Icons.keyboard_arrow_right_outlined) : null),
      ),
    );
  }
}
