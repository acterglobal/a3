import 'package:acter/features/deep_linking/actions/show_qr_code.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

class ExternalShareOptions extends StatelessWidget {
  final String link;
  final String? sectionTitle;
  final bool isShowCopyLinkOption;
  final bool isShowQrOption;
  final bool isShowSignalOption;
  final bool isShowWhatsAppOption;
  final bool isShowTelegramOption;
  final bool isShowMoreOption;

  const ExternalShareOptions({
    super.key,
    required this.link,
    this.sectionTitle,
    this.isShowCopyLinkOption = true,
    this.isShowQrOption = true,
    this.isShowSignalOption = true,
    this.isShowWhatsAppOption = true,
    this.isShowTelegramOption = true,
    this.isShowMoreOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final result = parseActerUri(Uri.parse(link));
    final type = result.type;
    final objectType = result.objectPath!.objectType;
    final objectId = result.target;
    final roomId = result.roomId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Divider(indent: 0),
            Text(
              sectionTitle ?? lang.share,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Expanded(child: Divider(indent: 20)),
          ],
        ),
        SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (isShowQrOption)
                shareToItemUI(
                  name: lang.qr,
                  iconData: PhosphorIcons.qrCode(),
                  color: Colors.grey.shade600,
                  onTap: () => showQrCode(context, link, title: Text('Share')),
                ),
              if (isShowCopyLinkOption)
                shareToItemUI(
                  name: lang.copyLink,
                  iconData: PhosphorIcons.link(),
                  color: Colors.blueGrey,
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(text: link),
                    );
                    EasyLoading.showToast(
                      lang.copyToClipboard,
                      toastPosition: EasyLoadingToastPosition.bottom,
                    );
                  },
                ),
              if (isShowSignalOption)
                shareToItemUI(
                  name: lang.signal,
                  iconData: PhosphorIcons.chat(),
                  color: Colors.deepPurpleAccent,
                  onTap: () {},
                ),
              if (isShowWhatsAppOption)
                shareToItemUI(
                  name: lang.whatsApp,
                  iconData: PhosphorIcons.whatsappLogo(),
                  color: Colors.green,
                  onTap: () {},
                ),
              if (isShowTelegramOption)
                shareToItemUI(
                  name: lang.telegram,
                  iconData: PhosphorIcons.telegramLogo(),
                  color: Colors.blue,
                  onTap: () {},
                ),
              if (isShowMoreOption)
                shareToItemUI(
                  name: lang.more,
                  iconData: PhosphorIcons.dotsThree(),
                  color: Colors.grey.shade800,
                  onTap: () async => await Share.share(link),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget shareToItemUI({
    required String name,
    required IconData iconData,
    required Color color,
    GestureTapCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: color,
                  style: BorderStyle.solid,
                  width: 1.0,
                ),
              ),
              child: Icon(iconData),
            ),
            SizedBox(height: 6),
            Text(name),
          ],
        ),
      ),
    );
  }
}
