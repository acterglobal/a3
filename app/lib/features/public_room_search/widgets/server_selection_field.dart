import 'package:acter/common/extensions/options.dart';
import 'package:acter/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
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

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final hintColor = Theme.of(context).hintColor;
    if (!editMode) {
      return TextFormField(
        initialValue: widget.currentSelection,
        style: TextStyle(color: hintColor),
        onTap: () {
          setState(() => editMode = true);
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: lang.server,
          suffix: Icon(Icons.edit, color: hintColor),
        ),
      );
    }
    return TypeAheadField<ServerEntry>(
      suggestionsCallback:
          (search) =>
              widget.options
                  .where(
                    (element) =>
                        element.value.contains(search) ||
                        (element.name?.contains(search) ?? false),
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
            labelText: lang.server,
            suffix: InkWell(
              onTap: () => onSubmit(controller.text),
              child: const Icon(Icons.send),
            ),
          ),
        );
      },
      itemBuilder: (context, entry) {
        return entry.name.map(
              (name) =>
                  ListTile(title: Text(name), subtitle: Text(entry.value)),
            ) ??
            ListTile(title: Text(entry.value));
      },
      onSelected: (entry) => onSubmit(entry.value),
    );
  }

  void onSubmit(String selected) {
    setState(() => editMode = false);
    widget.onSelect(selected);
  }
}
