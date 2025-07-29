import 'dart:async';
import 'dart:math';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/html_editor/mentions/selected_mention_provider.dart';
import 'package:acter/common/toolkit/html_editor/mentions/widgets/mention_list.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/actions/attachment_upload_action.dart';
import 'package:acter/features/chat_ng/actions/send_message_action.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter/features/chat_ng/widgets/chat_editor/chat_editor_actions_preview.dart';
import 'package:acter/features/chat_ng/widgets/chat_editor/chat_emoji_picker.dart';
import 'package:acter/features/chat_ng/widgets/chat_editor/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:logging/logging.dart';
import 'package:simply_mentions/text/mention_text_editing_controller.dart';

class UserMentionSyntax extends MentionSyntax {
  UserMentionSyntax(BuildContext context)
    : super(
        // Character that triggers the mention
        startingCharacter: '@',
        // Any text you want that will show when the document/data is not found
        missingText: L10n.of(context).notFound,
        // Pattern of the id
        pattern: '@?(.+)',
        // The leading characters in the syntax, should be something unlikely typed by the user themsleves
        prefix: '<###',
        // The trailing characters in the syntax, should be something unlikely typed by the user themsleves
        suffix: '###>',
      );
}

// Chat Input Field Widget
final _log = Logger('a3::chat::chat_editor');

class ChatEditor extends ConsumerStatefulWidget {
  static const sendBtnKey = Key('editor-send-button');
  final String roomId;
  final void Function(bool)? onTyping;
  const ChatEditor({super.key, required this.roomId, this.onTyping});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatEditorState();
}

class _ChatEditorState extends ConsumerState<ChatEditor> {
  MentionTextEditingController? mentionController;
  final ValueNotifier<bool> _isInputEmptyNotifier = ValueNotifier(true);
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roomId != widget.roomId) {
      // room id changes, dispose the old editor state
      _init();
    }
    _initMentionController();
  }

  void _init() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDraft());

    ref.listenManual(chatEditorStateProvider, (prev, next) async {
      if (next.isEditing &&
          (next.actionType != prev?.actionType ||
              next.selectedMsgItem != prev?.selectedMsgItem)) {
        _handleEditing(next.selectedMsgItem);
      }
      if (next.isReplying &&
          (next.actionType != prev?.actionType ||
              next.selectedMsgItem != prev?.selectedMsgItem)) {
        // set selection of editor for composing
        _saveMsgContent();
      }
    });
  }

  void _handleEditing(TimelineEventItem? item) {
    if (item == null) return;

    final msgContent = item.msgContent();
    if (msgContent == null) return;

    final body = msgContent.body();
    if (body.isEmpty) return;

    mentionController?.setMarkupText(context, body);
  }

  void _saveMsgContent() {
    final markedUp = mentionController?.getMarkupText();
    final markedUpText = markedUp ?? '';
    final parsed = parseSimplyMentions(markedUpText);
    saveMsgDraft(markedUpText, parsed.htmlText, widget.roomId, ref);
  }

  // composer draft load state handler
  Future<void> _loadDraft() async {
    final draft = await ref.read(
      chatComposerDraftProvider(widget.roomId).future,
    );

    if (draft != null) {
      final chatEditorState = ref.read(chatEditorStateProvider.notifier);
      chatEditorState.unsetActions();
      mentionController?.clear();
      draft.eventId().map((eventId) {
        final draftType = draft.draftType();
        final msgsList = ref
            .read(chatMessagesStateProvider(widget.roomId))
            .messages;
        try {
          final roomMsg = msgsList[eventId];
          final item = roomMsg?.eventItem();
          if (item == null) return;
          if (draftType == 'edit') {
            chatEditorState.setEditMessage(item);
          } else if (draftType == 'reply') {
            chatEditorState.setReplyToMessage(item);
          }
        } catch (e) {
          _log.severe('Message with $eventId not found');
          return;
        }
      });

      final fallbackPlain = draft.plainText();
      if (mounted && fallbackPlain.trim().isNotEmpty) {
        mentionController?.setMarkupText(context, fallbackPlain);
      }

      _log.info('compose text draft loaded for room: ${widget.roomId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final emojiPickerVisible = ref.watch(
      chatInputProvider.select((value) => value.emojiPickerVisible),
    );
    final isEncrypted =
        ref.watch(isRoomEncryptedProvider(widget.roomId)).valueOrNull == true;
    final chatEditorState = ref.watch(chatEditorStateProvider);

    Widget? previewWidget;

    if (chatEditorState.isReplying || chatEditorState.isEditing) {
      final msgItem = chatEditorState.selectedMsgItem;
      previewWidget = msgItem.map(
        (item) => ChatEditorActionsPreview(
          onClear: () {
            mentionController?.clear();
          },
          msgItem: item,
          roomId: widget.roomId,
        ),
        orElse: () => const SizedBox.shrink(),
      );
    }
    _initMentionController();

    return Column(
      children: <Widget>[
        if (previewWidget != null) previewWidget,
        renderEditorUI(emojiPickerVisible, isEncrypted),

        // Emoji Picker UI
        if (emojiPickerVisible)
          ChatEmojiPicker(
            onSelect: (emoji) {
              mentionController?.text =
                  '${mentionController?.text ?? ""}$emoji';
            },
          ),
      ],
    );
  }

  // chat editor UI
  Widget renderEditorUI(bool emojiPickerVisible, bool isEncrypted) {
    final chatEditorState = ref.watch(chatEditorStateProvider);
    final isPreviewOpen =
        chatEditorState.isReplying || chatEditorState.isEditing;
    final radiusVal = isPreviewOpen ? 2.0 : 15.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radiusVal),
          topRight: Radius.circular(radiusVal),
        ),
        border: BorderDirectional(top: BorderSide(color: greyColor)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leadingBtn(emojiPickerVisible),
          Expanded(child: editorField(isEncrypted)),
          trailingBtn(),
        ],
      ),
    );
  }

  void _toggleEmojiPicker(bool emojiPickerVisible) {
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    chatInputNotifier.emojiPickerVisible(!emojiPickerVisible);
  }

  Widget editorField(bool isEncrypted) {
    final hintText = isEncrypted == true
        ? L10n.of(context).newEncryptedMessage
        : L10n.of(context).newMessage;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        if (isDesktop(context))
          const SingleActivator(LogicalKeyboardKey.enter): _actionSubmit,
        if (isDesktop(context))
          LogicalKeySet(
            LogicalKeyboardKey.enter,
            LogicalKeyboardKey.shift,
          ): () =>
              mentionController?.text = '${mentionController?.text ?? ""}\n',
      },
      child: _renderEditor(context, hintText),
    );
  }

  Widget _renderEditor(BuildContext context, String hintText) {
    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: PortalTarget(
        visible: mentionController?.isMentioning() ?? false,
        portalFollower: _renderMentions(),
        anchor: Aligned(
          follower: Alignment.bottomLeft,
          target: Alignment.topLeft,
          widthFactor: 1,
          backup: const Aligned(
            follower: Alignment.bottomLeft,
            target: Alignment.topLeft,
            widthFactor: 1,
          ),
        ),
        child: TextField(
          controller: mentionController,
          textInputAction: TextInputAction.newline,
          maxLines: null,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
          style: Theme.of(
            context,
          ).textTheme.bodySmall.expect('bodySmall style not available'),
        ),
      ),
    );
  }

  void _dismissMentions() {
    mentionController?.cancelMentioning();
  }

  void _initMentionController() {
    if (mentionController == null) {
      mentionController ??= MentionTextEditingController(
        mentionSyntaxes: [UserMentionSyntax(context)],
        mentionBgColor: Theme.of(context).colorScheme.primary,
        mentionTextColor: Theme.of(context).colorScheme.onPrimary,
        idToMentionObject: (BuildContext context, String id) async {
          final suggestions = ref.read(
            userMentionSuggestionsProvider(widget.roomId),
          );
          return MentionObject(id: id, displayName: suggestions?[id] ?? id);
        },
        mentionTextStyle: Theme.of(
          context,
        ).textTheme.bodySmall.expect('bodySmall style not available'),
        runTextStyle: TextStyle(),
        // idToMentionObject: (BuildContext context, String id) => ref.
        //     documentMentions.firstWhere((element) => element.id == id));
        // );
      );

      mentionController!.addListener(() {
        ref.read(mentionQueryProvider.notifier).state =
            mentionController?.getSearchText() ?? '';
        _saveMsgContent();
        setState(() {});
        _isInputEmptyNotifier.value = mentionController?.text.isEmpty ?? true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  Widget _renderMentions() {
    if (mentionController?.isMentioning() != true) {
      return const SizedBox.shrink();
    }
    final maxHeight = max(300, MediaQuery.sizeOf(context).height * 0.5);

    return TapRegion(
      behavior: HitTestBehavior.opaque,
      onTapOutside: (event) => _dismissMentions(),
      child: Material(
        // elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight.toDouble()),
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: UserMentionList(
            onDismiss: _dismissMentions,
            onShow: () {},
            roomId: widget.roomId,
            onSelected: (t, id, displayName) {
              mentionController?.insertMention(
                MentionObject(id: id, displayName: displayName ?? id),
              );
            },
          ),
        ),
      ),
    );
  }

  // emoji button
  Widget leadingBtn(bool emojiPickerVisible) => Padding(
    padding: const EdgeInsets.only(top: 4, left: 4),
    child: IconButton(
      onPressed: () => _toggleEmojiPicker(emojiPickerVisible),
      icon: const Icon(Icons.emoji_emotions, size: 20),
    ),
  );

  // attachment/send button
  Widget trailingBtn() {
    final allowEditing = ref.watch(allowSendInputProvider(widget.roomId));
    return ValueListenableBuilder<bool>(
      valueListenable: _isInputEmptyNotifier,
      builder: (context, isEmpty, child) {
        if (allowEditing && !isEmpty) {
          return _renderSendBtn();
        }
        return _renderAttachmentBtn();
      },
    );
  }

  void _actionSubmit() async {
    try {
      sendMessageAction(
        content: parseSimplyMentions(mentionController?.getMarkupText() ?? ''),
        roomId: widget.roomId,
        onTyping: widget.onTyping,
        context: context,
        ref: ref,
        log: _log,
      );

      // cleaning the editor and states
      mentionController?.clear();
      // also clear composed state
      final convo = await ref.read(chatProvider(widget.roomId).future);
      final notifier = ref.read(chatEditorStateProvider.notifier);
      notifier.unsetActions();
      if (convo != null) {
        await convo.saveMsgDraft('', null, 'new', null);
      }
    } catch (e) {
      _log.severe('Error sending message', e);
    }
  }

  Widget _renderSendBtn() => Padding(
    padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
    child: IconButton.filled(
      alignment: Alignment.center,
      // key: ChatEditor.sendBtnKey,
      iconSize: 20,
      onPressed: _actionSubmit,
      icon: const Icon(Icons.send),
    ),
  );

  Widget _renderAttachmentBtn() => Padding(
    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
    child: IconButton(
      onPressed: () => selectAttachment(
        context: context,
        onSelected: (files, type) => attachmentUploadAction(
          roomId: widget.roomId,
          files: files,
          attachmentType: type,
          ref: ref,
          context: context,
          log: _log,
        ),
      ),
      icon: const Icon(Atlas.paperclip_attachment_thin, size: 20),
    ),
  );
}
