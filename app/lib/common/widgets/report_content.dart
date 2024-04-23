import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::report');

final _ignoreUserProvider = StateProvider.autoDispose<bool>((ref) => false);

/// Reusable reporting acter content widget.
class ReportContentWidget extends ConsumerWidget {
  final String title;
  final String description;
  final String eventId;
  final String senderId;
  final String roomId;
  final bool isSpace;

  const ReportContentWidget({
    super.key,
    required this.title,
    required this.description,
    required this.eventId,
    required this.roomId,
    required this.senderId,
    this.isSpace = false,
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
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          description,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.neutral6,
              ),
        ),
      ),
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InputTextField(
              controller: textController,
              hintText: L10n.of(context).reason,
              textInputType: TextInputType.multiline,
              maxLines: 5,
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  L10n.of(context).blockUserOptional,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                subtitle: Text(
                  L10n.of(context).markToHideAllCurrentAndFutureContent,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).colorScheme.neutral5,
                      ),
                ),
                value: ref.watch(_ignoreUserProvider),
                onChanged: (value) =>
                    ref.read(_ignoreUserProvider.notifier).update(
                          (state) => value!,
                        ),
              );
            },
          ),
        ],
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(L10n.of(context).close),
        ),
        ActerPrimaryActionButton(
          onPressed: () => reportContent(context, ref, textController.text),
          child: Text(L10n.of(context).report),
        ),
      ],
    );
  }

  void reportContent(BuildContext ctx, WidgetRef ref, String reason) async {
    bool res = false;
    final ignoreFlag = ref.read(_ignoreUserProvider);
    EasyLoading.show(status: L10n.of(ctx).sendingReport);
    try {
      if (isSpace) {
        final space = await ref.read(spaceProvider(roomId).future);
        if (ignoreFlag) {
          var member = await space.getMember(senderId);
          bool ignore = await member.ignore();
          _log.info('User added to ignore list:{$senderId:$ignore}');
        }
        res = await space.reportContent(eventId, null, reason);
        _log.info('Content from user:{$senderId flagged $res reason:$reason}');
      } else {
        final room = await ref.read(chatProvider(roomId).future);
        res = await room.reportContent(eventId, null, reason);
        _log.info('Content from user:{$senderId flagged $res reason:$reason}');
        if (ignoreFlag) {
          var member = await room.getMember(senderId);
          bool ignore = await member.ignore();
          _log.info('User added to ignore list:$senderId:$ignore');
        }
      }

      if (!ctx.mounted) {
        EasyLoading.dismiss();
        return;
      }
      if (res) {
        EasyLoading.showToast(L10n.of(ctx).reportSent);
      } else {
        EasyLoading.showError(
          L10n.of(ctx).reportSendingFailed,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (!ctx.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(ctx).reportSendingFailedDueTo(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
