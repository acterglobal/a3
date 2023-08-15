import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

class CustomChatInput extends ConsumerWidget {
  const CustomChatInput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(clientProvider)!.userId().toString();
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider);
    final chatRoomNotifier = ref.read(chatRoomProvider.notifier);
    final repliedToMessage =
        ref.watch(chatRoomProvider.notifier).repliedToMessage;
    final isAuthor = ref.watch(chatRoomProvider.notifier).isAuthor();
    final accountProfile = ref.watch(accountProfileProvider);
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        Visibility(
          visible:
              ref.watch(chatInputProvider.select((ci) => ci.showReplyView)),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  repliedToMessage != null
                      ? Consumer(
                          builder: (context, ref, child) {
                            final replyProfile = ref.watch(
                              memberProfileProvider(
                                repliedToMessage.author.id,
                              ),
                            );
                            return Row(
                              children: [
                                replyProfile.when(
                                  data: (profile) {
                                    return ActerAvatar(
                                      mode: DisplayMode.User,
                                      uniqueId: repliedToMessage.author.id,
                                      displayName: profile.displayName ??
                                          repliedToMessage.author.id,
                                      avatar: profile.getAvatarImage(),
                                      size: profile.hasAvatar() ? 12 : 24,
                                    );
                                  },
                                  error: (e, st) => Text(
                                    'Error loading avatar due to ${e.toString()}',
                                    textScaleFactor: 0.2,
                                  ),
                                  loading: () =>
                                      const CircularProgressIndicator(),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Reply to ${toBeginningOfSentenceCase(repliedToMessage.author.id)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    chatInputNotifier.toggleReplyView(false);
                                    chatInputNotifier.setReplyWidget(null);
                                  },
                                  child: const Icon(
                                    Atlas.xmark_circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                  if (repliedToMessage != null &&
                      chatInputState.replyWidget != null)
                    _ReplyContentWidget(
                      msg: repliedToMessage,
                      messageWidget: chatInputState.replyWidget,
                    ),
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: !chatInputState.emojiRowVisible,
          replacement: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Theme.of(context).colorScheme.onPrimary,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    if (isAuthor) {
                      popUpDialog(
                        context: context,
                        title: const Text(
                          'Are you sure you want to delete this message? This action cannot be undone.',
                        ),
                        btnText: 'No',
                        btn2Text: 'Yes',
                        btn2Color: Theme.of(context).colorScheme.onError,
                        onPressedBtn: () => context.pop(),
                        onPressedBtn2: () async {
                          var messageId = ref
                              .read(chatRoomProvider.notifier)
                              .currentMessageId;
                          if (messageId != null) {
                            try {
                              await chatRoomNotifier
                                  .redactRoomMessage(messageId);
                              chatInputNotifier.emojiRowVisible(false);
                              chatRoomNotifier.currentMessageId = null;
                              if (context.mounted) {
                                context.pop();
                              }
                            } catch (e) {
                              context.pop();
                              customMsgSnackbar(
                                context,
                                e.toString(),
                              );
                            }
                          } else {
                            debugPrint(messageId);
                          }
                        },
                      );
                    } else {
                      customMsgSnackbar(
                        context,
                        'Report message isn\'t implemented yet',
                      );
                    }
                  },
                  child: Text(
                    isAuthor ? 'Unsend' : 'Report',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => customMsgSnackbar(
                    context,
                    'More options not implemented yet',
                  ),
                  child: const Text(
                    'More',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            color: Theme.of(context).colorScheme.onPrimary,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    accountProfile.when(
                      data: (data) {
                        return ActerAvatar(
                          uniqueId: userId,
                          mode: DisplayMode.User,
                          displayName: data.profile.displayName ?? userId,
                          avatar: data.profile.getAvatarImage(),
                          size: data.profile.hasAvatar() ? 18 : 36,
                        );
                      },
                      error: (e, st) =>
                          Text('Error loading due to ${e.toString()}'),
                      loading: () => const CircularProgressIndicator(),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: _TextInputWidget(),
                      ),
                    ),
                    if (chatInputState.sendBtnVisible)
                      _BuildSendBtn(
                        onButtonPressed: () => onSendButtonPressed(ref),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        EmojiPickerWidget(
          size: size,
        ),
      ],
    );
  }

  Future<void> onSendButtonPressed(WidgetRef ref) async {
    var inputNotifier = ref.read(chatInputProvider.notifier);
    var roomNotifier = ref.read(chatRoomProvider.notifier);
    var mentionState = ref.read(mentionKeyProvider).currentState!;
    var markDownProvider = ref.read(messageMarkDownProvider);
    var markDownNotifier = ref.read(messageMarkDownProvider.notifier);

    inputNotifier.showSendBtn(false);
    String markdownText = mentionState.controller!.text;
    int messageLength = markdownText.length;
    markDownProvider.forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });
    await roomNotifier.handleSendPressed(markdownText, messageLength);
    markDownNotifier.update((state) => {});
    mentionState.controller!.clear();
  }
}

class _TextInputWidget extends ConsumerStatefulWidget {
  const _TextInputWidget();

  @override
  ConsumerState<_TextInputWidget> createState() =>
      _TextInputWidgetConsumerState();
}

class _TextInputWidgetConsumerState extends ConsumerState<_TextInputWidget> {
  Future<void> onSendButtonPressed(WidgetRef ref) async {
    var inputNotifier = ref.read(chatInputProvider.notifier);
    var mentionState = ref.read(mentionKeyProvider).currentState!;
    var markDownProvider = ref.read(messageMarkDownProvider);
    var markDownNotifier = ref.read(messageMarkDownProvider.notifier);
    var roomNotifier = ref.read(chatRoomProvider.notifier);

    inputNotifier.showSendBtn(false);
    String markdownText = mentionState.controller!.text;
    int messageLength = markdownText.length;
    markDownProvider.forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });
    await roomNotifier.handleSendPressed(markdownText, messageLength);
    markDownNotifier.update((state) => {});
    mentionState.controller!.clear();
  }

  @override
  Widget build(BuildContext context) {
    final mentionList = ref.watch(mentionListProvider);
    final mentionKey = ref.watch(mentionKeyProvider);
    final chatInputNotifier = ref.read(chatInputProvider.notifier);
    final chatRoomNotifier = ref.read(chatRoomProvider.notifier);
    final chatInputState = ref.watch(chatInputProvider);
    return FlutterMentions(
      key: mentionKey,
      suggestionPosition: SuggestionPosition.Top,
      onMentionAdd: (Map<String, dynamic> roomMember) {
        _handleMentionAdd(roomMember, ref);
      },
      suggestionListDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.neutral2,
        borderRadius: BorderRadius.circular(6),
      ),
      onChanged: (String value) async {
        if (!ref.read(chatInputFocusProvider).hasFocus) {
          ref.read(chatInputFocusProvider).requestFocus();
        }
        if (value.isNotEmpty) {
          chatInputNotifier.showSendBtn(true);
          await chatRoomNotifier.typingNotice(true);
        } else {
          chatInputNotifier.showSendBtn(false);
          await chatRoomNotifier.typingNotice(false);
        }
      },
      style: Theme.of(context).textTheme.bodySmall,
      cursorColor: Theme.of(context).colorScheme.tertiary,
      maxLines:
          MediaQuery.of(context).orientation == Orientation.portrait ? 6 : 2,
      minLines: 1,
      focusNode: ref.watch(chatInputFocusProvider),
      decoration: InputDecoration(
        isCollapsed: true,
        fillColor: Theme.of(context).colorScheme.primaryContainer,
        suffixIcon: InkWell(
          onTap: () => chatInputState.emojiPickerVisible
              ? chatInputNotifier.emojiPickerVisible(false)
              : chatInputNotifier.emojiPickerVisible(true),
          child: const Icon(Icons.emoji_emotions),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none),
        ),
        filled: true,
        hintText: AppLocalizations.of(context)!.newMessage,
        contentPadding: const EdgeInsets.all(15),
        hintMaxLines: 1,
      ),
      mentions: [
        Mention(
          trigger: '@',
          style: TextStyle(
            height: 0.5,
            background: Paint()
              ..color = Theme.of(context).colorScheme.neutral2
              ..strokeWidth = 13
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke,
          ),
          data: mentionList,
          matchAll: true,
          suggestionBuilder: (Map<String, dynamic> roomMember) {
            String title = roomMember['display'] ?? roomMember['link'];
            return ListTile(
              leading: Consumer(
                builder: (context, ref, child) {
                  final mentionProfile =
                      ref.watch(memberProfileProvider(roomMember['link']));
                  return mentionProfile.when(
                    data: (profile) {
                      return ActerAvatar(
                        mode: DisplayMode.User,
                        uniqueId: roomMember['link'],
                        avatar: profile.getAvatarImage(),
                        displayName: title,
                        size: profile.hasAvatar() ? 18 : 36,
                      );
                    },
                    error: (e, st) => Text(
                      'Error loading avatar due to ${e.toString()}',
                      textScaleFactor: 0.2,
                    ),
                    loading: () => const CircularProgressIndicator(),
                  );
                },
              ),
              title: Row(
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 15),
                  Text(
                    roomMember['link'],
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.neutral5,
                        ),
                  ),
                ],
              ),
            );
          },
        )
      ],
    );
  }

  void _handleMentionAdd(Map<String, dynamic> roomMember, WidgetRef ref) {
    String userId = roomMember['link'];
    String displayName = roomMember['display'] ?? userId;
    ref.read(messageMarkDownProvider).addAll({
      '@$displayName': '[$displayName](https://matrix.to/#/$userId)',
    });
  }
}

class _ReplyContentWidget extends StatelessWidget {
  const _ReplyContentWidget({
    required this.msg,
    required this.messageWidget,
  });

  final Message? msg;
  final Widget? messageWidget;

  @override
  Widget build(BuildContext context) {
    if (msg is ImageMessage) {
      var imageMsg = msg as ImageMessage;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ImageMessageBuilder(
          message: imageMsg,
          messageWidth: imageMsg.size.toInt(),
          isReplyContent: true,
        ),
      );
    } else if (msg is TextMessage) {
      var textMsg = msg as TextMessage;
      return Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.2),
        padding: const EdgeInsets.all(12),
        child: Html(
          data: textMsg.text,
          defaultTextStyle: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(overflow: TextOverflow.ellipsis),
          maxLines: 3,
        ),
      );
    }
    return messageWidget ?? const SizedBox.shrink();
  }
}

class _BuildSendBtn extends StatelessWidget {
  final Function()? onButtonPressed;

  const _BuildSendBtn({
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onButtonPressed,
      child: const Icon(Atlas.paper_airplane),
    );
  }
}

class EmojiPickerWidget extends ConsumerStatefulWidget {
  final Size size;

  const EmojiPickerWidget({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  ConsumerState<EmojiPickerWidget> createState() =>
      _EmojiPickerWidgetConsumerState();
}

class _EmojiPickerWidgetConsumerState extends ConsumerState<EmojiPickerWidget> {
  @override
  Widget build(BuildContext context) {
    final chatInputState = ref.watch(chatInputProvider);
    return Offstage(
      offstage: !chatInputState.emojiPickerVisible,
      child: SizedBox(
        height: widget.size.height * 0.3,
        child: EmojiPicker(
          onEmojiSelected: handleEmojiSelected,
          onBackspacePressed: handleBackspacePressed,
          config: Config(
            columns: 8,
            bgColor: Theme.of(context).colorScheme.neutral,
            emojiSizeMax: 36,
            verticalSpacing: 0,
            horizontalSpacing: 0,
            initCategory: Category.SMILEYS,
            recentTabBehavior: RecentTabBehavior.RECENT,
            recentsLimit: 28,
            noRecents: Text(
              AppLocalizations.of(context)!.noRecents,
            ),
            tabIndicatorAnimDuration: kTabScrollDuration,
            categoryIcons: const CategoryIcons(),
            buttonMode: ButtonMode.MATERIAL,
          ),
        ),
      ),
    );
  }

  void handleEmojiSelected(Category? category, Emoji emoji) {
    var mentionKey = ref.watch(mentionKeyProvider);
    mentionKey.currentState!.controller!.text += emoji.emoji;
    ref.read(chatInputProvider.notifier).showSendBtn(true);
  }

  void handleBackspacePressed() {
    var mentionState = ref.watch(mentionKeyProvider).currentState!;
    mentionState.controller!.text =
        mentionState.controller!.text.characters.skipLast(1).string;
    if (mentionState.controller!.text.isEmpty) {
      ref.read(chatInputProvider.notifier).showSendBtn(false);
    }
  }
}
