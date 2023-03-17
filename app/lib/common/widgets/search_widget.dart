import 'package:acter/common/themes/seperated_themes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:searchbar_animation/searchbar_animation.dart';

class SearchWidget extends StatelessWidget {
  final TextEditingController searchController;
  final Function(dynamic) onChanged;
  final Function() onReset;
  const SearchWidget({
    Key? key,
    required this.searchController,
    required this.onChanged,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SearchBarAnimation(
        textEditingController: searchController,
        isOriginalAnimation: false,
        enableKeyboardFocus: true,
        buttonBorderColour: AppCommonTheme.darkShade,
        buttonWidget: const Icon(
          Atlas.magnifying_glass,
          color: AppCommonTheme.primaryColor,
        ),
        onFieldSubmitted: (String value) {
          debugPrint('onFieldSubmitted value $value');
        },
        onChanged: (value) {
          onChanged(value);
        },
        onPressButton: (isOpen) {
          if (!isOpen) {
            searchController.clear();
            onReset();
          }
        },
        secondaryButtonWidget: const Icon(
          Icons.close,
          color: AppCommonTheme.primaryColor,
        ),
        trailingWidget: const Icon(Icons.search),
      ),
    );
  }
}
