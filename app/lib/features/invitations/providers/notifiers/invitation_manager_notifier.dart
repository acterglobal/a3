import 'dart:async';

import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::activities::invitation_list_notifier');

typedef InvitesState = ({List<RoomInvitation> rooms, List<String> objects});

class InvitationManagerNotifier extends AsyncNotifier<InvitesState> {
  // ignore: unused_field
  Stream<bool>? _listener;
  StreamSubscription<bool>? _poller;
  late InvitationsManager manager;

  FutureOr<InvitesState> _load() async {
    final roomInvites = (await manager.roomInvitations()).toList();
    final List<String> objectsWithInvites = [];
    return (rooms: roomInvites, objects: objectsWithInvites);
  }

  @override
  Future<InvitesState> build() async {
    manager = await ref.watch(invitationsManagerProvider.future);
    final listener = _listener = manager.subscribeStream();
    _poller?.cancel();

    _poller = listener.listen(
      (data) async {
        _log.info('attempting to reload');
        state = AsyncData(await _load());
      },
      onError: (e, s) {
        _log.severe('stream errored', e, s);
      },
      onDone: () {
        _log.info('stream ended');
      },
    );
    ref.onDispose(() => _poller?.cancel());
    return _load();
  }
}
