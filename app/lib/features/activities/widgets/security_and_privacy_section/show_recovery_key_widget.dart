import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/activities/actions/destroy_enc_key_action.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShowRecoveryKeyWidget extends ConsumerStatefulWidget {
  final String recoveryKey;
  final VoidCallback? onKeyDestroyed;
  
  const ShowRecoveryKeyWidget({
    super.key, 
    required this.recoveryKey,
    this.onKeyDestroyed,
  });

  @override
  ConsumerState<ShowRecoveryKeyWidget> createState() => ShowRecoveryKeyWidgetState();
}

class ShowRecoveryKeyWidgetState extends ConsumerState<ShowRecoveryKeyWidget> {
  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.encryptionBackupRecovery, textAlign: TextAlign.center,),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.encryptionBackupRecoveryExplainer,textAlign: TextAlign.center,),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: widget.recoveryKey,
              readOnly: true,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: widget.recoveryKey));
                    EasyLoading.showToast(
                      lang.encryptionBackupRecoveryCopiedToClipboard,
                      toastPosition: EasyLoadingToastPosition.bottom,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ActerPrimaryActionButton(
              onPressed: () {
                destroyEncKey(context, ref);
                widget.onKeyDestroyed?.call();
              },
              child: Text(lang.dontRemindMe),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.okay),
            ),
          ],
        ),
      ],
    );
  }
}