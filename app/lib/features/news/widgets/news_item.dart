import 'dart:typed_data';
import 'dart:io' show Platform;

import 'package:acter/features/news/widgets/news_side_bar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewsItem extends StatefulWidget {
  final Client client;
  final NewsEntry news;
  final int index;

  const NewsItem({
    Key? key,
    required this.client,
    required this.news,
    required this.index,
  }) : super(key: key);

  @override
  State<NewsItem> createState() => _NewsItemState();
}

class _NewsItemState extends State<NewsItem> {
  @override
  Widget build(BuildContext context) {
    var slide = widget.news.getSlide(0)!;
    var slideType = slide.typeStr();
    if (slideType == 'image') {
      return ImageSlide(
        news: widget.news,
        index: widget.index,
        background: widget.news.colors()?.background(),
        foreground: widget.news.colors()?.color(),
        client: widget.client,
        slide: slide,
      );
    }
    // else
    var bgColor = convertColor(
      widget.news.colors()?.background(),
      Theme.of(context).colorScheme.secondary,
    );
    var fgColor = convertColor(
      widget.news.colors()?.color(),
      Theme.of(context).colorScheme.primary,
    );
    bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          color: bgColor,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Text(
            slide.text(),
            style: GoogleFonts.inter(
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
                    flex: 1,
                    child: NewsSideBar(
                      client: widget.client,
                      news: widget.news,
                      index: widget.index,
                    ),
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

class ImageSlide extends StatefulWidget {
  final Client client;
  final NewsSlide slide;
  final NewsEntry news;
  final int index;
  final EfkColor? background;
  final EfkColor? foreground;

  const ImageSlide({
    Key? key,
    required this.news,
    required this.index,
    required this.client,
    required this.slide,
    this.background,
    this.foreground,
  }) : super(key: key);

  @override
  State<ImageSlide> createState() => _ImageSlideState();
}

class _ImageSlideState extends State<ImageSlide> {
  late Future<FfiBufferUint8> newsImage;
  @override
  void initState() {
    super.initState();
    getNewsImage();
  }

  Future<void> getNewsImage() async {
    newsImage = widget.slide.imageBinary();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var bgColor = convertColor(
      widget.news.colors()?.background(),
      Theme.of(context).colorScheme.secondary,
    );
    var fgColor = convertColor(
      widget.news.colors()?.color(),
      Theme.of(context).colorScheme.primary,
    );
    bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          color: bgColor,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: FutureBuilder<Uint8List>(
            future: newsImage.then((value) => value.asTypedList()),
            builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
              if (snapshot.hasData) {
                return _ImageWidget(image: snapshot.data, isDesktop: isDesktop);
              } else {
                return const Center(child: Text('Loading image'));
              }
            },
          ),
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
                          ExpandableText(
                            widget.slide.text(),
                            maxLines: 2,
                            expandText: '',
                            expandOnTextTap: true,
                            collapseOnTextTap: true,
                            animation: true,
                            linkColor: fgColor,
                            style: GoogleFonts.inter(
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
                  Expanded(
                    // FIXME: unify this in the same widget
                    flex: 1,
                    child: NewsSideBar(
                      client: widget.client,
                      news: widget.news,
                      index: widget.index,
                    ),
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
    required this.image,
    required this.isDesktop,
  });

  final List<int>? image;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    // Size size = WidgetsBinding.instance.window.physicalSize;
    if (image == null) {
      return const SizedBox.shrink();
    }

    // return Image.memory(Uint8List.fromList(image), fit: BoxFit.cover);
    return Image.memory(
      Uint8List.fromList(image!),
      fit: BoxFit.cover,
      // cacheWidth: size.width.toInt(),
      // cacheHeight: size.height.toInt(),
    );
  }
}
