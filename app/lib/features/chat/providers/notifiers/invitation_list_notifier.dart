import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Invitation;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvitationListNotifier extends StateNotifier<List<Invitation>> {
  InvitationListNotifier() : super([]);

  void setList(List<Invitation> list) {
    state = list;
  }
}
