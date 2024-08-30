import 'package:acter/common/widgets/icon_picker/model/color_model.dart';
import 'package:acter/common/widgets/icon_picker/model/icon_model.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

void showIconPicker({
  required BuildContext context,
  required Function(String, String) onSave,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    builder: (context) {
      return const IconPicker();
    },
  );
}

class IconPicker extends StatelessWidget {
  const IconPicker({super.key});

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
        ],
      ),
    );
  }

  Widget _buildIconPreviewUI() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        child: const Icon(Atlas.airplane, size: 70),
      ),
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select color'),
        const SizedBox(height: 12),
        Wrap(
          children: iconPickerColors
              .map((colorModel) => _buildColorBoxItem(colorModel))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildColorBoxItem(ColorModel colorModel) {
    return Container(
      height: 40,
      width: 40,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorModel.color,
        border: colorModel.isSelected
            ? Border.all(color: Colors.white, width: 2)
            : null,
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select icon'),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              children: iconsList
                  .map((colorModel) => _buildIconBoxItem(colorModel))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconBoxItem(IconModel iconModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white24,
        border: iconModel.isSelected
            ? Border.all(color: Colors.white, width: 2)
            : null,
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: Icon(iconModel.iconData),
    );
  }
}
