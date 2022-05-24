import 'dart:typed_data';
import 'package:effektio/common/widget/NewsSideBar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< HEAD
import 'package:effektio/common/store/Colors.dart';
=======
import 'package:effektio/common/store/separatedThemes.dart';
>>>>>>> a3294cdc35b5cd197063abbd534652b1f9343557
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';

class NewsItem extends StatefulWidget {
  const NewsItem({Key? key, required this.client, required this.news})
      : super(key: key);
  final Client client;
  final News news;

  @override
  _NewsItemState createState() => _NewsItemState();
}

class _NewsItemState extends State<NewsItem> {
  @override
  Widget build(BuildContext context) {
    var image = widget.news.image();
    var bgColor =
        convertColor(widget.news.bgColor(), AppCommonTheme.backgroundColor);
    var fgColor =
        convertColor(widget.news.fgColor(), AppCommonTheme.primaryColor);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          color: bgColor,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: image != null
              ? Image.memory(Uint8List.fromList(image), fit: BoxFit.cover)
              : null,
          clipBehavior: Clip.none,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              flex: 3,
              // ignore: sized_box_for_whitespace
              child: Container(
                height: MediaQuery.of(context).size.height / 4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Lorem Ipsum is simply dummy text of the printing and',
                        style: GoogleFonts.roboto(
                            color: fgColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                  color: bgColor,
                                  offset: const Offset(2, 2),
                                  blurRadius: 5),
                            ]),
                      ),
                      // ignore: prefer_const_constructors
                      SizedBox(height: 10),
                      // ignore: prefer_const_constructors
                      Text(
                        widget.news.text() ?? "",
                        style: GoogleFonts.roboto(
                            color: fgColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            shadows: [
                              Shadow(
                                  color: bgColor,
                                  offset: const Offset(1, 1),
                                  blurRadius: 3),
                            ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              // ignore: sized_box_for_whitespace
              child: Container(
                height: MediaQuery.of(context).size.height / 2.5,
                child: NewsSideBar(client: widget.client, news: widget.news),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
