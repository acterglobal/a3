import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/Utils/pins_utils.dart';
import 'package:acter/features/pins/actions/edit_pin_actions.dart';
import 'package:acter/features/pins/actions/reduct_pin_action.dart';
import 'package:acter/features/pins/actions/report_pin_action.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/fake_link_attachment_item.dart';
import 'package:acter/features/pins/widgets/pin_icon.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::pin::detail-page');

class PinDetailsPage extends ConsumerStatefulWidget {
  static const pinPageKey = Key('pin-page');
  static const actionMenuKey = Key('pin-action-menu');
  static const editBtnKey = Key('pin-edit-btn');
  static const titleFieldKey = Key('edit-pin-title-field');
  static const descriptionFieldKey = Key('edit-pin-description-field');

  final String pinId;

  // ignore: use_key_in_widget_constructors
  const PinDetailsPage({
    Key key = pinPageKey,
    required this.pinId,
  });

  @override
  ConsumerState<PinDetailsPage> createState() => _PinDetailsPageState();
}

class _PinDetailsPageState extends ConsumerState<PinDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBodyUI(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      actions: [_buildActionMenu()],
    );
  }

  Widget _buildBodyUI() {
    final pinData = ref.watch(pinProvider(widget.pinId));
    return pinData.when(
      data: (pin) {
        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildPinHeaderUI(pin),
              const SizedBox(height: 20),
              AttachmentSectionWidget(manager: pin.attachments()),
              FakeLinkAttachmentItem(pinId: pin.eventIdStr()),
              const SizedBox(height: 20),
              CommentsSection(manager: pin.comments()),
            ],
          ),
        );
      },
      loading: () => Skeletonizer(
        child: Text(L10n.of(context).loadingPin),
      ),
      error: (e, s) {
        _log.severe('Error loading pin', e, s);
        return Text(
          L10n.of(context).errorLoadingPin(e),
        );
      },
    );
  }

  // pin actions menu builder
  Widget _buildActionMenu() {
    final pinData = ref.watch(pinProvider(widget.pinId));
    return pinData.when(
      data: (pin) {
        //Get my membership details
        final membership =
            ref.watch(roomMembershipProvider(pin.roomIdStr())).valueOrNull;
        final canRedactData = ref.watch(canRedactProvider(pin));
        bool canPost = membership?.canString('CanPostPin') == true;
        bool canRedact = canRedactData.valueOrNull == true;
        return PopupMenuButton<String>(
          key: PinDetailsPage.actionMenuKey,
          icon: const Icon(Atlas.dots_vertical_thin),
          itemBuilder: (context) =>
              _buildAppBarActionMenuItems(pin, canPost, canRedact),
        );
      },
      loading: () => Skeletonizer(child: Text(L10n.of(context).loadingPin)),
      error: (e, s) {
        _log.severe('Error loading pin', e, s);
        return const SizedBox.shrink();
      },
    );
  }

  List<PopupMenuEntry<String>> _buildAppBarActionMenuItems(
    ActerPin pin,
    bool canPost,
    bool canRedact,
  ) {
    List<PopupMenuEntry<String>> actions = [];

    //Check for can post pin permission
    if (canPost) {
      //EDIT PIN TITLE MENU ITEM
      actions.add(
        PopupMenuItem<String>(
          key: PinDetailsPage.editBtnKey,
          onTap: () => showEditPintTitleDialog(context, ref, pin),
          child: Text(L10n.of(context).editTitle),
        ),
      );

      //EDIT PIN DESCRIPTION MENU ITEM
      actions.add(
        PopupMenuItem<String>(
          key: PinDetailsPage.editBtnKey,
          onTap: () => showEditPintDescriptionDialog(context, ref, pin),
          child: Text(L10n.of(context).editDescription),
        ),
      );
    }

    //REPORT PIN MENU ITEM
    actions.add(
      PopupMenuItem<String>(
        onTap: () => showReportDialog(context, pin),
        child: Row(
          children: <Widget>[
            Icon(
              Atlas.warning_thin,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 10),
            Text(L10n.of(context).reportPin),
          ],
        ),
      ),
    );

    //DELETE PIN MENU ITEM
    if (canRedact) {
      final roomId = pin.roomIdStr();
      actions.add(
        PopupMenuItem<String>(
          onTap: () => showRedactDialog(
            context: context,
            pin: pin,
            roomId: roomId,
          ),
          child: Text(
            L10n.of(context).removePin,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    return actions;
  }

  Widget _buildPinHeaderUI(ActerPin pin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PinIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    pinTitleUI(pin),
                    pinSpaceNameUI(pin),
                  ],
                ),
              ),
            ],
          ),
          pinDescriptionUI(pin),
        ],
      ),
    );
  }

  Widget pinTitleUI(ActerPin pin) {
    return SelectionArea(
      child: GestureDetector(
        onTap: () {
          final membership =
              ref.read(roomMembershipProvider(pin.roomIdStr())).valueOrNull;
          if (membership?.canString('CanPostPin') == true) {
            showEditTitleBottomSheet(
              context: context,
              bottomSheetTitle: L10n.of(context).editName,
              titleValue: pin.title(),
              onSave: (newTitle) async {
                final pinEditNotifier = ref.read(pinEditProvider(pin).notifier);
                pinEditNotifier.setTitle(newTitle);
                savePinTitle(context, pin, newTitle);
              },
            );
          }
        },
        child: Text(
          pin.title(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }

  Widget pinSpaceNameUI(ActerPin pin) {
    return SpaceChip(
      spaceId: pin.roomIdStr(),
      useCompatView: true,
    );
  }

  Widget pinDescriptionUI(ActerPin pin) {
    final description = pin.content();
    if (description == null) return const SizedBox.shrink();
    final htmlBody = description.formattedBody();
    final plainBody = description.body();
    if (htmlBody == null && plainBody.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        SelectionArea(
          child: GestureDetector(
            onTap: () {
              showEditHtmlDescriptionBottomSheet(
                context: context,
                descriptionHtmlValue: description.formattedBody(),
                descriptionMarkdownValue: plainBody,
                onSave: (htmlBodyDescription, plainDescription) async {
                  saveDescription(
                    context,
                    htmlBodyDescription,
                    plainDescription,
                    pin,
                  );
                },
              );
            },
            child: htmlBody != null
                ? RenderHtml(
                    text: htmlBody,
                    defaultTextStyle: Theme.of(context).textTheme.labelLarge,
                  )
                : Text(
                    plainBody,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
          ),
        ),
      ],
    );
  }
}
