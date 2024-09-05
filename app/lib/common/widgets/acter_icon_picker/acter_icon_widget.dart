import 'package:acter/common/widgets/acter_icon_picker/picker/acter_icon_picker.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter/material.dart';

class ActerIconWidget extends StatefulWidget {
  final double? iconSize;
  final Color? defaultColor;
  final ActerIcons? defaultIcon;
  final Function(Color, ActerIcons)? onIconSelection;

  const ActerIconWidget({
    super.key,
    this.iconSize,
    this.defaultColor,
    this.defaultIcon,
    this.onIconSelection,
  });

  @override
  State<ActerIconWidget> createState() => _ActerIconWidgetState();
}

class _ActerIconWidgetState extends State<ActerIconWidget> {
  final ValueNotifier<Color> color = ValueNotifier(Colors.blueGrey);
  final ValueNotifier<ActerIcons> icon = ValueNotifier(ActerIcons.list);

  @override
  Widget build(BuildContext context) {
    if (widget.defaultColor != null) {
      color.value = widget.defaultColor!;
    }
    if (widget.defaultIcon != null) {
      icon.value = widget.defaultIcon!;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: widget.onIconSelection == null
          ? null
          : () => showActerIconPicker(
                context: context,
                selectedColor: color.value,
                selectedIcon: icon.value,
                onIconSelection: (selectedColor, selectedIcon) {
                  color.value = selectedColor;
                  icon.value = selectedIcon;
                  if (widget.onIconSelection != null) {
                    widget.onIconSelection!(selectedColor, selectedIcon);
                  }
                },
              ),
      child: _buildIconUI(),
    );
  }

  Widget _buildIconUI() {
    return ValueListenableBuilder<Color>(
      valueListenable: color,
      builder: (context, colorData, child) {
        return ValueListenableBuilder<ActerIcons>(
          valueListenable: icon,
          builder: (context, acterIcon, child) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorData,
                borderRadius: const BorderRadius.all(Radius.circular(100)),
              ),
              child: Icon(acterIcon.data, size: widget.iconSize ?? 70),
            );
          },
        );
      },
    );
  }
}
