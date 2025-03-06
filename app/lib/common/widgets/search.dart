import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class Search extends StatelessWidget {
  final TextEditingController searchController;
  final Function(dynamic) onChanged;

  const Search({
    super.key,
    required this.searchController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: L10n.of(context).search,
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.surface,
                ),
                prefixIcon: const Icon(Atlas.magnifying_glass),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
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
