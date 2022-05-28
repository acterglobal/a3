// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/widget/CommentView.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' as ffi;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewsSideBar extends StatefulWidget {
  const NewsSideBar({Key? key, required this.client, required this.news})
      : super(key: key);
  final ffi.Client client;
  final ffi.News news;

  @override
  _NewsSideBarState createState() => _NewsSideBarState();
}

class _NewsSideBarState extends State<NewsSideBar> {
  static List<String> listPlayers = <String>[
    'Cristiano Ronaldo',
    'Lionel Messi',
    'Neymar Jr.',
    'Kevin De Bruyne',
    'Robert Lewandowski',
    'Kylian Mbappe',
    'Virgil Van Dijk',
    'Mohamed Salah',
    'Sadio Mane',
    'Sergio Ramos',
    'Paul Pogba',
    'Bruno Fernandes'
  ];

  static List<MaterialColor> listColors = <MaterialColor>[
    Colors.blue,
    Colors.orange,
    Colors.brown,
    Colors.blueGrey,
    Colors.deepPurple,
    Colors.indigo,
    Colors.green,
    Colors.yellow,
    Colors.lime,
    Colors.teal,
    Colors.red,
    Colors.pink
  ];

  TextEditingController commentcontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var bgColor =
        convertColor(widget.news.bgColor(), AppCommonTheme.backgroundColor);
    var fgColor =
        convertColor(widget.news.fgColor(), AppCommonTheme.primaryColor);

    TextStyle style = Theme.of(context).textTheme.bodyText1!.copyWith(
      fontSize: 13,
      color: fgColor,
      shadows: [
        Shadow(color: bgColor, offset: const Offset(2, 2), blurRadius: 5),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _sideBarItem(
            'heart',
            widget.news.likesCount().toString(),
            fgColor,
            style,
          ),
          _sideBarItem(
            'comment',
            widget.news.commentsCount().toString(),
            fgColor,
            style,
          ),
          _sideBarItem('reply', '76', fgColor, style),
          _profileImageButton(fgColor),
        ],
      ),
    );
  }

  // ignore: always_declare_return_types
  _profileImageButton(Color color) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        CachedNetworkImage(
          imageUrl:
              'https://dragonball.guru/wp-content/uploads/2021/01/goku-dragon-ball-guru.jpg',
          height: 45,
          width: 45,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: color,
              ),
              borderRadius: BorderRadius.circular(25),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.red, BlendMode.colorBurn),
              ),
            ),
          ),
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ),
      ],
    );
  }

  // ignore: always_declare_return_types
  _sideBarItem(String iconName, String label, Color? color, TextStyle style) {
    return GestureDetector(
      onTap: (() {
        if (iconName == 'comment') {
          showBottomSheet();
        }
      }),
      child: Column(
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/$iconName.svg',
            color: color,
            width: 35,
            height: 35,
          ),
          SizedBox(
            height: 5,
          ),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30.0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
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
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.all(12),
                              child: CommentView(
                                name: listPlayers[index],
                                titleColor: listColors[index],
                                comment: 'How they can do it',
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 8.0,
                          top: 8.0,
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: _profileImageButton(Colors.black),
                            ),
                            Expanded(
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppCommonTheme.textFieldColor,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Expanded(
                                  child: Stack(
                                    alignment: Alignment.centerRight,
                                    children: <Widget>[
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: TextField(
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          cursorColor: Colors.grey,
                                          // controller: _controller,
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
                                            // emojiShowing = !emojiShowing;
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
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackBar);
                              },
                              icon: const Icon(
                                Icons.send,
                                color: Colors.pink,
                              ),
                            )
                          ],
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
