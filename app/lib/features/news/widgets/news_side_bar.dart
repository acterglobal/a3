import 'dart:io';

import 'package:atlas_icons/atlas_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acter/common/snackbars/not_implemented.dart';
import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter/features/news/controllers/news_comment_controller.dart';
import 'package:acter/features/news/widgets/comment_view.dart';
import 'package:acter/common/widgets/like_button.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
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
  final newsCommentGlobalController = Get.put(NewsCommentController());

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
    TextStyle style = Theme.of(context).textTheme.bodyLarge!.copyWith(
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
        _SideBarItem(
          icon: const Icon(Atlas.comment_dots, color: Colors.white),
          label: widget.news.commentsCount().toString(),
          style: style,
        ),
        _SideBarItem(
          icon: const Icon(Atlas.curve_arrow_right_bold, color: Colors.white),
          label: '76',
          style: style,
        ),
        _ProfileImageWidget(borderColor: fgColor),
      ],
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

class _ProfileImageWidget extends StatelessWidget {
  const _ProfileImageWidget({
    required this.borderColor,
  });

  final Color borderColor;

  @override
  Widget build(BuildContext context) {
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

class _SideBarItem extends StatelessWidget {
  const _SideBarItem({
    required this.icon,
    required this.label,
    required this.style,
  });
  final Widget icon;
  final String label;
  final TextStyle style;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon,
        const SizedBox(height: 5),
        Text(label, style: style),
      ],
    );
  }

  void showBottomSheet(BuildContext context) {
    TextEditingController commentTextController = TextEditingController();
    bool emojiShowing = false;
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
            void onEmojiSelected(Emoji emoji) {
              commentTextController
                ..text += emoji.emoji
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: commentTextController.text.length),
                );
            }

            void onBackspacePressed() {
              commentTextController
                ..text =
                    commentTextController.text.characters.skipLast(1).toString()
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: commentTextController.text.length),
                );
            }

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
                      GetBuilder<NewsCommentController>(
                        builder: (NewsCommentController newsCommentController) {
                          return Expanded(
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              controller: scrollController,
                              itemCount: 10,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: CommentView(
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
                      Padding(
                        padding: EdgeInsets.only(
                          left: 8,
                          top: 8,
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: _ProfileImageWidget(
                                borderColor: Colors.black,
                              ),
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
                );
              },
            );
          },
        );
      },
    );
  }
}
