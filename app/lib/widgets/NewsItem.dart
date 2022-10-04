import 'dart:typed_data';

import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/widgets/NewsSideBar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewsItem extends StatelessWidget {
  final Client client;
  final News news;
  final int index;

  const NewsItem({
    Key? key,
    required this.client,
    required this.news,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var image = news.image();
    var bgColor = convertColor(news.bgColor(), AppCommonTheme.backgroundColor);
    var fgColor = convertColor(news.fgColor(), AppCommonTheme.primaryColor);

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
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
                      const SizedBox(height: 10),
                      ExpandableText(
                        news.text() ?? '',
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
              child: SizedBox(
                height: MediaQuery.of(context).size.height / 2.5,
                child: InkWell(
                  child: NewsSideBar(
                    client: client,
                    news: news,
                    index: index,
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
