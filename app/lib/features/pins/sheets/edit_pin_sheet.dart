import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
  MsgContent? pinContent;

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
    pinContent = pin.content();
    _titleController.text = pin.title();
    if (pinContent != null) {
      _textController.text = pinContent!.body();
    } else {
      _textController.text = '';
    }
    _urlController.text = pin.url() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(featuresProvider);
    bool isActive(f) => provider.isActive(f);
    bool hasLinkOrText() {
      return _urlController.text.isNotEmpty || _textController.text.isNotEmpty;
    }

    return SideSheet(
      header: 'Edit Pin',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text('Title'),
                  ),
                  InputTextField(
                    hintText: 'Pin Name',
                    textInputType: TextInputType.text,
                    controller: _titleController,
                    validator: (value) => (value != null && value.isNotEmpty)
                        ? null
                        : 'Please enter a title',
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text('Link'),
                  ),
                  InputTextField(
                    hintText: 'https://',
                    textInputType: TextInputType.url,
                    controller: _urlController,
                    validator: (value) =>
                        hasLinkOrText() ? null : 'Text or URL must be given',
                  ),
                  const SizedBox(height: 15),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Text('Description'),
                  ),
                  SizedBox(
                    height: 200,
                    child: !isActive(LabsFeature.showPinRichEditor)
                        ? MdEditorWithPreview(
                            validator: (value) => hasLinkOrText()
                                ? null
                                : 'Text or URL must be given',
                            controller: _textController,
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.tertiary,
                                width: 1.5,
                              ),
                            ),
                            child: HtmlEditor(
                              content: pinContent,
                              autoFocus: false,
                              footer: const SizedBox(),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
      confirmActionTitle: 'Save',
      cancelActionTitle: 'Cancel',
      confirmActionOnPressed: () async {
        if (_formKey.currentState!.validate()) {
          showAdaptiveDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => DefaultDialog(
              title: Text(
                'Saving changes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              isLoader: true,
            ),
          );
          _handleEditPin();
        }
      },
    );
  }

  void _handleEditPin() async {
    try {
      final pin = await ref.read(
        pinProvider(widget.pinId).future,
      );
      final pinContent = pin.content();

      final updateBuild = pin.updateBuilder();
      var hasChanges = false;

      if (_titleController.text != pin.title()) {
        updateBuild.title(_titleController.text);
        hasChanges = true;
      }

      if (pinContent != null && _textController.text != pinContent.body()) {
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
      Navigator.of(context, rootNavigator: true)
          .pop(); // pop the loading screen
      Navigator.of(context, rootNavigator: true).pop(); // pop the edit sheet
      context.pushNamed(
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
}
