import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'dart:async';

class Next {
  final bool isStart;
  final String? next;

  const Next({this.isStart = false, this.next});
}

class NotificationListState extends PagedState<Next?, ffi.Notification> {
  // We can extends [PagedState] to add custom parameters to our state

  const NotificationListState({
    List<ffi.Notification>? records,
    String? error,
    Next? nextPageKey = const Next(isStart: true),
    List<Next?>? previousPageKeys,
  }) : super(records: records, error: error, nextPageKey: nextPageKey);

  NotificationListState addNotification(ffi.Notification n) {
    final r = records ?? [];
    r.insert(0, n);
    return copyWith(
      records: r,
    );
  }

  @override
  NotificationListState copyWith({
    List<ffi.Notification>? records,
    dynamic error,
    dynamic nextPageKey,
    List<Next?>? previousPageKeys,
  }) {
    final sup = super.copyWith(
      records: records,
      error: error,
      nextPageKey: nextPageKey,
      previousPageKeys: previousPageKeys,
    );
    return NotificationListState(
      records: sup.records,
      error: sup.error,
      nextPageKey: sup.nextPageKey,
      previousPageKeys: sup.previousPageKeys,
    );
  }
}

class NotificationsListNotifier extends StateNotifier<NotificationListState>
    with PagedNotifierMixin<Next?, ffi.Notification, NotificationListState> {
  Stream<ffi.Notification>? _listener;
  // ignore: unused_field
  StreamSubscription<void>? _poller;
  final Ref ref;

  NotificationsListNotifier(this.ref) : super(const NotificationListState()) {
    initListener();
  }

  void initListener() {
    final client = ref.watch(clientProvider);
    if (client == null) {
      return;
    }

    _listener = client.notificationsStream();
    if (_listener != null) {
      _poller = _listener!.listen((ev) {
        // debugPrint(
        //   ' --- - - ----------------- new notification received',
        // );

        // final provider = ref.watch(featuresProvider);
        // if (provider.isActive(LabsFeature.showNotifications)) {
        //   if (!ev.read()) {
        //     final brief = extractBrief(ev);
        //     // notify(brief);
        //   }
        // }
        state = state.addNotification(ev);
      });
      ref.onDispose(() => _poller != null ? _poller!.cancel() : null);
    }
  }

  @override
  Future<List<ffi.Notification>?> load(Next? page, int limit) async {
    if (page == null) {
      return null;
    }

    final pageReq = page.next ?? '';
    final client = ref.read(clientProvider);
    if (client == null) {
      throw 'No client found';
    }
    try {
      final res = await client.listNotifications(pageReq, null);
      final entries = await res.notifications();
      final next = res.nextBatch();
      Next? finalPageKey;
      if (next != null) {
        // we are not at the end
        finalPageKey = Next(next: next);
      }
      state = state.copyWith(
        records: page.isStart
            ? [...entries]
            : [...(state.records ?? []), ...entries],
        nextPageKey: finalPageKey,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }

    return null;
  }
}
