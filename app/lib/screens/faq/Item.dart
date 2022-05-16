// ignore_for_file: unused_element, always_declare_return_types

import 'dart:io';

import 'package:effektio/common/widget/TagItem.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

class FaqItemScreen extends StatefulWidget {
  const FaqItemScreen({Key? key, required this.client, required this.faq})
      : super(key: key);
  final Client client;
  final Faq faq;

  @override
  _FaqItemScreenState createState() => _FaqItemScreenState();
}

TextEditingController _controller = TextEditingController();

class _FaqItemScreenState extends State<FaqItemScreen> {
  bool emojiShowing = false;

  _onEmojiSelected(Emoji emoji) {
    _controller
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
  }

  _onBackspacePressed() {
    _controller
      ..text = _controller.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu),
          )
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 4.0),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.faq.title(),
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 40.0,
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.only(left: 12.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[800],
                          border: Border.all(
                            color: Colors.white,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/asakerImage.png',
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                              ),
                              child: Text(
                                'Support',
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 40,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => {},
                                child: Image.asset(
                                  'assets/images/heart_like.png',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                ),
                                child: Text(
                                  widget.faq.likesCount().toString(),
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: GestureDetector(
                                  onTap: () => {},
                                  child: Image.asset(
                                    'assets/images/comment.png',
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  widget.faq.commentsCount().toString(),
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
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
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.faq.tags().length,
                      itemBuilder: (context, index) {
                        return TagListItem(
                          tagTitle: widget.faq.tags().elementAt(index).title(),
                          tagColor: Colors.white,
                        );
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
                Container(),
              ],
            ),
          ),
          Card(
            color: Colors.grey[800],
            child: Flexible(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 10,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Stack(
                              alignment: Alignment.centerRight,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
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
                        Flexible(
                          flex: 1,
                          child: SizedBox(
                            width: 30,
                            child: IconButton(
                              onPressed: () {
                                const snackBar = SnackBar(
                                  content: Text('Send icon tapped'),
                                );
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              },
                              icon: const Icon(
                                Icons.send,
                                color: Colors.pink,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      children: const [
                        Padding(
                          padding: EdgeInsets.fromLTRB(8.0, 4.0, 4.0, 4.0),
                          child: Text(
                            'Aa',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20.0),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            'U',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20.0),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text(
                            '@',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20.0),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.link,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.file_copy,
                            color: Colors.white,
                          ),
                        ),
                        Icon(Icons.image, color: Colors.white)
                      ],
                    ),
                    Offstage(
                      offstage: !emojiShowing,
                      child: SizedBox(
                        height: 250,
                        child: EmojiPicker(
                          onEmojiSelected: (Category category, Emoji emoji) {
                            _onEmojiSelected(emoji);
                          },
                          onBackspacePressed: _onBackspacePressed,
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
                            noRecentsText: 'No Recents',
                            noRecentsStyle: const TextStyle(
                              fontSize: 20,
                              color: Colors.black26,
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
            ),
            shape: const OutlineInputBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          )
        ],
      ),
    );
  }
}
