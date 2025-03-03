import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

Future<NewsSlideDraft> makeImageSlideForNews(
  WidgetRef ref,
  UpdateSlideItem slidePost,
  L10n lang,
) async {
  final imageDraft = await createImageMsgDraftDraft(ref, slidePost, lang);
  final imageSlideDraft = imageDraft.intoNewsSlideDraft();

  final sdk = await ref.read(sdkProvider.future);
  imageSlideDraft.color(
    sdk.api.newColorizeBuilder(
      null,
      slidePost.backgroundColor?.toInt(),
      slidePost.linkColor?.toInt(),
    ),
  );

  final refDetails = slidePost.refDetails;
  if (refDetails != null) {
    final objRefBuilder = sdk.api.newObjRefBuilder(null, refDetails);
    imageSlideDraft.addReference(objRefBuilder);
  }
  return imageSlideDraft;
}

Future<StorySlideDraft> makeImageSlideForStory(
  WidgetRef ref,
  UpdateSlideItem slidePost,
  L10n lang,
) async {
  final imageDraft = await createImageMsgDraftDraft(ref, slidePost, lang);
  final imageSlideDraft = imageDraft.intoStorySlideDraft();

  final sdk = await ref.read(sdkProvider.future);
  imageSlideDraft.color(
    sdk.api.newColorizeBuilder(
      null,
      slidePost.backgroundColor?.toInt(),
      slidePost.linkColor?.toInt(),
    ),
  );

  final refDetails = slidePost.refDetails;
  if (refDetails != null) {
    final objRefBuilder = sdk.api.newObjRefBuilder(null, refDetails);
    imageSlideDraft.addReference(objRefBuilder);
  }
  return imageSlideDraft;
}

Future<MsgDraft> createImageMsgDraftDraft(
  WidgetRef ref,
  UpdateSlideItem slidePost,
  L10n lang,
) async {
  final client = await ref.read(alwaysClientProvider.future);

  final file = slidePost.mediaFile;
  if (file == null) {
    throw 'Image File missing';
  }
  String? mimeType = file.mimeType ?? lookupMimeType(file.path);
  if (mimeType == null) throw lang.failedToDetectMimeType;
  if (!mimeType.startsWith('image/')) {
    throw lang.postingOfTypeNotYetSupported(mimeType);
  }
  Uint8List bytes = await file.readAsBytes();
  final decodedImage = await decodeImageFromList(bytes);
  final imageDraft = client
      .imageDraft(file.path, mimeType)
      .size(bytes.length)
      .width(decodedImage.width)
      .height(decodedImage.height);
  return imageDraft;
}
