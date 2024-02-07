import 'dart:core';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
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

class PinPage extends ConsumerStatefulWidget {
  final String pinId;
  const PinPage({
    super.key,
    required this.pinId,
  });

  @override
  ConsumerState<PinPage> createState() => _PinPageConsumerState();
}

class _PinPageConsumerState extends ConsumerState<PinPage> {
  final ScrollController controller = ScrollController();
  Widget buildActions(
    BuildContext context,
    WidgetRef ref,
    ActerPin pin,
  ) {
    final spaceId = pin.roomIdStr();
    List<PopupMenuEntry> actions = [];
    final pinEditNotifier = ref.watch(pinEditStateProvider(pin).notifier);
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
        actions.addAll([
          PopupMenuItem(
            onTap: () => showAdaptiveDialog(
              context: context,
              builder: (context) => RedactContentWidget(
                title: 'Remove this post',
                eventId: pin.eventIdStr(),
                onSuccess: () {
                  ref.invalidate(pinsProvider);
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
          PopupMenuItem(
            onTap: () => showAdaptiveDialog(
              context: context,
              builder: (ctx) => ReportContentWidget(
                title: 'Report this Pin',
                description:
                    'Report this content to your homeserver administrator. Please note that your administrator won\'t be able to read or view files in encrypted spaces.',
                eventId: widget.pinId,
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
        ]);
      }
    }
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton(
      itemBuilder: (ctx) => actions,
      icon: const Icon(Atlas.dots_vertical_thin),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final pin = ref.watch(pinProvider(widget.pinId));
    return Scaffold(
      body: CustomScrollView(
        controller: controller,
        slivers: [
          pin.when(
            data: (data) => SliverAppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 100,
              centerTitle: false,
              leading: IconButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.goNamed(Routes.pins.name),
                icon: const Icon(
                  Icons.chevron_left,
                  size: 42,
                ),
              ),
              leadingWidth: 40,
              title: Consumer(
                builder: (context, ref, child) {
                  final pinEdit = ref.watch(pinEditStateProvider(data));
                  final pinEditNotifier =
                      ref.watch(pinEditStateProvider(data).notifier);
                  return TextFormField(
                    initialValue: data.title(),
                    readOnly: !pinEdit.editMode,
                    style: Theme.of(context).textTheme.headlineMedium,
                    decoration: InputDecoration(
                      enabledBorder: pinEdit.editMode ? null : InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onChanged: (val) => pinEditNotifier.setTitle(val),
                  );
                },
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: primaryGradient,
                ),
              ),
              actions: [
                pin.maybeWhen(
                  data: (pin) => buildActions(context, ref, pin),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            error: (err, st) => SliverAppBar(
              title: Text('Error loading pin title: ${err.toString()}'),
            ),
            loading: () => const SliverAppBar(
              title: Skeletonizer(child: Text('')),
            ),
          ),
          SliverToBoxAdapter(
            child: pin.when(
              data: (pin) => PinItem(pin, controller),
              error: (error, stack) => Center(
                child: Text('Loading failed: $error'),
              ),
              loading: () => const Center(
                child: Text('Loading'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
