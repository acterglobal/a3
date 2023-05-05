import 'dart:io';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/models/ToDoTask.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Account;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommentInput extends StatefulWidget {
  const CommentInput(this.task, this.callback, {super.key});
  final ToDoTask task;
  final VoidCallback? callback;

  @override
  State<CommentInput> createState() => CommentInputState();
}

class CommentInputState extends State<CommentInput> {
  final ToDoController controller = Get.find<ToDoController>();
  bool emojiShowing = false;
  final TextEditingController _inputController = TextEditingController();

  void onEmojiSelected(Emoji emoji) {
    _inputController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
  }

  void onBackspacePressed() {
    _inputController
      ..text = _inputController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
  }

  @override
  Widget build(BuildContext context) {
    Account account = controller.client.account();
    return Container(
      decoration: const BoxDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: UserAvatar(
                    uniqueKey: account.userId(),
                    radius: 18,
                    isGroup: false,
                    avatar: account.avatar(),
                    stringName: simplifyUserId(account.userId()) ?? '',
                    cacheHeight: 120,
                    cacheWidth: 120,
                  ),
                ),
                GetBuilder<ToDoController>(
                  id: 'comment-input',
                  builder: (cntrl) {
                    return Expanded(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextField(
                                style: Theme.of(context).textTheme.bodySmall,
                                cursorColor:
                                    Theme.of(context).colorScheme.tertiary,
                                controller: _inputController,
                                decoration: const InputDecoration(
                                  hintText: 'New Message',
                                  border: InputBorder.none,
                                ),
                                onChanged: (val) => cntrl.updateCommentInput(
                                  _inputController,
                                  val,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.emoji_emotions_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() => emojiShowing = !emojiShowing);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                GetBuilder<ToDoController>(
                  id: 'comment-input',
                  builder: (cntrl) {
                    return Visibility(
                      visible: _inputController.text.trim().isNotEmpty,
                      child: IconButton(
                        onPressed: () async => await cntrl
                            .sendComment(
                          widget.task.commentsManager.commentDraft(),
                          _inputController.text.trim(),
                        )
                            .then((res) {
                          cntrl.updateCommentInput(_inputController, '');
                          if (widget.callback != null) {
                            Future.delayed(const Duration(milliseconds: 800),
                                () {
                              widget.callback!();
                            });
                          }
                          debugPrint('Comment id: $res');
                        }),
                        icon: Icon(
                          Atlas.paper_airplane,
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            Offstage(
              offstage: !emojiShowing,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (Category? category, Emoji emoji) {
                    onEmojiSelected(emoji);
                  },
                  onBackspacePressed: onBackspacePressed,
                  config: Config(
                    columns: 7,
                    emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    initCategory: Category.RECENT,
                    bgColor: Colors.white,
                    indicatorColor: Colors.blue,
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.blue,
                    backspaceColor: Colors.blue,
                    skinToneDialogBgColor: Colors.white,
                    skinToneIndicatorColor: Colors.grey,
                    enableSkinTones: true,
                    showRecentsTab: true,
                    recentsLimit: 28,
                    noRecents: const Text(
                      'No Recents',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black26,
                      ),
                    ),
                    tabIndicatorAnimDuration: kTabScrollDuration,
                    categoryIcons: const CategoryIcons(),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
