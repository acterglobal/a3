import 'dart:core';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PinPage extends ConsumerWidget {
  final String pinId;
  const PinPage({
    super.key,
    required this.pinId,
  });

  Widget buildActions(
    BuildContext context,
    WidgetRef ref,
    ActerPin pin,
  ) {
    final spaceId = pin.roomIdStr();
    List<PopupMenuEntry> actions = [];
    final pinEditNotifier = ref.watch(pinEditProvider(pin).notifier);
    final membership = ref.watch(roomMembershipProvider(spaceId));
    if (membership.valueOrNull != null) {
      final memb = membership.requireValue!;
      if (memb.canString('CanPostPin')) {
        actions.add(
          PopupMenuItem(
            onTap: () => pinEditNotifier.setEditMode(true),
            child: const Row(
              children: <Widget>[
                Icon(
                  Atlas.pencil_box_thin,
                ),
                SizedBox(width: 10),
                Text('Edit Pin'),
              ],
            ),
          ),
        );
      }
      if (memb.canString('CanRedactOwn') &&
          memb.userId().toString() == pin.sender().toString()) {
        final roomId = pin.roomIdStr();
        actions.add(
          PopupMenuItem(
            onTap: () => showAdaptiveDialog(
              context: context,
              builder: (context) => RedactContentWidget(
                title: 'Remove this pin',
                eventId: pin.eventIdStr(),
                onSuccess: () {
                  if (context.mounted) {
                    context.pop();
                  }
                },
                senderId: pin.sender().toString(),
                roomId: roomId,
                isSpace: true,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Atlas.trash_can_thin,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                const Text('Remove Pin'),
              ],
            ),
          ),
        );
      }
    } else {
      actions.add(
        PopupMenuItem(
          onTap: () => showAdaptiveDialog(
            context: context,
            builder: (ctx) => ReportContentWidget(
              title: 'Report this Pin',
              description:
                  'Report this content to your homeserver administrator. Please note that your administrator won\'t be able to read or view files in encrypted spaces.',
              eventId: pinId,
              roomId: pin.roomIdStr(),
              senderId: pin.sender().toString(),
              isSpace: true,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Atlas.warning_thin,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 10),
              const Text('Report Pin'),
            ],
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton(
      icon: const Icon(Atlas.dots_vertical_thin),
      itemBuilder: (ctx) => actions,
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
              final pinEdit = ref.watch(pinEditProvider(acterPin));
              final pinEditNotifer =
                  ref.watch(pinEditProvider(acterPin).notifier);
              return SliverAppBar(
                centerTitle: false,
                leadingWidth: 40,
                toolbarHeight: 100,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(gradient: primaryGradient),
                ),
                title: !pinEdit.editMode
                    ? Text(
                        acterPin.title(),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      )
                    : TextFormField(
                        initialValue: acterPin.title(),
                        readOnly: !pinEdit.editMode,
                        style: Theme.of(context).textTheme.titleLarge,
                        decoration: InputDecoration(
                          enabledBorder:
                              pinEdit.editMode ? null : InputBorder.none,
                          focusedBorder:
                              pinEdit.editMode ? null : InputBorder.none,
                          filled: false,
                        ),
                        onChanged: (val) => pinEditNotifer.setTitle(val),
                      ),
                actions: [
                  buildActions(context, ref, acterPin),
                ],
              );
            },
            loading: () => const SliverAppBar(
              title: Skeletonizer(child: Text('Loading pin')),
            ),
            error: (err, st) => SliverAppBar(
              title: Text('Error loading pin ${err.toString()}'),
            ),
          ),
          SliverToBoxAdapter(
            child: pin.when(
              data: (acterPin) => PinItem(acterPin),
              error: (err, st) => Text('Error loading pins ${err.toString()}'),
              loading: () => const Skeletonizer(
                child: Card(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
