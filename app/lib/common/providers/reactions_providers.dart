import 'package:acter/common/providers/notifiers/reactions_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';

/// Provider the profile data of a the given space, keeps up to date with underlying client
final reactionManagerProvider = NotifierProvider.family<
  ReactionManagerNotifier,
  ReactionManager,
  ReactionManager
>(() => ReactionManagerNotifier());
