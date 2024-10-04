import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchValueProvider = StateProvider.autoDispose<String>((ref) => '');

class ActerSearchWidget extends ConsumerWidget {
  final TextEditingController searchTextController;

  const ActerSearchWidget({
    super.key,
    required this.searchTextController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildSearchBar(context, ref);
  }

  Widget _buildSearchBar(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: SearchBar(
        controller: searchTextController,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Atlas.magnifying_glass),
        ),
        hintText: L10n.of(context).search,
        trailing: searchTextController.text.isNotEmpty
            ? [
                IconButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    ref.read(searchValueProvider.notifier).state = '';
                    searchTextController.clear();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ]
            : null,
        onChanged: (value) =>
            ref.read(searchValueProvider.notifier).state = value,
      ),
    );
  }
}
