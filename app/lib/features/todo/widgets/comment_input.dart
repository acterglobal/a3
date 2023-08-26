import 'dart:io';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/models/ToDoTask.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class CommentInput extends ConsumerStatefulWidget {
  const CommentInput(this.task, this.callback, {super.key});
  final ToDoTask task;
  final VoidCallback? callback;

  @override
  ConsumerState<CommentInput> createState() => CommentInputState();
}

class CommentInputState extends ConsumerState<CommentInput> {
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

  Future<void> onSend() async {
    final eventId = await controller.sendComment(
      widget.task.commentsManager.commentDraft(),
      _inputController.text.trim(),
    );
    controller.updateCommentInput(_inputController, '');
    if (widget.callback != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        widget.callback!();
      });
    }
    debugPrint('Comment id: $eventId');
  }

  @override
  Widget build(BuildContext context) {
    String userId = controller.client.userId().toString();
    final accountProfile = ref.watch(accountProfileProvider);
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
                  child: accountProfile.when(
                    data: (data) => ActerAvatar(
                      mode: DisplayMode.User,
                      uniqueId: userId,
                      size: 18,
                      displayName: simplifyUserId(userId),
                      avatar: data.profile.getAvatarImage(),
                    ),
                    error: (err, stackTrace) {
                      debugPrint('Failed to load avatar $err');
                      return ActerAvatar(
                        mode: DisplayMode.User,
                        uniqueId: userId,
                        size: 18,
                        displayName: simplifyUserId(userId),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
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
                                if (mounted) {
                                  setState(() => emojiShowing = !emojiShowing);
                                }
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
                  builder: (ToDoController controller) {
                    return Visibility(
                      visible: _inputController.text.trim().isNotEmpty,
                      child: IconButton(
                        onPressed: onSend,
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
            EmojiPickerWidget(
              size: Size(
                MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height / 2,
              ),
              onEmojiSelected: (Category? category, Emoji emoji) {
                onEmojiSelected(emoji);
              },
              onBackspacePressed: onBackspacePressed,
            )
          ],
        ),
      ),
    );
  }
}
