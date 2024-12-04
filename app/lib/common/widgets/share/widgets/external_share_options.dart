import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ExternalShareOptions extends StatelessWidget {
  final String? sectionTitle;
  final GestureTapCallback? onTapCopy;
  final GestureTapCallback? onTapQr;
  final GestureTapCallback? onTapSignal;
  final GestureTapCallback? onTapWhatsApp;
  final GestureTapCallback? onTapTelegram;
  final GestureTapCallback? onTapMore;

  const ExternalShareOptions({
    super.key,
    this.sectionTitle,
    this.onTapCopy,
    this.onTapQr,
    this.onTapSignal,
    this.onTapWhatsApp,
    this.onTapTelegram,
    this.onTapMore,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);

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
              if (onTapQr != null)
                shareToItemUI(
                  name: lang.qr,
                  iconWidget: Icon(PhosphorIcons.qrCode()),
                  color: Colors.grey.shade600,
                  onTap: onTapQr,
                ),
              if (onTapCopy != null)
                shareToItemUI(
                  name: lang.copyLink,
                  iconWidget: Icon(PhosphorIcons.link()),
                  color: Colors.blueGrey,
                  onTap: onTapCopy,
                ),
              if (onTapSignal != null)
                shareToItemUI(
                  name: lang.signal,
                  iconWidget: Image.asset(
                    'assets/icon/signal_logo.png',
                    height: 25,
                    width: 25,
                  ),
                  color: Colors.blue,
                  onTap: onTapSignal,
                ),
              if (onTapWhatsApp != null)
                shareToItemUI(
                  name: lang.whatsApp,
                  iconWidget: Icon(PhosphorIcons.whatsappLogo()),
                  color: Colors.green,
                  onTap: onTapWhatsApp,
                ),
              if (onTapTelegram != null)
                shareToItemUI(
                  name: lang.telegram,
                  iconWidget: Icon(PhosphorIcons.telegramLogo()),
                  color: Colors.blue,
                  onTap: onTapTelegram,
                ),
              if (onTapMore != null)
                shareToItemUI(
                  name: lang.more,
                  iconWidget: Icon(PhosphorIcons.dotsThree()),
                  color: Colors.grey.shade800,
                  onTap: onTapMore,
                ),
            ],
          ),
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
