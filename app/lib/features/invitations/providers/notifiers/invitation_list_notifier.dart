import 'dart:async';

import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::activities::invitation_list_notifier');

class InvitationListNotifier extends Notifier<List<Invitation>> {
  late Stream<FfiListInvitation> _listener;
  late StreamSubscription<FfiListInvitation> _poller;

  @override
  List<Invitation> build() {
    final client = ref.watch(clientProvider).valueOrNull;
    if (client == null) {
      return [];
    }
    _listener = client.invitationsRx(); // keep it resident in memory
    _poller = _listener.listen(
      (data) {
        final asList = data.toList();
        state = asList;
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller.cancel());
    return [];
  }
}
