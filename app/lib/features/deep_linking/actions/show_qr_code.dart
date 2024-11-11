import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

Future<void> showQrCode(
  BuildContext context,
  String codeData,
) async {
  showModalBottomSheet(
    showDragHandle: true,
    context: context,
    constraints: const BoxConstraints(maxHeight: 450),
    isScrollControlled: true,
    builder: (context) => _ShowQrCode(qrData: codeData),
  );
}

class _ShowQrCode extends StatelessWidget {
  final String qrData;

  const _ShowQrCode({required this.qrData});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: PrettyQrView.data(
          data: qrData,
          errorCorrectLevel: QrErrorCorrectLevel.M,
          decoration: PrettyQrDecoration(
            shape: PrettyQrSmoothSymbol(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            background: Theme.of(context).dialogBackgroundColor,
            image: const PrettyQrDecorationImage(
              image: AssetImage('assets/icon/logo.png'),
            ),
          ),
        ),
      );
}
