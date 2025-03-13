import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:riverpod/riverpod.dart';

/// saves selected users from search result
final createChatSelectedUsersProvider = StateProvider<List<ffi.UserProfile>>(
  (ref) => [],
);
