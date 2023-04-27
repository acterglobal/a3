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
      alignment: Alignment.bottomRight,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (slideType == 'image')
              Center(
                child: SizedBox.square(
                  dimension: 346,
                  child: ImageSlide(
                    slide: slide,
                  ),
                ),
              ),
            Container(
              width: MediaQuery.of(context).size.width * 0.78,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
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
          ],
        ),
        NewsSideBar(
          client: widget.client,
          news: widget.news,
          index: widget.index,
        ),
      ],
    );
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
          return _ImageWidget(
            image: snapshot.data,
            imageDesc: imageDesc,
          );
        } else {
          return const Center(child: Text('Loading image'));
        }
      },
    );
  }
}

class _ImageWidget extends StatelessWidget {
  const _ImageWidget({
    required this.image,
    required this.imageDesc,
  });

  final List<int>? image;
  final ImageDesc? imageDesc;

  @override
  Widget build(BuildContext context) {
    // Size size = WidgetsBinding.instance.window.physicalSize;
    if (image == null) {
      return const SizedBox.shrink();
    }

    // return Image.memory(Uint8List.fromList(image), fit: BoxFit.cover);
    return FittedBox(
      fit: BoxFit.contain,
      child: Image.memory(
        Uint8List.fromList(image!),
        height: imageDesc!.height()!.toDouble(),
        width: imageDesc!.width()!.toDouble(),
      ),
    );
  }
}
