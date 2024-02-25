import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::redact');

/// Reusable reporting acter content widget.
class RedactContentWidget extends ConsumerWidget {
  final String? title;
  final String? description;
  final String eventId;
  final String senderId;
  final String roomId;
  final bool isSpace;
  final void Function()? onRemove;
  final Function()? onSuccess;
  final TextEditingController reasonController = TextEditingController();

  RedactContentWidget({
    super.key,
    this.title,
    this.description,
    required this.eventId,
    required this.roomId,
    required this.senderId,
    this.isSpace = false,
    this.onSuccess,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultDialog(
      title: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title ?? 'Remove',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          description ??
              'Remove this content. This can not be undone. Provide an optional reason to explain, why this was removed',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.neutral6,
              ),
        ),
      ),
      description: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InputTextField(
          controller: reasonController,
          hintText: 'Reason',
          textInputType: TextInputType.multiline,
          maxLines: 5,
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: onRemove ??
              () => redactContent(context, ref, reasonController.text),
          child: const Text('Remove'),
        ),
      ],
    );
  }

  void redactContent(BuildContext ctx, WidgetRef ref, String reason) async {
    showAdaptiveDialog(
      context: (ctx),
      builder: (ctx) => const DefaultDialog(
        title: Text('Removing content'),
        isLoader: true,
      ),
    );
    try {
      if (isSpace) {
        final space = await ref.read(spaceProvider(roomId).future);
        final redactedId = await space.redactContent(eventId, reason);
        ref.invalidate(spacePinsProvider(space));
        _log.info(
          'Content from user:{$senderId redacted $redactedId reason:$reason}',
        );
      } else {
        final room = await ref.read(chatProvider(roomId).future);
        final redactedId = await room.redactContent(eventId, reason);
        ref.invalidate(spaceEventsProvider(roomId));
        _log.info(
          'Content from user:{$senderId redacted $redactedId reason:$reason}',
        );
      }

      if (ctx.mounted) {
        Navigator.of(ctx, rootNavigator: true).pop();
        Navigator.of(ctx, rootNavigator: true).pop(true);
        customMsgSnackbar(ctx, 'Content successfully removed');
        if (onSuccess != null) {
          onSuccess!();
        }
      }
    } catch (e) {
      if (ctx.mounted) {
        Navigator.of(ctx, rootNavigator: true).pop();
        showAdaptiveDialog(
          context: ctx,
          builder: (ctx) => DefaultDialog(
            title: Text('Redaction sending failed due to some $e'),
            actions: <Widget>[
              OutlinedButton(
                onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }
}
