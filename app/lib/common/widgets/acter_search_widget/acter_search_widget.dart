import 'package:acter/common/widgets/acter_search_widget/providers/acter_search_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActerSearchWidget extends ConsumerStatefulWidget {
  const ActerSearchWidget({super.key});

  @override
  ConsumerState<ActerSearchWidget> createState() => _ActerSearchWidgetState();
}

class _ActerSearchWidgetState extends ConsumerState<ActerSearchWidget> {
  final TextEditingController searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: SearchBar(
        controller: searchTextController,
        leading: searchLeadingUIWidget(),
        hintText: L10n.of(context).search,
        trailing: searchTrailingUIWidget(),
        onChanged: (value) => onChangeSearchText(value),
      ),
    );
  }

  Widget searchLeadingUIWidget() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Icon(Atlas.magnifying_glass),
    );
  }

  Iterable<Widget>? searchTrailingUIWidget() {
    return searchTextController.text.isNotEmpty
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
        : null;
  }

  void onChangeSearchText(String value) {
    ref.read(searchValueProvider.notifier).state = value;
  }
}
