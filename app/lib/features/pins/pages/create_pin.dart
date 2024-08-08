import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/pins/widgets/pin_attachment_options.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

const createPinPageKey = Key('create-pin-page');
const titleFieldKey = Key('create-pin-title-field');
const descriptionFieldKey = Key('create-pin-description-field');
const submitBtn = Key('create-pin-submit');

class CreatePin extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;

  const CreatePin({
    super.key = createPinPageKey,
    this.initialSelectedSpace,
  });

  @override
  ConsumerState<CreatePin> createState() => _CreatePinConsumerState();
}

class _CreatePinConsumerState extends ConsumerState<CreatePin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  EditorState textEditorState = EditorState.blank();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      if (widget.initialSelectedSpace != null &&
          widget.initialSelectedSpace!.isNotEmpty) {
        final parentNotifier = ref.read(selectedSpaceIdProvider.notifier);
        parentNotifier.state = widget.initialSelectedSpace;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildBody()),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(L10n.of(context).createPin),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 15),
                    _buildTitleField(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SelectSpaceFormField(
                        canCheck: 'CanPostPin',
                        isCompactView: true,
                      ),
                    ),
                    const SizedBox(height: 15),
                    attachmentHeader(),
                    const PinAttachmentOptions(),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
          _buildCreateButton(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).title),
        const SizedBox(height: 6),
        InputTextField(
          hintText: L10n.of(context).pinName,
          key: titleFieldKey,
          textInputType: TextInputType.text,
          controller: _titleController,
          validator: (value) => (value != null && value.trim().isNotEmpty)
              ? null
              : L10n.of(context).pleaseEnterATitle,
        ),
      ],
    );
  }

  Widget attachmentHeader() {
    return Row(
      children: [
        Expanded(child: Text(L10n.of(context).attachments)),
        ActerInlineTextButton(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (context) => const PinAttachmentOptions(),
            );
          },
          child: Text(L10n.of(context).add),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return ActerPrimaryActionButton(
      key: submitBtn,
      onPressed: () {},
      child: Text(L10n.of(context).create),
    );
  }
}
