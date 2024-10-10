import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ActerSearchWidget extends StatefulWidget {
  final String? hintText;
  final Widget? leading;
  final Iterable<Widget>? trailing;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const ActerSearchWidget({
    super.key,
    this.hintText,
    this.leading,
    this.trailing,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<ActerSearchWidget> createState() => _ActerSearchWidgetState();
}

class _ActerSearchWidgetState extends State<ActerSearchWidget> {
  final TextEditingController searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: SearchBar(
        controller: searchTextController,
        leading: widget.leading ?? searchLeadingUIWidget(),
        hintText: widget.hintText ?? L10n.of(context).search,
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
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                widget.onClear;
                searchTextController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.clear),
            ),
          ]
        : null;
  }
}
