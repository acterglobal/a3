import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ActerIconPicker extends ConsumerStatefulWidget {
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
  ConsumerState<ActerIconPicker> createState() => _ActerIconPickerState();
}

class _ActerIconPickerState extends ConsumerState<ActerIconPicker> {
  final ValueNotifier<Color> selectedColor = ValueNotifier(Colors.blueGrey);
  final ValueNotifier<ActerIcon> selectedIcon = ValueNotifier(ActerIcon.list);
  final ValueNotifier<List<ActerIcon>> actorIconList = ValueNotifier(
    ActerIcon.values,
  );

  void _setWidgetValues() {
    widget.selectedColor.map((color) => selectedColor.value = color);
    widget.selectedIcon.map((icon) => selectedIcon.value = icon);
  }

  void _filterIconList(String searchValue) {
    if (searchValue.isEmpty) {
      actorIconList.value = ActerIcon.values;
    } else {
      actorIconList.value =
          ActerIcon.values.where((icon) {
            return icon.name.toLowerCase().contains(searchValue.toLowerCase());
          }).toList();
    }
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIconPreviewAndColorSelectorView(),
          Expanded(child: _buildIconSelector()),
          ActerPrimaryActionButton(
            key: Key('acter-primary-action-button'),
            onPressed: () {
              widget.onIconSelection.map((cb) {
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

  Widget _buildIconPreviewAndColorSelectorView() {
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
      child:
          keyboardVisibility.valueOrNull ?? false
              ? const SizedBox.shrink()
              : Column(
                children: [
                  _buildIconPreviewUI(),
                  const SizedBox(height: 24),
                  _buildColorSelector(),
                  const SizedBox(height: 24),
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
                  key: Key('icon-preview'),
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
    final colorBoxes =
        iconPickerColors
            .asMap()
            .map(
              (index, color) =>
                  MapEntry(index, _buildColorBoxItem(color, index)),
            )
            .values
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).selectColor),
        const SizedBox(height: 12),
        Wrap(children: colorBoxes),
      ],
    );
  }

  Widget _buildColorBoxItem(Color colorItem, int index) {
    return ValueListenableBuilder<Color>(
      valueListenable: selectedColor,
      builder: (context, color, child) {
        return InkWell(
          key: Key('color-picker-$index'),
          borderRadius: BorderRadius.circular(100),
          onTap: () => selectedColor.value = colorItem,
          child: Container(
            height: 40,
            width: 40,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorItem,
              border:
                  colorItem == color
                      ? Border.all(color: Colors.white, width: 1)
                      : null,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchWidget() {
    return ActerSearchWidget(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white12,
      onChanged: _filterIconList,
      onClear: () => _filterIconList(''),
    );
  }

  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(L10n.of(context).selectIcon),
        const SizedBox(height: 5),
        _buildSearchWidget(),
        const SizedBox(height: 5),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: actorIconList,
            builder: (context, iconList, child) {
              if (iconList.isEmpty) {
                return Center(
                  key: Key('no-icons-found'),
                  child: Text(L10n.of(context).noIconsFound),
                );
              }
              return _buildIconsBoxList(iconList);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIconsBoxList(List<ActerIcon> iconList) {
    final iconBoxes =
        iconList
            .asMap()
            .map(
              (index, acterIcon) =>
                  MapEntry(index, _buildIconBoxItem(acterIcon, index)),
            )
            .values
            .toList();
    return SingleChildScrollView(child: Wrap(children: iconBoxes));
  }

  Widget _buildIconBoxItem(ActerIcon acterIconItem, int index) {
    return ValueListenableBuilder<ActerIcon>(
      valueListenable: selectedIcon,
      builder: (context, acterIcon, child) {
        return InkWell(
          key: Key('icon-picker-$index'),
          borderRadius: BorderRadius.circular(100),
          onTap: () => selectedIcon.value = acterIconItem,
          child: Container(
            height: 45,
            width: 45,
            alignment: Alignment.center,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              border:
                  acterIconItem == acterIcon
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
