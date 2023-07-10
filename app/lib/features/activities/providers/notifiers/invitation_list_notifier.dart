import 'dart:async';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvitationListNotifier extends Notifier<List<Invitation>> {
  late Stream<FfiListInvitation> _listener;
  // ignore: unused_field
  late StreamSubscription<void> _sub;

  @override
  List<Invitation> build() {
    final client = ref.watch(clientProvider)!;
    _listener = client.invitationsRx();
    _sub = _listener.listen((ev) {
      final as_list = ev.toList();
      print(' --- - - ----------------- new invitations received ${ev.length}');
      state = as_list;
    });
    return [];
  }
}
