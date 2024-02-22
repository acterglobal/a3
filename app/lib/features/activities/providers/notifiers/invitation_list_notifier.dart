import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvitationListNotifier extends Notifier<List<Invitation>> {
  late Stream<FfiListInvitation> _listener;
  // ignore: unused_field
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
      debugPrint(
        ' --- - - ----------------- new invitations received ${asList.length}',
      );
      state = asList;
    });
    ref.onDispose(() => _poller.cancel());
    return [];
  }
}
