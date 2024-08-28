import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class PinIcon extends StatelessWidget {
  final Color? iconColor;

  const PinIcon({
    super.key,
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
      child: const Icon(Atlas.pin),
    );
  }
}
