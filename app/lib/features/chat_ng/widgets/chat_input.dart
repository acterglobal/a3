import 'dart:async';

import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::chat::custom_input');

final _allowEdit = StateProvider.family.autoDispose<bool, String>(
  (ref, roomId) => ref.watch(
    chatInputProvider
        .select((state) => state.sendingState == SendingState.preparing),
  ),
);

class ChatInput extends ConsumerWidget {
  static const loadingKey = Key('chat-ng-loading');
  static const noAccessKey = Key('chat-ng-no-access');

  final String roomId;
  final void Function(bool)? onTyping;

  const ChatInput({super.key, required this.roomId, this.onTyping});

  Widget _loadingWidget(BuildContext context) {
    return Skeletonizer(
      child: FrostEffect(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.emoji_emotions, size: 20),
              ),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .unselectedWidgetColor
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: IntrinsicHeight(
                      child: HtmlEditor(
                        footer: null,
                        editable: true,
                        shrinkWrap: true,
                        editorPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        onChanged: (body, html) {},
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Atlas.paperclip_attachment_thin,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noAccessWidget(BuildContext context) {
    return FrostEffect(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const SizedBox(width: 1),
              const Icon(
                Atlas.block_prohibited_thin,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                key: ChatInput.noAccessKey,
                L10n.of(context).chatMissingPermissionsToSend,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSend = ref.watch(canSendProvider(roomId)).valueOrNull;
    if (canSend == null) {
      // we are still loading
      return _loadingWidget(context);
    }
    if (canSend) {
      return _InputWidget(
        roomId: roomId,
        onTyping: onTyping,
      );
    }
    // no permissions to send messages
    return _noAccessWidget(context);
  }
}

class _InputWidget extends ConsumerStatefulWidget {
  final String roomId;
  final void Function(bool)? onTyping;
  const _InputWidget({required this.roomId, this.onTyping});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => __InputWidgetState();
}

class __InputWidgetState extends ConsumerState<_InputWidget> {
  EditorState textEditorState = EditorState.blank();
  late EditorScrollController scrollController;
  FocusNode chatFocus = FocusNode();
  StreamSubscription<(TransactionTime, Transaction)>? _updateListener;
  final ValueNotifier<bool> _isInputEmptyNotifier = ValueNotifier(true);
  double _cHeight = 0.10;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    scrollController =
        EditorScrollController(editorState: textEditorState, shrinkWrap: true);
    // listener for editor input state
    _updateListener = textEditorState.transactionStream.listen((data) {
      _inputUpdate();
      _updateHeight();
    });
  }

  @override
  void dispose() {
    _updateListener?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _InputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _inputUpdate() {
    // check if actual document content is empty
    final state = textEditorState.document.root.children
        .every((node) => node.delta?.toPlainText().isEmpty ?? true);
    _isInputEmptyNotifier.value = state;
    _debounceTimer?.cancel();
    // delay operation to avoid excessive re-writes
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      // save composing draft
      // await saveDraft(textController.text, widget.roomId, ref);
      _log.info('compose draft saved for room: ${widget.roomId}');
    });
  }

  // handler for expanding editor field height
  void _updateHeight() {
    final text = textEditorState.intoMarkdown();
    final lineCount = '\n'.allMatches(text).length;

    // Calculate new height based on line count
    // Start with 5% and increase by 2% per line up to 20%
    setState(() {
      _cHeight = (0.05 + (lineCount - 1) * 0.02).clamp(0.05, 0.15);
    });
  }

  Widget _editorWidget() {
    final widgetSize = MediaQuery.sizeOf(context);
    return FrostEffect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Row(
          children: [
            leadingButton(),
            IntrinsicHeight(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: widgetSize.height * _cHeight,
                width: widgetSize.width * 0.75,
                margin: const EdgeInsets.symmetric(vertical: 12),

                decoration: BoxDecoration(
                  color:
                      Theme.of(context).unselectedWidgetColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                // constraints: BoxConstraints(
                //   maxHeight: widgetSize.height * 0.15,
                //   minHeight: widgetSize.height * 0.06,
                // ),
                child: SingleChildScrollView(
                  child: IntrinsicHeight(
                    child: Focus(
                      focusNode: chatFocus,
                      child: HtmlEditor(
                        footer: null,
                        roomId: widget.roomId,
                        editable: true,
                        shrinkWrap: true,
                        editorState: textEditorState,
                        scrollController: scrollController,
                        editorPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        onChanged: (body, html) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isInputEmptyNotifier,
              builder: (context, isEmpty, child) =>
                  trailingButton(widget.roomId, isEmpty),
            ),
          ],
        ),
      ),
    );
  }

  // emoji button
  Widget leadingButton() {
    return IconButton(
      onPressed: () {},
      icon: const Icon(Icons.emoji_emotions, size: 20),
    );
  }

  // attachment/send button
  Widget trailingButton(String roomId, bool isEmpty) {
    final allowEditing = ref.watch(_allowEdit(roomId));

    if (allowEditing && !isEmpty) {
      return IconButton.filled(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        key: CustomChatInput.sendBtnKey,
        iconSize: 20,
        onPressed: () => {},
        icon: const Icon(Icons.send),
      );
    }

    return IconButton(
      onPressed: () {},
      icon: const Icon(
        Atlas.paperclip_attachment_thin,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardVisible = ref.watch(keyboardVisibleProvider).valueOrNull;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return Column(
      children: <Widget>[
        _editorWidget(),
        // adjust bottom viewport so toolbar doesn't obscure field when visible
        if (isKeyboardVisible != null && isKeyboardVisible)
          SizedBox(height: viewInsets + 50),
      ],
    );
  }
}
