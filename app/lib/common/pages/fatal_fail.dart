
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/dialogs/nuke_confirmation.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class FatalFailPage extends ConsumerWidget {
  final String error;
  final String trace;
  const FatalFailPage({
    super.key,
    required this.error,
    required this.trace,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Fatal Error: $error')),
      body: Center(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: SvgPicture.asset('assets/images/genericError.svg'),
            ),
            Text(
              'Something went terribly wrong: $error',
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon:  Icon(Atlas.bomb_thin,
                    color: Theme.of(context).colorScheme.error,),
                  label: Text('Nuke local data',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),),
                  onPressed: () => customMsgSnackbar(context, 'long press to activate'),
                  onLongPress: () => nukeConfirmationDialog(context, ref),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Atlas.bug_clipboard_thin),
                  label: const Text('Report bug'),
                  onPressed: () => context.goNamed(Routes.bugReport.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
