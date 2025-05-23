import 'package:acter/common/dialogs/nuke_confirmation.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/router/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stack_trace/stack_trace.dart';

class FatalFailPage extends ConsumerStatefulWidget {
  final String error;
  final String trace;

  const FatalFailPage({super.key, required this.error, required this.trace});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FatalFailPageState();
}

class _FatalFailPageState extends ConsumerState<FatalFailPage> {
  bool showStack = false;
  late String stack;

  @override
  void initState() {
    super.initState();
    stack = Trace.parse(widget.trace).terse.toString();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height / 4;
    final lang = L10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(lang.fatalError)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                SizedBox(
                  height: height,
                  width: height,
                  child: SvgPicture.asset('assets/images/genericError.svg'),
                ),
                Text(lang.somethingWrong),
                Text(widget.error),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_all_outlined),
                  label: Text(lang.copyToClipboard),
                ),
                TextButton.icon(
                  onPressed: onStacktraceToggle,
                  icon: Icon(
                    showStack
                        ? Icons.toggle_off_outlined
                        : Icons.toggle_on_outlined,
                  ),
                  label: Text(
                    showStack ? lang.hideStacktrace : lang.showStacktrace,
                  ),
                ),
              ],
            ),
            if (showStack) Text(stack),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActerDangerActionButton.icon(
                  icon: const Icon(Atlas.bomb_thin),
                  label: Text(lang.nukeLocalData),
                  onPressed: onNukePressed,
                  onLongPress: () => nukeConfirmationDialog(context, ref),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Atlas.bug_clipboard_thin),
                  label: Text(lang.reportBug),
                  onPressed: () => context.pushNamed(Routes.bugReport.name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void onCopy() {
    final data = ClipboardData(text: '${widget.error}\n$stack');
    Clipboard.setData(data);
    EasyLoading.showToast(L10n.of(context).errorCopiedToClipboard);
  }

  void onStacktraceToggle() {
    setState(() => showStack = !showStack);
  }

  void onNukePressed() {
    EasyLoading.showToast(L10n.of(context).longPressToActivate);
  }
}
