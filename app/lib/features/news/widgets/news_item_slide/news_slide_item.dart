import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/widgets/news_item_slide/image_slide.dart';
import 'package:acter/features/news/widgets/news_item_slide/text_slide.dart';
import 'package:acter/features/news/widgets/news_item_slide/video_slide.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class NewsSlideItem extends StatelessWidget {
  final NewsSlide slide;
  final bool showRichText;

  const NewsSlideItem({
    super.key,
    required this.slide,
    this.showRichText = true,
  });

  @override
  Widget build(BuildContext context) {
    return buildNewsSlideItem(context);
  }

  Widget buildNewsSlideItem(BuildContext context) {
    final slideType = slide.typeStr();
    final slideBackgroundColor = NewsUtils.getBackgroundColor(context, slide);
    return Container(
      color: slideBackgroundColor,
      child: switch (slideType) {
        'image' => ImageSlide(slide: slide),
        'video' => VideoSlide(slide: slide),
        'text' => showRichText ? TextSlide(slide: slide) : normalTextSlide(),
        _ => notSupportedSlide(context, slideType),
      },
    );
  }

  Widget normalTextSlide() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(child: Text(slide.msgContent().body().toString())),
    );
  }

  Widget notSupportedSlide(BuildContext context, slideType) {
    return Expanded(
      child: Center(
        child: Text(L10n.of(context).slidesNotYetSupported(slideType)),
      ),
    );
  }
}
