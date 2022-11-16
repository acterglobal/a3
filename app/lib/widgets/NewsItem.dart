import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' show Platform;

import 'package:cached_memory_image/cached_memory_image.dart';
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
    var bgColor = convertColor(news.bgColor(), AppCommonTheme.backgroundColor);
    var fgColor = convertColor(news.fgColor(), AppCommonTheme.primaryColor);
    bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          color: bgColor,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: _buildImage(),
          clipBehavior: Clip.none,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxWidth >= 600
                  ? isDesktop
                      ? MediaQuery.of(context).size.height * 0.5
                      : MediaQuery.of(context).size.height * 0.7
                  : MediaQuery.of(context).size.height * 0.4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: <Widget>[
                          const Spacer(),
                          _buildTitle(bgColor, fgColor),
                          const SizedBox(height: 10),
                          _buildSubtitle(bgColor, fgColor),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child:
                        NewsSideBar(client: client, news: news, index: index),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget? _buildImage() {
    var image = news.image();
    if (image == null) {
      return null;
    }
    var id = news.id();
    // return Image.memory(Uint8List.fromList(image), fit: BoxFit.cover);
    return CachedMemoryImage(
      uniqueKey: 'news-item-$id',
      bytes: Uint8List.fromList(image),
      fit: BoxFit.cover,
    );
  }

  Widget _buildTitle(ui.Color backgroundColor, ui.Color foregroundColor) {
    return Text(
      news.text() ?? '',
      style: GoogleFonts.roboto(
        color: foregroundColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: backgroundColor,
            offset: const Offset(2, 2),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(ui.Color backgroundColor, ui.Color foregroundColor) {
    return ExpandableText(
      news.text() ?? '',
      maxLines: 2,
      expandText: '',
      expandOnTextTap: true,
      collapseOnTextTap: true,
      animation: true,
      linkColor: foregroundColor,
      style: GoogleFonts.roboto(
        color: foregroundColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        shadows: [
          Shadow(
            color: backgroundColor,
            offset: const Offset(1, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}
