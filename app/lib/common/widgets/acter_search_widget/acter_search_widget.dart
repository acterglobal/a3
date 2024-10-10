import 'package:acter/common/widgets/acter_search_widget/providers/acter_search_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActerSearchWidget extends ConsumerStatefulWidget {
  final TextEditingController? searchTextController;
  final String? hintText;
  final Widget? leading;
  final Iterable<Widget>? trailing;
  final Function(String)? onChanged;

  const ActerSearchWidget({
    super.key,
    this.searchTextController,
    this.hintText,
    this.leading,
    this.trailing,
    this.onChanged,
  });

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
        controller: widget.searchTextController ?? searchTextController,
        leading: widget.leading ?? searchLeadingUIWidget(),
        hintText: widget.hintText ?? L10n.of(context).search,
        trailing: widget.trailing ?? searchTrailingUIWidget(),
        onChanged: (value) => widget.onChanged != null
            ? widget.onChanged!(value)
            : onChangeSearchText(value),
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
