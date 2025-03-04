import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::actions::report_content');

final _ignoreUserProvider = StateProvider.autoDispose<bool>((ref) => false);

Future<bool> openReportContentDialog(
  BuildContext context, {
  required String title,
  required String description,
  required final String eventId,
  required final String roomId,
  required final String senderId,
  final bool? isSpace,
}) async {
  return await showAdaptiveDialog(
    context: context,
    useRootNavigator: false,
    builder:
        (context) => _ReportContentWidget(
          title: title,
          description: description,
          eventId: eventId,
          senderId: senderId,
          roomId: roomId,
          isSpace: isSpace ?? false,
        ),
  );
}

/// Reusable reporting acter content widget.
class _ReportContentWidget extends ConsumerWidget {
  final String title;
  final String description;
  final String eventId;
  final String senderId;
  final String roomId;
  final bool isSpace;

  const _ReportContentWidget({
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
    final lang = L10n.of(context);
    return DefaultDialog(
      title: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(description, style: Theme.of(context).textTheme.bodySmall),
      ),
      description: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InputTextField(
              controller: textController,
              hintText: lang.reason,
              textInputType: TextInputType.multiline,
              maxLines: 5,
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  lang.blockUserOptional,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                subtitle: Text(
                  lang.markToHideAllCurrentAndFutureContent,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                value: ref.watch(_ignoreUserProvider),
                onChanged: (val) {
                  if (val == null) {
                    _log.severe('Changed value not available');
                    return;
                  }
                  ref.read(_ignoreUserProvider.notifier).update((state) => val);
                },
              );
            },
          ),
        ],
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.close),
        ),
        ActerPrimaryActionButton(
          onPressed: () => reportContent(context, ref, textController.text),
          child: Text(lang.report),
        ),
      ],
    );
  }

  void reportContent(BuildContext context, WidgetRef ref, String reason) async {
    bool res = false;
    final ignoreFlag = ref.read(_ignoreUserProvider);
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.sendingReport);
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
        if (room == null) throw RoomNotFound();
        res = await room.reportContent(eventId, null, reason);
        _log.info('Content from user:{$senderId flagged $res reason:$reason}');
        if (ignoreFlag) {
          final member = await room.getMember(senderId);
          bool ignore = await member.ignore();
          _log.info('User added to ignore list:$senderId:$ignore');
        }
      }

      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      if (res) {
        EasyLoading.showToast(lang.reportSent);
        Navigator.pop(context);
      } else {
        _log.severe('Failed to report content');
        EasyLoading.showError(
          lang.reportSendingFailed,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, s) {
      _log.severe('Failed to report content', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.reportSendingFailedDueTo(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
