import 'dart:io';

import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as m_colors;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class PinItemPage extends StatefulWidget {
  final Client client;
  final ActerPin pin;

  const PinItemPage({
    Key? key,
    required this.client,
    required this.pin,
  }) : super(key: key);

  @override
  _PinItemPageState createState() => _PinItemPageState();
}

TextEditingController _controller = TextEditingController();

class _PinItemPageState extends State<PinItemPage> {
  TextEditingController pinController = TextEditingController();
  bool emojiShowing = false;
  bool commentShowing = false;
  bool editPinTitle = false;

  @override
  void initState() {
    super.initState();

    commentShowing = false;
    editPinTitle = false;
    pinController.text = widget.pin.title();
  }

  void onEmojiSelected(Emoji emoji) {
    _controller
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
  }

  void onBackspacePressed() {
    _controller
      ..text = _controller.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppCommonTheme.backgroundColor,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu),
          )
        ],
      ),
      backgroundColor: AppCommonTheme.backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Visibility(
                  visible: editPinTitle ? true : false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextField(
                          controller: pinController,
                          style: const m_colors.TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Pin title',
                            labelStyle: TextStyle(color: Colors.white),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => editPinTitle = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(pinController.text.toString()),
                              ),
                            );
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Visibility(
                    visible: editPinTitle ? false : true,
                    child: Row(
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            widget.pin.title(),
                            style: PinTheme.titleStyle,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => editPinTitle = true);
                            },
                            child: const Icon(Icons.edit, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: PinTheme.supportColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset('assets/images/asakerImage.png'),
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'Support',
                                style: PinTheme.teamNameStyle,
                              ),
                            )
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => {},
                                child: Image.asset(
                                  'assets/images/heart_like.png',
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  '0', //widget.pin.likesCount().toString(),
                                  style: PinTheme.likeAndCommentStyle,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    commentShowing = !commentShowing;
                                  });
                                },
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Image.asset(
                                        'assets/images/comment.png',
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Text(
                                        '0', //widget.pin.commentsCount().toString(),
                                        style: PinTheme.likeAndCommentStyle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const Divider(
                  height: 2,
                  thickness: 2,
                  indent: 20,
                  endIndent: 20,
                  color: Colors.grey,
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 0, //widget.pin.tags().length,
                      itemBuilder: (context, index) {
                        return null;
                        // var color = widget.pin.tags().elementAt(index).color();
                        // var colorToShow = 0;
                        // if (color != null) {
                        //   var colorList = color.rgbaU8();
                        //   colorToShow = hexOfRGBA(
                        //     colorList.elementAt(0),
                        //     colorList.elementAt(1),
                        //     colorList.elementAt(2),
                        //     opacity: 0.7,
                        //   );
                        // }

                        // return TagListItem(
                        //   tagTitle: widget.pin.tags().elementAt(index).title(),
                        //   tagColor: colorToShow > 0
                        //       ? m_colors.Color(colorToShow)
                        //       : Colors.white,
                        // );
                      },
                    ),
                  ),
                ),
                const Divider(
                  height: 2,
                  thickness: 2,
                  indent: 20,
                  endIndent: 20,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          Visibility(
            visible: commentShowing ? true : false,
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Expanded(
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: TextField(
                                    style: const TextStyle(color: Colors.white),
                                    cursorColor: Colors.grey,
                                    controller: _controller,
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
                      ),
                      IconButton(
                        onPressed: () {
                          const snackBar = SnackBar(
                            content: Text('Send icon tapped'),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        },
                        icon: const Icon(Icons.send, color: Colors.pink),
                      )
                    ],
                  ),

                  // To file an ticket about these functionality
                  // Row(
                  //   children: const [
                  //     Padding(
                  //       padding: EdgeInsets.fromLTRB(8.0, 4.0, 4.0, 4.0),
                  //       child: Text(
                  //         'Aa',
                  //         style: TextStyle(color: Colors.white, fontSize: 20.0),
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding: EdgeInsets.all(4.0),
                  //       child: Text(
                  //         'U',
                  //         style: TextStyle(color: Colors.white, fontSize: 20.0),
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding: EdgeInsets.all(4.0),
                  //       child: Text(
                  //         '@',
                  //         style: TextStyle(color: Colors.white, fontSize: 20.0),
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding: EdgeInsets.all(4.0),
                  //       child: Icon(
                  //         Icons.link,
                  //         color: Colors.white,
                  //       ),
                  //     ),
                  //     Spacer(),
                  //     Padding(
                  //       padding: EdgeInsets.all(8.0),
                  //       child: Icon(
                  //         Icons.file_copy,
                  //         color: Colors.white,
                  //       ),
                  //     ),
                  //     Icon(Icons.image, color: Colors.white)
                  //   ],
                  // ),
                  Offstage(
                    offstage: !emojiShowing,
                    child: SizedBox(
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
                            'No recents',
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
              decoration: m_colors.BoxDecoration(
                color: Colors.grey[800],
                borderRadius: const m_colors.BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                  bottomLeft: m_colors.Radius.zero,
                  bottomRight: m_colors.Radius.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
