import 'package:acter/common/providers/app_install_check_provider.dart';
import 'package:acter/features/deep_linking/actions/show_qr_code.dart';
import 'package:acter/features/share/actions/mail_to.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

class ExternalShareOptions extends ConsumerWidget {
  final String? sectionTitle;
  final String? qrContent;
  final String? shareContent;

  const ExternalShareOptions({
    super.key,
    this.sectionTitle,
    this.qrContent,
    this.shareContent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sectionTitle != null) ...[
          Row(
            children: [
              Divider(indent: 0),
              Text(
                sectionTitle!,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Expanded(child: Divider(indent: 20)),
            ],
          ),
          SizedBox(height: 12),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (qrContent != null) qrOptionsUI(context, qrContent!),
              if (shareContent != null)
                shareOptionsUI(context, ref, shareContent!),
            ],
          ),
        ),
      ],
    );
  }

  Widget qrOptionsUI(BuildContext context, String qrContent) {
    final lang = L10n.of(context);
    return shareToItemUI(
      name: lang.qr,
      iconWidget: Icon(PhosphorIcons.qrCode()),
      color: Colors.grey.shade600,
      onTap: () {
        Navigator.pop(context);
        showQrCode(
          context,
          qrContent,
        );
      },
    );
  }

  Widget shareOptionsUI(
    BuildContext context,
    WidgetRef ref,
    String shareContent,
  ) {
    final lang = L10n.of(context);
    final isWhatsAppInstalled =
        ref.watch(isAppInstalledProvider(ExternalApps.whatsApp)).valueOrNull ==
            true;
    final isTelegramInstalled =
        ref.watch(isAppInstalledProvider(ExternalApps.telegram)).valueOrNull ==
            true;
    final isSignalInstalled =
        ref.watch(isAppInstalledProvider(ExternalApps.signal)).valueOrNull ==
            true;
    return Row(
      children: [
        shareToItemUI(
          name: lang.copyLink,
          iconWidget: Icon(PhosphorIcons.link()),
          color: Colors.blueGrey,
          onTap: () async {
            await Clipboard.setData(
              ClipboardData(text: shareContent),
            );
            EasyLoading.showToast(lang.messageCopiedToClipboard);
          },
        ),
        shareToItemUI(
          name: lang.sendEmail,
          iconWidget: Icon(Atlas.envelope),
          color: Colors.redAccent,
          onTap: () async => await mailTo(
            toAddress: '',
            subject: 'body=$shareContent',
          ),
        ),
        if (isSignalInstalled)
          shareToItemUI(
            name: lang.signal,
            iconWidget: Image.asset(
              'assets/icon/signal_logo.png',
              height: 25,
              width: 25,
            ),
            color: Colors.blue,
            onTap: () {},
          ),
        if (isWhatsAppInstalled)
          shareToItemUI(
            name: lang.whatsApp,
            iconWidget: Icon(PhosphorIcons.whatsappLogo()),
            color: Colors.green,
            onTap: () {},
          ),
        if (isTelegramInstalled)
          shareToItemUI(
            name: lang.telegram,
            iconWidget: Icon(PhosphorIcons.telegramLogo()),
            color: Colors.blue,
            onTap: () {},
          ),
        shareToItemUI(
          name: lang.more,
          iconWidget: Icon(PhosphorIcons.dotsThree()),
          color: Colors.grey.shade800,
          onTap: () async => await Share.share(shareContent),
        ),
      ],
    );
  }

  Widget shareToItemUI({
    required String name,
    required Widget iconWidget,
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
              child: iconWidget,
            ),
            SizedBox(height: 6),
            Text(name),
          ],
        ),
      ),
    );
  }
}
