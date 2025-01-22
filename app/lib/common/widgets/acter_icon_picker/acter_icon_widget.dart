import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/picker/acter_icon_picker.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setWidgetValues();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => _showIconPicker(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconUI(),
          if (widget.onIconSelection != null) _buildChangeTextUI(context),
        ],
      ),
    );
  }

  Widget _buildIconUI() {
    return ValueListenableBuilder<Color>(
      valueListenable: color,
      builder: (context, colorData, child) => ValueListenableBuilder<ActerIcon>(
        valueListenable: icon,
        builder: (context, acterIcon, child) => Icon(
          acterIcon.data,
          size: widget.iconSize ?? 100,
          color: colorData,
        ),
      ),
    );
  }

  Widget _buildChangeTextUI(BuildContext context) {
    return ActerInlineTextButton(
      onPressed: () => _showIconPicker(context),
      child: Text(L10n.of(context).change),
    );
  }

  // Extracted method to handle showing the picker
  void _showIconPicker(BuildContext context) {
    showActerIconPicker(
      context: context,
      selectedColor: color.value,
      selectedIcon: icon.value,
      onIconSelection: (selectedColor, selectedIcon) {
        color.value = selectedColor;
        icon.value = selectedIcon;
        widget.onIconSelection?.call(selectedColor, selectedIcon);
      },
    );
  }
}
