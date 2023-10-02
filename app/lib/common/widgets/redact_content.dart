import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reusable reporting acter content widget.
class RedactContentWidget extends ConsumerWidget {
  final String? title;
  final String? description;
  final String eventId;
  final String senderId;
  final String roomId;
  final bool isSpace;
  final Function()? onSuccess;
  const RedactContentWidget({
    super.key,
    this.title,
    this.description,
    required this.eventId,
    required this.roomId,
    required this.senderId,
    this.isSpace = false,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController textController = TextEditingController();
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
          controller: textController,
          hintText: 'Reason',
          textInputType: TextInputType.multiline,
          maxLines: 5,
        ),
      ),
      actions: <Widget>[
        DefaultButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          title: 'Close',
          isOutlined: true,
        ),
        DefaultButton(
          onPressed: () => redactContent(context, ref, textController.text),
          title: 'Remove',
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        ),
      ],
    );
  }

  void redactContent(BuildContext ctx, WidgetRef ref, String reason) async {
    bool res = false;
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
        res = await space.redactContent(eventId, reason);
        debugPrint('Content from user:{$senderId flagged $res reason:$reason}');
      } else {
        final room = await ref.read(chatProvider(roomId).future);
        res = await room.redactContent(eventId, reason);
        debugPrint('Content from user:{$senderId flagged $res reason:$reason}');
      }

      if (res) {
        if (ctx.mounted) {
          Navigator.of(ctx, rootNavigator: true).pop();
          Navigator.of(ctx, rootNavigator: true).pop(true);
          customMsgSnackbar(ctx, 'Content successfully deleted');
          if (onSuccess != null) {
            onSuccess!();
          }
        }
      } else {
        if (ctx.mounted) {
          Navigator.of(ctx, rootNavigator: true).pop();
          showAdaptiveDialog(
            context: ctx,
            builder: (ctx) => DefaultDialog(
              title: const Text('Redaction sending failed'),
              actions: <Widget>[
                DefaultButton(
                  onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                  title: 'Close',
                  isOutlined: true,
                ),
              ],
            ),
          );
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
              DefaultButton(
                onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                title: 'Close',
                isOutlined: true,
              ),
            ],
          ),
        );
      }
    }
  }
}
