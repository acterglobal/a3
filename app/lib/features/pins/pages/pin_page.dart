import 'dart:core';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/redact_content.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/pins/widgets/pin_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:go_router/go_router.dart';

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
    final membership = ref.watch(roomMembershipProvider(spaceId));
    if (membership.valueOrNull != null) {
      final memb = membership.requireValue!;
      if (memb.canString('CanRedact') ||
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
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final pin = ref.watch(pinProvider(pinId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        toolbarHeight: 100,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.chevron_left,
            size: 42,
          ),
        ),
        title: Consumer(
          builder: (context, ref, child) {
            final membership =
                ref.watch(roomMembershipProvider(pin.valueOrNull!.roomIdStr()));
            final canEdit = membership.valueOrNull != null
                ? membership.requireValue!.canString('CanPostPin')
                    ? true
                    : false
                : false;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                initialValue: pin.hasValue ? pin.value!.title() : 'Loading pin',
                readOnly: !canEdit,
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                ),
              ),
            );
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        actions: [
          pin.maybeWhen(
            data: (pin) => buildActions(context, ref, pin),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: pin.when(
        data: (pin) => PinItem(pin),
        error: (error, stack) => Center(
          child: Text('Loading failed: $error'),
        ),
        loading: () => const Center(
          child: Text('Loading'),
        ),
      ),
    );
  }
}
