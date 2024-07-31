import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::redact');

Future<bool> openRedactContentDialog(
  BuildContext context, {
  final String? title,
  final String? description,
  required final String eventId,
  required final String roomId,
  final bool? isSpace,
  final void Function()? onRemove,
  final Function()? onSuccess,
  final Key? cancelBtnKey,
  final Key? removeBtnKey,
}) async {
  return await showAdaptiveDialog(
    context: context,
    useRootNavigator: false,
    builder: (context) => _RedactContentWidget(
      title: title,
      description: description,
      eventId: eventId,
      roomId: roomId,
      isSpace: isSpace ?? false,
      onRemove: onRemove,
      onSuccess: onSuccess,
      cancelBtnKey: cancelBtnKey,
      removeBtnKey: removeBtnKey,
    ),
  );
}

/// Reusable reporting acter content widget.
class _RedactContentWidget extends ConsumerWidget {
  final String? title;
  final String? description;
  final String eventId;
  final String roomId;
  final bool isSpace;
  final void Function()? onRemove;
  final Function()? onSuccess;
  final Key? cancelBtnKey;
  final Key? removeBtnKey;
  final TextEditingController reasonController = TextEditingController();

  _RedactContentWidget({
    this.title,
    this.description,
    required this.eventId,
    required this.roomId,
    this.isSpace = false,
    this.onSuccess,
    this.onRemove,
    this.cancelBtnKey,
    this.removeBtnKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultDialog(
      title: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title ?? L10n.of(context).remove,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          description ?? L10n.of(context).removeThisContent,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      description: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InputTextField(
          controller: reasonController,
          hintText: L10n.of(context).reason,
          textInputType: TextInputType.multiline,
          maxLines: 5,
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          key: cancelBtnKey,
          onPressed: () => Navigator.pop(context, false),
          child: Text(L10n.of(context).close),
        ),
        ActerPrimaryActionButton(
          key: removeBtnKey,
          onPressed: onRemove ??
              () => redactContent(context, ref, reasonController.text),
          child: Text(L10n.of(context).remove),
        ),
      ],
    );
  }

  void redactContent(BuildContext context, WidgetRef ref, String reason) async {
    EasyLoading.show(status: L10n.of(context).removingContent);
    try {
      if (isSpace) {
        final space = await ref.read(spaceProvider(roomId).future);
        final redactedId = await space.redactContent(eventId, reason);
        ref.invalidate(pinListProvider(roomId));
        _log.info(
          'Content from $redactedId reason:$reason}',
        );
      } else {
        final room = await ref.read(chatProvider(roomId).future);
        if (room == null) {
          throw RoomNotFound();
        }
        final redactedId = await room.redactContent(eventId, reason);
        ref.invalidate(allEventListProvider(roomId));
        _log.info(
          'Content from $redactedId reason:$reason}',
        );
      }

      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).contentSuccessfullyRemoved);
      Navigator.pop(context, true);
      if (onSuccess != null) {
        onSuccess!();
      }
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        '${L10n.of(context).redactionFailed} $e',
        duration: const Duration(seconds: 3),
      );
    }
  }
}
