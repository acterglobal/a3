import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';

final _log = Logger('a3::news::send_news');

Future<void> sendNews(BuildContext context, WidgetRef ref) async {
  // Hide Keyboard
  SystemChannels.textInput.invokeMethod('TextInput.hide');
  final client = ref.read(alwaysClientProvider);
  final spaceId = ref.read(newsStateProvider).newsPostSpaceId;
  final newsSlideList = ref.read(newsStateProvider).newsSlideList;
  final lang = L10n.of(context);

  if (spaceId == null) {
    EasyLoading.showToast(L10n.of(context).pleaseFirstSelectASpace);
    return;
  }

  // Show loading message
  EasyLoading.show(status: L10n.of(context).slidePosting);
  try {
    final space = await ref.read(spaceProvider(spaceId).future);
    NewsEntryDraft draft = space.newsDraft();
    for (final slidePost in newsSlideList) {
      final sdk = await ref.read(sdkProvider.future);
      // If slide type is text
      if (slidePost.type == NewsSlideType.text) {
        if (slidePost.text == null || slidePost.text!.trim().isEmpty) {
          if (!context.mounted) {
            EasyLoading.dismiss();
            return;
          }
          EasyLoading.showError(
            L10n.of(context).yourTextSlidesMustContainsSomeText,
            duration: const Duration(seconds: 3),
          );
          return;
        }
        final textDraft = slidePost.html != null
            ? client.textHtmlDraft(slidePost.html!, slidePost.text!)
            : client.textMarkdownDraft(slidePost.text!);
        final textSlideDraft = textDraft.intoNewsSlideDraft();

        textSlideDraft.color(
          sdk.api.newColorizeBuilder(null, slidePost.backgroundColor?.value),
        );

        if (slidePost.newsReferencesModel != null) {
          final objRef = getSlideReference(sdk, slidePost.newsReferencesModel!);
          textSlideDraft.addReference(objRef);
        }
        await draft.addSlide(textSlideDraft);
      }

      // If slide type is image
      else if (slidePost.type == NewsSlideType.image &&
          slidePost.mediaFile != null) {
        final file = slidePost.mediaFile!;
        String? mimeType = file.mimeType ?? lookupMimeType(file.path);
        if (mimeType == null) throw lang.failedToDetectMimeType;
        if (!mimeType.startsWith('image/')) {
          if (!context.mounted) {
            EasyLoading.dismiss();
            return;
          }
          EasyLoading.showError(
            L10n.of(context).postingOfTypeNotYetSupported(mimeType),
            duration: const Duration(seconds: 3),
          );
          return;
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
        if (slidePost.newsReferencesModel != null) {
          final objRef = getSlideReference(sdk, slidePost.newsReferencesModel!);
          imageSlideDraft.addReference(objRef);
        }
        await draft.addSlide(imageSlideDraft);
      }

      // If slide type is video
      else if (slidePost.type == NewsSlideType.video &&
          slidePost.mediaFile != null) {
        final file = slidePost.mediaFile!;
        String? mimeType = file.mimeType ?? lookupMimeType(file.path);
        if (mimeType == null) throw lang.failedToDetectMimeType;
        if (!mimeType.startsWith('video/')) {
          if (!context.mounted) {
            EasyLoading.dismiss();
            return;
          }
          EasyLoading.showError(
            L10n.of(context).postingOfTypeNotYetSupported(mimeType),
            duration: const Duration(seconds: 3),
          );
          return;
        }
        Uint8List bytes = await file.readAsBytes();
        final videoDraft =
            client.videoDraft(file.path, mimeType).size(bytes.length);
        final videoSlideDraft = videoDraft.intoNewsSlideDraft();
        videoSlideDraft.color(
          sdk.api.newColorizeBuilder(null, slidePost.backgroundColor?.value),
        );
        if (slidePost.newsReferencesModel != null) {
          final objRef = getSlideReference(sdk, slidePost.newsReferencesModel!);
          videoSlideDraft.addReference(objRef);
        }
        await draft.addSlide(videoSlideDraft);
      }
    }
    await draft.send();

    // close loading
    EasyLoading.dismiss();

    if (!context.mounted) return;
    // FIXME due to #718. well lets at least try forcing a refresh upon route.
    ref.invalidate(newsStateProvider);
    // Navigate back to update screen.
    Navigator.pop(context);
    context.pushReplacementNamed(
      Routes.main.name,
    ); // go to the home / main updates
  } catch (e, s) {
    _log.severe('Failed to send news', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      L10n.of(context).creatingNewsFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}

ObjRef getSlideReference(
  ActerSdk sdk,
  NewsReferencesModel newsReferencesModel,
) {
  final refDetails = switch (newsReferencesModel.type) {
    NewsReferencesType.calendarEvent => sdk.api
        .newCalendarEventRefBuilder(newsReferencesModel.id!, null, null)
        .build(),
    NewsReferencesType.link => sdk.api
        .newLinkRefBuilder(newsReferencesModel.title!, newsReferencesModel.id!)
        .build(),
  };
  return sdk.api.newObjRefBuilder(null, refDetails).build();
}
