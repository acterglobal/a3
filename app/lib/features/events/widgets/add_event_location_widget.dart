import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/features/events/model/keys.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LocationType { virtual, realWorld }

class AddEventLocationWidget extends ConsumerStatefulWidget {
  const AddEventLocationWidget({super.key});

  @override
  ConsumerState<AddEventLocationWidget> createState() => _AddEventLocationWidgetState();
}

class _AddEventLocationWidgetState extends ConsumerState<AddEventLocationWidget> {
  final _locationNameController = TextEditingController();
  EditorState textEditorState = EditorState.blank();
  LocationType _selectedType = LocationType.virtual;

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilterChip(
              label: Text(lang.virtual),
              selected: _selectedType == LocationType.virtual,
              onSelected: (selected) {
                if (!(_selectedType == LocationType.virtual)) {
                  setState(() => _selectedType = LocationType.virtual);
                }
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(lang.realWorld),
              selected: _selectedType == LocationType.realWorld,
              onSelected: (selected) {
                if (!(_selectedType == LocationType.realWorld)) {
                  setState(() => _selectedType = LocationType.realWorld);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _locationNameField(context),
        const SizedBox(height: 10),
        if (_selectedType == LocationType.virtual)
          _locationUrlField(context)
        else
          _locationAddressField(context),
        const SizedBox(height: 10),
        _buildNoteField(context),
        const SizedBox(height: 40),
        _buildActionButtons(context),
        ],
        ),
      ),
    );
  }

  // Event name field
  Widget _locationNameField(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.locationName),
        const SizedBox(height: 10),
        TextFormField(
          key: EventsKeys.eventLocationNameTextField,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          controller: _locationNameController,
          decoration: InputDecoration(hintText: lang.enterLocationName),
          // required field, space not allowed
          validator:
              (val) =>
                  val == null || val.trim().isEmpty
                      ? lang.pleaseEnterLocationName
                      : null,
        ),
      ],
    );
  }

  Widget _locationUrlField(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.locationUrl),
        const SizedBox(height: 10),
        TextFormField(
          key: EventsKeys.eventLocationUrlTextField,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          controller: _locationNameController,
          decoration: InputDecoration(hintText: lang.enterLocationUrl),
          // required field, space not allowed
          validator:
              (val) =>
                  val == null || val.trim().isEmpty
                      ? lang.pleaseEnterLocationUrl
                      : null,
        ),
      ],
    );
  }

  Widget _locationAddressField(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.addLocationAddress),
        const SizedBox(height: 10),
        TextFormField(
          key: EventsKeys.eventLocationAddressTextField,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          controller: _locationNameController,
          decoration: InputDecoration(hintText: lang.enterLocationAddress),
          // required field, space not allowed
          validator:
              (val) =>
                  val == null || val.trim().isEmpty
                      ? lang.pleaseEnterLocationAddress
                      : null,
        ),
      ],
    );
  }

  Widget _buildNoteField(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.note),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: InputDecoration(
            hintText: lang.enterNote,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          child: SizedBox(
            height: 100,
            child: HtmlEditor(
              key: EventsKeys.eventLocationNoteTextField,
              editorState: textEditorState,
              editable: true,
              autofocus: false,
              onChanged: (body, html) {
                textEditorState = EditorState(
                  document: ActerDocumentHelpers.parse(body, htmlContent: html),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () {},
          child: Text(lang.addLocation),
        ),
        const SizedBox(height: 10),
         OutlinedButton(
          onPressed: () {},
          child: Text(lang.cancel),
        ),
        
      ],
    );
  }
}