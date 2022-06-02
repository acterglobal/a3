// ignore_for_file: prefer_const_constructors

import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/widget/like_button.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' as ffi;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NewsSideBar extends StatefulWidget {
  const NewsSideBar({Key? key, required this.client, required this.news, required this.index})
      : super(key: key);
  final ffi.Client client;
  final ffi.News news;
  final int index;

  @override
  _NewsSideBarState createState() => _NewsSideBarState();
}

class _NewsSideBarState extends State<NewsSideBar> {
  @override
  Widget build(BuildContext context) {
    var bgColor =
        convertColor(widget.news.bgColor(), AppCommonTheme.backgroundColor);
    var fgColor =
        convertColor(widget.news.fgColor(), AppCommonTheme.primaryColor);

    TextStyle style = Theme.of(context)
        .textTheme
        .bodyText1!
        .copyWith(fontSize: 13, color: fgColor, shadows: [
      Shadow(color: bgColor, offset: const Offset(2, 2), blurRadius: 5),
    ],);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Center(
            child: LikeButton(
          likeCount: widget.news.likesCount().toString(),
          style: style,
          color: fgColor,
          index: widget.index,
        ),),
        _sideBarItem(
          'comment',
          widget.news.commentsCount().toString(),
          fgColor,
          style,
        ),
        _sideBarItem('reply', '76', fgColor, style),
        _profileImageButton(fgColor),
      ],
    );
  }

  // ignore: always_declare_return_types
  _profileImageButton(Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
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
                  colorFilter:
                      ColorFilter.mode(Colors.red, BlendMode.colorBurn),
                ),
              ),
            ),
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
        ],
      ),
    );
  }

  // ignore: always_declare_return_types
  _sideBarItem(String iconName, String label, Color? color, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
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
}
