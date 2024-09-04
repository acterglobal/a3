import 'package:acter/common/widgets/acter_icon_picker/acter_icon_picker.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter/material.dart';

class ActerIconWidget extends StatefulWidget {
  final double? iconSize;
  final Color defaultColor;
  final ActerIcons defaultIcon;
  final Function(Color, ActerIcons)? onIconSelection;

  const ActerIconWidget({
    super.key,
    this.iconSize,
    this.defaultColor = Colors.blueGrey,
    this.defaultIcon = ActerIcons.list,
    this.onIconSelection,
  });

  @override
  State<ActerIconWidget> createState() => _ActerIconWidgetState();
}

class _ActerIconWidgetState extends State<ActerIconWidget> {
  late Color color;
  late ActerIcons acterIcon;

  @override
  void initState() {
    super.initState();
    color = widget.defaultColor;
    acterIcon = widget.defaultIcon;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => showActerIconPicker(
        context: context,
        selectedColor: color,
        selectedIcon: acterIcon,
        onIconSelection: (selectedColor, selectedIcon) {
          color = selectedColor;
          acterIcon = selectedIcon;
          setState(() {});
          if (widget.onIconSelection != null) {
            widget.onIconSelection!(selectedColor, selectedIcon);
          }
        },
      ),
      child: _buildIconUI(),
    );
  }

  Widget _buildIconUI() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(100)),
        ),
        child: Icon(acterIcon.data, size: widget.iconSize ?? 70),
      ),
    );
  }
}
