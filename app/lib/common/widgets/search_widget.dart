import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class SearchWidget extends StatelessWidget {
  final TextEditingController searchController;
  final Function(dynamic) onChanged;
  final Function()? onReset;
  const SearchWidget({
    Key? key,
    required this.searchController,
    required this.onChanged,
    this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.background,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.neutral4,
                ),
                prefixIcon: const Icon(Atlas.magnifying_glass),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              cursorColor: Colors.white,
              controller: searchController,
              onChanged: (value) {
                onChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
