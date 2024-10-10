import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchValueProvider = StateProvider.autoDispose<String>((ref) => '');

class ActerSearchWidget extends ConsumerStatefulWidget {
  final bool clearInitialSearch;

  const ActerSearchWidget({super.key, this.clearInitialSearch = true});

  @override
  ConsumerState<ActerSearchWidget> createState() => _ActerSearchWidgetState();
}

class _ActerSearchWidgetState extends ConsumerState<ActerSearchWidget> {
  final TextEditingController searchTextController = TextEditingController();

  String get searchValue => ref.watch(searchValueProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      if (widget.clearInitialSearch) {
        searchTextController.text = '';
        ref.read(searchValueProvider.notifier).state = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    searchTextController.text = searchValue;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: SearchBar(
        controller: searchTextController,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Atlas.magnifying_glass),
        ),
        hintText: L10n.of(context).search,
        trailing: searchValue.isNotEmpty
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
        onChanged: (value) {
          ref.read(searchValueProvider.notifier).state = value;
        },
      ),
    );
  }
}
