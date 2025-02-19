import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

Future<NewsSlideDraft> makeVideoSlideForNews(
  WidgetRef ref,
  UpdateSlideItem slidePost,
  L10n lang,
) async {
  final videoDraft = await createVideoMsgDraftDraft(ref, slidePost, lang);
  final videoSlideDraft = videoDraft.intoNewsSlideDraft();

  final sdk = await ref.read(sdkProvider.future);
  videoSlideDraft.color(
    sdk.api.newColorizeBuilder(null, slidePost.backgroundColor?.toInt()),
  );
  final refDetails = slidePost.refDetails;
  if (refDetails != null) {
    final objRefBuilder = sdk.api.newObjRefBuilder(null, refDetails);
    videoSlideDraft.addReference(objRefBuilder);
  }
  return videoSlideDraft;
}

Future<StorySlideDraft> makeVideoSlideForStory(
  WidgetRef ref,
  UpdateSlideItem slidePost,
  L10n lang,
) async {
  final videoDraft = await createVideoMsgDraftDraft(ref, slidePost, lang);
  final videoSlideDraft = videoDraft.intoStorySlideDraft();

  final sdk = await ref.read(sdkProvider.future);
  videoSlideDraft.color(
    sdk.api.newColorizeBuilder(null, slidePost.backgroundColor?.toInt()),
  );
  final refDetails = slidePost.refDetails;
  if (refDetails != null) {
    final objRefBuilder = sdk.api.newObjRefBuilder(null, refDetails);
    videoSlideDraft.addReference(objRefBuilder);
  }
  return videoSlideDraft;
}

Future<MsgDraft> createVideoMsgDraftDraft(
  WidgetRef ref,
  UpdateSlideItem slidePost,
  L10n lang,
) async {
  final client = await ref.read(alwaysClientProvider.future);
  final file = slidePost.mediaFile;
  if (file == null) {
    throw 'Video File missing';
  }

  String? mimeType = file.mimeType ?? lookupMimeType(file.path);
  if (mimeType == null) throw lang.failedToDetectMimeType;
  if (!mimeType.startsWith('video/')) {
    throw lang.postingOfTypeNotYetSupported(mimeType);
  }
  Uint8List bytes = await file.readAsBytes();
  final videoDraft = client.videoDraft(file.path, mimeType).size(bytes.length);
  return videoDraft;
}
