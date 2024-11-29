import 'package:acter/common/widgets/share/widgets/attach_options.dart';
import 'package:acter/common/widgets/share/widgets/external_share_options.dart';
import 'package:acter/features/deep_linking/actions/show_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

Future<void> openShareSpaceObjectDialog({
  required BuildContext context,
  required String link,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => ShareActionUI(link: link),
  );
}

class ShareActionUI extends StatelessWidget {
  final String link;

  const ShareActionUI({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AttachOptions(
              onTapBoost: () {},
            ),
            SizedBox(height: 16),
            ExternalShareOptions(
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
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
