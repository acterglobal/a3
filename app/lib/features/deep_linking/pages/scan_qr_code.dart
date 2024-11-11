import 'package:acter/features/deep_linking/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

class ScanQrCode extends StatelessWidget {
  const ScanQrCode({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
      ),
      body: QRCodeDartScanView(
        scanInvertedQRCode:
            true, // enable scan invert qr code ( default = false)
        intervalScan: const Duration(milliseconds: 300),

        typeScan: TypeScan.live,
        onCapture: (r) => _onCapture(context, r),
      ),
    );
  }

  Future<void> _onCapture(BuildContext context, Result result) async {
    print(result);
    EasyLoading.dismiss();
    try {
      final uri = Uri.tryParse(result.text);
      if (uri == null) {
        EasyLoading.showError(
          'Content is not a URI',
          duration: const Duration(seconds: 3),
        );
        return;
      }
      final resp = parseUri(uri);
      EasyLoading.showToast('Successfully detected. forwarding');
      print(resp);
      if (context.mounted) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop(resp);
        }
      }
    } on UriParseError catch (e) {
      EasyLoading.showError(
        'Uri not supported: $e',
        duration: const Duration(seconds: 3),
      );
      return;
    }
  }
}
