import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter/material.dart';

class PinIcon extends StatelessWidget {
  final IconData? iconData;
  final Color? iconColor;

  const PinIcon({
    super.key,
    this.iconData,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return pinIconUI(context);
  }

  Widget pinIconUI(BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: iconColor ?? Theme.of(context).unselectedWidgetColor,
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: Icon(iconData ?? ActerIcons.pin.data),
    );
  }
}
