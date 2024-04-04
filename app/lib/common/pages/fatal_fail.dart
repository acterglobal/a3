import 'package:acter/common/dialogs/nuke_confirmation.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stack_trace/stack_trace.dart';

class FatalFailPage extends ConsumerStatefulWidget {
  final String error;
  final String trace;

  const FatalFailPage({
    super.key,
    required this.error,
    required this.trace,
  });

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
    return Scaffold(
      appBar: AppBar(title: const Text('Fatal Error')),
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
                const Text('Something went terribly wrong:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.error),
                    IconButton(
                      onPressed: onCopy,
                      icon: const Icon(Icons.copy_all_outlined),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() => showStack = !showStack);
                      },
                      icon: Icon(
                        showStack
                            ? Icons.toggle_off_outlined
                            : Icons.toggle_on_outlined,
                      ),
                    ),
                    const Text('Stacktrace'),
                  ],
                ),
              ],
            ),
            if (showStack) Text(stack),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: Icon(
                    Atlas.bomb_thin,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    'Nuke local data',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onPressed: onNukePressed,
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

  void onCopy() {
    Clipboard.setData(
      ClipboardData(text: '${widget.error}\n$stack'),
    );
    EasyLoading.showToast('Error & Stacktrace copied to clipboard');
  }

  void onNukePressed() {
    EasyLoading.showToast('long press to activate');
  }
}
