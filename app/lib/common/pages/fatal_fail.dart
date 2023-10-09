
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
            // ButtonBar(
            //   alignment: MainAxisAlignment.center,
            //   children: [
            //     OutlinedButton.icon(
            //       icon: const Icon(Atlas.home_thin),
            //       label: const Text('Go to home'),
            //       onPressed: () => context.goNamed(Routes.main.name),
            //     ),
            //     OutlinedButton.icon(
            //       icon: const Icon(Atlas.bug_clipboard_thin),
            //       label: const Text('Report bug'),
            //       onPressed: () => context.goNamed(Routes.bugReport.name),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
