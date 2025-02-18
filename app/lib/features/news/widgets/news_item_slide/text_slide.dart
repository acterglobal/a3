import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
    final defaultTextStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: fgColor);

    return formattedText != null
        ? renderHtmlText(formattedText, defaultTextStyle)
        : renderNormalText(bodyText, defaultTextStyle);
  }

  Widget renderHtmlText(String formattedText, TextStyle? defaultTextStyle) {
    return SelectionArea(
      child: RenderHtml(
        key: NewsUpdateKeys.textUpdateContent,
        text: formattedText,
        defaultTextStyle: defaultTextStyle,
      ),
    );
  }

  Widget renderNormalText(String bodyText, TextStyle? defaultTextStyle) {
    return SelectableText(
      key: NewsUpdateKeys.textUpdateContent,
      bodyText,
      style: defaultTextStyle,
    );
  }
}
