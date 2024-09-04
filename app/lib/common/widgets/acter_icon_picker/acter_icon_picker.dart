import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/providers/acter_icon_picker_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showActerIconPicker({required BuildContext context}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    builder: (context) {
      return const ActerIconPicker();
    },
  );
}

class ActerIconPicker extends StatelessWidget {
  const ActerIconPicker({super.key});

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
    return Consumer(
      builder: (context, ref, child) {
        final selectedColor =
            ref.watch(acterIconPickerStateProvider).selectedColor;
        final selectedIcon =
            ref.watch(acterIconPickerStateProvider).selectedIcon;
        return Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
            child: Icon(selectedIcon, size: 70),
          ),
        );
      },
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

  Widget _buildColorBoxItem(Color color) {
    return Consumer(builder: (context, ref, child) {
      final selectedColor =
          ref.watch(acterIconPickerStateProvider).selectedColor;
      return InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () =>
            ref.read(acterIconPickerStateProvider.notifier).selectColor(color),
        child: Container(
          height: 40,
          width: 40,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            border: selectedColor == color
                ? Border.all(color: Colors.white, width: 1)
                : null,
            borderRadius: const BorderRadius.all(Radius.circular(100)),
          ),
        ),
      );
    });
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
              children: ActerIcons.values
                  .map((acterIcon) => _buildIconBoxItem(acterIcon))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconBoxItem(ActerIcons acterIcon) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedIcon =
            ref.watch(acterIconPickerStateProvider).selectedIcon;
        return InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: () => ref
              .read(acterIconPickerStateProvider.notifier)
              .selectIcon(acterIcon),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              border: selectedIcon == acterIcon.data
                  ? Border.all(color: Colors.white, width: 1)
                  : null,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
            child: Icon(acterIcon.data),
          ),
        );
      },
    );
  }
}
