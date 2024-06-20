import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class PinItem extends ConsumerStatefulWidget {
  static const linkFieldKey = Key('edit-pin-link-field');
  static const descriptionFieldKey = Key('edit-pin-description-field');
  static const saveBtnKey = Key('pin-edit-save');
  final ActerPin pin;

  const PinItem(this.pin, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinItemState();
}

class _PinItemState extends ConsumerState<PinItem> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  late TextEditingController _linkController;
  int? attachmentCount;

  @override
  void initState() {
    super.initState();
    _buildPinContent();
  }

  // pin content builder (default md-editor)
  void _buildPinContent() {
    _linkController = TextEditingController(text: widget.pin.url() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final spaceId = pin.roomIdStr();
    final isLink = pin.isLink();

    return Form(
      key: _formkey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            alignment: Alignment.topLeft,
            margin: const EdgeInsets.all(8),
            child: SpaceChip(spaceId: spaceId),
          ),
          if (isLink) _buildPinLink(),
          _pinDescription(),
        ],
      ),
    );
  }

  Widget _pinDescription() {
    final description = widget.pin.content();
    if (description == null) return const SizedBox.shrink();
    final formattedBody = description.formattedBody();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectionArea(
            child: GestureDetector(
              onTap: () {
                showEditDescriptionSheet(
                  description.formattedBody(),
                  description.body(),
                );
              },
              child: formattedBody != null
                  ? RenderHtml(
                      text: formattedBody,
                      defaultTextStyle: Theme.of(context).textTheme.labelLarge,
                    )
                  : Text(
                      description.body(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void showEditDescriptionSheet(
    htmlBodyDescription,
    plainDescription,
  ) {
    showEditHtmlDescriptionBottomSheet(
      context: context,
      descriptionHtmlValue: htmlBodyDescription,
      descriptionMarkdownValue: plainDescription,
      onSave: (htmlBodyDescription, plainDescription) async {
        _saveDescription(context, htmlBodyDescription, plainDescription);
      },
    );
  }

  Future<void> _saveDescription(
    BuildContext context,
    String htmlBodyDescription,
    String plainDescription,
  ) async {
    try {
      EasyLoading.show(status: L10n.of(context).updatingDescription);
      final updateBuilder = widget.pin.updateBuilder();
      updateBuilder.contentText(plainDescription);
      updateBuilder.contentHtml(plainDescription, htmlBodyDescription);
      await updateBuilder.send();
      EasyLoading.dismiss();
      if (!context.mounted) return;
      context.pop();
    } catch (e) {
      EasyLoading.dismiss();
      if (!context.mounted) return;
      EasyLoading.showError(L10n.of(context).updateNameFailed(e));
    }
  }

  // pin link widget
  Widget _buildPinLink() {
    final pinEdit = ref.watch(pinEditProvider(widget.pin));
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        key: PinItem.linkFieldKey,
        onTap: () async =>
            !pinEdit.editMode ? await openLink(pinEdit.link, context) : null,
        controller: _linkController,
        readOnly: !pinEdit.editMode,
        decoration: const InputDecoration(
          prefixIcon: Icon(Atlas.link_chain_thin, size: 18),
        ),
        validator: (value) {
          if (value != null) {
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.isAbsolute) {
              return L10n.of(context).linkIsNotValid;
            }
          }
          return null;
        },
      ),
    );
  }
}
