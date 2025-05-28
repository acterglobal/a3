import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/features/events/model/event_location_model.dart';
import 'package:acter/features/events/model/keys.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddEventLocationWidget extends ConsumerStatefulWidget {
  final Function(EventLocationDraft) onAdd;

  const AddEventLocationWidget({super.key, required this.onAdd});

  @override
  ConsumerState<AddEventLocationWidget> createState() =>
      _AddEventLocationWidgetState();
}

class _AddEventLocationWidgetState
    extends ConsumerState<AddEventLocationWidget> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'location form key');
  final _locationNameController = TextEditingController();
  final _locationUrlController = TextEditingController();

  EditorState textEditorNoteState = EditorState.blank();
  EditorState textEditorAddressState = EditorState.blank();
  LocationType _selectedType = LocationType.virtual;
  String? _addressError;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTypeSelector(context),
              const SizedBox(height: 16),
              _buildLocationNameField(context),
              const SizedBox(height: 10),
              if (_selectedType == LocationType.virtual)
                _buildLocationUrlField(context)
              else
                _buildLocationAddressField(context),
              const SizedBox(height: 10),
              _buildNoteField(context),
              const SizedBox(height: 40),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context) {
    final lang = L10n.of(context);
    return Row(
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
    );
  }

  // Event name field
  Widget _buildLocationNameField(BuildContext context) {
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

  Widget _buildLocationUrlField(BuildContext context) {
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
          controller: _locationUrlController,
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

  Widget _buildLocationAddressField(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.addLocationAddress),
        const SizedBox(height: 10),
        InputDecorator(
          decoration: InputDecoration(
            hintText: lang.enterLocationAddress,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            contentPadding: const EdgeInsets.all(12),
            errorText: _addressError,
          ),
          child: SizedBox(
            height: 100,
            child: HtmlEditor(
              key: EventsKeys.eventLocationAddressTextField,
              editorState: textEditorAddressState,
              editable: true,
              hintText: lang.enterLocationAddress,
              onChanged: (body, html) {
                setState(() {
                  textEditorAddressState = EditorState(
                    document: ActerDocumentHelpers.parse(
                      body,
                      htmlContent: html,
                    ),
                  );
                  _addressError = null; // Clear error on change
                });
              },
            ),
          ),
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
              editorState: textEditorNoteState,
              editable: true,
              hintText: lang.enterNote,
              onChanged: (body, html) {
                textEditorNoteState = EditorState(
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
          onPressed: () => _addLocation(),
          child: Text(lang.addLocation),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(lang.cancel),
        ),
      ],
    );
  }

  void _addLocation() {
    bool valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _addressError = null;
    });
    if (_selectedType == LocationType.realWorld) {
      final address = textEditorAddressState.intoMarkdown().trim();
      if (address.isEmpty) {
        setState(() {
          _addressError = L10n.of(context).pleaseEnterLocationAddress;
        });
        valid = false;
      }
    }
    if (valid) {
      final location = EventLocationDraft(
        name: _locationNameController.text,
        type: _selectedType,
        url:
            _selectedType == LocationType.virtual
                ? _locationUrlController.text
                : null,
        address:
            _selectedType == LocationType.realWorld
                ? textEditorAddressState.intoMarkdown()
                : null,
        note: textEditorNoteState.intoMarkdown(),
      );
      widget.onAdd(location);
    }
  }
}
