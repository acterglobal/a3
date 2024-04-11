import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PinPage extends ConsumerWidget {
  static const pinPageKey = Key('pin-page');
  static const actionMenuKey = Key('pin-action-menu');
  static const editBtnKey = Key('pin-edit-btn');
  static const titleFieldKey = Key('edit-pin-title-field');

  final String pinId;

  // ignore: use_key_in_widget_constructors
  const PinPage({
    Key key = pinPageKey,
    required this.pinId,
  });

  // pin actions menu builder
  Widget _buildActionMenu(
    BuildContext context,
    WidgetRef ref,
    ActerPin pin,
  ) {
    final spaceId = pin.roomIdStr();
    List<PopupMenuEntry<String>> actions = [];
    final pinEditNotifier = ref.watch(pinEditProvider(pin).notifier);
    final membership = ref.watch(roomMembershipProvider(spaceId));
    if (membership.valueOrNull != null) {
      final memb = membership.requireValue!;
      if (memb.canString('CanPostPin')) {
        actions.add(
          PopupMenuItem<String>(
            key: PinPage.editBtnKey,
            onTap: () => pinEditNotifier.setEditMode(true),
            child: Row(
              children: <Widget>[
                const Icon(Atlas.pencil_box_thin),
                const SizedBox(width: 10),
                Text(L10n.of(context).editPin),
              ],
            ),
          ),
        );
      }

      if (memb.canString('CanRedactOwn') &&
          memb.userId().toString() == pin.sender().toString()) {
        final roomId = pin.roomIdStr();
        actions.add(
          PopupMenuItem<String>(
            onTap: () => showRedactDialog(
              context: context,
              pin: pin,
              roomId: roomId,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Atlas.trash_can_thin,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                Text(L10n.of(context).removePin),
              ],
            ),
          ),
        );
      } else {
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
      }
    }

    return PopupMenuButton<String>(
      key: PinPage.actionMenuKey,
      icon: const Icon(Atlas.dots_vertical_thin),
      itemBuilder: (ctx) => actions,
    );
  }

  // redact pin dialog
  void showRedactDialog({
    required BuildContext context,
    required ActerPin pin,
    required String roomId,
  }) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => RedactContentWidget(
        title: L10n.of(context).removeThisPin,
        eventId: pin.eventIdStr(),
        onSuccess: () {
          if (context.mounted && context.canPop()) {
            context.pop();
          }
        },
        senderId: pin.sender().toString(),
        roomId: roomId,
        isSpace: true,
      ),
    );
  }

  // report pin dialog
  void showReportDialog(BuildContext context, ActerPin pin) {
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => ReportContentWidget(
        title: L10n.of(context).reportThisPin,
        description: L10n.of(context).reportThisContent,
        eventId: pinId,
        roomId: pin.roomIdStr(),
        senderId: pin.sender().toString(),
        isSpace: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = ref.watch(pinProvider(pinId));

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          pin.when(
            data: (acterPin) {
              return SliverAppBar(
                centerTitle: false,
                leadingWidth: 40,
                toolbarHeight: 100,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(gradient: primaryGradient),
                ),
                title: _buildTitle(context, ref, acterPin),
                actions: [
                  _buildActionMenu(context, ref, acterPin),
                ],
              );
            },
            loading: () => SliverAppBar(
              title: Skeletonizer(child: Text(L10n.of(context).loadingPin)),
            ),
            error: (err, st) => SliverAppBar(
              title: Text(L10n.of(context).errorLoadingPin(err)),
            ),
          ),
          SliverToBoxAdapter(
            child: pin.when(
              data: (acterPin) => Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  PinItem(acterPin),
                  const SizedBox(height: 20),
                  AttachmentSectionWidget(manager: acterPin.attachments()),
                  const SizedBox(height: 20),
                  CommentsSection(manager: acterPin.comments()),
                ],
              ),
              error: (err, st) => Text(L10n.of(context).errorLoadingPin(err)),
              loading: () => const Skeletonizer(
                child: Card(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // pin title builder
  Widget _buildTitle(BuildContext context, WidgetRef ref, ActerPin pin) {
    final pinEdit = ref.watch(pinEditProvider(pin));
    final pinEditNotifer = ref.watch(pinEditProvider(pin).notifier);
    return Visibility(
      visible: !pinEdit.editMode,
      replacement: TextFormField(
        key: PinPage.titleFieldKey,
        initialValue: pin.title(),
        style: Theme.of(context).textTheme.titleLarge,
        onChanged: (val) => pinEditNotifer.setTitle(val),
      ),
      child: Text(
        pin.title(),
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
