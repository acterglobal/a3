import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/pins/widgets/pin_attachment_options.dart';
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

  String htmlBodyDescription = '1';
  String plainDescription = '';

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 14),
                    _buildTitleField(),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SelectSpaceFormField(
                        canCheck: 'CanPostPin',
                        isCompactView: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _pinDescription(),
                    attachmentHeader(),
                    PinAttachmentOptions(
                      pinDescriptionParams: (
                        htmlBodyDescription: htmlBodyDescription,
                        plainDescription: plainDescription,
                      ),
                      onAddText: (htmlBodyDescription, plainDescription) {
                        this.htmlBodyDescription = htmlBodyDescription;
                        this.plainDescription = plainDescription;
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 14),
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
              builder: (context) => PinAttachmentOptions(
                pinDescriptionParams: (
                  htmlBodyDescription: htmlBodyDescription,
                  plainDescription: plainDescription,
                ),
                onAddText: (htmlBodyDescription, plainDescription) {
                  this.htmlBodyDescription = htmlBodyDescription;
                  this.plainDescription = plainDescription;
                  setState(() {});
                },
              ),
            );
          },
          child: Text(L10n.of(context).add),
        ),
      ],
    );
  }

  Widget _pinDescription() {
    if (plainDescription.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).description),
        const SizedBox(height: 12),
        SelectionArea(
          child: GestureDetector(
            onTap: () {
              showEditHtmlDescriptionBottomSheet(
                context: context,
                descriptionHtmlValue: htmlBodyDescription,
                descriptionMarkdownValue: plainDescription,
                onSave: (htmlBodyDescription, plainDescription) async {
                  Navigator.pop(context);
                  this.htmlBodyDescription = htmlBodyDescription;
                  this.plainDescription = plainDescription;
                  setState(() {});
                },
              );
            },
            child: htmlBodyDescription.isNotEmpty
                ? RenderHtml(
                    text: htmlBodyDescription,
                    defaultTextStyle: Theme.of(context).textTheme.labelLarge,
                  )
                : Text(
                    plainDescription,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
          ),
        ),
        const SizedBox(height: 20),
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
