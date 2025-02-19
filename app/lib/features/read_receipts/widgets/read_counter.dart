import 'dart:async';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/common/widgets/visibility/shadow_effect_widget.dart';
import 'package:acter/features/read_receipts/providers/read_receipts.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ReadCounterWidget extends ConsumerStatefulWidget {
  final Future<ReadReceiptsManager> manager;
  final int? triggerAfterSecs;
  const ReadCounterWidget({
    super.key,
    required this.manager,
    this.triggerAfterSecs,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ReadCounterWidgetState();
}

class _ReadCounterWidgetState extends ConsumerState<ReadCounterWidget> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _updateTrigger();
  }

  @override
  void didUpdateWidget(covariant ReadCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTrigger();
  }

  void _updateTrigger() {
    _timer?.cancel(); // cancel any pending timers
    final seconds = widget.triggerAfterSecs;
    if (seconds != null && seconds != 0) {
      _timer = Timer(Duration(seconds: seconds), () async {
        final manager =
            await ref.read(readReceiptsManagerProvider(widget.manager).future);
        if (!manager.readByMe()) {
          await manager.announceRead();
        }
        _timer = null; // reset the timer
      });
    } else {
      _timer = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(readReceiptsManagerProvider(widget.manager));
    return manager.when(
      data: (manager) {
        final count = manager.readCount();
        return Column(
          children: [
            ShadowEffectWidget(child: Icon(PhosphorIcons.eye()),),
            ShadowEffectWidget(child:Text('$count'),),
          ],
        );
      },
      loading: () => const _ReadCounterWidgetLoading(),
      error: (error, stackTrace) => Column(
        children: [
          ActerInlineErrorButton.icon(
            error: error,
            stack: stackTrace,
            icon: Icon(PhosphorIcons.eye()),
            onRetryTap: () =>
                ref.invalidate(readReceiptsManagerProvider(widget.manager)),
          ),
          const Text('error'),
        ],
      ),
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
    );
  }
}

class _ReadCounterWidgetLoading extends StatelessWidget {
  const _ReadCounterWidgetLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(PhosphorIcons.eye()),
        const Skeletonizer(child: Text('count')),
      ],
    );
  }
}
