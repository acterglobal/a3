import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' show Platform;

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
          child: _ImageWidget(news: news, isDesktop: isDesktop),
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
                          _TitleWidget(
                            news: news,
                            backgroundColor: bgColor,
                            foregroundColor: fgColor,
                          ),
                          const SizedBox(height: 10),
                          _SubtitleWidget(
                            news: news,
                            backgroundColor: bgColor,
                            foregroundColor: fgColor,
                          ),
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
}

class _ImageWidget extends StatelessWidget {
  const _ImageWidget({
    required this.news,
    required this.isDesktop,
  });

  final News news;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    var image = news.image();
    Size size = WidgetsBinding.instance.window.physicalSize;
    if (image == null) {
      return const SizedBox.shrink();
    }

    // return Image.memory(Uint8List.fromList(image), fit: BoxFit.cover);
    return Image.memory(
      Uint8List.fromList(image),
      fit: BoxFit.cover,
      cacheWidth: size.width.toInt(),
      cacheHeight: size.height.toInt(),
    );
  }
}

class _TitleWidget extends StatelessWidget {
  const _TitleWidget({
    required this.news,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final News news;
  final ui.Color backgroundColor;
  final ui.Color foregroundColor;

  @override
  Widget build(BuildContext context) {
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
}

class _SubtitleWidget extends StatelessWidget {
  const _SubtitleWidget({
    required this.news,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final News news;
  final ui.Color backgroundColor;
  final ui.Color foregroundColor;

  @override
  Widget build(BuildContext context) {
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
