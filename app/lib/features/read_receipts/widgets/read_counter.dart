import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/features/read_receipts/providers/read_receipts.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ReadCounterWidget extends StatefulHookConsumerWidget {
  final Future<ReadReceiptsManager> manager;
  const ReadCounterWidget({super.key, required this.manager});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReadCounterWidgetState();
}

class _ReadCounterWidgetState extends ConsumerState<ReadCounterWidget> {
  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(readReceiptsManagerProvider(widget.manager));
    return manager.when(
      data: (manager) {
        final count = manager.readCount();
        return Text('$count');
      },
      loading: () => const _ReadCounterWidgetLoading(),
      error: (error, stackTrace) => ActerInlineErrorButton.icon(
        error: error,
        icon: const Icon(Icons.abc),
      ),
    );
  }
}

class _ReadCounterWidgetLoading extends StatelessWidget {
  const _ReadCounterWidgetLoading({Key? super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: null,
    );
  }
}
