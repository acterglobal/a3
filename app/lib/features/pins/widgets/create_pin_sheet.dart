import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatePinSheet extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  const CreatePinSheet({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<CreatePinSheet> createState() => _CreatePinSheetConsumerState();
}

class _CreatePinSheetConsumerState extends ConsumerState<CreatePinSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final spaceNotifier = ref.read(selectedSpaceIdProvider.notifier);
      spaceNotifier.state = widget.initialSelectedSpace;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasLinkOrText() {
      return _linkController.text.trim().isNotEmpty ||
          _textController.text.trim().isNotEmpty;
    }

    return SideSheet(
      header: 'Create new Pin',
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
                    validator: (value) =>
                        (value != null && value.trim().isNotEmpty)
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
                    controller: _linkController,
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
                    child: MdEditorWithPreview(
                      validator: (value) =>
                          hasLinkOrText() ? null : 'Text or URL must be given',
                      controller: _textController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const SelectSpaceFormField(canCheck: 'CanPostPin'),
            ],
          ),
        ),
      ),
      confirmActionTitle: 'Create Pin',
      cancelActionTitle: 'Cancel',
      confirmActionOnPressed: () async {
        if (_formKey.currentState!.validate()) {
          showAdaptiveDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) => DefaultDialog(
              title: Text(
                'Posting Pin',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              isLoader: true,
            ),
          );
          _handleCreatePin();
        }
      },
    );
  }

  void _handleCreatePin() async {
    try {
      final spaceId = ref.read(selectedSpaceIdProvider);
      final space = await ref.read(spaceProvider(spaceId!).future);
      final pinDraft = space.pinDraft();
      final title = _titleController.text;
      final text = _textController.text;
      final url = _linkController.text;

      if (title.trim().isNotEmpty) {
        pinDraft.title(title);
      }

      if (text.isNotEmpty) {
        pinDraft.contentMarkdown(text);
      }
      if (url.isNotEmpty) {
        pinDraft.url(url);
      }
      final pinId = await pinDraft.send();
      // reset controllers
      _textController.text = '';
      _linkController.text = '';

      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      Navigator.of(context, rootNavigator: true).pop();
      context.pushNamed(
        Routes.pin.name,
        pathParameters: {'pinId': pinId.toString()},
      );
    } catch (e) {
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      customMsgSnackbar(context, 'Failed to pin: $e');
    }
  }
}
