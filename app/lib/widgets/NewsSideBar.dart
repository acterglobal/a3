import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/news_comment_controller.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CommentView.dart';
import 'package:effektio/widgets/LikeButton.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' as ffi;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class NewsSideBar extends StatefulWidget {
  final ffi.Client client;
  final ffi.News news;
  final int index;

  const NewsSideBar({
    Key? key,
    required this.client,
    required this.news,
    required this.index,
  }) : super(key: key);

  @override
  _NewsSideBarState createState() => _NewsSideBarState();
}

class _NewsSideBarState extends State<NewsSideBar> {
  TextEditingController commentTextController = TextEditingController();
  final newsCommentGlobalController = Get.put(NewsCommentController());

  bool emojiShowing = false;
  bool isKeyBoardOpen = false;

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
    var bgColor = convertColor(
      widget.news.bgColor(),
      AppCommonTheme.backgroundColor,
    );
    var fgColor = convertColor(
      widget.news.fgColor(),
      AppCommonTheme.primaryColor,
    );
    TextStyle style = Theme.of(context).textTheme.bodyText1!.copyWith(
      fontSize: 13,
      color: fgColor,
      shadows: [
        Shadow(color: bgColor, offset: const Offset(2, 2), blurRadius: 5),
      ],
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        LikeButton(
          likeCount: widget.news.likesCount().toString(),
          style: style,
          color: fgColor,
          index: widget.index,
        ),
        buildSideBarItem(
          'comment',
          widget.news.commentsCount().toString(),
          fgColor,
          style,
        ),
        buildSideBarItem('reply', '76', fgColor, style),
        buildProfileImage(fgColor),
      ],
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
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget buildSideBarItem(
    String iconName,
    String label,
    Color? color,
    TextStyle style,
  ) {
    return GestureDetector(
      onTap: () {
        if (iconName == 'comment') {
          showBottomSheet();
        } else {
          showNotYetImplementedMsg(context, 'News Action not yet implemented');
        }
      },
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/images/$iconName.svg',
            color: color,
            width: 35,
            height: 35,
          ),
          const SizedBox(height: 5),
          Text(label, style: style),
        ],
      ),
    );
  }

  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppCommonTheme.backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              '101 Comments',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GetBuilder<NewsCommentController>(builder:
                          (NewsCommentController newsCommentController) {
                        return Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            controller: scrollController,
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: CommentView(
                                  commentModel:
                                      newsCommentController.listComments[index],
                                  postition: index,
                                ),
                              );
                            },
                          ),
                        );
                      }),
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void showReportBottomSheet() {
    showModalBottomSheet(
      backgroundColor: Colors.grey[800],
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppCommonTheme.textFieldColor,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Spam', style: TextStyle(color: Colors.white)),
                        Icon(Icons.keyboard_arrow_right, color: Colors.white)
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Violence', style: TextStyle(color: Colors.white)),
                        Icon(Icons.keyboard_arrow_right, color: Colors.white)
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Fake Account',
                          style: TextStyle(color: Colors.white),
                        ),
                        Icon(Icons.keyboard_arrow_right, color: Colors.white)
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Copyrights',
                          style: TextStyle(color: Colors.white),
                        ),
                        Icon(Icons.keyboard_arrow_right, color: Colors.white)
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Spam',
                          style: TextStyle(color: Colors.white),
                        ),
                        Icon(Icons.keyboard_arrow_right, color: Colors.white)
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
