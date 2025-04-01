import 'package:acter/features/room/model/room_join_rule.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/spaces/model/default_space_feature_settings.dart';
import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// user selected visibility provider
final selectedJoinRuleProvider = StateProvider<RoomJoinRule?>(
  (ref) => null,
); // user selected visibility provider

// create default chat provider
final createDefaultChatProvider = StateProvider<bool>((ref) => false);

// create default chat provider
final showSpaceCreationConfigurationProvider = StateProvider<bool>(
  (ref) => false,
);

// Feature activation state provider
final featureActivationStateProvider =
    StateProvider<Map<SpaceFeature, FeatureActivationState>>(
      (ref) => generateRecommendedSettings,
    );
