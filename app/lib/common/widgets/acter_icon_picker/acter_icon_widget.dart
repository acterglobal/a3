import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/picker/acter_icon_picker.dart';
import 'package:flutter/material.dart';

class ActerIconWidget extends StatefulWidget {
  final double? iconSize;
  final Color? color;
  final ActerIcon? icon;
  final bool showEditIconIndicator;
  final Function(Color, ActerIcon)? onIconSelection;

  const ActerIconWidget({
    super.key,
    this.iconSize,
    this.color,
    this.icon,
    this.showEditIconIndicator = false,
    this.onIconSelection,
  });

  @override
  State<ActerIconWidget> createState() => _ActerIconWidgetState();
}

class _ActerIconWidgetState extends State<ActerIconWidget> {
  final ValueNotifier<Color> color = ValueNotifier(Colors.grey);
  final ValueNotifier<ActerIcon> icon = ValueNotifier(ActerIcon.list);

  void _setWidgetValues() {
    widget.color.map((clr) => color.value = clr);
    widget.icon.map((icn) => icon.value = icn);
  }

  @override
  void initState() {
    super.initState();
    _setWidgetValues();
  }

  @override
  void didUpdateWidget(ActerIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color || oldWidget.icon != widget.icon) {
      _setWidgetValues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: widget.onIconSelection.map(
        (cb) => () {
          showActerIconPicker(
            context: context,
            selectedColor: color.value,
            selectedIcon: icon.value,
            onIconSelection: (selectedColor, selectedIcon) {
              color.value = selectedColor;
              icon.value = selectedIcon;
              cb(selectedColor, selectedIcon);
            },
          );
        },
      ),
      child:
          widget.showEditIconIndicator
              ? _buildEditIconUI(context)
              : _buildIconUI(),
    );
  }

  Widget _buildIconUI() {
    return ValueListenableBuilder<Color>(
      valueListenable: color,
      builder:
          (context, colorData, child) => ValueListenableBuilder<ActerIcon>(
            valueListenable: icon,
            builder:
                (context, acterIcon, child) => Icon(
                  acterIcon.data,
                  size: widget.iconSize ?? 70,
                  color: colorData,
                ),
          ),
    );
  }

  Widget _buildEditIconUI(BuildContext context) {
    final borderColor = Theme.of(context).unselectedWidgetColor;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(width: 2, color: borderColor),
        ),
        child: Stack(
          children: [
            Padding(padding: const EdgeInsets.all(16), child: _buildIconUI()),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(width: 1, color: borderColor),
                    color: borderColor,
                  ),
                  child: const Icon(Icons.edit, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
