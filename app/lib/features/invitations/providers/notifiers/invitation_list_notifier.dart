import 'dart:async';

import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::activities::invitation_list_notifier');

class InvitationListNotifier extends Notifier<List<RoomInvitation>> {
  late Stream<FfiListRoomInvitation> _listener;
  late StreamSubscription<FfiListRoomInvitation> _poller;
  late InvitationsManager manager;

  void reset() async {
    manager = await ref.watch(invitationsManagerProvider.future);
    final invites = await manager.roomInvitations();
    state = invites.toList();
  }

  @override
  List<RoomInvitation> build() {
    // FIXME: needs listener
    Future.delayed(Duration(milliseconds: 10), reset);
    return [];
  }
}
