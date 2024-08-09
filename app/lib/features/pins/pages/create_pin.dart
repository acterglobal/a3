import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/pins/Utils/pins_utils.dart';
import 'package:acter/features/pins/models/create_pin_state/create_pin_state.dart';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_attachment_options.dart';
import 'package:acter/features/pins/widgets/pin_link_bottom_sheet.dart';
import 'package:atlas_icons/atlas_icons.dart';
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
    final pinState = ref.watch(createPinStateProvider);
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
                    _pinDescription(pinState),
                    attachmentHeader(pinState),
                    if (pinState.pinAttachmentList.isEmpty)
                      const PinAttachmentOptions()
                    else
                      attachmentListUI(pinState),
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
          textInputAction: TextInputAction.done,
          controller: _titleController,
          onInputChanged: (text) => ref
              .read(createPinStateProvider.notifier)
              .setPinTitleValue(text ?? ''),
          validator: (value) => (value != null && value.trim().isNotEmpty)
              ? null
              : L10n.of(context).pleaseEnterATitle,
        ),
      ],
    );
  }

  Widget attachmentHeader(CreatePinState pinState) {
    return Row(
      children: [
        Expanded(child: Text(L10n.of(context).attachments)),
        if (pinState.pinAttachmentList.isNotEmpty)
          ActerInlineTextButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => const PinAttachmentOptions(
                  isBottomSheetOpen: true,
                ),
              );
            },
            child: Text(L10n.of(context).add),
          ),
      ],
    );
  }

  Widget attachmentListUI(CreatePinState pinState) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: pinState.pinAttachmentList.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final attachmentData = pinState.pinAttachmentList[index];
        return attachmentItemUI(attachmentData, index);
      },
    );
  }

  Widget attachmentItemUI(PinAttachment attachmentData, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: attachmentLeadingIcon(attachmentData.pinAttachmentType),
        onTap: () => attachmentItemOnTap(attachmentData, index),
        title: Text(
          attachmentData.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (attachmentData.pinAttachmentType == PinAttachmentType.link)
              Text(attachmentData.link ?? '')
            else ...[
              Text(attachmentData.size ?? ''),
              const SizedBox(width: 10),
              const Text('.'),
              const SizedBox(width: 10),
              Text(
                documentTypeFromFileExtension(
                  attachmentData.fileExtension ?? '',
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          onPressed: () =>
              ref.read(createPinStateProvider.notifier).removeAttachment(index),
          icon: const Icon(
            Atlas.xmark_circle,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  void attachmentItemOnTap(PinAttachment attachmentData, int index) {
    if (attachmentData.pinAttachmentType == PinAttachmentType.link) {
      showPinLinkBottomSheet(
        context: context,
        pinTitle: attachmentData.title,
        pinLink: attachmentData.link,
        onSave: (title, link) {
          Navigator.pop(context);
          final pinAttachment = attachmentData.copyWith(
            title: title,
            link: link,
          );
          ref
              .read(createPinStateProvider.notifier)
              .changeAttachmentTitle(pinAttachment, index);
        },
      );
    } else {
      showEditTitleBottomSheet(
        context: context,
        titleValue: attachmentData.title,
        onSave: (newTitle) {
          Navigator.pop(context);
          final pinAttachment = attachmentData.copyWith(title: newTitle);
          ref
              .read(createPinStateProvider.notifier)
              .changeAttachmentTitle(pinAttachment, index);
        },
      );
    }
  }

  Widget attachmentLeadingIcon(PinAttachmentType pinAttachmentType) {
    switch (pinAttachmentType) {
      case PinAttachmentType.link:
        return const Icon(Atlas.link);
      case PinAttachmentType.image:
        return const Icon(Atlas.image_gallery);
      case PinAttachmentType.video:
        return const Icon(Atlas.video_camera);
      case PinAttachmentType.audio:
        return const Icon(Atlas.audio_headphones);
      case PinAttachmentType.file:
        return const Icon(Atlas.file);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _pinDescription(CreatePinState pinState) {
    if (pinState.pinDescriptionParams == null ||
        pinState.pinDescriptionParams!.htmlBodyDescription.trim().isEmpty ||
        pinState.pinDescriptionParams!.plainDescription.trim().isEmpty) {
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
                descriptionHtmlValue:
                    pinState.pinDescriptionParams!.htmlBodyDescription,
                descriptionMarkdownValue:
                    pinState.pinDescriptionParams!.plainDescription,
                onSave: (htmlBodyDescription, plainDescription) async {
                  Navigator.pop(context);
                  ref.read(createPinStateProvider.notifier).setDescriptionValue(
                        htmlBodyDescription: htmlBodyDescription,
                        plainDescription: plainDescription,
                      );
                },
              );
            },
            child: pinState.pinDescriptionParams!.htmlBodyDescription.isNotEmpty
                ? RenderHtml(
                    text: pinState.pinDescriptionParams!.htmlBodyDescription,
                    defaultTextStyle: Theme.of(context).textTheme.labelLarge,
                  )
                : Text(
                    pinState.pinDescriptionParams!.plainDescription,
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
