import 'dart:typed_data';
import 'package:effektio/common/widget/NewsSideBar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:expandable_text/expandable_text.dart';

class NewsItem extends StatefulWidget {
  const NewsItem(
      {Key? key, required this.client, required this.news, required this.index})
      : super(key: key);
  final Client client;
  final News news;
  final int index;

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
              flex: 5,
              // ignore: sized_box_for_whitespace
              child: Container(
                height: MediaQuery.of(context).size.height / 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Column(
                    children: <Widget>[
                      const Spacer(),
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
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      // ignore: prefer_const_constructors
                      SizedBox(height: 10),
                      // ignore: prefer_const_constructors
                      ExpandableText(
                        widget.news.text() ?? '',
                        maxLines: 2,
                        expandText: '',
                        expandOnTextTap: true,
                        collapseOnTextTap: true,
                        animation: true,
                        linkColor: fgColor,
                        style: GoogleFonts.roboto(
                          color: fgColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              color: bgColor,
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              // ignore: sized_box_for_whitespace
              child: Container(
                height: MediaQuery.of(context).size.height / 2.5,
                child: InkWell(
                  child: NewsSideBar(
                    client: widget.client,
                    news: widget.news,
                    index: widget.index,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
