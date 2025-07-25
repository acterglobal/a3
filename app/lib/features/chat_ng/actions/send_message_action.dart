import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/chat_editor/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgDraft;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:logging/logging.dart';

// send chat message action
Future<void> sendMessageAction({
  required MarkedUpEditContent content,
  required String roomId,
  required BuildContext context,
  required WidgetRef ref,
  void Function(bool)? onTyping,
  required Logger log,
}) async {
  if (ref.read(chatInputProvider.notifier).isSending) {
    return; // we are in a sending process, ignore double sends
  }

  final lang = L10n.of(context);
  final body = content.plainText;
  final html = content.htmlText;
  final mentions = content.userMentions;

  if (!hasValidEditorContent(plainText: body, html: html)) {
    return;
  }

  ref.read(chatInputProvider.notifier).startSending();
  try {
    // end the typing notification
    onTyping?.map((cb) => cb(false));

    // make the actual draft
    final chatEditorState = ref.read(chatEditorStateProvider);
    final client = await ref.read(alwaysClientProvider.future);
    late MsgDraft draft;

    if (html.isNotEmpty) {
      draft = client.textHtmlDraft(html, body);
    } else {
      draft = client.textMarkdownDraft(body);
    }

    // add mentions to the draft
    for (final mention in mentions) {
      draft.addMention(mention);
    }

    // actually send it out
    final stream = await ref.read(timelineStreamProvider(roomId).future);

    if (chatEditorState.isReplying) {
      final remoteId = chatEditorState.selectedMsgItem?.eventId();
      if (remoteId == null) throw 'remote id of sel msg not available';
      await stream.replyMessage(remoteId, draft);
    } else if (chatEditorState.isEditing) {
      final remoteId = chatEditorState.selectedMsgItem?.eventId();
      if (remoteId == null) throw 'remote id of sel msg not available';
      await stream.editMessage(remoteId, draft);
    } else {
      await stream.sendMessage(draft);
    }

    ref.read(chatInputProvider.notifier).messageSent();

    // also clear composed state
    final convo = await ref.read(chatProvider(roomId).future);
    final notifier = ref.read(chatEditorStateProvider.notifier);
    notifier.unsetActions();
    if (convo != null) {
      await convo.saveMsgDraft('', null, 'new', null);
    }
  } catch (e, s) {
    log.severe('Sending chat message failed', e, s);
    EasyLoading.showError(
      lang.failedToSend(e),
      duration: const Duration(seconds: 3),
    );
    ref.read(chatInputProvider.notifier).sendingFailed();
  }
}
