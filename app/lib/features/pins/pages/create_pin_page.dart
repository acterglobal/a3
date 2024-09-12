import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/attachments/actions/handle_selected_attachments.dart';
import 'package:acter/features/pins/actions/attachment_leading_icon.dart';
import 'package:acter/features/pins/actions/set_pin_description.dart';
import 'package:acter/features/pins/actions/set_pin_links.dart';
import 'package:acter/features/pins/models/create_pin_state/create_pin_state.dart';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_attachment_options.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::pins::create_pin');

class CreatePinPage extends ConsumerStatefulWidget {
  static const createPinPageKey = Key('create-pin-page');
  static const titleFieldKey = Key('create-pin-title-field');
  static const descriptionFieldKey = Key('create-pin-description-field');
  static const submitBtn = Key('create-pin-submit');

  final String? initialSelectedSpace;

  const CreatePinPage({
    super.key = createPinPageKey,
    this.initialSelectedSpace,
  });

  @override
  ConsumerState<CreatePinPage> createState() => _CreatePinConsumerState();
}

class _CreatePinConsumerState extends ConsumerState<CreatePinPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  ActerIcon? pinIcon;
  Color? pinIconColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final initialSpace = widget.initialSelectedSpace;
      if (initialSpace != null && initialSpace.isNotEmpty) {
        ref.read(selectedSpaceIdProvider.notifier).state = initialSpace;
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
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
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
                      Center(
                        child: ActerIconWidget(
                          icon: pinIcon ?? ActerIcon.pin,
                          onIconSelection: (pinIconColor, pinIcon) {
                            this.pinIcon = pinIcon;
                            this.pinIconColor = pinIconColor;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildTitleField(),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: SelectSpaceFormField(
                          canCheck: 'CanPostPin',
                          useCompatView: true,
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
          key: CreatePinPage.titleFieldKey,
          textInputType: TextInputType.text,
          textInputAction: TextInputAction.done,
          controller: _titleController,
          onInputChanged: (text) => ref
              .read(createPinStateProvider.notifier)
              .setPinTitleValue(text ?? ''),
          validator: (val) => (val != null && val.trim().isNotEmpty)
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
        leading: attachmentLeadingIcon(attachmentData.attachmentType),
        onTap: () => attachmentItemOnTap(attachmentData, index),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attachmentData.title.isNotEmpty)
              Text(
                attachmentData.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (attachmentData.attachmentType == AttachmentType.link)
              Text(attachmentData.link ?? ''),
          ],
        ),
        subtitle: attachmentData.attachmentType == AttachmentType.link
            ? null
            : Row(
                children: [
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
    if (attachmentData.attachmentType == AttachmentType.link) {
      showEditPinLinkBottomSheet(
        context: context,
        ref: ref,
        attachmentData: attachmentData,
        index: index,
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

  Widget _pinDescription(CreatePinState pinState) {
    final params = pinState.pinDescriptionParams;
    if (params == null) return const SizedBox.shrink();
    if (params.htmlBodyDescription.trim().isEmpty ||
        params.plainDescription.trim().isEmpty) {
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
              showEditPinDescriptionBottomSheet(
                context: context,
                ref: ref,
                htmlBodyDescription: params.htmlBodyDescription,
                plainDescription: params.plainDescription,
              );
            },
            child: params.htmlBodyDescription.isNotEmpty
                ? RenderHtml(
                    text: params.htmlBodyDescription,
                    defaultTextStyle: Theme.of(context).textTheme.labelLarge,
                  )
                : Text(
                    params.plainDescription,
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
      key: CreatePinPage.submitBtn,
      onPressed: _createPin,
      child: Text(L10n.of(context).create),
    );
  }

  Future<void> _createPin() async {
    //Close keyboard
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    EasyLoading.show(status: L10n.of(context).creatingPin);
    try {
      final spaceId = ref.read(selectedSpaceIdProvider);
      if (spaceId == null) throw 'Space for pin not selected';
      final space = await ref.read(spaceProvider(spaceId).future);
      final pinDraft = space.pinDraft();
      final pinState = ref.read(createPinStateProvider);

      // Pin IconData
      if (pinIconColor != null || pinIcon != null) {
        final sdk = await ref.watch(sdkProvider.future);
        final displayBuilder = sdk.api.newDisplayBuilder();
        pinIconColor.map((p0) => displayBuilder.color(p0.value));
        pinIcon.map((p0) => displayBuilder.icon('acter-icon', p0.name));
        pinDraft.display(displayBuilder.build());
      }

      // Pin Title
      final pinTitle = pinState.pinTitle;
      if (pinTitle != null && pinTitle.isNotEmpty) {
        pinDraft.title(pinTitle);
      }

      // Pin Description
      final params = pinState.pinDescriptionParams;
      if (params != null) {
        if (params.htmlBodyDescription.isNotEmpty) {
          pinDraft.contentHtml(
            params.plainDescription,
            params.htmlBodyDescription,
          );
        } else {
          pinDraft.contentMarkdown(params.plainDescription);
        }
      }

      final pinId = await pinDraft.send();

      // Add Attachments
      await addAttachment(pinId, pinState);

      EasyLoading.dismiss();
      if (!mounted) return;
      EasyLoading.showToast(L10n.of(context).pinCreatedSuccessfully);
      context.replaceNamed(
        Routes.pin.name,
        pathParameters: {'pinId': pinId.toString()},
      );
    } catch (e, s) {
      _log.severe('Failed to create pin', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).errorCreatingPin(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> addAttachment(EventId pinId, CreatePinState pinState) async {
    final acterPin = await ref.read(pinProvider(pinId.toString()).future);
    final manager = await acterPin.attachments();
    if (!mounted) return;
    for (final attachment in pinState.pinAttachmentList) {
      await handleAttachmentSelected(
        context: context,
        ref: ref,
        manager: manager,
        attachments: attachment.path.map((p0) => [File(p0)]) ?? [],
        title: attachment.title,
        link: attachment.link,
        attachmentType: attachment.attachmentType,
      );
    }
  }
}
