import 'package:acter/common/widgets/acter_icon_picker/picker/acter_icon_picker.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';

class ActerIconWidget extends StatefulWidget {
  final double? iconSize;
  final Color? color;
  final ActerIcon? icon;
  final Function(Color, ActerIcon)? onIconSelection;

  const ActerIconWidget({
    super.key,
    this.iconSize,
    this.color,
    this.icon,
    this.onIconSelection,
  });

  @override
  State<ActerIconWidget> createState() => _ActerIconWidgetState();
}

class _ActerIconWidgetState extends State<ActerIconWidget> {
  final ValueNotifier<Color> color = ValueNotifier(Colors.grey);
  final ValueNotifier<ActerIcon> icon = ValueNotifier(ActerIcon.list);

  @override
  Widget build(BuildContext context) {
    widget.color.map((p0) => color.value = p0);
    widget.icon.map((p0) => icon.value = p0);
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
                  widget.onIconSelection
                      .map((cb) => cb(selectedColor, selectedIcon));
                },
              ),
      child: _buildIconUI(),
    );
  }

  Widget _buildIconUI() {
    return ValueListenableBuilder<Color>(
      valueListenable: color,
      builder: (context, colorData, child) {
        return ValueListenableBuilder<ActerIcon>(
          valueListenable: icon,
          builder: (context, acterIcon, child) {
            return Icon(
              acterIcon.data,
              size: widget.iconSize ?? 100,
              color: colorData,
            );
          },
        );
      },
    );
  }
}
