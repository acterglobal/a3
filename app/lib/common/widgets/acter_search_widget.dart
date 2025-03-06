import 'package:acter/common/extensions/options.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class ActerSearchWidget extends StatefulWidget {
  static const searchBarKey = Key('acter-search-bar');
  static const clearSearchActionButtonKey = Key(
    'acter-search-bar-clear-action-btn',
  );

  final String? hintText;
  final String? initialText;
  final Widget? leading;
  final Iterable<Widget>? trailing;
  final EdgeInsetsGeometry padding;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ActerSearchWidget({
    super.key,
    this.hintText,
    this.initialText,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<ActerSearchWidget> createState() => _ActerSearchWidgetState();
}

class _ActerSearchWidgetState extends State<ActerSearchWidget> {
  final TextEditingController searchTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.initialText.map((text) => searchTextController.text = text);
  }

  @override
  void dispose() {
    searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      child: SearchBar(
        key: ActerSearchWidget.searchBarKey,
        controller: searchTextController,
        leading: widget.leading ?? searchLeadingUIWidget(),
        hintText: widget.hintText ?? L10n.of(context).search,
        hintStyle: WidgetStateProperty.all(
          Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: widget.trailing ?? searchTrailingUIWidget(),
        onChanged: (value) => widget.onChanged(value),
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
            key: ActerSearchWidget.clearSearchActionButtonKey,
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              widget.onClear();
              searchTextController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.clear),
          ),
        ]
        : null;
  }
}
