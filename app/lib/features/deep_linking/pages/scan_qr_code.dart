import 'package:acter/features/deep_linking/actions/handle_deep_link_uri.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

class ScanQrCode extends ConsumerWidget {
  const ScanQrCode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
      ),
      body: QRCodeDartScanView(
        scanInvertedQRCode:
            true, // enable scan invert qr code ( default = false)
        intervalScan: const Duration(milliseconds: 300),

        typeScan: TypeScan.live,
        onCapture: (r) => _onCapture(context, ref, r),
      ),
    );
  }

  Future<void> _onCapture(
    BuildContext context,
    WidgetRef ref,
    Result result,
  ) async {
    EasyLoading.dismiss();
    final uri = Uri.tryParse(result.text);
    if (uri == null) {
      EasyLoading.showError(
        'Content is not a URI',
        duration: const Duration(seconds: 3),
      );
      return;
    }
    if (context.mounted) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
      await handleDeepLinkUri(context: context, ref: ref, uri: uri);
    }
  }
}
