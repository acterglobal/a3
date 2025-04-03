import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/spaces/actions/create_space.dart';
import 'package:acter/features/spaces/model/permission_config.dart';
import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppPermissionsBuilder extends Mock implements AppPermissionsBuilder {}

void main() {
  late MockAppPermissionsBuilder mockBuilder;

  setUp(() {
    mockBuilder = MockAppPermissionsBuilder();
  });

  group('applyPermissions', () {
    test(
      'should apply feature activation and permissions for activated features',
      () {
        // Arrange
        final featureStates = {
          SpaceFeature.boosts: FeatureActivationState(
            isActivated: true,
            permissions: [
              PermissionConfig(
                key: PermissionType.boostPost,
                permissionLevel: PermissionLevel.admin,
                // displayText: 'Boost Post',
              ),
            ],
          ),
          SpaceFeature.stories: FeatureActivationState(
            isActivated: false,
            permissions: [],
          ),
        };

        // Act
        applyPermissions(mockBuilder, featureStates);

        // Assert
        verify(() => mockBuilder.news(true)).called(1);
        verify(
          () => mockBuilder.newsPermisisons(PermissionLevel.admin.value),
        ).called(1);
        verify(() => mockBuilder.stories(false)).called(1);
        verifyNoMoreInteractions(mockBuilder);
      },
    );

    test('should handle all feature types and their permissions', () {
      // Arrange
      final featureStates = {
        SpaceFeature.boosts: FeatureActivationState(
          isActivated: true,
          permissions: [
            PermissionConfig(
              key: PermissionType.boostPost,
              permissionLevel: PermissionLevel.admin,
            ),
          ],
        ),
        SpaceFeature.stories: FeatureActivationState(
          isActivated: true,
          permissions: [
            PermissionConfig(
              key: PermissionType.storyPost,
              permissionLevel: PermissionLevel.everyone,
            ),
          ],
        ),
        SpaceFeature.pins: FeatureActivationState(
          isActivated: true,
          permissions: [
            PermissionConfig(
              key: PermissionType.pinPost,
              permissionLevel: PermissionLevel.moderator,
            ),
          ],
        ),
        SpaceFeature.events: FeatureActivationState(
          isActivated: true,
          permissions: [
            PermissionConfig(
              key: PermissionType.eventPost,
              permissionLevel: PermissionLevel.moderator,
            ),
            PermissionConfig(
              key: PermissionType.eventRsvp,
              permissionLevel: PermissionLevel.everyone,
            ),
          ],
        ),
        SpaceFeature.tasks: FeatureActivationState(
          isActivated: true,
          permissions: [
            PermissionConfig(
              key: PermissionType.taskListPost,
              permissionLevel: PermissionLevel.admin,
            ),
            PermissionConfig(
              key: PermissionType.taskItemPost,
              permissionLevel: PermissionLevel.moderator,
            ),
          ],
        ),
      };

      // Act
      applyPermissions(mockBuilder, featureStates);

      // Assert
      verify(() => mockBuilder.news(true)).called(1);
      verify(
        () => mockBuilder.newsPermisisons(PermissionLevel.admin.value),
      ).called(1);
      verify(() => mockBuilder.stories(true)).called(1);
      verify(
        () => mockBuilder.storiesPermisisons(PermissionLevel.everyone.value),
      ).called(1);
      verify(() => mockBuilder.pins(true)).called(1);
      verify(
        () => mockBuilder.pinsPermisisons(PermissionLevel.moderator.value),
      ).called(1);
      verify(() => mockBuilder.calendarEvents(true)).called(1);
      verify(
        () => mockBuilder.calendarEventsPermisisons(
          PermissionLevel.moderator.value,
        ),
      ).called(1);
      verify(
        () => mockBuilder.rsvpPermisisons(PermissionLevel.everyone.value),
      ).called(1);
      verify(() => mockBuilder.tasks(true)).called(1);
      verify(
        () => mockBuilder.taskListsPermisisons(PermissionLevel.admin.value),
      ).called(1);
      verify(
        () => mockBuilder.tasksPermisisons(PermissionLevel.moderator.value),
      ).called(1);
    });

    test('should not apply permissions for deactivated features', () {
      // Arrange
      final featureStates = {
        SpaceFeature.boosts: FeatureActivationState(
          isActivated: false,
          permissions: [
            PermissionConfig(
              key: PermissionType.boostPost,
              permissionLevel: PermissionLevel.admin,
            ),
          ],
        ),
      };

      // Act
      applyPermissions(mockBuilder, featureStates);

      // Assert
      verify(() => mockBuilder.news(false)).called(1);
      verifyNoMoreInteractions(mockBuilder);
    });
  });
}
