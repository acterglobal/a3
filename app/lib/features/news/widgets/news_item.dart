import 'dart:typed_data';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/news/widgets/news_side_bar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsItem extends ConsumerWidget {
  final Client client;
  final NewsEntry news;
  final int index;

  const NewsItem({
    super.key,
    required this.client,
    required this.news,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var slide = news.getSlide(0)!;
    var slideType = slide.typeStr();
    final roomId = news.roomId().toString();
    final space = ref.watch(briefSpaceItemProvider(roomId));

    // else
    var bgColor = convertColor(
      news.colors()?.background(),
      Theme.of(context).colorScheme.background,
    );
    var fgColor = convertColor(
      news.colors()?.color(),
      Theme.of(context).colorScheme.primary,
    );

    Stack regularSlide(Widget child) => Stack(
          children: [
            child,
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 80, bottom: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      context.goNamed(
                        Routes.space.name,
                        pathParameters: {'spaceId': roomId},
                      );
                    },
                    child: space.when(
                      data: (space) =>
                          Text(space!.spaceProfileData.displayName ?? roomId),
                      error: (e, st) => Text('Error loading space: $e'),
                      loading: () => Text(roomId),
                    ),
                  ),
                  Text(
                    slide.text(),
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: fgColor,
                      shadows: [
                        Shadow(
                          color: bgColor,
                          offset: const Offset(1, 1),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: NewsSideBar(
                news: news,
                index: index,
              ),
            ),
          ],
        );

    switch (slideType) {
      case 'image':
        return regularSlide(ImageSlide(slide: slide));

      case 'video':
        return regularSlide(
          const Expanded(
            child: Center(
              child: Text('video slides not yet supported'),
            ),
          ),
        );

      case 'text':
        return Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 80, bottom: 8),
                child: Card(
                  color: bgColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: slide.hasFormattedText()
                        ? RenderHtml(
                            text: slide.text(),
                            defaultTextStyle:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: fgColor,
                                    ),
                          )
                        : Text(
                            slide.text(),
                            softWrap: true,
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      color: fgColor,
                                    ),
                          ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: NewsSideBar(
                news: news,
                index: index,
              ),
            ),
          ],
        );

      default:
        return regularSlide(
          Expanded(
            child: Center(
              child: Text('$slideType slides not yet supported'),
            ),
          ),
        );
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
    if (mounted) {
      setState(() {});
    }
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
