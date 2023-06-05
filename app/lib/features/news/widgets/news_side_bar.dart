import 'dart:io';

import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/like_button.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/news/widgets/comment_view.dart';
import 'package:acter/models/CommentModel.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NewsSideBar extends StatefulWidget {
  final ffi.Client client;
  final ffi.NewsEntry news;
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
  @override
  Widget build(BuildContext context) {
    var bgColor = convertColor(
      widget.news.colors()?.background(),
      Theme.of(context).colorScheme.neutral6,
    );
    var fgColor = convertColor(
      widget.news.colors()?.color(),
      Theme.of(context).colorScheme.neutral6,
    );
    TextStyle style = Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontSize: 13,
      color: fgColor,
      shadows: [
        Shadow(color: bgColor, offset: const Offset(2, 2), blurRadius: 5),
      ],
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        LikeButton(
          likeCount: widget.news.likesCount().toString(),
          style: style,
          color: fgColor,
          index: widget.index,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => showCommentsBottomSheet(context),
          child: _SideBarItem(
            icon: const Icon(Atlas.comment_dots, color: Colors.white),
            label: widget.news.commentsCount().toString(),
            style: style,
          ),
        ),
        _SideBarItem(
          icon: const Icon(Atlas.curve_arrow_right_bold, color: Colors.white),
          label: '76',
          style: style,
        ),
        GestureDetector(
          onTap: () => showReportBottomSheet(),
          child: _SideBarItem(
            icon: const Icon(Atlas.dots_horizontal_thin),
            label: '',
            style: style,
          ),
        ),
        _ProfileImageWidget(borderColor: fgColor),
        const SizedBox(height: 8),
      ],
    );
  }

  void showReportBottomSheet() {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      builder: (context) {
        return SizedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Copy Link',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Divider(indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Bookmark/Save',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Divider(indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Get Notified',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Divider(indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Report this post',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge!
                      .copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const Divider(indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void showCommentsBottomSheet(BuildContext context) {
    TextEditingController textCtlr = TextEditingController();
    bool emojiShowing = false;
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void onEmojiSelected(Emoji emoji) {
              textCtlr.text += emoji.emoji;
              textCtlr.selection = TextSelection.fromPosition(
                TextPosition(offset: textCtlr.text.length),
              );
            }

            void onBackspacePressed() {
              textCtlr.text = textCtlr.text.characters.skipLast(1).toString();
              textCtlr.selection = TextSelection.fromPosition(
                TextPosition(offset: textCtlr.text.length),
              );
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.2,
              maxChildSize: 0.5,
              minChildSize: 0.1,
              builder: (BuildContext context, ScrollController scrollCtlr) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '101 Comments',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      controller: scrollCtlr,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(12),
                          child: CommentView(
                            commentModel: CommentModel(
                                'avatar',
                                'Eugene',
                                Colors.orange,
                                'Hello, nice update!',
                                '19:06',
                                true,
                                7, [
                              ReplyModel(
                                'avatar',
                                'Ben',
                                Colors.green,
                                'Yeahh!',
                                '19:11',
                                true,
                                2,
                              )
                            ]),
                            postition: index,
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
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.neutral6,
                                  width: 1.5,
                                ),
                              ),
                              child: const UserAvatarWidget(),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Stack(
                                alignment: Alignment.centerRight,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: TextField(
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      cursorColor: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      controller: textCtlr,
                                      decoration: InputDecoration(
                                        hintText: 'Add a comment',
                                        hintStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
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
                              customMsgSnackbar(
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
                            emojiSizeMax: 32 * (Platform.isIOS ? 1.3 : 1),
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
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ProfileImageWidget extends StatelessWidget {
  final Color borderColor;

  const _ProfileImageWidget({
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        customMsgSnackbar(context, 'Profile Action not yet implemented');
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
  final Widget icon;
  final String label;
  final TextStyle style;

  const _SideBarItem({
    required this.icon,
    required this.label,
    required this.style,
  });

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
}
