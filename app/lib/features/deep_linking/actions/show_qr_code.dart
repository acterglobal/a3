import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

Future<void> showQrCode(
  BuildContext context,
  String codeData, {
  Widget? title,
}) async {
  showDialog(
    context: context,
    builder: (context) => _ShowQrCode(qrData: codeData, title: title),
  );
}

class _ShowQrCode extends StatelessWidget {
  final Widget? title;
  final String qrData;

  const _ShowQrCode({required this.qrData, this.title});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: title,
    content: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: PrettyQrView.data(
        data: qrData,
        errorCorrectLevel: QrErrorCorrectLevel.M,
        decoration: PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
          background: Theme.of(context).dialogTheme.backgroundColor,
          image: const PrettyQrDecorationImage(
            image: AssetImage('assets/icon/logo.png'),
          ),
        ),
      ),
    ),
  );
}
