import 'dart:typed_data';

import 'package:acter/features/news/widgets/news_side_bar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

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

    // else
    var bgColor = convertColor(
      widget.news.colors()?.background(),
      Theme.of(context).colorScheme.secondary,
    );
    var fgColor = convertColor(
      widget.news.colors()?.color(),
      Theme.of(context).colorScheme.primary,
    );
    return Stack(
      children: [
        slideWidget(slideType, slide),
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(8),
          alignment: const Alignment(-0.95, 0.5),
          child: Text(
            slide.text(),
            softWrap: true,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: fgColor,
              shadows: [
                Shadow(
                  color: bgColor,
                  offset: const Offset(1, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: NewsSideBar(
            client: widget.client,
            news: widget.news,
            index: widget.index,
          ),
        ),
      ],
    );
  }

  Widget slideWidget(String slideType, NewsSlide slide) {
    switch (slideType) {
      case 'image':
        return ImageSlide(
          slide: slide,
        );
      case 'text':
        return const SizedBox();

      case 'video':
        return const SizedBox();

      default:
        return const SizedBox();
    }
  }
}

class ImageSlide extends StatefulWidget {
  final NewsSlide slide;

  const ImageSlide({
    Key? key,
    required this.slide,
  }) : super(key: key);

  @override
  State<ImageSlide> createState() => _ImageSlideState();
}

class _ImageSlideState extends State<ImageSlide> {
  late Future<FfiBufferUint8> newsImage;
  late ImageDesc? imageDesc;
  @override
  void initState() {
    super.initState();
    getNewsImage();
  }

  Future<void> getNewsImage() async {
    newsImage = widget.slide.imageBinary();
    imageDesc = widget.slide.imageDesc();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: newsImage.then((value) => value.asTypedList()),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.hasData) {
          return Container(
            foregroundDecoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: MemoryImage(
                  Uint8List.fromList(snapshot.data!),
                ),
              ),
            ),
          );
        } else {
          return const Center(child: Text('Loading image'));
        }
      },
    );
  }
}
