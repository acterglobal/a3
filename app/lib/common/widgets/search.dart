import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  final TextEditingController searchController;
  final Function(dynamic) onChanged;
  
  const Search({super.key, required this.searchController, required this.onChanged});

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
                    color: Theme.of(context).colorScheme.neutral4),
                prefixIcon: const Icon(Atlas.magnifying_glass),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              cursorColor: Colors.white,
              controller: searchController,
              onChanged: (value){
                onChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
