import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';

final _log = Logger('a3::news::submit_news');

Future<NewsSlideDraft> _makeTextSlide(
  WidgetRef ref,
  NewsSlideItem slidePost,
  L10n lang,
) async {
  final sdk = await ref.read(sdkProvider.future);
  final client = ref.read(alwaysClientProvider);

  final text = slidePost.text?.trim();
  if (text == null || text.isEmpty == true) {
    throw lang.yourTextSlidesMustContainsSomeText;
  }
  final html = slidePost.html;
  final textDraft = html != null
      ? client.textHtmlDraft(html, text)
      : client.textMarkdownDraft(text);
  final textSlideDraft = textDraft.intoNewsSlideDraft();

  textSlideDraft.color(
    sdk.api.newColorizeBuilder(null, slidePost.backgroundColor?.value),
  );

  final refDetails = slidePost.refDetails;
  if (refDetails != null) {
    final objRef = sdk.api.newObjRefBuilder(null, refDetails).build();
    textSlideDraft.addReference(objRef);
  }

  return textSlideDraft;
}

Future<NewsSlideDraft> _makeImageSlide(
  WidgetRef ref,
  NewsSlideItem slidePost,
  L10n lang,
) async {
  final sdk = await ref.read(sdkProvider.future);
  final client = ref.read(alwaysClientProvider);

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
  final imageSlideDraft = imageDraft.intoNewsSlideDraft();
  imageSlideDraft.color(
    sdk.api.newColorizeBuilder(null, slidePost.backgroundColor?.value),
  );

  final refDetails = slidePost.refDetails;
  if (refDetails != null) {
    final objRef = sdk.api.newObjRefBuilder(null, refDetails).build();
    imageSlideDraft.addReference(objRef);
  }
  return imageSlideDraft;
}

Future<NewsSlideDraft> _makeVideoSlide(
  WidgetRef ref,
  NewsSlideItem slidePost,
  L10n lang,
) async {
  final sdk = await ref.read(sdkProvider.future);
  final client = ref.read(alwaysClientProvider);
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
  final videoSlideDraft = videoDraft.intoNewsSlideDraft();
  videoSlideDraft.color(
    sdk.api.newColorizeBuilder(null, slidePost.backgroundColor?.value),
  );
  final refDetails = slidePost.refDetails;
  if (refDetails != null) {
    final objRef = sdk.api.newObjRefBuilder(null, refDetails).build();
    videoSlideDraft.addReference(objRef);
  }
  return videoSlideDraft;
}

Future<void> sendNews(BuildContext context, WidgetRef ref) async {
  // Hide Keyboard
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final newsSlideList = ref.read(newsStateProvider).newsSlideList;
  final lang = L10n.of(context);
  final spaceId = ref.read(newsStateProvider).newsPostSpaceId ??
      await selectSpaceDrawer(
        context: context,
        canCheck: 'CanPostNews',
      );

  if (spaceId == null) {
    EasyLoading.showToast(lang.pleaseFirstSelectASpace);
    return;
  }

  // Show loading message
  EasyLoading.show(status: lang.slidePosting);
  final space = await ref.read(spaceProvider(spaceId).future);
  NewsEntryDraft draft = space.newsDraft();
  int slideIdx = 0;
  for (final slidePost in newsSlideList) {
    // for users
    slideIdx += 1;
    // If slide type is text
    try {
      final slide = await switch (slidePost.type) {
        NewsSlideType.text => _makeTextSlide(ref, slidePost, lang),
        NewsSlideType.image => _makeImageSlide(ref, slidePost, lang),
        NewsSlideType.video => _makeVideoSlide(ref, slidePost, lang),
      };
      await draft.addSlide(slide);
    } catch (err, s) {
      _log.severe(
        'Failed to process ${slidePost.type} at $slideIdx ',
        err,
        s,
      );
      EasyLoading.showError(
        lang.errorProcessingSlide(slideIdx, err),
        duration: const Duration(seconds: 3),
      );
      return;
    }
  }
  try {
    final eventId = await draft.send();
    // we want to stay informed about this via push notifications
    await autosubscribe(ref: ref, objectId: eventId.toString(), lang: lang);
  } catch (e, s) {
    _log.severe('Failed to send news', e, s);
    EasyLoading.showError(
      lang.creatingNewsFailed(e),
      duration: const Duration(seconds: 3),
    );
    return;
  }

  // close loading
  EasyLoading.dismiss();

  // FIXME due to #718. well lets at least try forcing a refresh upon route.
  ref.invalidate(newsStateProvider);
  // Navigate back to update screen.
  if (!context.mounted) return;
  Navigator.pop(context);
  context.pushReplacementNamed(Routes.main.name); // go to the home/main updates
}
