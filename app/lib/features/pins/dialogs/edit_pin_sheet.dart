import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// interface data providers
final titleProvider = StateProvider<String>((ref) => '');
final textProvider = StateProvider<String>((ref) => '');
final linkProvider = StateProvider<String>((ref) => '');

class EditPinSheet extends ConsumerStatefulWidget {
  final String pinId;
  const EditPinSheet({super.key, required this.pinId});

  @override
  ConsumerState<EditPinSheet> createState() => _EditPinSheetConsumerState();
}

class _EditPinSheetConsumerState extends ConsumerState<EditPinSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _pinData();
  }

  // apply existing data to fields
  void _pinData() async {
    final pin = await ref.read(
      pinProvider(widget.pinId).future,
    );
    _titleController.text = pin.title();
    _textController.text = pin.contentText() ?? '';
    _urlController.text = pin.url() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SideSheet(
      header: 'Edit Pin',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextFormField(
                          decoration: InputDecoration(
                            hintText: 'Your title',
                            labelText: 'Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          controller: _titleController,
                          validator: (value) =>
                              (value != null && value.isNotEmpty)
                                  ? null
                                  : 'Please enter a title',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                decoration: InputDecoration(
                  icon: const Icon(Atlas.link_thin),
                  hintText: 'https://',
                  labelText: 'link',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                validator: (value) => (value != null && value.isNotEmpty)
                    ? null
                    : _textController.text.isEmpty
                        ? 'Text or URL must be given'
                        : null,
                controller: _urlController,
              ),
              MdEditorWithPreview(
                validator: (value) => (value != null && value.isNotEmpty)
                    ? null
                    : _urlController.text.isEmpty
                        ? 'Text or URL must be given'
                        : null,
                controller: _textController,
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(Routes.main.name),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              popUpDialog(
                context: context,
                title: Text(
                  'Saving Pin update',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                isLoader: true,
              );
              try {
                final pin = await ref.read(
                  pinProvider(widget.pinId).future,
                );

                final updateBuild = pin.updateBuilder();
                var hasChanges = false;

                if (_titleController.text != pin.title()) {
                  updateBuild.title(_titleController.text);
                  hasChanges = true;
                }

                if (_textController.text != pin.contentText()) {
                  updateBuild.contentMarkdown(_textController.text);
                  hasChanges = true;
                }
                if (_urlController.text != pin.url()) {
                  updateBuild.url(_urlController.text);
                  hasChanges = true;
                }

                if (hasChanges) {
                  await updateBuild.send();
                }
                // We are doing as expected, but the lints triggers.
                // ignore: use_build_context_synchronously
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context, rootNavigator: true).pop();
                context.goNamed(
                  Routes.pin.name,
                  pathParameters: {'pinId': widget.pinId.toString()},
                );
              } catch (e) {
                // We are doing as expected, but the lints triggers.
                // ignore: use_build_context_synchronously
                if (!context.mounted) {
                  return;
                }
                customMsgSnackbar(context, 'Failed to update pin: $e');
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
