import 'package:acter/common/utils/constants.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ServerSelectionField extends StatefulWidget {
  final List<ServerEntry> options;
  final void Function(String) onSelect;
  final String currentSelection;
  final bool autofocus;

  const ServerSelectionField({
    super.key,
    required this.options,
    required this.onSelect,
    required this.currentSelection,
    this.autofocus = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _ServerSelectionFieldState createState() => _ServerSelectionFieldState();
}

class _ServerSelectionFieldState extends State<ServerSelectionField> {
  bool editMode = false;

  void setEditing() {
    setState(() => editMode = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!editMode) {
      return TextFormField(
        initialValue: widget.currentSelection,
        style: TextStyle(color: Theme.of(context).hintColor),
        onTap: () {
          setState(() => editMode = true);
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: L10n.of(context).server,
          suffix: Icon(
            Icons.edit,
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }
    return TypeAheadField<ServerEntry>(
      suggestionsCallback: (search) => widget.options
          .where(
            (element) =>
                element.value.contains(search) ||
                element.name?.contains(search) == true,
          )
          .toList(),
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onTapOutside: (pointer) {
            // close edit mode when the user clicks elsewhere
            setState(() => editMode = false);
          },
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: L10n.of(context).server,
            suffix: InkWell(
              onTap: () {
                onSubmit(controller.text);
              },
              child: const Icon(Icons.send),
            ),
          ),
        );
      },
      itemBuilder: (context, entry) =>
          entry.name.map(
            (p0) => ListTile(
              title: Text(p0),
              subtitle: Text(entry.value),
            ),
          ) ??
          ListTile(
            title: Text(entry.value),
          ),
      onSelected: (entry) => onSubmit(entry.value),
    );
  }

  void onSubmit(String selected) {
    setState(() => editMode = false);
    widget.onSelect(selected);
  }
}
