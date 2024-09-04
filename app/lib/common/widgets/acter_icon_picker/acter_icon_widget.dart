import 'package:acter/common/widgets/acter_icon_picker/acter_icon_picker.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/providers/acter_icon_picker_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActerIconWidget extends ConsumerStatefulWidget {
  final ActerIcons? defaultIcon;

  const ActerIconWidget({
    super.key,
    this.defaultIcon,
  });

  @override
  ConsumerState<ActerIconWidget> createState() => _ActerIconWidgetState();
}

class _ActerIconWidgetState extends ConsumerState<ActerIconWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.defaultIcon != null) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        ref
            .read(acterIconPickerStateProvider.notifier)
            .selectIcon(widget.defaultIcon!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = ref.watch(acterIconPickerStateProvider).selectedColor;
    final selectedIcon = ref.watch(acterIconPickerStateProvider).selectedIcon;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => showActerIconPicker(context: context),
      child: _buildIconUI(ref, selectedColor, selectedIcon),
    );
  }

  Widget _buildIconUI(
    WidgetRef ref,
    Color selectedColor,
    IconData selectedIcon,
  ) {
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
  }
}
