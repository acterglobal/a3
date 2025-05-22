import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/news/actions/make_image_slide.dart';
import 'package:acter/features/news/actions/make_text_slide.dart';
import 'package:acter/features/news/actions/make_video_slide.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::updates::submit_news');

Future<void> sendNews(BuildContext context, WidgetRef ref) async {
  // Hide Keyboard
  SystemChannels.textInput.invokeMethod('TextInput.hide');

  final newsSlideList = ref.read(newsStateProvider).newsSlideList;
  final lang = L10n.of(context);
  final spaceId =
      ref.read(newsStateProvider).newsPostSpaceId ??
      await selectSpaceDrawer(
        context: context,
        canCheck: (m) => m?.canString('CanPostNews') == true,
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
        UpdateSlideType.text => makeTextSlideForNews(ref, slidePost, lang),
        UpdateSlideType.image => makeImageSlideForNews(ref, slidePost, lang),
        UpdateSlideType.video => makeVideoSlideForNews(ref, slidePost, lang),
      };
      await draft.addSlide(slide);
    } catch (err, s) {
      _log.severe('Failed to process ${slidePost.type} at $slideIdx ', err, s);
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
