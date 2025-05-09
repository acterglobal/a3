import 'dart:io';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/html/render_html.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/attachments/actions/handle_selected_attachments.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter/features/pins/actions/attachment_leading_icon.dart';
import 'package:acter/features/pins/actions/set_pin_description.dart';
import 'package:acter/features/pins/actions/set_pin_links.dart';
import 'package:acter/features/pins/models/create_pin_state/create_pin_state.dart';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_attachment_options.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::pins::create_page');

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
    widget.initialSelectedSpace.map((p0) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        ref.read(selectedSpaceIdProvider.notifier).state = p0;
      });
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
    return AppBar(title: Text(L10n.of(context).createPin));
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
                          showEditIconIndicator: true,
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectSpaceFormField(
                          canCheck: (m) => m?.canString('CanPostPin') == true,
                          useCompactView: true,
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
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.title),
        const SizedBox(height: 6),
        InputTextField(
          hintText: lang.pinName,
          key: CreatePinPage.titleFieldKey,
          textInputType: TextInputType.text,
          textInputAction: TextInputAction.done,
          controller: _titleController,
          onInputChanged: (text) {
            final notifier = ref.read(createPinStateProvider.notifier);
            notifier.setPinTitleValue(text ?? '');
          },
          // required field, space not allowed
          validator:
              (val) =>
                  val == null || val.trim().isEmpty
                      ? lang.pleaseEnterATitle
                      : null,
        ),
      ],
    );
  }

  Widget attachmentHeader(CreatePinState pinState) {
    final lang = L10n.of(context);
    return Row(
      children: [
        Expanded(child: Text(lang.attachments)),
        if (pinState.pinAttachmentList.isNotEmpty)
          ActerInlineTextButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder:
                    (context) =>
                        const PinAttachmentOptions(isBottomSheetOpen: true),
              );
            },
            child: Text(lang.add),
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
        subtitle:
            attachmentData.attachmentType == AttachmentType.link
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
          onPressed: () {
            final notifier = ref.read(createPinStateProvider.notifier);
            notifier.removeAttachment(index);
          },
          icon: const Icon(Atlas.xmark_circle, color: Colors.red),
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
        onSave: (ref, newTitle) {
          Navigator.pop(context);
          final pinAttachment = attachmentData.copyWith(title: newTitle);
          final notifier = ref.read(createPinStateProvider.notifier);
          notifier.changeAttachmentTitle(pinAttachment, index);
        },
      );
    }
  }

  Widget _pinDescription(CreatePinState pinState) {
    final params = pinState.pinDescriptionParams;
    if (params == null ||
        params.htmlBodyDescription.trim().isEmpty ||
        params.plainDescription.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
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
                htmlBodyDescription: params.htmlBodyDescription,
                plainDescription: params.plainDescription,
              );
            },
            child:
                params.htmlBodyDescription.isNotEmpty
                    ? RenderHtml(
                      text: params.htmlBodyDescription,
                      defaultTextStyle: textTheme.labelLarge,
                    )
                    : Text(
                      params.plainDescription,
                      style: textTheme.labelLarge,
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
    final lang = L10n.of(context);
    //Close keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    String? spaceId = ref.read(selectedSpaceIdProvider);
    spaceId ??= await selectSpace();
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    EasyLoading.show(status: lang.creatingPin);
    try {
      final space = await ref.read(
        spaceProvider(spaceId.expect('space not selected')).future,
      );
      final pinDraft = space.pinDraft();
      final pinState = ref.read(createPinStateProvider);

      // Pin IconData
      if (pinIconColor != null || pinIcon != null) {
        final sdk = await ref.watch(sdkProvider.future);
        final displayBuilder = sdk.api.newDisplayBuilder();
        pinIconColor.map((color) => displayBuilder.color(color.toInt()));
        pinIcon.map((icon) => displayBuilder.icon('acter-icon', icon.name));
        pinDraft.display(displayBuilder.build());
      }

      // Pin Title
      pinState.pinTitle.map((title) {
        if (title.isNotEmpty) pinDraft.title(title);
      });

      // Pin Description
      final params = pinState.pinDescriptionParams;
      if (params != null) {
        final plain = params.plainDescription;
        final html = params.htmlBodyDescription;
        if (html.isNotEmpty) {
          pinDraft.contentHtml(plain, html);
        } else {
          pinDraft.contentMarkdown(plain);
        }
      }

      final pinId = await pinDraft.send();

      // Add Attachments
      await addAttachment(pinId, pinState);
      await autosubscribe(ref: ref, objectId: pinId.toString(), lang: lang);

      EasyLoading.dismiss();
      if (!mounted) return;
      EasyLoading.showToast(lang.pinCreatedSuccessfully);
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
        lang.errorCreatingPin(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<String?> selectSpace() async {
    final newSelectedSpaceId = await selectSpaceDrawer(
      context: context,
      currentSpaceId: ref.read(selectedSpaceIdProvider),
      canCheck: (m) => m?.canString('CanPostPin') == true,
      title: Text(L10n.of(context).selectSpace),
    );
    ref.read(selectedSpaceIdProvider.notifier).state = newSelectedSpaceId;
    return newSelectedSpaceId;
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
        attachments: attachment.path.map((path) => [File(path)]) ?? [],
        title: attachment.title,
        link: attachment.link,
        attachmentType: attachment.attachmentType,
      );
    }
  }
}
