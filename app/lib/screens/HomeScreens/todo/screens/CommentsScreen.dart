import 'dart:io';

import 'package:beamer/beamer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/news_comment_controller.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/ToDoCommentView.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoCommentScreen extends StatefulWidget {
  const ToDoCommentScreen({Key? key}) : super(key: key);

  @override
  State<ToDoCommentScreen> createState() => _ToDoCommentScreenState();
}

class _ToDoCommentScreenState extends State<ToDoCommentScreen> {

  bool emojiShowing = false;
  bool isKeyBoardOpen = false;
  TextEditingController commentTextController = TextEditingController();


  void onEmojiSelected(Emoji emoji) {
    commentTextController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: commentTextController.text.length),
      );
  }

  void onBackspacePressed() {
    commentTextController
      ..text = commentTextController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: commentTextController.text.length),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppCommonTheme.backgroundColorLight,
        leading: GestureDetector(
          onTap: () {
            Beamer.of(context).beamBack();
          },
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: const Text(
          'Comments',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GetBuilder<NewsCommentController>(
            builder: (NewsCommentController newsCommentController) {
              return Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: ToDoCommentView(
                        commentModel: newsCommentController
                            .listComments[index],
                        postition: index,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: buildProfileImage(Colors.black),
                    ),
                    Expanded(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: AppCommonTheme.textFieldColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextField(
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                                cursorColor: Colors.grey,
                                controller: commentTextController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.emoji_emotions_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  emojiShowing = !emojiShowing;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showNotYetImplementedMsg(
                          context,
                          'Send not yet implemented',
                        );
                      },
                      icon: const Icon(Icons.send, color: Colors.pink),
                    ),
                  ],
                ),
              ),
              Offstage(
                offstage: !emojiShowing,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (Category category, Emoji emoji) {
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
                      progressIndicatorColor: Colors.blue,
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
          )
        ],
      ),
    );
  }

  Widget buildProfileImage(Color borderColor) {
    return GestureDetector(
      onTap: () {
        showNotYetImplementedMsg(context, 'Profile Action not yet implemented');
      },
      child: CachedNetworkImage(
        imageUrl:
        'https://dragonball.guru/wp-content/uploads/2021/01/goku-dragon-ball-guru.jpg',
        height: 45,
        width: 45,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(25),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        maxHeightDiskCache: 120,
        maxWidthDiskCache: 120,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }
}
