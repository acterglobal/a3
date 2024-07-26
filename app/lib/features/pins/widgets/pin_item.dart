import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_link_sheet.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/Utils/pins_utils.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
  final GlobalKey<FormState> _formkey =
      GlobalKey<FormState>(debugLabel: 'pin edit form');
  int? attachmentCount;

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
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectionArea(
            child: GestureDetector(
              onTap: () {
                showEditHtmlDescriptionBottomSheet(
                  context: context,
                  descriptionHtmlValue: description.formattedBody(),
                  descriptionMarkdownValue: description.body(),
                  onSave: (htmlBodyDescription, plainDescription) async {
                    saveDescription(
                      context,
                      htmlBodyDescription,
                      plainDescription,
                      widget.pin,
                    );
                  },
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

  // pin link widget
  Widget _buildPinLink() {
    return SelectionArea(
      child: GestureDetector(
        onTap: () async {
          await openLink(widget.pin.url() ?? '', context);
        },
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Atlas.link_chain_thin, size: 18),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.pin.url() ?? '',
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    showEditLinkBottomSheet(
                      context: context,
                      bottomSheetTitle: L10n.of(context).editLink,
                      linkValue: widget.pin.url() ?? '',
                      onSave: (newLink) async {
                        final pinEditNotifier =
                            ref.watch(pinEditProvider(widget.pin).notifier);
                        pinEditNotifier.setLink(newLink);
                        savePinLink(context, widget.pin, newLink);
                      },
                    );
                  },
                  child: const Icon(Atlas.pencil_edit, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
