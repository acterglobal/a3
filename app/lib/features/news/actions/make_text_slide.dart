import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<NewsSlideDraft> makeTextSlideForNews(
  WidgetRef ref,
  UpdateSlideItem slidePost,
  L10n lang,
) async {
  final textDraft = await createTextMsgDraftDraft(ref, slidePost, lang);
  final textSlideDraft = textDraft.intoNewsSlideDraft();

  final sdk = await ref.read(sdkProvider.future);
  textSlideDraft.color(
    sdk.api.newColorizeBuilder(
      null,
      slidePost.backgroundColor?.toInt(),
      slidePost.linkColor?.toInt(),
    ),
  );

  final refDetails = slidePost.refDetails;
  if (refDetails != null) {
    final objRefBuilder = sdk.api.newObjRefBuilder(null, refDetails);
    textSlideDraft.addReference(objRefBuilder);
  }

  return textSlideDraft;
}

Future<StorySlideDraft> makeTextSlideForStory(
  WidgetRef ref,
  UpdateSlideItem slidePost,
  L10n lang,
) async {
  final textDraft = await createTextMsgDraftDraft(ref, slidePost, lang);
  final textSlideDraft = textDraft.intoStorySlideDraft();
  final sdk = await ref.read(sdkProvider.future);

  textSlideDraft.color(
    sdk.api.newColorizeBuilder(
      null,
      slidePost.backgroundColor?.toInt(),
      slidePost.linkColor?.toInt(),
    ),
  );

  final refDetails = slidePost.refDetails;
  if (refDetails != null) {
    final objRefBuilder = sdk.api.newObjRefBuilder(null, refDetails);
    textSlideDraft.addReference(objRefBuilder);
  }

  return textSlideDraft;
}

Future<MsgDraft> createTextMsgDraftDraft(
  WidgetRef ref,
  UpdateSlideItem slidePost,
  L10n lang,
) async {
  final client = await ref.read(alwaysClientProvider.future);

  final text = slidePost.text?.trim();
  if (text == null || text.isEmpty == true) {
    throw lang.yourTextSlidesMustContainsSomeText;
  }
  final html = slidePost.html;
  final textDraft = html != null
      ? client.textHtmlDraft(html, text)
      : client.textMarkdownDraft(text);
  return textDraft;
}
