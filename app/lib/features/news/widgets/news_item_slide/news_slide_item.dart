import 'package:acter/features/news/model/type/update_slide.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/widgets/news_item_slide/image_slide.dart';
import 'package:acter/features/news/widgets/news_item_slide/news_slide_actions.dart';
import 'package:acter/features/news/widgets/news_item_slide/text_slide.dart';
import 'package:acter/features/news/widgets/news_item_slide/video_slide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class UpdateSlideItem extends StatelessWidget {
  final UpdateSlide slide;
  final bool showRichContent;

  const UpdateSlideItem({
    super.key,
    required this.slide,
    this.showRichContent = true,
  });

  @override
  Widget build(BuildContext context) {
    return buildUpdateSlideItem(context);
  }

  Widget buildUpdateSlideItem(BuildContext context) {
    final slideType = slide.typeStr();
    final slideBackgroundColor = NewsUtils.getBackgroundColor(context, slide);
    return Stack(
      children: [
        //SLIDE CONTENT UI
        Positioned.fill(
          child: Container(
            color: slideBackgroundColor,
            child: switch (slideType) {
              'image' => ImageSlide(slide: slide),
              'video' => VideoSlide(slide: slide),
              'text' =>
                showRichContent ? TextSlide(slide: slide) : normalTextSlide(),
              _ => notSupportedSlide(context, slideType),
            },
          ),
        ),
        //SLIDE ACTIONS
        if (showRichContent)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 190,
              padding: const EdgeInsets.only(
                right: 60,
                bottom: 80,
              ),
              child: UpdateSlideActions(newsSlide: slide),
            ),
          ),
      ],
    );
  }

  Widget normalTextSlide() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          slide.msgContent().body().toString(),
          overflow: TextOverflow.ellipsis,
          maxLines: 7,
        ),
      ),
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
