import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// saves selected users from search result
final createChatSelectedUsersProvider =
    StateProvider<List<ffi.UserProfile>>((ref) => []);
