import 'dart:async';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class InvitationListNotifier extends Notifier<List<Invitation>> {
  Stream<FfiListInvitation>? _listener;
  // ignore: unused_field
  StreamSubscription<void>? _poller;

  @override
  List<Invitation> build() {
    final client = ref.watch(clientProvider);
    if (client == null) {
      _listener = null;
      _poller = null;
      return [];
    }
    _listener = client.invitationsRx();
    if (_listener != null) {
      _poller = _listener!.listen((ev) {
        final asList = ev.toList();
        debugPrint(
          ' --- - - ----------------- new invitations received ${asList.length}',
        );
        state = asList;
      });
      ref.onDispose(() => _poller != null ? _poller!.cancel() : null);
    }
    return [];
  }
}
