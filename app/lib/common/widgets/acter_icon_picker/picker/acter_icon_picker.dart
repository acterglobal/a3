import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

void showActerIconPicker({
  required BuildContext context,
  required final Color selectedColor,
  required final ActerIcon selectedIcon,
  final Function(Color, ActerIcon)? onIconSelection,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    builder: (context) {
      return ActerIconPicker(
        selectedColor: selectedColor,
        selectedIcon: selectedIcon,
        onIconSelection: onIconSelection,
      );
    },
  );
}

class ActerIconPicker extends StatefulWidget {
  final Color selectedColor;
  final ActerIcon selectedIcon;
  final Function(Color, ActerIcon)? onIconSelection;

  const ActerIconPicker({
    super.key,
    required this.selectedColor,
    required this.selectedIcon,
    this.onIconSelection,
  });

  @override
  State<ActerIconPicker> createState() => _ActerIconPickerState();
}

class _ActerIconPickerState extends State<ActerIconPicker> {
  final ValueNotifier<Color> selectedColor = ValueNotifier(Colors.blueGrey);
  final ValueNotifier<ActerIcon> selectedIcon = ValueNotifier(ActerIcon.list);

  @override
  void initState() {
    super.initState();
    selectedColor.value = widget.selectedColor;
    selectedIcon.value = widget.selectedIcon;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIconPreviewUI(),
          const SizedBox(height: 24),
          _buildColorSelector(),
          const SizedBox(height: 24),
          Expanded(child: _buildIconSelector()),
          ActerPrimaryActionButton(
            onPressed: () {
              widget.onIconSelection.let((cb) {
                cb(selectedColor.value, selectedIcon.value);
              });
              Navigator.pop(context);
            },
            child: Text(L10n.of(context).select),
          ),
        ],
      ),
    );
  }

  Widget _buildIconPreviewUI() {
    return ValueListenableBuilder<Color>(
      valueListenable: selectedColor,
      builder: (context, color, child) {
        return ValueListenableBuilder<ActerIcon>(
          valueListenable: selectedIcon,
          builder: (context, acterIcon, child) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  acterIcon.data,
                  size: 100,
                  color: color,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).selectColor),
        const SizedBox(height: 12),
        Wrap(
          children: iconPickerColors
              .map((color) => _buildColorBoxItem(color))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildColorBoxItem(Color colorItem) {
    return ValueListenableBuilder<Color>(
      valueListenable: selectedColor,
      builder: (context, color, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => selectedColor.value = colorItem,
          child: Container(
            height: 40,
            width: 40,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorItem,
              border: colorItem == color
                  ? Border.all(color: Colors.white, width: 1)
                  : null,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).selectIcon),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              children: ActerIcon.values
                  .map((acterIcon) => _buildIconBoxItem(acterIcon))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconBoxItem(ActerIcon acterIconItem) {
    return ValueListenableBuilder<ActerIcon>(
      valueListenable: selectedIcon,
      builder: (context, acterIcon, child) {
        return InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => selectedIcon.value = acterIconItem,
          child: Container(
            height: 45,
            width: 45,
            alignment: Alignment.center,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              border: acterIconItem == acterIcon
                  ? Border.all(color: Colors.white, width: 1)
                  : null,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
            child: Icon(acterIconItem.data),
          ),
        );
      },
    );
  }
}
