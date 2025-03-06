import 'package:acter/common/toolkit/html/render_html.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/type/update_slide.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:flutter/material.dart';

class TextSlide extends StatelessWidget {
  final UpdateSlide slide;

  const TextSlide({super.key, required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 70),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 100),
        child: buildTextContentUI(context),
      ),
    );
  }

  Widget buildTextContentUI(BuildContext context) {
    final slideContent = slide.msgContent();
    final formattedText = slideContent.formattedBody();
    final bodyText = slideContent.body();
    final fgColor = NewsUtils.getForegroundColor(context, slide);
    final linkColor = NewsUtils.getLinkColor(context, slide);
    final defaultTextStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: fgColor);

    final linkTextStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: linkColor,
      decoration: TextDecoration.underline,
    );

    return formattedText != null
        ? renderHtmlText(formattedText, defaultTextStyle, linkTextStyle)
        : renderNormalText(bodyText, defaultTextStyle);
  }

  Widget renderHtmlText(
    String formattedText,
    TextStyle? defaultTextStyle,
    TextStyle? linkTextStyle,
  ) {
    return SelectionArea(
      child: RenderHtml(
        key: UpdateKeys.textUpdateContent,
        text: formattedText,
        defaultTextStyle: defaultTextStyle,
        linkTextStyle: linkTextStyle,
      ),
    );
  }

  Widget renderNormalText(String bodyText, TextStyle? defaultTextStyle) {
    return SelectableText(
      key: UpdateKeys.textUpdateContent,
      bodyText,
      style: defaultTextStyle,
    );
  }
}
