import 'package:acter/features/deep_linking/actions/show_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QrCodeButton extends StatelessWidget {
  final String qrCodeData;
  final Widget? qrTitle;
  const QrCodeButton({super.key, required this.qrCodeData, this.qrTitle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(PhosphorIconsRegular.qrCode),
      onPressed: () => showQrCode(context, qrCodeData, title: qrTitle),
    );
  }
}
