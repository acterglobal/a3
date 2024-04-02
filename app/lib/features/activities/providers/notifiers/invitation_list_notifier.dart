import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

class InvitationListNotifier extends Notifier<List<Invitation>> {
  late Stream<FfiListInvitation> _listener;
  late StreamSubscription<FfiListInvitation> _poller;

  @override
  List<Invitation> build() {
    final client = ref.watch(clientProvider);
    if (client == null) {
      return [];
    }
    _listener = client.invitationsRx(); // keep it resident in memory
    _poller = _listener.listen((ev) {
      final asList = ev.toList();
      state = asList;
    });
    ref.onDispose(() => _poller.cancel());
    return [];
  }
}
