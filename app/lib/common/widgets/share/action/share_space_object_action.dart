import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/share/widgets/attach_options.dart';
import 'package:acter/common/widgets/share/widgets/external_share_options.dart';
import 'package:acter/features/deep_linking/actions/show_qr_code.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

Future<void> openShareSpaceObjectDialog({
  required BuildContext context,
  required String spaceId,
  required ObjectType objectType,
  required String objectId,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => ShareSpaceObjectActionUI(
      spaceId: spaceId,
      objectType: objectType,
      objectId: objectId,
    ),
  );
}

class ShareSpaceObjectActionUI extends StatelessWidget {
  final String spaceId;
  final ObjectType objectType;
  final String objectId;

  const ShareSpaceObjectActionUI({
    super.key,
    required this.spaceId,
    required this.objectType,
    required this.objectId,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            attachmentOptionsUI(context),
            SizedBox(height: 16),
            externalShareOptionsUI(context)
          ],
        ),
      ),
    );
  }

  Widget attachmentOptionsUI(BuildContext context) {
    final newsRefType = getNewsRefTypeFromObjType(objectType);
    return AttachOptions(
      onTapBoost: () {
        Navigator.pop(context);
        context.pushNamed(
          Routes.actionAddUpdate.name,
          queryParameters: {'spaceId': spaceId},
          extra: newsRefType != null
              ? NewsReferencesModel(
                  type: newsRefType,
                  id: objectId,
                )
              : null,
        );
      },
    );
  }

  Widget externalShareOptionsUI(BuildContext context) {
    final lang = L10n.of(context);
    final link = '';
    return ExternalShareOptions(
      onTapQr: () {
        Navigator.pop(context);
        showQrCode(context, link, title: Text('Share'));
      },
      onTapCopy: () async {
        Navigator.pop(context);
        await Clipboard.setData(ClipboardData(text: link));
        EasyLoading.showToast(
          lang.copyToClipboard,
          toastPosition: EasyLoadingToastPosition.bottom,
        );
      },
      onTapMore: () async {
        Navigator.pop(context);
        await Share.share(link);
      },
    );
  }

  NewsReferencesType? getNewsRefTypeFromObjType(ObjectType objectType) {
    return switch (objectType) {
      ObjectType.pin => NewsReferencesType.pin,
      ObjectType.calendarEvent => NewsReferencesType.calendarEvent,
      ObjectType.taskList => NewsReferencesType.taskList,
      _ => null,
    };
  }
}
