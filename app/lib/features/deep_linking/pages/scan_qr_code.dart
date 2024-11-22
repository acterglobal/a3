import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/deep_linking/utils.dart';
import 'package:acter/features/super_invites/dialogs/redeem_dialog.dart';
import 'package:acter/features/users/actions/show_global_user_dialog.dart';
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
    debugPrint(result.toString());
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
      if (context.mounted) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop(resp);
        }
        await _handleParseResult(context, ref, resp);
      }
    } on UriParseError catch (e) {
      EasyLoading.showError(
        'Uri not supported: $e',
        duration: const Duration(seconds: 3),
      );
      return;
    }
  }

  Future<void> _handleParseResult(
    BuildContext context,
    WidgetRef ref,
    UriParseResult result,
  ) async {
    final _ = switch (result.type) {
      LinkType.userId =>
        await showUserInfoDrawer(context: context, userId: result.target),
      LinkType.superInvite => await showReedemTokenDialog(
          context,
          ref,
          result.target,
        ),
      _ => EasyLoading.showError(
          'Link ${result.type} not yet supported.',
          duration: const Duration(seconds: 3),
        ),
    };
  }
}
